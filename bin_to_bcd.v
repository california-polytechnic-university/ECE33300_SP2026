`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/08/2026 11:31:40 AM
// Design Name: Reaction Game
// Module Name: bin_to_bcd
// Project Name: ECE 3300 Final
// Description: 
// Isaiah Okuma & Matthew Okuma
// ECE 3300 Final Project
//////////////////////////////////////////////////////////////////////////////////


module bin_to_bcd(
    input [15:0] bin,
    output reg [3:0] thousands,
    output reg [3:0] hundreds,
    output reg [3:0] tens,
    output reg [3:0] ones
);
    integer i;
    reg [31:0] bcd; 

    always @(*) begin
        bcd = {16'b0, bin};
        for (i = 0; i < 16; i = i + 1) begin
            if (bcd[19:16] >= 5) bcd[19:16] = bcd[19:16] + 3;
            if (bcd[23:20] >= 5) bcd[23:20] = bcd[23:20] + 3;
            if (bcd[27:24] >= 5) bcd[27:24] = bcd[27:24] + 3;
            if (bcd[31:28] >= 5) bcd[31:28] = bcd[31:28] + 3;
            
            bcd = bcd << 1;
        end
        
        {thousands, hundreds, tens, ones} = bcd[31:16];
    end
endmodule

