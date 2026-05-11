`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/04/2026 12:51:34 PM
// Design Name: Reaction Game
// Module Name: score_selector
// Project Name: ECE 3300 Final
// Description: 
// Isaiah Okuma & Matthew Okuma
// ECE 3300 Final Project
//////////////////////////////////////////////////////////////////////////////////


module score_selector(
    input [15:0] live_timer,
    input [15:0] high_score,
    input sel, 
    output [15:0] final_display_val
);

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : mux_gen
            gate_mux_2to1 m (
                .a(live_timer[i]),
                .b(high_score[i]),
                .sel(sel),
                .out(final_display_val[i])
            );
        end
    endgenerate

endmodule


