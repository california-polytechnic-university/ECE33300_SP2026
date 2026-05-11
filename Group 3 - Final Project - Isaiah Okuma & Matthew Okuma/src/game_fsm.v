`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/04/2026 12:42:44 PM
// Design Name: Reaction Game
// Module Name: game_fsm
// Project Name: ECE 3300 Final
// Description: 
// Isaiah Okuma & Matthew Okuma
// ECE 3300 Final Project
//////////////////////////////////////////////////////////////////////////////////


module game_fsm (
    input clk,          
    input ms_pulse,
    input reset,
    input start_btn,    
    input react_btn,    
    input [15:0] rand_delay,
    output reg [1:0] state,
    output reg timer_en,    
    output reg fifo_wr_en   
);

    localparam ST_IDLE   = 2'b00;
    localparam ST_DELAY  = 2'b01;
    localparam ST_ACTIVE = 2'b10;
    localparam ST_DONE   = 2'b11;

    reg [15:0] delay_cnt;

    always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= ST_IDLE;
        delay_cnt <= 0;
        timer_en <= 0;
        fifo_wr_en <= 0;
    end else begin
        fifo_wr_en <= 0; 

        case (state)
            ST_IDLE: begin
                timer_en <= 0;
                delay_cnt <= 0;
                if (start_btn) state <= ST_DELAY;
            end

            ST_DELAY: begin
                if (ms_pulse) begin
                    if (delay_cnt >= rand_delay) begin
                        state <= ST_ACTIVE;
                        delay_cnt <= 0;
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end 
            end

            ST_ACTIVE: begin
                timer_en <= 1; 
                if (react_btn) begin
                    state <= ST_DONE;
                    timer_en <= 0;
                    fifo_wr_en <= 1; 
                end
            end

            ST_DONE: begin
                if (start_btn) state <= ST_IDLE;
            end

            default: state <= ST_IDLE;
        endcase
    end
end
endmodule


