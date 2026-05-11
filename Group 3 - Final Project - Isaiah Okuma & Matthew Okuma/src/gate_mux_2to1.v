`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/04/2026 12:50:50 PM
// Design Name: Reaction Game
// Module Name: gate_mux_2to1
// Project Name: ECE 3300 Final
// Description: 
// Isaiah Okuma & Matthew Okuma
// ECE 3300 Final Project
//////////////////////////////////////////////////////////////////////////////////


module gate_mux_2to1(
    input a,      
    input b,      
    input sel,    
    output out
);
    wire not_sel;
    wire and_a, and_b;

    not n1 (not_sel, sel);
    and a1 (and_a, a, not_sel);
    and a2 (and_b, b, sel);
    or  o1 (out, and_a, and_b);

endmodule


