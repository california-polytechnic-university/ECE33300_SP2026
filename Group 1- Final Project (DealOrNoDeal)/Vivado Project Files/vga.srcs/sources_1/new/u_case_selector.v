`timescale 1ns / 1ps
 
module case_selector (
    input              clk,
    input              rst,
 
    // Control from game_fsm or top module
    input              selector_enable,
 
    // FIFO Generator interface
    input      [15:0]  fifo_dout,
    input              fifo_empty,
    output reg         fifo_rd_en,
 
    // Case status outputs
    output reg [3:0]   current_selected_case,
    output reg [15:0]  available_cases,
 
    // One-clock status pulses
    output reg         valid_selection,
    output reg         invalid_selection
);
 
    localparam IDLE    = 3'd0;
    localparam READ    = 3'd1;  // assert fifo_rd_en
    localparam WAIT_1  = 3'd2;  // wait one cycle for FIFO output to settle
    localparam WAIT_2  = 3'd3;  // data now valid on fifo_dout
    localparam PROCESS = 3'd4;
    reg [2:0] state;
    reg [3:0] selected_case_buffer;
 
    always @(posedge clk) begin
        if (rst) begin
            state                 <= IDLE;
            fifo_rd_en            <= 1'b0;
            current_selected_case <= 4'd0;
            available_cases       <= 16'hFFFF;
            valid_selection       <= 1'b0;
            invalid_selection     <= 1'b0;
            selected_case_buffer  <= 4'd0;
        end else begin
            fifo_rd_en        <= 1'b0;
            valid_selection   <= 1'b0;
            invalid_selection <= 1'b0;
            
            case (state)
 
                    IDLE: begin
                               if (selector_enable && !fifo_empty)
                                   state <= READ;
                           end
           
                           READ: begin
                               // Assert rd_en for exactly one cycle
                               fifo_rd_en <= 1'b1;
                               state      <= WAIT_1;
                           end
           
                           WAIT_1: begin
                               // rd_en has gone low, fifo_dout not yet valid
                               state <= WAIT_2;
                           end
           
                           WAIT_2: begin
                               // fifo_dout is now stable - latch it
                               selected_case_buffer <= fifo_dout[3:0];
                               state                <= PROCESS;
                           end
                PROCESS: begin
                    current_selected_case <= selected_case_buffer;
                
                    if (available_cases[selected_case_buffer]) begin
                        available_cases[selected_case_buffer] <= 1'b0;
                        valid_selection                       <= 1'b1;
                    end else begin
                        invalid_selection <= 1'b1;
                    end
                
                    state <= IDLE;
                end
 
                default: begin
                    state <= IDLE;
                end
 
            endcase
        end
    end
 
endmodule
