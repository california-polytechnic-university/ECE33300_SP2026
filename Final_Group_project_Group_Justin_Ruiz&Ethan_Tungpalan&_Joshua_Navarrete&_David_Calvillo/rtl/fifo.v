

module fifo #(
    parameter DATA_W = 8,
    parameter DEPTH  = 32
)(
    input  wire              clk,
    input  wire              rst,

    input  wire              wr_en,
    input  wire [DATA_W-1:0] din,

    input  wire              rd_en,
    output wire [DATA_W-1:0] dout,

    output wire              empty,
    output wire              full
);

    localparam ADDR_W = 5;

    reg [DATA_W-1:0] mem [0:DEPTH-1];
    reg [ADDR_W-1:0] wr_ptr, rd_ptr;
    reg [ADDR_W:0]   count;

    assign empty = (count == 0);
    assign full  = (count == DEPTH);
    assign dout  = mem[rd_ptr];

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end else begin

            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr      <= wr_ptr + 1'b1;
            end
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
            case ({wr_en && !full, rd_en && !empty})
                2'b10:   count <= count + 1'b1;
                2'b01:   count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
