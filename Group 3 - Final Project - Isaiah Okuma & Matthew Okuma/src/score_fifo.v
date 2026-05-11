`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/04/2026 12:44:11 PM
// Design Name: Reaction Game
// Module Name: score_fifo
// Project Name: ECE 3300 Final
// Description: 
// Isaiah Okuma & Matthew Okuma
// ECE 3300 Final Project
//////////////////////////////////////////////////////////////////////////////////


module score_fifo(
    input clk,
    input wr_en,      
    input rd_en,      
    input [7:0] din,  
    output [7:0] dout,
    output full, empty
);
    reg [7:0] mem [15:0];
    reg [3:0] wr_ptr = 0, rd_ptr = 0;

    always @(posedge clk) if (wr_en && !full) mem[wr_ptr] <= din;
    always @(posedge clk) if (wr_en && !full) wr_ptr <= wr_ptr + 1;
    always @(posedge clk) if (rd_en && !empty) rd_ptr <= rd_ptr + 1;

    assign dout = mem[rd_ptr];
    assign full = ((wr_ptr + 1) == rd_ptr);
    assign empty = (wr_ptr == rd_ptr);
endmodule


