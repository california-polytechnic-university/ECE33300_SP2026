

`timescale 1ns / 1ps
`include "connect8_defs.vh"

module connect8_tb;

    reg clk;
    reg rst;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    reg        p1_drop_req;
    reg [2:0]  p1_drop_col;
    reg        p2_drop_req;
    reg [2:0]  p2_drop_col;
    reg        undo_pulse;
    reg        redo_pulse;
    reg        dump_pulse;
    reg        auto_tx_toggle_pulse;

    wire [`BOARD_ROWS*`BOARD_COLS*2-1:0] board_flat;
    wire [2:0]  query_col;
    wire [2:0]  drop_row;
    wire        col_full;
    wire        board_full;

    wire        board_wr_en;
    wire [2:0]  board_wr_col, board_wr_row;
    wire [1:0]  board_wr_data;

    wire        log_push_en, log_undo_en, log_redo_en;
    wire [6:0]  log_push_data, undo_data, redo_data;
    wire        undo_valid, redo_valid;
    wire [6:0]  cur_ptr_out;

    wire [5:0]  emitter_read_idx;
    wire [6:0]  emitter_read_data;
    wire        emit_single_req, emit_dump_req, emitter_busy;

    wire        tx_wr_en;
    wire [7:0]  tx_din;
    wire        tx_full;
    wire        uart_tx_line;

    wire        p1_win, p2_win;
    wire [2:0]  game_state;
    wire        auto_tx_enabled;

    game_board u_board (
        .clk(clk), .rst(rst),
        .wr_en(board_wr_en), .wr_col(board_wr_col),
        .wr_row(board_wr_row), .wr_data(board_wr_data),
        .query_col(query_col), .drop_row(drop_row),
        .col_full(col_full), .board_flat(board_flat),
        .board_full(board_full)
    );

    move_log #(.DEPTH(64)) u_log (
        .clk(clk), .rst(rst),
        .push_en(log_push_en), .push_data(log_push_data),
        .undo_en(log_undo_en), .undo_valid(undo_valid), .undo_data(undo_data),
        .redo_en(log_redo_en), .redo_valid(redo_valid), .redo_data(redo_data),
        .read_idx(emitter_read_idx), .read_data(emitter_read_data),
        .cur_ptr_out(cur_ptr_out)
    );

    win_detector u_win (
        .board_flat(board_flat), .p1_win(p1_win), .p2_win(p2_win)
    );

    game_fsm u_fsm (
        .clk(clk), .rst(rst),
        .p1_drop_req(p1_drop_req), .p1_drop_col(p1_drop_col),
        .p2_drop_req(p2_drop_req), .p2_drop_col(p2_drop_col),
        .undo_pulse(undo_pulse), .redo_pulse(redo_pulse),
        .dump_pulse(dump_pulse), .auto_tx_toggle_pulse(auto_tx_toggle_pulse),
        .query_col(query_col), .drop_row(drop_row),
        .col_full(col_full), .board_full(board_full),
        .board_wr_en(board_wr_en), .board_wr_col(board_wr_col),
        .board_wr_row(board_wr_row), .board_wr_data(board_wr_data),
        .p1_win(p1_win), .p2_win(p2_win),
        .log_push_en(log_push_en), .log_push_data(log_push_data),
        .log_undo_en(log_undo_en), .log_redo_en(log_redo_en),
        .undo_valid(undo_valid), .undo_data(undo_data),
        .redo_valid(redo_valid), .redo_data(redo_data),
        .emit_single_req(emit_single_req), .emit_dump_req(emit_dump_req),
        .emitter_busy(emitter_busy),
        .game_state(game_state), .auto_tx_enabled(auto_tx_enabled)
    );

    uart_emitter #(.LOG_DEPTH(64)) u_emit (
        .clk(clk), .rst(rst),
        .single_req(emit_single_req), .dump_req(emit_dump_req),
        .read_idx(emitter_read_idx), .read_data(emitter_read_data),
        .cur_ptr_in(cur_ptr_out),
        .tx_wr_en(tx_wr_en), .tx_din(tx_din), .tx_full(tx_full),
        .busy(emitter_busy)
    );

    uart_tx u_uart (
        .clk(clk), .rst(rst),
        .wr_en(tx_wr_en), .din(tx_din),
        .fifo_full(tx_full), .tx(uart_tx_line)
    );

    reg [7:0] uart_buf [0:511];
    integer   uart_count;

    always @(posedge clk) begin
        if (rst) begin
            uart_count <= 0;
        end else if (tx_wr_en) begin
            uart_buf[uart_count] <= tx_din;
            uart_count           <= uart_count + 1;
        end
    end

    integer pass_count;
    integer fail_count;

    task reset_dut;
        begin
            rst                  = 1'b1;
            p1_drop_req          = 1'b0;
            p1_drop_col          = 3'd0;
            p2_drop_req          = 1'b0;
            p2_drop_col          = 3'd0;
            undo_pulse           = 1'b0;
            redo_pulse           = 1'b0;
            dump_pulse           = 1'b0;
            auto_tx_toggle_pulse = 1'b0;
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            rst = 1'b0;
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    task play_move;
        input       player;
        input [2:0] col;
        begin
            @(posedge clk);
            if (player == 1'b0) begin
                p1_drop_col <= col;
                p1_drop_req <= 1'b1;
            end else begin
                p2_drop_col <= col;
                p2_drop_req <= 1'b1;
            end
            @(posedge clk);
            p1_drop_req <= 1'b0;
            p2_drop_req <= 1'b0;
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    task pulse_undo;
        begin
            @(posedge clk);
            undo_pulse <= 1'b1;
            @(posedge clk);
            undo_pulse <= 1'b0;
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    task pulse_redo;
        begin
            @(posedge clk);
            redo_pulse <= 1'b1;
            @(posedge clk);
            redo_pulse <= 1'b0;
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    task pulse_dump;
        begin
            @(posedge clk);
            dump_pulse <= 1'b1;
            @(posedge clk);
            dump_pulse <= 1'b0;
            @(posedge clk);
        end
    endtask

    task wait_uart_idle;
        integer i;
        begin

            @(posedge clk);
            @(posedge clk);
            i = 0;

            while (emitter_busy && i < 5000) begin
                @(posedge clk);
                i = i + 1;
            end
        end
    endtask

    task expect_state;
        input [2:0]   expected;
        input [511:0] msg;
        begin
            if (game_state === expected) begin
                $display("  [PASS] state=%0d  (%0s)", game_state, msg);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] state expected %0d, got %0d  (%0s)",
                         expected, game_state, msg);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task expect_cell;
        input [2:0]   row;
        input [2:0]   col;
        input [1:0]   expected;
        reg   [1:0]   actual;
        begin
            actual = board_flat[(row * `BOARD_COLS + col) * 2 +: 2];
            if (actual === expected) begin
                $display("  [PASS] cell[%0d][%0d]=%b", row, col, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] cell[%0d][%0d] expected %b, got %b",
                         row, col, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task expect_eq;
        input integer   actual;
        input integer   expected;
        input [511:0]   msg;
        begin
            if (actual === expected) begin
                $display("  [PASS] %0s = %0d", msg, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %0s expected %0d, got %0d",
                         msg, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task expect_uart_byte;
        input integer   idx;
        input [7:0]     expected;
        begin
            if (uart_buf[idx] === expected) begin
                $display("  [PASS] uart[%0d] = '%c' (0x%02h)",
                         idx, uart_buf[idx], uart_buf[idx]);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] uart[%0d] expected '%c' (0x%02h), got '%c' (0x%02h)",
                         idx, expected, expected,
                         uart_buf[idx], uart_buf[idx]);
                fail_count = fail_count + 1;
            end
        end
    endtask

    integer i;

    initial begin
        $dumpfile("connect8_tb.vcd");
        $dumpvars(0, connect8_tb);

        pass_count = 0;
        fail_count = 0;

        $display("===========================================================");
        $display(" Connect-8 Master Testbench");
        $display("===========================================================");

        $display("\n--- TEST 1: Reset state ---");
        reset_dut();
        expect_state(`STATE_PLAY_P1, "after reset");
        expect_eq(cur_ptr_out, 0,    "move count after reset");
        for (i = 0; i < 8; i = i + 1) begin
            expect_cell(7, i[2:0], `CELL_EMPTY);
        end

        $display("\n--- TEST 2: Single drop ---");
        reset_dut();
        play_move(0, 3'd3);
        expect_cell(7, 3, `CELL_P1);
        expect_state(`STATE_PLAY_P2, "P2 to play after P1 drop");
        expect_eq(cur_ptr_out, 1, "move count after one move");

        $display("\n--- TEST 3: Gravity stacking ---");
        reset_dut();
        play_move(0, 3'd4);
        play_move(1, 3'd4);
        play_move(0, 3'd4);
        expect_cell(7, 4, `CELL_P1);
        expect_cell(6, 4, `CELL_P2);
        expect_cell(5, 4, `CELL_P1);

        $display("\n--- TEST 4: Horizontal win (P1, row 7, cols 0-3) ---");
        reset_dut();
        play_move(0, 3'd0);
        play_move(1, 3'd0);
        play_move(0, 3'd1);
        play_move(1, 3'd1);
        play_move(0, 3'd2);
        play_move(1, 3'd2);
        play_move(0, 3'd3);
        expect_state(`STATE_WIN_P1, "horizontal P1 win");
        expect_cell(7, 0, `CELL_P1);
        expect_cell(7, 1, `CELL_P1);
        expect_cell(7, 2, `CELL_P1);
        expect_cell(7, 3, `CELL_P1);

        $display("\n--- TEST 5: Vertical win (P2, col 1, uses for loop) ---");
        reset_dut();
        for (i = 0; i < 4; i = i + 1) begin
            play_move(0, (i[0] ? 3'd2 : 3'd0));
            play_move(1, 3'd1);
        end
        expect_state(`STATE_WIN_P2, "vertical P2 win");
        expect_cell(7, 1, `CELL_P2);
        expect_cell(6, 1, `CELL_P2);
        expect_cell(5, 1, `CELL_P2);
        expect_cell(4, 1, `CELL_P2);

        $display("\n--- TEST 6: Diagonal '\\' win for P1 ---");
        reset_dut();
        play_move(0, 3'd3);
        play_move(1, 3'd2);
        play_move(0, 3'd2);
        play_move(1, 3'd1);
        play_move(0, 3'd4);
        play_move(1, 3'd1);
        play_move(0, 3'd1);
        play_move(1, 3'd0);
        play_move(0, 3'd4);
        play_move(1, 3'd0);
        play_move(0, 3'd4);
        play_move(1, 3'd0);
        play_move(0, 3'd0);
        expect_state(`STATE_WIN_P1, "diagonal P1 win");
        expect_cell(4, 0, `CELL_P1);
        expect_cell(5, 1, `CELL_P1);
        expect_cell(6, 2, `CELL_P1);
        expect_cell(7, 3, `CELL_P1);

        $display("\n--- TEST 7: Undo last move ---");
        reset_dut();
        play_move(0, 3'd3);
        play_move(1, 3'd4);
        expect_eq(cur_ptr_out, 2, "before undo");
        pulse_undo();
        expect_cell(7, 4, `CELL_EMPTY);
        expect_state(`STATE_PLAY_P2, "after undo, P2 to replay");
        expect_eq(cur_ptr_out, 1, "after undo");

        $display("\n--- TEST 8: Redo ---");

        pulse_redo();
        expect_cell(7, 4, `CELL_P2);
        expect_state(`STATE_PLAY_P1, "after redo, P1 to play");
        expect_eq(cur_ptr_out, 2, "after redo");

        $display("\n--- TEST 9: Push truncates redo history ---");
        reset_dut();
        play_move(0, 3'd0);
        play_move(1, 3'd1);
        play_move(0, 3'd2);
        pulse_undo();
        pulse_undo();
        expect_eq(cur_ptr_out, 1, "after 2 undos");

        play_move(1, 3'd5);
        expect_eq(cur_ptr_out, 2, "after new push");

        if (redo_valid) begin
            $display("  [FAIL] redo_valid still high after push truncation");
            fail_count = fail_count + 1;
        end else begin
            $display("  [PASS] redo_valid is low after push truncation");
            pass_count = pass_count + 1;
        end

        $display("\n--- TEST 10: Column-full drop ignored ---");
        reset_dut();

        for (i = 0; i < 4; i = i + 1) begin
            play_move(0, 3'd7);
            play_move(1, 3'd7);
        end

        expect_eq(cur_ptr_out, 8, "col 7 fully filled");

        @(posedge clk);
        p1_drop_col <= 3'd7;
        p1_drop_req <= 1'b1;
        @(posedge clk);
        p1_drop_req <= 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        expect_eq(cur_ptr_out, 8, "move count unchanged after blocked drop");
        expect_state(`STATE_PLAY_P1, "still P1's turn after blocked drop");

        $display("\n--- TEST 11: UART per-move emit ---");
        reset_dut();
        play_move(0, 3'd3);
        wait_uart_idle();
        expect_eq(uart_count, 6, "6 bytes pushed for one move");
        expect_uart_byte(0, "P");
        expect_uart_byte(1, "1");
        expect_uart_byte(2, ":");
        expect_uart_byte(3, "3");
        expect_uart_byte(4, 8'h0D);
        expect_uart_byte(5, 8'h0A);

        $display("\n--- TEST 12: UART manual dump ---");
        reset_dut();

        @(posedge clk);
        auto_tx_toggle_pulse <= 1'b1;
        @(posedge clk);
        auto_tx_toggle_pulse <= 1'b0;
        @(posedge clk);
        @(posedge clk);
        play_move(0, 3'd5);
        play_move(1, 3'd2);
        wait_uart_idle();
        expect_eq(uart_count, 0, "no per-move bytes when auto-tx is off");

        pulse_dump();
        wait_uart_idle();
        expect_eq(uart_count, 12, "12 bytes from dump (2 moves x 6)");

        expect_uart_byte(0, "P");
        expect_uart_byte(1, "1");
        expect_uart_byte(2, ":");
        expect_uart_byte(3, "5");
        expect_uart_byte(4, 8'h0D);
        expect_uart_byte(5, 8'h0A);

        expect_uart_byte(6,  "P");
        expect_uart_byte(7,  "2");
        expect_uart_byte(8,  ":");
        expect_uart_byte(9,  "2");
        expect_uart_byte(10, 8'h0D);
        expect_uart_byte(11, 8'h0A);

        $display("\n===========================================================");
        $display(" RESULTS: %0d passed, %0d failed", pass_count, fail_count);
        $display("===========================================================");
        if (fail_count == 0)
            $display(" *** ALL TESTS PASSED ***");
        else
            $display(" *** %0d TEST(S) FAILED ***", fail_count);
        $display("===========================================================");

        $finish;
    end

    initial begin
        #2_000_000;
        $display("[TIMEOUT] simulation ran too long, finishing");
        $finish;
    end

endmodule
