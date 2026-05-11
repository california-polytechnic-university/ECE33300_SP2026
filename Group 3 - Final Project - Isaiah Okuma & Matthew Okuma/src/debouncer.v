`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/04/2026 12:43:23 PM
// Design Name: Reaction Game
// Module Name: debouncer
// Project Name: ECE 3300 Final
// Description: 
// Isaiah Okuma & Matthew Okuma
// ECE 3300 Final Project
//////////////////////////////////////////////////////////////////////////////////


module debouncer(
    input clk,       
    input btn_in,
    output reg btn_out
);
    reg [15:0] count; 
    
    always @(posedge clk) begin
        if (btn_in == 0) begin
            count <= 0;
            btn_out <= 0;
        end else begin
            count <= count + 1;
            if (count == 16'hFFFF) begin 
                btn_out <= 1;
            end
        end
    end
endmodule


