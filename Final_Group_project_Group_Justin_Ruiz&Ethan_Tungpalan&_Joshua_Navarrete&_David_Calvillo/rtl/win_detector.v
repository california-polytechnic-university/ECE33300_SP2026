

`include "connect8_defs.vh"

module win_detector (
    input  wire [`BOARD_ROWS*`BOARD_COLS*2-1:0] board_flat,
    output wire                                 p1_win,
    output wire                                 p2_win
);

    localparam ROWS = `BOARD_ROWS;
    localparam COLS = `BOARD_COLS;
    localparam K    = `WIN_STREAK;

    localparam NH = ROWS * (COLS - K + 1);
    localparam NV = (ROWS - K + 1) * COLS;
    localparam ND = (ROWS - K + 1) * (COLS - K + 1);

    wire [NH-1:0] p1_h,  p2_h;
    wire [NV-1:0] p1_v,  p2_v;
    wire [ND-1:0] p1_dr, p2_dr;
    wire [ND-1:0] p1_dl, p2_dl;

    genvar gr, gc;

    generate
        for (gr = 0; gr < ROWS; gr = gr + 1) begin : G_H_R
            for (gc = 0; gc <= COLS - K; gc = gc + 1) begin : G_H_C
                wire [1:0] c0 = board_flat[(gr*COLS + gc + 0)*2 +: 2];
                wire [1:0] c1 = board_flat[(gr*COLS + gc + 1)*2 +: 2];
                wire [1:0] c2 = board_flat[(gr*COLS + gc + 2)*2 +: 2];
                wire [1:0] c3 = board_flat[(gr*COLS + gc + 3)*2 +: 2];
                assign p1_h[gr*(COLS-K+1) + gc] =
                    (c0 == `CELL_P1) & (c1 == `CELL_P1) & (c2 == `CELL_P1) & (c3 == `CELL_P1);
                assign p2_h[gr*(COLS-K+1) + gc] =
                    (c0 == `CELL_P2) & (c1 == `CELL_P2) & (c2 == `CELL_P2) & (c3 == `CELL_P2);
            end
        end
    endgenerate

    generate
        for (gr = 0; gr <= ROWS - K; gr = gr + 1) begin : G_V_R
            for (gc = 0; gc < COLS; gc = gc + 1) begin : G_V_C
                wire [1:0] c0 = board_flat[((gr+0)*COLS + gc)*2 +: 2];
                wire [1:0] c1 = board_flat[((gr+1)*COLS + gc)*2 +: 2];
                wire [1:0] c2 = board_flat[((gr+2)*COLS + gc)*2 +: 2];
                wire [1:0] c3 = board_flat[((gr+3)*COLS + gc)*2 +: 2];
                assign p1_v[gr*COLS + gc] =
                    (c0 == `CELL_P1) & (c1 == `CELL_P1) & (c2 == `CELL_P1) & (c3 == `CELL_P1);
                assign p2_v[gr*COLS + gc] =
                    (c0 == `CELL_P2) & (c1 == `CELL_P2) & (c2 == `CELL_P2) & (c3 == `CELL_P2);
            end
        end
    endgenerate

    generate
        for (gr = 0; gr <= ROWS - K; gr = gr + 1) begin : G_DR_R
            for (gc = 0; gc <= COLS - K; gc = gc + 1) begin : G_DR_C
                wire [1:0] c0 = board_flat[((gr+0)*COLS + (gc+0))*2 +: 2];
                wire [1:0] c1 = board_flat[((gr+1)*COLS + (gc+1))*2 +: 2];
                wire [1:0] c2 = board_flat[((gr+2)*COLS + (gc+2))*2 +: 2];
                wire [1:0] c3 = board_flat[((gr+3)*COLS + (gc+3))*2 +: 2];
                assign p1_dr[gr*(COLS-K+1) + gc] =
                    (c0 == `CELL_P1) & (c1 == `CELL_P1) & (c2 == `CELL_P1) & (c3 == `CELL_P1);
                assign p2_dr[gr*(COLS-K+1) + gc] =
                    (c0 == `CELL_P2) & (c1 == `CELL_P2) & (c2 == `CELL_P2) & (c3 == `CELL_P2);
            end
        end
    endgenerate

    generate
        for (gr = 0; gr <= ROWS - K; gr = gr + 1) begin : G_DL_R
            for (gc = K - 1; gc < COLS; gc = gc + 1) begin : G_DL_C
                wire [1:0] c0 = board_flat[((gr+0)*COLS + (gc-0))*2 +: 2];
                wire [1:0] c1 = board_flat[((gr+1)*COLS + (gc-1))*2 +: 2];
                wire [1:0] c2 = board_flat[((gr+2)*COLS + (gc-2))*2 +: 2];
                wire [1:0] c3 = board_flat[((gr+3)*COLS + (gc-3))*2 +: 2];
                assign p1_dl[gr*(COLS-K+1) + (gc - (K-1))] =
                    (c0 == `CELL_P1) & (c1 == `CELL_P1) & (c2 == `CELL_P1) & (c3 == `CELL_P1);
                assign p2_dl[gr*(COLS-K+1) + (gc - (K-1))] =
                    (c0 == `CELL_P2) & (c1 == `CELL_P2) & (c2 == `CELL_P2) & (c3 == `CELL_P2);
            end
        end
    endgenerate

    assign p1_win = (|p1_h) | (|p1_v) | (|p1_dr) | (|p1_dl);
    assign p2_win = (|p2_h) | (|p2_v) | (|p2_dr) | (|p2_dl);

endmodule
