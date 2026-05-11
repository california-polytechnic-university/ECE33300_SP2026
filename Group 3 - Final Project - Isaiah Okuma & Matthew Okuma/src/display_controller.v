`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/04/2026 12:49:30 PM
// Design Name: Reaction Game
// Module Name: display_controller
// Project Name: ECE 3300 Final
// Description: 
// Isaiah Okuma & Matthew Okuma
// ECE 3300 Final Project
//////////////////////////////////////////////////////////////////////////////////


module display_controller(
    input clk_100MHz,
    input [15:0] score, 
    output reg [7:0] an,
    output [6:0] seg    
);

    reg [3:0] digit_data;
    reg [1:0] digit_sel;
    reg [16:0] refresh_counter;

    // 1. Logic to cycle through the 4 digits
    always @(posedge clk_100MHz) begin
        refresh_counter <= refresh_counter + 1;
        digit_sel <= refresh_counter[16:15]; // Refresh rate ~190Hz
    end

    // 2. Logic to pick which 4-bit BCD chunk to show
    always @(*) begin
        case(digit_sel)
            2'b00: begin an = 8'b11111110; digit_data = score[3:0];   end // Ones
            2'b01: begin an = 8'b11111101; digit_data = score[7:4];   end // Tens
            2'b10: begin an = 8'b11111011; digit_data = score[11:8];  end // Hundreds
            2'b11: begin an = 8'b11110111; digit_data = score[15:12]; end // Thousands
            default: an = 8'b11111111;
        endcase
    end

    hex_to_7seg decoder (
        .hex(digit_data), 
        .seg(seg)
    );

endmodule



