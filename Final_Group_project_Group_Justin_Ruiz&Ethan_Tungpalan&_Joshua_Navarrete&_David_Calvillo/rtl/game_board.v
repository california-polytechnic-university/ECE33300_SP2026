

`include "connect8_defs.vh"

module game_board (
    input  wire        clk,
    input  wire        rst,

    input  wire        wr_en,
    input  wire [2:0]  wr_col,
    input  wire [2:0]  wr_row,
    input  wire [1:0]  wr_data,

    input  wire [2:0]  query_col,
    output wire [2:0]  drop_row,
    output wire        col_full,

    output wire [`BOARD_ROWS*`BOARD_COLS*2-1:0] board_flat,
    output wire                                 board_full
);

    reg [1:0] cells [0:`BOARD_ROWS-1][0:`BOARD_COLS-1];

    integer i, j;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < `BOARD_ROWS; i = i + 1)
                for (j = 0; j < `BOARD_COLS; j = j + 1)
                    cells[i][j] <= `CELL_EMPTY;
        end else if (wr_en) begin
            cells[wr_row][wr_col] <= wr_data;
        end
    end

    reg [2:0] drop_row_r;
    reg       col_full_r;
    integer   k;

    always @* begin
        drop_row_r = 3'd0;
        col_full_r = 1'b1;
        for (k = 0; k < `BOARD_ROWS; k = k + 1) begin
            if (cells[k][query_col] == `CELL_EMPTY) begin
                drop_row_r = k[2:0];
                col_full_r = 1'b0;
            end
        end
    end

    assign drop_row = drop_row_r;
    assign col_full = col_full_r;

    genvar gr, gc;
    generate
        for (gr = 0; gr < `BOARD_ROWS; gr = gr + 1) begin : G_FLAT_ROW
            for (gc = 0; gc < `BOARD_COLS; gc = gc + 1) begin : G_FLAT_COL
                assign board_flat[(gr*`BOARD_COLS + gc)*2 +: 2] = cells[gr][gc];
            end
        end
    endgenerate

    reg board_full_r;
    integer m, n;
    always @* begin
        board_full_r = 1'b1;
        for (m = 0; m < `BOARD_ROWS; m = m + 1)
            for (n = 0; n < `BOARD_COLS; n = n + 1)
                if (cells[m][n] == `CELL_EMPTY) board_full_r = 1'b0;
    end
    assign board_full = board_full_r;

endmodule
