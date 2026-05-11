`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/09/2026 01:59:02 PM
// Design Name: Reaction Game
// Module Name: vga_digit
// Project Name: ECE 3300 Final
// Description: 
// Isaiah Okuma & Matthew Okuma
// ECE 3300 Final Project
//////////////////////////////////////////////////////////////////////////////////


module vga_digit (
    input [9:0] px, py,         
    input [9:0] x_pos, y_pos,   
    input [6:0] segs,           
    output reg draw_on
);
    always @(*) begin
        draw_on = 0;
        if (px >= x_pos+5 && px < x_pos+35 && py >= y_pos && py < y_pos+5) draw_on = segs[6];
        if (px >= x_pos && px < x_pos+5 && py >= y_pos+5 && py < y_pos+35) draw_on = segs[1];
        if (px >= x_pos+35 && px < x_pos+40 && py >= y_pos+5 && py < y_pos+35) draw_on = segs[5];
        if (px >= x_pos+5 && px < x_pos+35 && py >= y_pos+35 && py < y_pos+40) draw_on = segs[0];
        if (px >= x_pos && px < x_pos+5 && py >= y_pos+40 && py < y_pos+70) draw_on = segs[2];
        if (px >= x_pos+35 && px < x_pos+40 && py >= y_pos+40 && py < y_pos+70) draw_on = segs[4];
        if (px >= x_pos+5 && px < x_pos+35 && py >= y_pos+70 && py < y_pos+75) draw_on = segs[3];
    end
endmodule
