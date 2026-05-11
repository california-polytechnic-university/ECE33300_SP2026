module debounce(
    input clk,
    input noisy,
    output reg clean
);

    reg [19:0] count = 0;
    reg old = 0;

    initial begin
        clean = 0;
    end

    always @(posedge clk) begin
        if (noisy != old) begin
            old <= noisy;
            count <= 0;
        end else if (count == 20'd999999) begin
            clean <= old;
        end else begin
            count <= count + 1;
        end
    end

endmodule