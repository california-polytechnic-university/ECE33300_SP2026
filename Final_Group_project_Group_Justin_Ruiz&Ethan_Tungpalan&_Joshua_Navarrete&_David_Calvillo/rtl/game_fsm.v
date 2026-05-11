

`include "connect8_defs.vh"

module game_fsm (
    input  wire        clk,
    input  wire        rst,

    input  wire        p1_drop_req,
    input  wire [2:0]  p1_drop_col,
    input  wire        p2_drop_req,
    input  wire [2:0]  p2_drop_col,

    input  wire        undo_pulse,
    input  wire        redo_pulse,
    input  wire        dump_pulse,
    input  wire        auto_tx_toggle_pulse,

    output wire [2:0]  query_col,
    input  wire [2:0]  drop_row,
    input  wire        col_full,
    input  wire        board_full,
    output reg         board_wr_en,
    output reg  [2:0]  board_wr_col,
    output reg  [2:0]  board_wr_row,
    output reg  [1:0]  board_wr_data,

    input  wire        p1_win,
    input  wire        p2_win,

    output reg         log_push_en,
    output reg  [6:0]  log_push_data,
    output reg         log_undo_en,
    output reg         log_redo_en,
    input  wire        undo_valid,
    input  wire [6:0]  undo_data,
    input  wire        redo_valid,
    input  wire [6:0]  redo_data,

    output reg         emit_single_req,
    output reg         emit_dump_req,
    input  wire        emitter_busy,

    output wire [2:0]  game_state,
    output wire        auto_tx_enabled
);

    reg [2:0] state;
    reg       last_player;
    reg       auto_tx;

    assign game_state      = state;
    assign auto_tx_enabled = auto_tx;

    assign query_col = (state == `STATE_PLAY_P1) ? p1_drop_col : p2_drop_col;

    always @(posedge clk) begin
        if (rst) begin
            state           <= `STATE_PLAY_P1;
            last_player     <= 1'b0;
            auto_tx         <= 1'b1;
            board_wr_en     <= 1'b0;
            board_wr_col    <= 3'd0;
            board_wr_row    <= 3'd0;
            board_wr_data   <= `CELL_EMPTY;
            log_push_en     <= 1'b0;
            log_push_data   <= 7'd0;
            log_undo_en     <= 1'b0;
            log_redo_en     <= 1'b0;
            emit_single_req <= 1'b0;
            emit_dump_req   <= 1'b0;
        end else begin

            board_wr_en     <= 1'b0;
            log_push_en     <= 1'b0;
            log_undo_en     <= 1'b0;
            log_redo_en     <= 1'b0;
            emit_single_req <= 1'b0;
            emit_dump_req   <= 1'b0;

            if (auto_tx_toggle_pulse) auto_tx <= ~auto_tx;
            if (dump_pulse && !emitter_busy) emit_dump_req <= 1'b1;

            case (state)

                `STATE_PLAY_P1: begin
                    if (p1_drop_req && !col_full) begin
                        board_wr_en   <= 1'b1;
                        board_wr_col  <= p1_drop_col;
                        board_wr_row  <= drop_row;
                        board_wr_data <= `CELL_P1;
                        log_push_en   <= 1'b1;
                        log_push_data <= {`P1, drop_row, p1_drop_col};
                        last_player   <= 1'b0;
                        state         <= `STATE_COMMIT;
                    end else if (undo_pulse && undo_valid) begin
                        board_wr_en   <= 1'b1;
                        board_wr_col  <= undo_data[2:0];
                        board_wr_row  <= undo_data[5:3];
                        board_wr_data <= `CELL_EMPTY;
                        log_undo_en   <= 1'b1;
                        state         <= `STATE_PLAY_P2;
                    end else if (redo_pulse && redo_valid) begin
                        board_wr_en   <= 1'b1;
                        board_wr_col  <= redo_data[2:0];
                        board_wr_row  <= redo_data[5:3];
                        board_wr_data <= redo_data[6] ? `CELL_P2 : `CELL_P1;
                        log_redo_en   <= 1'b1;
                        last_player   <= redo_data[6];
                        state         <= `STATE_COMMIT;
                    end
                end

                `STATE_PLAY_P2: begin
                    if (p2_drop_req && !col_full) begin
                        board_wr_en   <= 1'b1;
                        board_wr_col  <= p2_drop_col;
                        board_wr_row  <= drop_row;
                        board_wr_data <= `CELL_P2;
                        log_push_en   <= 1'b1;
                        log_push_data <= {`P2, drop_row, p2_drop_col};
                        last_player   <= 1'b1;
                        state         <= `STATE_COMMIT;
                    end else if (undo_pulse && undo_valid) begin
                        board_wr_en   <= 1'b1;
                        board_wr_col  <= undo_data[2:0];
                        board_wr_row  <= undo_data[5:3];
                        board_wr_data <= `CELL_EMPTY;
                        log_undo_en   <= 1'b1;
                        state         <= `STATE_PLAY_P1;
                    end else if (redo_pulse && redo_valid) begin
                        board_wr_en   <= 1'b1;
                        board_wr_col  <= redo_data[2:0];
                        board_wr_row  <= redo_data[5:3];
                        board_wr_data <= redo_data[6] ? `CELL_P2 : `CELL_P1;
                        log_redo_en   <= 1'b1;
                        last_player   <= redo_data[6];
                        state         <= `STATE_COMMIT;
                    end
                end

                `STATE_COMMIT: begin
                    if (auto_tx && !emitter_busy) emit_single_req <= 1'b1;
                    state <= `STATE_CHECK;
                end

                `STATE_CHECK: begin
                    if      (p1_win)               state <= `STATE_WIN_P1;
                    else if (p2_win)               state <= `STATE_WIN_P2;
                    else if (board_full)           state <= `STATE_DRAW;
                    else if (last_player == 1'b0)  state <= `STATE_PLAY_P2;
                    else                           state <= `STATE_PLAY_P1;
                end

                `STATE_WIN_P1, `STATE_WIN_P2, `STATE_DRAW: begin

                end

                default: state <= `STATE_PLAY_P1;
            endcase
        end
    end

endmodule
