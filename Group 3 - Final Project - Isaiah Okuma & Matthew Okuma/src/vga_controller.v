`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/04/2026 12:42:03 PM
// Design Name: Reaction Game
// Module Name: vga_controller
// Project Name: ECE 3300 Final
// Description: 
// Isaiah Okuma & Matthew Okuma
// ECE 3300 Final Project
//////////////////////////////////////////////////////////////////////////////////


module vga_controller (
    input clk_25MHz,
    input [1:0] game_state,
    input [15:0] reaction_timer, 
    output reg hsync,
    output reg vsync,
    output reg [3:0] vga_r,
    output reg [3:0] vga_g,
    output reg [3:0] vga_b
);

    // --- 1. VGA Timing Constants 
    parameter H_ACTIVE = 640;
    parameter H_FP     = 16;
    parameter H_SYNC   = 96;
    parameter H_BP     = 48;
    parameter H_TOTAL  = 800;

    parameter V_ACTIVE = 480;
    parameter V_FP     = 10;
    parameter V_SYNC   = 2;
    parameter V_BP     = 33;
    parameter V_TOTAL  = 525;

    // --- 2. Counters & Signal Logic ---
    reg [9:0] h_cnt = 0;
    reg [9:0] v_cnt = 0;

    always @(posedge clk_25MHz) begin
        if (h_cnt == H_TOTAL - 1) begin
            h_cnt <= 0;
            if (v_cnt == V_TOTAL - 1)
                v_cnt <= 0;
            else
                v_cnt <= v_cnt + 1;
        end else begin
            h_cnt <= h_cnt + 1;
        end
    end

    // Sync Pulses
    always @(posedge clk_25MHz) begin
        hsync <= (h_cnt >= (H_ACTIVE + H_FP)) && (h_cnt < (H_ACTIVE + H_FP + H_SYNC));
        vsync <= (v_cnt >= (V_ACTIVE + V_FP)) && (v_cnt < (V_ACTIVE + V_FP + V_SYNC));
    end

    // Video On Signal
    wire video_on = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);
    wire [9:0] pixel_x = h_cnt;
    wire [9:0] pixel_y = v_cnt;

function [6:0] decode(input [3:0] bcd);
        case(bcd)
            4'h0: decode = 7'b1111110; 4'h1: decode = 7'b0110000;
            4'h2: decode = 7'b1101101; 4'h3: decode = 7'b1111001;
            4'h4: decode = 7'b0110011; 4'h5: decode = 7'b1011011;
            4'h6: decode = 7'b1011111; 4'h7: decode = 7'b1110000;
            4'h8: decode = 7'b1111111; 4'h9: decode = 7'b1111011;
            default: decode = 7'b0000000;
        endcase
    endfunction

    wire digit_on, d3, d2, d1, d0;
    
    // Draw 4 digits in the center of the screen
    vga_digit dig3(h_cnt, v_cnt, 10'd250, 10'd200, decode(reaction_timer[15:12]), d3);
    vga_digit dig2(h_cnt, v_cnt, 10'd300, 10'd200, decode(reaction_timer[11:8]),  d2);
    vga_digit dig1(h_cnt, v_cnt, 10'd350, 10'd200, decode(reaction_timer[7:4]),   d1);
    vga_digit dig0(h_cnt, v_cnt, 10'd400, 10'd200, decode(reaction_timer[3:0]),   d0);

    assign digit_on = (d3 | d2 | d1 | d0);

    always @(*) begin
        if (!video_on) begin
            {vga_r, vga_g, vga_b} = 12'h000;
        end else begin
            if ((game_state == 2'b10 || game_state == 2'b11) && digit_on) begin
            {vga_r, vga_g, vga_b} = 12'hFFF; 
        end else begin
                case(game_state)
                    2'b01:   {vga_r, vga_g, vga_b} = 12'hF00; // Red
                    2'b10:   {vga_r, vga_g, vga_b} = 12'h0F0; // Green
                    2'b11:   {vga_r, vga_g, vga_b} = 12'h00F; // Blue
                    default: {vga_r, vga_g, vga_b} = 12'h000; // Black
                endcase
            end
        end
    end

endmodule

