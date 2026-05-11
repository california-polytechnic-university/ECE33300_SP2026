

module clk_divider #(
    parameter PIX_DIV   = 4,
    parameter SLOW_DIV  = 1_000_000,
    parameter BLINK_DIV = 50_000_000
)(
    input  wire clk,
    input  wire rst,
    output reg  pix_tick,
    output reg  slow_tick,
    output reg  blink_tick
);

    reg [1:0]  pix_cnt;
    reg [19:0] slow_cnt;
    reg [25:0] blink_cnt;

    always @(posedge clk) begin
        if (rst) begin
            pix_cnt    <= 0;
            slow_cnt   <= 0;
            blink_cnt  <= 0;
            pix_tick   <= 1'b0;
            slow_tick  <= 1'b0;
            blink_tick <= 1'b0;
        end else begin

            if (pix_cnt == PIX_DIV - 1) begin
                pix_cnt  <= 0;
                pix_tick <= 1'b1;
            end else begin
                pix_cnt  <= pix_cnt + 1'b1;
                pix_tick <= 1'b0;
            end

            if (slow_cnt == SLOW_DIV - 1) begin
                slow_cnt  <= 0;
                slow_tick <= 1'b1;
            end else begin
                slow_cnt  <= slow_cnt + 1'b1;
                slow_tick <= 1'b0;
            end

            if (blink_cnt == BLINK_DIV - 1) begin
                blink_cnt  <= 0;
                blink_tick <= 1'b1;
            end else begin
                blink_cnt  <= blink_cnt + 1'b1;
                blink_tick <= 1'b0;
            end
        end
    end

endmodule
