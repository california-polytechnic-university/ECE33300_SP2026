

`include "connect8_defs.vh"

module vga_controller (
    input  wire        clk,
    input  wire        rst,
    input  wire        pix_tick,
    input  wire        blink_tick,

    input  wire [`BOARD_ROWS*`BOARD_COLS*2-1:0] board_flat,
    input  wire [15:0] sw_lvl,
    input  wire [2:0]  game_state,

    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b,
    output wire        vga_hsync,
    output wire        vga_vsync
);

    localparam H_VIS = `VGA_H_VISIBLE;
    localparam H_FRT = `VGA_H_FRONT;
    localparam H_SYN = `VGA_H_SYNC;
    localparam H_TOT = `VGA_H_TOTAL;
    localparam V_VIS = `VGA_V_VISIBLE;
    localparam V_FRT = `VGA_V_FRONT;
    localparam V_SYN = `VGA_V_SYNC;
    localparam V_TOT = `VGA_V_TOTAL;

    localparam TOP_MARGIN  = 30;
    localparam ROW_PX      = 30;
    localparam COL_HDR_Y0  = TOP_MARGIN;
    localparam COL_HDR_Y1  = COL_HDR_Y0 + ROW_PX;

    localparam CELL_PX  = 40;
    localparam BOARD_PX = CELL_PX * `BOARD_COLS;
    localparam BOARD_X0 = (H_VIS - BOARD_PX) / 2;
    localparam BOARD_X1 = BOARD_X0 + BOARD_PX;
    localparam BOARD_Y0 = COL_HDR_Y1;
    localparam BOARD_Y1 = BOARD_Y0 + BOARD_PX;

    localparam P1_Y0 = BOARD_Y1;
    localparam P1_Y1 = P1_Y0 + ROW_PX;
    localparam P2_Y0 = P1_Y1;
    localparam P2_Y1 = P2_Y0 + ROW_PX;

    reg [9:0] h_count;
    reg [9:0] v_count;

    always @(posedge clk) begin
        if (rst) begin
            h_count <= 0;
            v_count <= 0;
        end else if (pix_tick) begin
            if (h_count == H_TOT - 1) begin
                h_count <= 0;
                if (v_count == V_TOT - 1) v_count <= 0;
                else                      v_count <= v_count + 1'b1;
            end else begin
                h_count <= h_count + 1'b1;
            end
        end
    end

    assign vga_hsync = ~((h_count >= (H_VIS + H_FRT)) &&
                         (h_count <  (H_VIS + H_FRT + H_SYN)));
    assign vga_vsync = ~((v_count >= (V_VIS + V_FRT)) &&
                         (v_count <  (V_VIS + V_FRT + V_SYN)));

    wire video_on = (h_count < H_VIS) && (v_count < V_VIS);

    reg [2:0] col_idx;
    reg [5:0] cell_x;

    always @* begin
        if      (h_count < BOARD_X0 + 1*CELL_PX) begin col_idx = 3'd0; cell_x = h_count - (BOARD_X0 + 0*CELL_PX); end
        else if (h_count < BOARD_X0 + 2*CELL_PX) begin col_idx = 3'd1; cell_x = h_count - (BOARD_X0 + 1*CELL_PX); end
        else if (h_count < BOARD_X0 + 3*CELL_PX) begin col_idx = 3'd2; cell_x = h_count - (BOARD_X0 + 2*CELL_PX); end
        else if (h_count < BOARD_X0 + 4*CELL_PX) begin col_idx = 3'd3; cell_x = h_count - (BOARD_X0 + 3*CELL_PX); end
        else if (h_count < BOARD_X0 + 5*CELL_PX) begin col_idx = 3'd4; cell_x = h_count - (BOARD_X0 + 4*CELL_PX); end
        else if (h_count < BOARD_X0 + 6*CELL_PX) begin col_idx = 3'd5; cell_x = h_count - (BOARD_X0 + 5*CELL_PX); end
        else if (h_count < BOARD_X0 + 7*CELL_PX) begin col_idx = 3'd6; cell_x = h_count - (BOARD_X0 + 6*CELL_PX); end
        else                                     begin col_idx = 3'd7; cell_x = h_count - (BOARD_X0 + 7*CELL_PX); end
    end

    reg [2:0] row_idx;
    reg [5:0] cell_y;

    always @* begin
        if      (v_count < BOARD_Y0 + 1*CELL_PX) begin row_idx = 3'd0; cell_y = v_count - (BOARD_Y0 + 0*CELL_PX); end
        else if (v_count < BOARD_Y0 + 2*CELL_PX) begin row_idx = 3'd1; cell_y = v_count - (BOARD_Y0 + 1*CELL_PX); end
        else if (v_count < BOARD_Y0 + 3*CELL_PX) begin row_idx = 3'd2; cell_y = v_count - (BOARD_Y0 + 2*CELL_PX); end
        else if (v_count < BOARD_Y0 + 4*CELL_PX) begin row_idx = 3'd3; cell_y = v_count - (BOARD_Y0 + 3*CELL_PX); end
        else if (v_count < BOARD_Y0 + 5*CELL_PX) begin row_idx = 3'd4; cell_y = v_count - (BOARD_Y0 + 4*CELL_PX); end
        else if (v_count < BOARD_Y0 + 6*CELL_PX) begin row_idx = 3'd5; cell_y = v_count - (BOARD_Y0 + 5*CELL_PX); end
        else if (v_count < BOARD_Y0 + 7*CELL_PX) begin row_idx = 3'd6; cell_y = v_count - (BOARD_Y0 + 6*CELL_PX); end
        else                                     begin row_idx = 3'd7; cell_y = v_count - (BOARD_Y0 + 7*CELL_PX); end
    end

    wire in_board_x = (h_count >= BOARD_X0) && (h_count < BOARD_X1);
    wire in_board   = in_board_x && (v_count >= BOARD_Y0) && (v_count <  BOARD_Y1);
    wire in_col_hdr = in_board_x && (v_count >= COL_HDR_Y0) && (v_count <  COL_HDR_Y1);
    wire in_p1_row  = in_board_x && (v_count >= P1_Y0) && (v_count <  P1_Y1);
    wire in_p2_row  = in_board_x && (v_count >= P2_Y0) && (v_count <  P2_Y1);

    wire [1:0] cell_val = board_flat[(row_idx * `BOARD_COLS + col_idx) * 2 +: 2];

    wire is_grid_line = in_board && (
        (cell_x == 6'd0)             || (cell_x == CELL_PX - 1) ||
        (cell_y == 6'd0)             || (cell_y == CELL_PX - 1)
    );

    function [14:0] dig_3x5;
        input [3:0] d;
        begin
            case (d)
                4'd0: dig_3x5 = 15'b111_101_101_101_111;
                4'd1: dig_3x5 = 15'b010_110_010_010_111;
                4'd2: dig_3x5 = 15'b111_001_111_100_111;
                4'd3: dig_3x5 = 15'b111_001_111_001_111;
                4'd4: dig_3x5 = 15'b101_101_111_001_001;
                4'd5: dig_3x5 = 15'b111_100_111_001_111;
                4'd6: dig_3x5 = 15'b111_100_111_101_111;
                4'd7: dig_3x5 = 15'b111_001_010_010_010;
                4'd8: dig_3x5 = 15'b111_101_111_101_111;
                4'd9: dig_3x5 = 15'b111_101_111_001_111;
                default: dig_3x5 = 15'd0;
            endcase
        end
    endfunction

    wire [9:0] col_v_off = v_count - COL_HDR_Y0;
    wire [9:0] p1_v_off  = v_count - P1_Y0;
    wire [9:0] p2_v_off  = v_count - P2_Y0;

    wire col_in_y = (col_v_off >= 10'd5) && (col_v_off < 10'd25);
    wire p1_in_y  = (p1_v_off  >= 10'd5) && (p1_v_off  < 10'd25);
    wire p2_in_y  = (p2_v_off  >= 10'd5) && (p2_v_off  < 10'd25);

    wire [2:0] col_dy = (col_v_off[4:0] - 5'd5) >> 2;
    wire [2:0] p1_dy  = (p1_v_off[4:0]  - 5'd5) >> 2;
    wire [2:0] p2_dy  = (p2_v_off[4:0]  - 5'd5) >> 2;

    wire        single_in_x = (cell_x >= 6'd14) && (cell_x < 6'd26);
    wire [1:0]  single_dx   = (cell_x - 6'd14) >> 2;

    wire [3:0]  col_num    = {1'b0, col_idx};
    wire [3:0]  col_idx_b  = col_dy * 3 + single_dx;
    wire [14:0] col_bm     = dig_3x5(col_num);
    wire        col_pixel  = in_col_hdr && col_in_y && single_in_x &&
                             col_bm[4'd14 - col_idx_b];

    wire [3:0]  p1_num    = {1'b0, col_idx};
    wire [3:0]  p1_idx_b  = p1_dy * 3 + single_dx;
    wire [14:0] p1_bm     = dig_3x5(p1_num);
    wire        p1_pixel  = in_p1_row && p1_in_y && single_in_x &&
                            p1_bm[4'd14 - p1_idx_b];

    wire [3:0] p2_num   = col_idx + 4'd8;
    wire        p2_two  = (p2_num >= 4'd10);
    wire [3:0] p2_tens  = p2_two ? 4'd1 : 4'd0;
    wire [3:0] p2_ones  = p2_two ? (p2_num - 4'd10) : p2_num;

    wire        p2_tens_in_x = p2_two && (cell_x >= 6'd6)  && (cell_x < 6'd18);
    wire [1:0]  p2_tens_dx   = (cell_x - 6'd6) >> 2;
    wire [3:0]  p2_tens_idx  = p2_dy * 3 + p2_tens_dx;
    wire [14:0] p2_tens_bm   = dig_3x5(p2_tens);
    wire        p2_tens_pix  = p2_tens_in_x && p2_tens_bm[4'd14 - p2_tens_idx];

    wire [5:0]  ones_x_start = p2_two ? 6'd22 : 6'd14;
    wire        p2_ones_in_x = (cell_x >= ones_x_start) &&
                               (cell_x <  ones_x_start + 6'd12);
    wire [1:0]  p2_ones_dx   = (cell_x - ones_x_start) >> 2;
    wire [3:0]  p2_ones_idx  = p2_dy * 3 + p2_ones_dx;
    wire [14:0] p2_ones_bm   = dig_3x5(p2_ones);
    wire        p2_ones_pix  = p2_ones_in_x && p2_ones_bm[4'd14 - p2_ones_idx];

    wire p2_pixel = in_p2_row && p2_in_y && (p2_tens_pix || p2_ones_pix);

    wire p1_sw_held = sw_lvl[col_idx];
    wire p2_sw_held = sw_lvl[{1'b1, col_idx}];

    always @* begin
        if (!video_on) begin
            vga_r = 4'h0; vga_g = 4'h0; vga_b = 4'h0;
        end else if (in_col_hdr) begin

            if (col_pixel) begin
                vga_r = 4'hF; vga_g = 4'hF; vga_b = 4'hF;
            end else begin
                vga_r = 4'h0; vga_g = 4'h0; vga_b = 4'h0;
            end
        end else if (in_p1_row) begin

            if (p1_pixel) begin
                vga_r = 4'hF; vga_g = 4'h2; vga_b = 4'h2;
            end else if (p1_sw_held) begin
                vga_r = 4'h4; vga_g = 4'h0; vga_b = 4'h0;
            end else begin
                vga_r = 4'h0; vga_g = 4'h0; vga_b = 4'h0;
            end
        end else if (in_p2_row) begin

            if (p2_pixel) begin
                vga_r = 4'h2; vga_g = 4'h2; vga_b = 4'hF;
            end else if (p2_sw_held) begin
                vga_r = 4'h0; vga_g = 4'h0; vga_b = 4'h4;
            end else begin
                vga_r = 4'h0; vga_g = 4'h0; vga_b = 4'h0;
            end
        end else if (in_board) begin
            if (is_grid_line) begin
                vga_r = 4'h1; vga_g = 4'h1; vga_b = 4'h1;
            end else begin
                case (cell_val)
                    `CELL_P1: begin vga_r = 4'hF; vga_g = 4'h2; vga_b = 4'h2; end
                    `CELL_P2: begin vga_r = 4'h2; vga_g = 4'h2; vga_b = 4'hF; end
                    default:  begin vga_r = 4'h5; vga_g = 4'h5; vga_b = 4'h5; end
                endcase
            end
        end else begin

            vga_r = 4'h0; vga_g = 4'h0; vga_b = 4'h0;
        end
    end

    wire _unused_ok = &{1'b0, blink_tick, game_state, 1'b0};

endmodule
