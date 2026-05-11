

module uart_tx(
    input clk,
    input start,
    input [7:0] data,
    output reg tx,
    output reg busy
);

    parameter CLKS_PER_BIT = 868;

    reg [13:0] clk_count = 0;
    reg [3:0] bit_index = 0;
    reg [9:0] tx_shift = 10'b1111111111;

    initial begin
        tx = 1'b1;
        busy = 1'b0;
        clk_count = 0;
        bit_index = 0;
        tx_shift = 10'b1111111111;
    end

    always @(posedge clk) begin

        if (!busy) begin
            tx <= 1'b1;
            clk_count <= 0;
            bit_index <= 0;

            if (start) begin
                busy <= 1'b1;

                tx_shift <= {1'b1, data, 1'b0};
            end
        end

        else begin
            tx <= tx_shift[bit_index];

            if (clk_count < CLKS_PER_BIT - 1) begin
                clk_count <= clk_count + 1;
            end

            else begin
                clk_count <= 0;

                if (bit_index < 9) begin
                    bit_index <= bit_index + 1;
                end

                else begin
                    busy <= 1'b0;
                    bit_index <= 0;
                    tx <= 1'b1;
                end
            end
        end
    end

endmodule
