`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/08/2026 07:19:27 PM
// Design Name: 
// Module Name: pong_animate_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "project_defs.vh"

module pong_animate_unit
(
    input   clk,
    input   reset,
    input   video_on,
    input   pause,
    input   [1:0] btn,
    input   [9:0] pix_x,
    input   [9:0] pix_y,
    input   [31:0] score_bcd,
    output  [11:0] graph_rgb,
    output  paddle_hit_pulse,
    output  miss_pulse
);

    //====================================================
    // TIMING SIGNALS:
    //====================================================   
    wire refr_tick;

    //====================================================
    // CONSTANTS : defines area where anything can be drawn
    //====================================================
    localparam MAX_X = 640;
    localparam MAX_Y = 480;

    //====================================================
    // WALL: draws the  white wall that the ball hits when the ball is going up
    //====================================================
    
    localparam WALL_Y_T = 75;
    localparam WALL_Y_B = 80;
    
    //====================================================
    // BAR: defines the bar that is used to bounce the ball up
    //====================================================
    localparam BAR_Y_T = 400; //top of bar
    localparam BAR_Y_B = 405; //bottom of bar
    localparam BAR_X_SIZE = 72; //defines width of bar in pixels
    localparam BAR_V = 4; // defines velocity of ball in terms of pixels per seocnd
    reg [9:0] bar_x_reg, bar_x_next; //stores bar position in x position 
    wire [9:0] bar_x_l, bar_x_r; //defines left and right edge


    localparam signed [10:0] BALL_V_P = 11'sd2;
    localparam signed [10:0] BALL_V_N = -11'sd2;

    localparam BAR_START_X  = (MAX_X - BAR_X_SIZE)/2;
    localparam BALL_START_X = (MAX_X - BALL_SIZE)/2;
    localparam BALL_START_Y = WALL_Y_B + 5;
    
    //====================================================
    // SCOREBOARD: defines where the scoreboard is located on the VGA
    //====================================================
    localparam DIGIT_W  = 24;
    localparam DIGIT_H  = 40;
    localparam DIGIT_GAP = 8;
    localparam SEG_T    = 4;
    localparam MID_Y    = 20;
    localparam SCORE_DIGITS  = 4;
    localparam SCORE_TOTAL_W =
    (SCORE_DIGITS * DIGIT_W) +
    ((SCORE_DIGITS - 1) * DIGIT_GAP);

    localparam SCORE_X0 = 10;
    localparam SCORE_Y0 = 30;

    //====================================================
    // BALL
    //====================================================
    localparam BALL_SIZE = 8;

    wire [9:0] ball_x_l, ball_x_r;
    wire [9:0] ball_y_t, ball_y_b;

    reg  [9:0] ball_x_reg, ball_y_reg;
    wire [9:0] ball_x_next, ball_y_next;

    reg  signed [10:0] x_delta_reg, x_delta_next;
    reg  signed [10:0] y_delta_reg, y_delta_next;

    wire signed [10:0] ball_x_sum;
    wire signed [10:0] ball_y_sum;

    //====================================================
    // OBJECT FLAGS
    //====================================================
    wire wall_on, bar_on, sq_ball_on, rd_ball_on;
    wire [11:0] wall_rgb, bar_rgb, ball_rgb;

    //====================================================
    // SCORE DRAWING WIRES
    //====================================================
    wire score_d3_on, score_d2_on, score_d1_on, score_d0_on;
    wire score_on;
    wire [11:0] score_rgb;

    //====================================================
    // COLLISION / MISS
    //====================================================
    wire paddle_hit;
    wire miss_now;
    reg miss_pulse_tmp;
    reg paddle_hit_pulse_tmp;
    reg [11:0] graph_rgb_tmp;

    //====================================================
    // 7-segment digit decode for VGA score overlay
    // seg bits: [6]=a [5]=b [4]=c [3]=d [2]=e [1]=f [0]=g
    //====================================================
    function [6:0] seg7_map;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: seg7_map = 7'b1111110;
                4'd1: seg7_map = 7'b0110000;
                4'd2: seg7_map = 7'b1101101;
                4'd3: seg7_map = 7'b1111001;
                4'd4: seg7_map = 7'b0110011;
                4'd5: seg7_map = 7'b1011011;
                4'd6: seg7_map = 7'b1011111;
                4'd7: seg7_map = 7'b1110000;
                4'd8: seg7_map = 7'b1111111;
                4'd9: seg7_map = 7'b1111011;
                default: seg7_map = 7'b0000000;
            endcase
        end
    endfunction

    //====================================================
    // Test whether a pixel is inside a VGA-rendered 7-seg digit
    //====================================================
    function digit_on;
        input [9:0] x;
        input [9:0] y;
        input [9:0] ox;
        input [9:0] oy;
        input [3:0] digit;
        reg [6:0] segs;
        reg [9:0] dx, dy;
        begin
            segs = seg7_map(digit);

            if ((x < ox) || (x >= ox + DIGIT_W) || (y < oy) || (y >= oy + DIGIT_H))
                digit_on = 1'b0;
            else begin
                dx = x - ox;
                dy = y - oy;

                digit_on =
                    (segs[6] && (dy < SEG_T) &&
                     (dx >= SEG_T) && (dx < DIGIT_W-SEG_T)) ||

                    (segs[5] && (dx >= DIGIT_W-SEG_T) &&
                     (dy >= SEG_T) && (dy < MID_Y)) ||

                    (segs[4] && (dx >= DIGIT_W-SEG_T) &&
                     (dy >= MID_Y) && (dy < DIGIT_H-SEG_T)) ||

                    (segs[3] && (dy >= DIGIT_H-SEG_T) &&
                     (dx >= SEG_T) && (dx < DIGIT_W-SEG_T)) ||

                    (segs[2] && (dx < SEG_T) &&
                     (dy >= MID_Y) && (dy < DIGIT_H-SEG_T)) ||

                    (segs[1] && (dx < SEG_T) &&
                     (dy >= SEG_T) && (dy < MID_Y)) ||

                    (segs[0] && (dy >= MID_Y-(SEG_T/2)) &&
                     (dy < MID_Y+(SEG_T/2)) &&
                     (dx >= SEG_T) && (dx < DIGIT_W-SEG_T));
            end
        end
    endfunction

    //====================================================
    // BALL ROM (round shape): LUT for design of ball
    //====================================================
    wire [2:0] rom_addr, rom_col;
    reg  [7:0] rom_data;
    wire rom_bit;
    always @* 
    begin
        case (rom_addr)
            3'h0: rom_data = 8'b00011000;
            3'h1: rom_data = 8'b00111100;
            3'h2: rom_data = 8'b01111110;
            3'h3: rom_data = 8'b11111111;
            3'h4: rom_data = 8'b11111111;
            3'h5: rom_data = 8'b01111110;
            3'h6: rom_data = 8'b00111100;
            3'h7: rom_data = 8'b00011000;
            default: rom_data = 8'b00000000;
        endcase
    end

    //====================================================
    // Register update
    //====================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bar_x_reg   <= BAR_START_X[9:0];
            ball_x_reg  <= BALL_START_X[9:0];
            ball_y_reg  <= BALL_START_Y[9:0];
            x_delta_reg <= BALL_V_P;
            y_delta_reg <= BALL_V_P;
        end
        else if (miss_now) begin
            bar_x_reg   <= bar_x_reg;
            ball_x_reg  <= BALL_START_X[9:0];
            ball_y_reg  <= BALL_START_Y[9:0];
            x_delta_reg <= BALL_V_P;
            y_delta_reg <= BALL_V_P;
        end
        else if (!pause) begin
            bar_x_reg   <= bar_x_next;
            ball_x_reg  <= ball_x_next;
            ball_y_reg  <= ball_y_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
        end
    end

    //====================================================
    // Hit / miss pulses
    //====================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            paddle_hit_pulse_tmp <= 1'b0;
            miss_pulse_tmp       <= 1'b0;
        end
        else if (pause) begin
            paddle_hit_pulse_tmp <= 1'b0;
            miss_pulse_tmp       <= 1'b0;
        end
        else begin
            paddle_hit_pulse_tmp <= (refr_tick && paddle_hit && (y_delta_reg > 0));
            miss_pulse_tmp       <= miss_now;
        end
    end

    assign paddle_hit_pulse = paddle_hit_pulse_tmp;
    assign miss_pulse       = miss_pulse_tmp;

    //====================================================
    // Refresh tick
    //====================================================
    assign refr_tick = (pix_y == 10'd481) && (pix_x == 10'd0);

    //====================================================
    // Wall
    //====================================================
    assign wall_on  = (WALL_Y_T <= pix_y) && (pix_y <= WALL_Y_B);
    assign wall_rgb = `COLOR_WALL;

    //====================================================
    // Paddle
    //====================================================
    assign bar_x_l = bar_x_reg;
    assign bar_x_r = bar_x_l + BAR_X_SIZE - 1;

    assign bar_on =
        (bar_x_l <= pix_x) &&
        (pix_x <= bar_x_r) &&
        (BAR_Y_T <= pix_y) &&
        (pix_y <= BAR_Y_B);

    assign bar_rgb = `COLOR_BAR;

    always @* begin
        bar_x_next = bar_x_reg;

        if (refr_tick && !pause) begin
            if (btn[1] && (bar_x_r < (MAX_X - 1 - BAR_V)))
                bar_x_next = bar_x_reg + BAR_V;
            else if (btn[0] && (bar_x_l > BAR_V))
                bar_x_next = bar_x_reg - BAR_V;
        end
    end

    //====================================================
    // Ball RENDERER: VGA display logic
    //====================================================
    assign ball_y_t = ball_y_reg;
    assign ball_x_l = ball_x_reg;
    assign ball_y_b = ball_y_t + BALL_SIZE - 1;
    assign ball_x_r = ball_x_l + BALL_SIZE - 1;
    // Check if current pixel is inside ball boundery box 
    assign sq_ball_on =
        (ball_x_l <= pix_x) &&
        (pix_x <= ball_x_r) &&
        (ball_y_t <= pix_y) &&
        (pix_y <= ball_y_b);
    // Circular mask for ball shape
    assign rom_addr = pix_y[2:0] - ball_y_t[2:0];
    assign rom_col  = pix_x[2:0] - ball_x_l[2:0];
    assign rom_bit  = rom_data[rom_col];

    assign rd_ball_on = sq_ball_on && rom_bit;
    assign ball_rgb   = `COLOR_BALL;

    //====================================================
    // BALL HIT/MISS: Determines position and if ball hits or misses bar
    //====================================================
    // logic to determine if ball hits paddle
    assign paddle_hit =
        (BAR_Y_T <= ball_y_b) &&
        (ball_y_b <= BAR_Y_B) &&
        (bar_x_l <= ball_x_r) &&
        (bar_x_r >= ball_x_l);
    //logic to determine if ball misses paddle and hits the bottom
    assign miss_now = refr_tick && (ball_y_b >= (MAX_Y - 1)) && (y_delta_reg > 0);

    //====================================================
    // BALL POSITION: Determines ball positon per frame tick
    //====================================================
    
    assign ball_x_sum = $signed({1'b0, ball_x_reg}) + x_delta_reg;
    assign ball_y_sum = $signed({1'b0, ball_y_reg}) + y_delta_reg;
    assign ball_x_next = refr_tick ? ball_x_sum[9:0] : ball_x_reg;
    assign ball_y_next = refr_tick ? ball_y_sum[9:0] : ball_y_reg;

    //====================================================
    // BALL VELOCITY 
    //====================================================
    always @* begin
        x_delta_next = x_delta_reg;
        y_delta_next = y_delta_reg;
    //left wall bounce
        if (ball_x_l < 1)
            x_delta_next = BALL_V_P;
    //right wall bounce
        else if (ball_x_r > (MAX_X - 2))
            x_delta_next = BALL_V_N;
    //top wall bounce
        if (ball_y_t <= WALL_Y_B)
            y_delta_next = BALL_V_P;
    //paddle bounce when moving downward
        else if (paddle_hit && (y_delta_reg > 0))
            y_delta_next = BALL_V_N;
    end
    
    //====================================================
    // Combines score digits onto a single score_on wire
    //====================================================
    assign score_d3_on = digit_on(pix_x, pix_y,
                                  SCORE_X0,
                                  SCORE_Y0,
                                  score_bcd[15:12]);

    assign score_d2_on = digit_on(pix_x, pix_y,
                                  SCORE_X0 + (DIGIT_W + DIGIT_GAP),
                                  SCORE_Y0,
                                  score_bcd[11:8]);

    assign score_d1_on = digit_on(pix_x, pix_y,
                                  SCORE_X0 + 2*(DIGIT_W + DIGIT_GAP),
                                  SCORE_Y0,
                                  score_bcd[7:4]);

    assign score_d0_on = digit_on(pix_x, pix_y,
                                  SCORE_X0 + 3*(DIGIT_W + DIGIT_GAP),
                                  SCORE_Y0,
                                  score_bcd[3:0]);

    assign score_on  = score_d3_on | score_d2_on | score_d1_on | score_d0_on;
    assign score_rgb = `COLOR_SCORE;

    //====================================================
    // RGB output
    //====================================================
    always @* begin
        if (!video_on)
            graph_rgb_tmp = `COLOR_BLANK;
        else if (score_on)
            graph_rgb_tmp = score_rgb;
        else if (wall_on)
            graph_rgb_tmp = wall_rgb;
        else if (bar_on)
            graph_rgb_tmp = bar_rgb;
        else if (rd_ball_on)
            graph_rgb_tmp = ball_rgb;
        else
            graph_rgb_tmp = `COLOR_BG;
    end

    assign graph_rgb = graph_rgb_tmp;

endmodule
