module count_3bit_select(
    input clk,
    output [2:0] sel
    );

    reg [16:0] cntbig = 0;

    always @(posedge clk)
    begin
        cntbig <= cntbig + 1;
    end

`ifndef SYNTHESIS
    assign sel = cntbig[11:9];
`else
    assign sel = cntbig[16:14];
`endif

endmodule
