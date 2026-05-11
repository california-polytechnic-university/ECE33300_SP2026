

`include "connect8_defs.vh"

module move_log #(
    parameter DEPTH = 64
)(
    input  wire        clk,
    input  wire        rst,

    input  wire        push_en,
    input  wire [6:0]  push_data,

    input  wire        undo_en,
    output wire        undo_valid,
    output wire [6:0]  undo_data,

    input  wire        redo_en,
    output wire        redo_valid,
    output wire [6:0]  redo_data,

    input  wire [5:0]  read_idx,
    output wire [6:0]  read_data,

    output wire [6:0]  cur_ptr_out
);

    localparam PTR_W = 7;

    reg [6:0]       log [0:DEPTH-1];
    reg [PTR_W-1:0] wr_ptr;
    reg [PTR_W-1:0] cur_ptr;

    assign undo_valid  = (cur_ptr > 0);
    assign redo_valid  = (cur_ptr < wr_ptr);
    assign undo_data   = log[cur_ptr - 1'b1];
    assign redo_data   = log[cur_ptr];
    assign read_data   = log[read_idx];
    assign cur_ptr_out = cur_ptr;

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr  <= 0;
            cur_ptr <= 0;
            for (i = 0; i < DEPTH; i = i + 1)
                log[i] <= 7'd0;
        end else begin

            if (push_en) begin
                log[cur_ptr] <= push_data;
                cur_ptr      <= cur_ptr + 1'b1;
                wr_ptr       <= cur_ptr + 1'b1;
            end else if (undo_en && undo_valid) begin
                cur_ptr <= cur_ptr - 1'b1;
            end else if (redo_en && redo_valid) begin
                cur_ptr <= cur_ptr + 1'b1;
            end
        end
    end

endmodule
