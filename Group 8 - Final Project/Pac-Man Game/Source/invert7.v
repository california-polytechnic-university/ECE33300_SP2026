`timescale 1ns / 1ps

module invert7(
    input [6:0] a,
    output [6:0] x  
    );
    
    assign x = ~a;
endmodule

