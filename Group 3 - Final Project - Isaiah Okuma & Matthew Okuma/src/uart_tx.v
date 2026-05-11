`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/04/2026 12:45:01 PM
// Design Name: Reaction Game
// Module Name: uart_tx
// Project Name: ECE 3300 Final
// Description: 
// Isaiah Okuma & Matthew Okuma
// ECE 3300 Final Project
//////////////////////////////////////////////////////////////////////////////////


module uart_tx(
    input clk_100MHz,
    input [7:0] data,
    input start,
    output reg tx_pin,
    output reg busy
);
    localparam BIT_PERIOD = 10416;
    reg [13:0] clk_cnt = 0;
    reg [3:0] bit_idx = 0;
    reg [7:0] tx_data;

    always @(posedge clk_100MHz) begin
        if (!busy) begin
            if (start) begin
                busy <= 1;
                tx_data <= data;
                clk_cnt <= 0;
                bit_idx <= 0;
                tx_pin <= 0; 
            end else tx_pin <= 1;
        end else begin
            if (clk_cnt < BIT_PERIOD) clk_cnt <= clk_cnt + 1;
            else begin
                clk_cnt <= 0;
                if (bit_idx < 8) begin
                    tx_pin <= tx_data[bit_idx];
                    bit_idx <= bit_idx + 1;
                end else if (bit_idx == 8) begin
                    tx_pin <= 1; // Stop Bit
                    bit_idx <= bit_idx + 1;
                end else begin
                    busy <= 0;
                end
            end
        end
    end
endmodule


