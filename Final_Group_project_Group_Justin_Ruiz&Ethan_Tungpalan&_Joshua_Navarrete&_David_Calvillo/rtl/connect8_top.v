

`include "connect8_defs.vh"

module connect8_top (

    input  wire        CLK100MHZ,

    input  wire [15:0] sw,
    input  wire        btnC,
    input  wire        btnU,
    input  wire        btnD,
    input  wire        btnL,
    input  wire        btnR,

    output wire [15:0] led,
    output wire        LED16_R,
    output wire        LED16_G,
    output wire        LED16_B,
    output wire        LED17_R,
    output wire        LED17_G,
    output wire        LED17_B,

    output wire [6:0]  seg,
    output wire        dp,
    output wire [7:0]  an,

    output wire [3:0]  vgaRed,
    output wire [3:0]  vgaGreen,
    output wire [3:0]  vgaBlue,
    output wire        Hsync,
    output wire        Vsync,

    output wire        UART_RXD_OUT
);

    wire clk = CLK100MHZ;
    wire rst;

    wire pix_tick, slow_tick, blink_tick;

    wire        p1_drop_req, p2_drop_req;
    wire [2:0]  p1_drop_col, p2_drop_col;
    wire        undo_pulse, redo_pulse, dump_pulse, auto_tx_toggle_pulse;

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

    wire        p1_win, p2_win;

    wire [2:0]  game_state;
    wire        auto_tx_enabled;

    wire [15:0] sw_lvl;

    clk_divider u_clkdiv (
        .clk        (clk),
        .rst        (1'b0),
        .pix_tick   (pix_tick),
        .slow_tick  (slow_tick),
        .blink_tick (blink_tick)
    );

    input_ctrl u_input (
        .clk                  (clk),
        .slow_tick            (slow_tick),
        .btnc_raw             (btnC),
        .btnu_raw             (btnU),
        .btnd_raw             (btnD),
        .btnl_raw             (btnL),
        .btnr_raw             (btnR),
        .sw_raw               (sw),
        .rst                  (rst),
        .dump_pulse           (dump_pulse),
        .auto_tx_toggle_pulse (auto_tx_toggle_pulse),
        .undo_pulse           (undo_pulse),
        .redo_pulse           (redo_pulse),
        .p1_drop_req          (p1_drop_req),
        .p1_drop_col          (p1_drop_col),
        .p2_drop_req          (p2_drop_req),
        .p2_drop_col          (p2_drop_col),
        .sw_lvl               (sw_lvl)
    );

    game_board u_board (
        .clk         (clk),
        .rst         (rst),
        .wr_en       (board_wr_en),
        .wr_col      (board_wr_col),
        .wr_row      (board_wr_row),
        .wr_data     (board_wr_data),
        .query_col   (query_col),
        .drop_row    (drop_row),
        .col_full    (col_full),
        .board_flat  (board_flat),
        .board_full  (board_full)
    );

    move_log #(.DEPTH(64)) u_log (
        .clk         (clk),
        .rst         (rst),
        .push_en     (log_push_en),
        .push_data   (log_push_data),
        .undo_en     (log_undo_en),
        .undo_valid  (undo_valid),
        .undo_data   (undo_data),
        .redo_en     (log_redo_en),
        .redo_valid  (redo_valid),
        .redo_data   (redo_data),
        .read_idx    (emitter_read_idx),
        .read_data   (emitter_read_data),
        .cur_ptr_out (cur_ptr_out)
    );

    win_detector u_win (
        .board_flat (board_flat),
        .p1_win     (p1_win),
        .p2_win     (p2_win)
    );

    game_fsm u_fsm (
        .clk                  (clk),
        .rst                  (rst),
        .p1_drop_req          (p1_drop_req),
        .p1_drop_col          (p1_drop_col),
        .p2_drop_req          (p2_drop_req),
        .p2_drop_col          (p2_drop_col),
        .undo_pulse           (undo_pulse),
        .redo_pulse           (redo_pulse),
        .dump_pulse           (dump_pulse),
        .auto_tx_toggle_pulse (auto_tx_toggle_pulse),
        .query_col            (query_col),
        .drop_row             (drop_row),
        .col_full             (col_full),
        .board_full           (board_full),
        .board_wr_en          (board_wr_en),
        .board_wr_col         (board_wr_col),
        .board_wr_row         (board_wr_row),
        .board_wr_data        (board_wr_data),
        .p1_win               (p1_win),
        .p2_win               (p2_win),
        .log_push_en          (log_push_en),
        .log_push_data        (log_push_data),
        .log_undo_en          (log_undo_en),
        .log_redo_en          (log_redo_en),
        .undo_valid           (undo_valid),
        .undo_data            (undo_data),
        .redo_valid           (redo_valid),
        .redo_data            (redo_data),
        .emit_single_req      (emit_single_req),
        .emit_dump_req        (emit_dump_req),
        .emitter_busy         (emitter_busy),
        .game_state           (game_state),
        .auto_tx_enabled      (auto_tx_enabled)
    );

    uart_emitter #(.LOG_DEPTH(64)) u_emit (
        .clk         (clk),
        .rst         (rst),
        .single_req  (emit_single_req),
        .dump_req    (emit_dump_req),
        .read_idx    (emitter_read_idx),
        .read_data   (emitter_read_data),
        .cur_ptr_in  (cur_ptr_out),
        .tx_wr_en    (tx_wr_en),
        .tx_din      (tx_din),
        .tx_full     (tx_full),
        .busy        (emitter_busy)
    );

    uart_tx u_uart (
        .clk        (clk),
        .rst        (rst),
        .wr_en      (tx_wr_en),
        .din        (tx_din),
        .fifo_full  (tx_full),
        .tx         (UART_RXD_OUT)
    );

    vga_controller u_vga (
        .clk        (clk),
        .rst        (rst),
        .pix_tick   (pix_tick),
        .blink_tick (blink_tick),
        .board_flat (board_flat),
        .sw_lvl     (sw_lvl),
        .game_state (game_state),
        .vga_r      (vgaRed),
        .vga_g      (vgaGreen),
        .vga_b      (vgaBlue),
        .vga_hsync  (Hsync),
        .vga_vsync  (Vsync)
    );

    seven_seg_driver u_ssd (
        .clk        (clk),
        .rst        (rst),
        .blink_tick (blink_tick),
        .game_state (game_state),
        .move_count (cur_ptr_out),
        .an         (an),
        .seg        (seg),
        .dp         (dp)
    );

    led_driver u_led (
        .clk        (clk),
        .rst        (rst),
        .blink_tick (blink_tick),
        .game_state (game_state),
        .sw_lvl     (sw_lvl),
        .led        (led),
        .led16_r    (LED16_R),
        .led16_g    (LED16_G),
        .led16_b    (LED16_B),
        .led17_r    (LED17_R),
        .led17_g    (LED17_G),
        .led17_b    (LED17_B)
    );

endmodule
