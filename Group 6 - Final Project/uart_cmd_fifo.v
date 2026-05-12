`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2026 02:33:11 PM
// Design Name: 
// Module Name: uart_cmd_fifo
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



module uart_cmd_fifo #
(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_W = 4
)
(
    input               clk,
    input               reset,
    input               wr_en,
    input               rd_en,
    input   [WIDTH-1:0] din,
    output  [WIDTH-1:0] dout,
    output             empty,
    output              full,
    output  [ADDR_W:0]  count
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_W-1:0] wr_ptr;
    reg [ADDR_W-1:0] rd_ptr;
    reg  [ADDR_W:0] count_tmp;

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    // asynchronous read of current front element
    assign dout = mem[rd_ptr];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= {ADDR_W{1'b0}};
            rd_ptr <= {ADDR_W{1'b0}};
            count_tmp  <= {(ADDR_W+1){1'b0}};
        end
        else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: begin
                    mem[wr_ptr] <= din;
                    wr_ptr <= wr_ptr + 1'b1;
                    count_tmp  <= count_tmp + 1'b1;
                end

                2'b01: begin
                    rd_ptr <= rd_ptr + 1'b1;
                    count_tmp  <= count_tmp - 1'b1;
                end

                2'b11: begin
                    mem[wr_ptr] <= din;
                    wr_ptr <= wr_ptr + 1'b1;
                    rd_ptr <= rd_ptr + 1'b1;
                    count_tmp  <= count_tmp; // same occupancy
                end

                default: begin
                    wr_ptr <= wr_ptr;
                    rd_ptr <= rd_ptr;
                    count_tmp  <= count_tmp;
                end
            endcase
        end
    end
assign count = count_tmp;
endmodule
