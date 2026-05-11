`timescale 1ns / 1ps


module moving_object_sprite_gen(
    output reg [2:0] vga_out,
    input      [9:0] scan_pix_x,
    input      [8:0] scan_pix_y,

    input      [9:0] pacman_x,
    input      [8:0] pacman_y,
    input      [3:0] pacman_dir,

    input      [9:0] ghost1_x,
    input      [8:0] ghost1_y,
    input      [3:0] ghost1_dir,

    input      [9:0] ghost2_x,
    input      [8:0] ghost2_y,
    input      [3:0] ghost2_dir,

    input      [9:0] ghost3_x,
    input      [8:0] ghost3_y,
    input      [3:0] ghost3_dir,

    input      [9:0] ghost4_x,
    input      [8:0] ghost4_y,
    input      [3:0] ghost4_dir,

    input      [3:0] ghost_eaten,
    input            power_mode,
    input            animation_clk,
    input            clk_100mhz,
    input      [1:0] clk_100mhz_phase
);

    localparam BLACK  = 3'b000;
    localparam RED    = 3'b001;
    localparam GREEN  = 3'b010;
    localparam YELLOW = 3'b011;
    localparam BLUE   = 3'b100;
    localparam PINK   = 3'b101;
    localparam CYAN   = 3'b110;
    localparam WHITE  = 3'b111;

    wire pacman_anim = animation_clk;
    wire ghost_anim  = animation_clk;

    function pixel_from_mask;
        input [15:0] mask;
        input [4:0]  x;
        begin
            pixel_from_mask = (x <= 5'd15) ? mask[15 - x] : 1'b0;
        end
    endfunction

    function [15:0] pac_row_mask;
        input [4:0] y;
        begin
            case (y)
                5'd0:  pac_row_mask = 16'b0000011111100000;
                5'd1:  pac_row_mask = 16'b0001111111111000;
                5'd2:  pac_row_mask = 16'b0011111111111100;
                5'd3:  pac_row_mask = 16'b0111111111111110;
                5'd4:  pac_row_mask = 16'b0111111111111110;
                5'd5:  pac_row_mask = 16'b1111111111111111;
                5'd6:  pac_row_mask = 16'b1111111111111111;
                5'd7:  pac_row_mask = 16'b1111111111111111;
                5'd8:  pac_row_mask = 16'b1111111111111111;
                5'd9:  pac_row_mask = 16'b1111111111111111;
                5'd10: pac_row_mask = 16'b1111111111111111;
                5'd11: pac_row_mask = 16'b1111111111111111;
                5'd12: pac_row_mask = 16'b0111111111111110;
                5'd13: pac_row_mask = 16'b0111111111111110;
                5'd14: pac_row_mask = 16'b0011111111111100;
                5'd15: pac_row_mask = 16'b0001111111111000;
                default: pac_row_mask = 16'b0000000000000000;
            endcase
        end
    endfunction

    function [15:0] ghost_row_mask_frame0;
        input [4:0] y;
        begin
            case (y)
                5'd0:  ghost_row_mask_frame0 = 16'b0000111111110000;
                5'd1:  ghost_row_mask_frame0 = 16'b0001111111111000;
                5'd2:  ghost_row_mask_frame0 = 16'b0011111111111100;
                5'd3:  ghost_row_mask_frame0 = 16'b0111111111111110;
                5'd4:  ghost_row_mask_frame0 = 16'b0111111111111110;
                5'd5:  ghost_row_mask_frame0 = 16'b0111111111111110;
                5'd6:  ghost_row_mask_frame0 = 16'b0111111111111110;
                5'd7:  ghost_row_mask_frame0 = 16'b0111111111111110;
                5'd8:  ghost_row_mask_frame0 = 16'b0111111111111110;
                5'd9:  ghost_row_mask_frame0 = 16'b0111111111111110;
                5'd10: ghost_row_mask_frame0 = 16'b0111111111111110;
                5'd11: ghost_row_mask_frame0 = 16'b0111111111111110;
                5'd12: ghost_row_mask_frame0 = 16'b0111111111111110;
                5'd13: ghost_row_mask_frame0 = 16'b0110110110110110;
                5'd14: ghost_row_mask_frame0 = 16'b0010010010010010;
                default: ghost_row_mask_frame0 = 16'b0000000000000000;
            endcase
        end
    endfunction

    function [15:0] ghost_row_mask_frame1;
        input [4:0] y;
        begin
            case (y)
                5'd0:  ghost_row_mask_frame1 = 16'b0000111111110000;
                5'd1:  ghost_row_mask_frame1 = 16'b0001111111111000;
                5'd2:  ghost_row_mask_frame1 = 16'b0011111111111100;
                5'd3:  ghost_row_mask_frame1 = 16'b0111111111111110;
                5'd4:  ghost_row_mask_frame1 = 16'b0111111111111110;
                5'd5:  ghost_row_mask_frame1 = 16'b0111111111111110;
                5'd6:  ghost_row_mask_frame1 = 16'b0111111111111110;
                5'd7:  ghost_row_mask_frame1 = 16'b0111111111111110;
                5'd8:  ghost_row_mask_frame1 = 16'b0111111111111110;
                5'd9:  ghost_row_mask_frame1 = 16'b0111111111111110;
                5'd10: ghost_row_mask_frame1 = 16'b0111111111111110;
                5'd11: ghost_row_mask_frame1 = 16'b0111111111111110;
                5'd12: ghost_row_mask_frame1 = 16'b0111111111111110;
                5'd13: ghost_row_mask_frame1 = 16'b0011011011011010;
                5'd14: ghost_row_mask_frame1 = 16'b0001001001001000;
                default: ghost_row_mask_frame1 = 16'b0000000000000000;
            endcase
        end
    endfunction

    function [4:0] abs5;
        input [4:0] a;
        input [4:0] b;
        begin
            abs5 = (a >= b) ? (a - b) : (b - a);
        end
    endfunction

    wire in_pacman = (scan_pix_x >= pacman_x) && (scan_pix_x < pacman_x + 10'd16) &&
                     (scan_pix_y >= pacman_y) && (scan_pix_y < pacman_y + 9'd16);

    wire in_g1 = (scan_pix_x >= ghost1_x) && (scan_pix_x < ghost1_x + 10'd16) &&
                 (scan_pix_y >= ghost1_y) && (scan_pix_y < ghost1_y + 9'd16);
    wire in_g2 = (scan_pix_x >= ghost2_x) && (scan_pix_x < ghost2_x + 10'd16) &&
                 (scan_pix_y >= ghost2_y) && (scan_pix_y < ghost2_y + 9'd16);
    wire in_g3 = (scan_pix_x >= ghost3_x) && (scan_pix_x < ghost3_x + 10'd16) &&
                 (scan_pix_y >= ghost3_y) && (scan_pix_y < ghost3_y + 9'd16);
    wire in_g4 = (scan_pix_x >= ghost4_x) && (scan_pix_x < ghost4_x + 10'd16) &&
                 (scan_pix_y >= ghost4_y) && (scan_pix_y < ghost4_y + 9'd16);

    wire [4:0] pac_lx = scan_pix_x - pacman_x;
    wire [4:0] pac_ly = scan_pix_y - pacman_y;
    wire [4:0] g1_lx  = scan_pix_x - ghost1_x;
    wire [4:0] g1_ly  = scan_pix_y - ghost1_y;
    wire [4:0] g2_lx  = scan_pix_x - ghost2_x;
    wire [4:0] g2_ly  = scan_pix_y - ghost2_y;
    wire [4:0] g3_lx  = scan_pix_x - ghost3_x;
    wire [4:0] g3_ly  = scan_pix_y - ghost3_y;
    wire [4:0] g4_lx  = scan_pix_x - ghost4_x;
    wire [4:0] g4_ly  = scan_pix_y - ghost4_y;

    wire pacman_base = in_pacman && pixel_from_mask(pac_row_mask(pac_ly), pac_lx);
    wire pacman_moving = (pacman_dir != 4'b0000);

    wire pac_mouth_right = pacman_moving && pacman_anim && (pacman_dir == 4'b0010) &&
                           (pac_lx >= 5'd8) && (abs5(pac_ly, 5'd7) <= (pac_lx - 5'd7));
    wire pac_mouth_left  = pacman_moving && pacman_anim && (pacman_dir == 4'b0001) &&
                           (pac_lx <= 5'd7) && (abs5(pac_ly, 5'd7) <= (5'd8 - pac_lx));
    wire pac_mouth_up    = pacman_moving && pacman_anim && (pacman_dir == 4'b0100) &&
                           (pac_ly <= 5'd7) && (abs5(pac_lx, 5'd7) <= (5'd8 - pac_ly));
    wire pac_mouth_down  = pacman_moving && pacman_anim && (pacman_dir == 4'b1000) &&
                           (pac_ly >= 5'd8) && (abs5(pac_lx, 5'd7) <= (pac_ly - 5'd7));

    wire pacman_draw = pacman_base && !(pac_mouth_right || pac_mouth_left || pac_mouth_up || pac_mouth_down);

    wire g1_body_raw = in_g1 && pixel_from_mask(ghost_anim ? ghost_row_mask_frame1(g1_ly) : ghost_row_mask_frame0(g1_ly), g1_lx);
    wire g2_body_raw = in_g2 && pixel_from_mask(ghost_anim ? ghost_row_mask_frame1(g2_ly) : ghost_row_mask_frame0(g2_ly), g2_lx);
    wire g3_body_raw = in_g3 && pixel_from_mask(ghost_anim ? ghost_row_mask_frame1(g3_ly) : ghost_row_mask_frame0(g3_ly), g3_lx);
    wire g4_body_raw = in_g4 && pixel_from_mask(ghost_anim ? ghost_row_mask_frame1(g4_ly) : ghost_row_mask_frame0(g4_ly), g4_lx);

    wire g1_body = g1_body_raw && !ghost_eaten[0];
    wire g2_body = g2_body_raw && !ghost_eaten[1];
    wire g3_body = g3_body_raw && !ghost_eaten[2];
    wire g4_body = g4_body_raw && !ghost_eaten[3];

    function eye_white;
        input [4:0] x;
        input [4:0] y;
        begin
            eye_white = (((x >= 5'd3) && (x <= 5'd6)  && (y >= 5'd4) && (y <= 5'd7)) ||
                         ((x >= 5'd9) && (x <= 5'd12) && (y >= 5'd4) && (y <= 5'd7)));
        end
    endfunction

    function pupil_black;
        input [4:0] x;
        input [4:0] y;
        input [3:0] dir;
        reg [4:0] offx;
        reg [4:0] offy;
        begin
            case (dir)
                4'b0001: begin offx = 5'd0; offy = 5'd1; end
                4'b0010: begin offx = 5'd2; offy = 5'd1; end
                4'b0100: begin offx = 5'd1; offy = 5'd0; end
                4'b1000: begin offx = 5'd1; offy = 5'd2; end
                default: begin offx = 5'd1; offy = 5'd1; end
            endcase

            pupil_black = (((x == (5'd3 + offx)) || (x == (5'd4 + offx))) &&
                            ((y == (5'd4 + offy)) || (y == (5'd5 + offy)))) ||
                           (((x == (5'd9 + offx)) || (x == (5'd10 + offx))) &&
                            ((y == (5'd4 + offy)) || (y == (5'd5 + offy))));
        end
    endfunction

    // Eyes only
    wire g1_eye_area = in_g1 && (g1_body_raw || ghost_eaten[0]);
    wire g2_eye_area = in_g2 && (g2_body_raw || ghost_eaten[1]);
    wire g3_eye_area = in_g3 && (g3_body_raw || ghost_eaten[2]);
    wire g4_eye_area = in_g4 && (g4_body_raw || ghost_eaten[3]);

    wire g1_eye_w = g1_eye_area && eye_white(g1_lx, g1_ly);
    wire g2_eye_w = g2_eye_area && eye_white(g2_lx, g2_ly);
    wire g3_eye_w = g3_eye_area && eye_white(g3_lx, g3_ly);
    wire g4_eye_w = g4_eye_area && eye_white(g4_lx, g4_ly);

    wire g1_pupil = g1_eye_area && pupil_black(g1_lx, g1_ly, ghost1_dir);
    wire g2_pupil = g2_eye_area && pupil_black(g2_lx, g2_ly, ghost2_dir);
    wire g3_pupil = g3_eye_area && pupil_black(g3_lx, g3_ly, ghost3_dir);
    wire g4_pupil = g4_eye_area && pupil_black(g4_lx, g4_ly, ghost4_dir);

    always @(*) begin
        if (pacman_draw)
            vga_out = YELLOW;
        else if (g1_pupil || g2_pupil || g3_pupil || g4_pupil)
            vga_out = BLACK;
        else if (g1_eye_w || g2_eye_w || g3_eye_w || g4_eye_w)
            vga_out = WHITE;
        else if (g1_body)
            vga_out = power_mode ? BLUE : RED;
        else if (g2_body)
            vga_out = power_mode ? BLUE : PINK;
        else if (g3_body)
            vga_out = power_mode ? BLUE : CYAN;
        else if (g4_body)
            vga_out = power_mode ? BLUE : GREEN;
        else
            vga_out = BLACK;
    end

endmodule
