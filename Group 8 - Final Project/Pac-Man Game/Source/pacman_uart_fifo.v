`timescale 1ns / 1ps


module pacman_uart_fifo
  #(parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4)   // depth = 2^ADDR_WIDTH
   (
    input                         clk,
    input                         reset,

    input                         wr_en,
    input      [DATA_WIDTH-1:0]    wr_data,
    output                        full,

    input                         rd_en,
    output     [DATA_WIDTH-1:0]    rd_data,
    output                        empty,

    output     [ADDR_WIDTH:0]      fifo_count
    );

   localparam FIFO_DEPTH = (1 << ADDR_WIDTH);

   reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
   reg [ADDR_WIDTH-1:0] wr_ptr;
   reg [ADDR_WIDTH-1:0] rd_ptr;
   reg [ADDR_WIDTH:0]   count;

   assign full       = (count == FIFO_DEPTH);
   assign empty      = (count == 0);
   assign fifo_count = count;

   assign rd_data = mem[rd_ptr];

   always @(posedge clk or posedge reset) begin
      if (reset) begin
         wr_ptr <= {ADDR_WIDTH{1'b0}};
         rd_ptr <= {ADDR_WIDTH{1'b0}};
         count  <= {(ADDR_WIDTH+1){1'b0}};
      end else begin
         case ({wr_en && !full, rd_en && !empty})

           2'b10: begin
              mem[wr_ptr] <= wr_data;
              wr_ptr <= wr_ptr + 1'b1;
              count  <= count + 1'b1;
           end

           2'b01: begin
              rd_ptr <= rd_ptr + 1'b1;
              count  <= count - 1'b1;
           end

           2'b11: begin
              mem[wr_ptr] <= wr_data;
              wr_ptr <= wr_ptr + 1'b1;
              rd_ptr <= rd_ptr + 1'b1;
              count  <= count;
           end

           default: begin
              count <= count;
           end

         endcase
      end
   end

endmodule
