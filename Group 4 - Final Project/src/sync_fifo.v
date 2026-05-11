// Standard Synchronous FIFO
// Holds UART bytes before they are processed by the game logic

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4 // 2^4 = 16 elements deep
)(
    input  wire clk,
    input  wire rst,
    input  wire wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output wire empty,
    output wire full
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0]   count;

    assign empty = (count == 0);
    assign full  = (count == (1 << ADDR_WIDTH));

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr  <= 0;
            rd_ptr  <= 0;
            count   <= 0;
            rd_data <= 0;
        end else begin
            // Handle Write
            if (wr_en && !full) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end
            
            // Handle Read
            if (rd_en && !empty) begin
                rd_data <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end
            
            // Handle Count
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1'b1; // Write only
                2'b01: count <= count - 1'b1; // Read only
                default: count <= count;      // Both or neither
            endcase
        end
    end
endmodule
