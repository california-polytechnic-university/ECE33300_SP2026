`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/08/2026 07:14:43 PM
// Design Name: 
// Module Name: clk_50MHz_generator
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



module clk_50MHz_generator(
    input  wire clk,
    input  wire reset_clk,
    output wire clk_50mhz
);
    reg clk_reg;

    always @(posedge clk or posedge reset_clk) begin
        if (reset_clk)
            clk_reg <= 1'b0;
        else
            clk_reg <= ~clk_reg;
    end

    assign clk_50mhz = clk_reg;

endmodule

