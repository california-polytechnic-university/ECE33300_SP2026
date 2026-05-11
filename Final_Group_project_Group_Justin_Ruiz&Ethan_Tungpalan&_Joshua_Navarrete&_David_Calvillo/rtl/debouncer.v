

module debouncer #(
    parameter N = 16
)(
    input  wire clk,
    input  wire rst,
    input  wire slow_tick,
    input  wire in,
    output reg  out_db,
    output wire rise,
    output wire fall
);

    reg sync0, sync1;

    always @(posedge clk) begin
        if (rst) begin
            sync0 <= 1'b0;
            sync1 <= 1'b0;
        end else begin
            sync0 <= in;
            sync1 <= sync0;
        end
    end

    reg [3:0] cnt;

    always @(posedge clk) begin
        if (rst) begin
            cnt    <= 0;
            out_db <= 1'b0;
        end else if (slow_tick) begin
            if (sync1 == out_db) begin
                cnt <= 0;
            end else if (cnt == N - 1) begin
                out_db <= sync1;
                cnt    <= 0;
            end else begin
                cnt <= cnt + 1'b1;
            end
        end
    end

    reg out_db_prev;
    always @(posedge clk) begin
        if (rst) out_db_prev <= 1'b0;
        else     out_db_prev <= out_db;
    end

    assign rise =  out_db & ~out_db_prev;
    assign fall = ~out_db &  out_db_prev;

endmodule
