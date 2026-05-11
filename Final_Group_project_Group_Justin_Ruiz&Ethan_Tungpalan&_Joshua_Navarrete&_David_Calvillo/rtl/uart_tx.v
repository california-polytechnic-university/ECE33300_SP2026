

`include "connect8_defs.vh"

module uart_tx #(
    parameter CLK_FREQ   = `SYS_CLK_HZ,
    parameter BAUD       = `UART_BAUD,
    parameter FIFO_DEPTH = 32
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       wr_en,
    input  wire [7:0] din,
    output wire       fifo_full,
    output reg        tx
);

    localparam BAUD_DIV = CLK_FREQ / BAUD;

    localparam [1:0] S_IDLE  = 2'd0,
                     S_START = 2'd1,
                     S_DATA  = 2'd2,
                     S_STOP  = 2'd3;

    wire       fifo_empty;
    wire [7:0] fifo_dout;
    reg        fifo_rd;

    fifo #(
        .DATA_W (8),
        .DEPTH  (FIFO_DEPTH)
    ) u_byte_fifo (
        .clk   (clk),
        .rst   (rst),
        .wr_en (wr_en),
        .din   (din),
        .rd_en (fifo_rd),
        .dout  (fifo_dout),
        .empty (fifo_empty),
        .full  (fifo_full)
    );

    reg [1:0]                  state;
    reg [13:0] baud_cnt;
    reg [2:0]                  bit_idx;
    reg [7:0]                  shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            baud_cnt  <= 0;
            bit_idx   <= 0;
            shift_reg <= 8'h00;
            tx        <= 1'b1;
            fifo_rd   <= 1'b0;
        end else begin
            fifo_rd <= 1'b0;

            case (state)
                S_IDLE: begin
                    tx <= 1'b1;
                    if (!fifo_empty) begin
                        shift_reg <= fifo_dout;
                        fifo_rd   <= 1'b1;
                        baud_cnt  <= 0;
                        state     <= S_START;
                    end
                end

                S_START: begin
                    tx <= 1'b0;
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 0;
                        bit_idx  <= 0;
                        state    <= S_DATA;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                S_DATA: begin
                    tx <= shift_reg[bit_idx];
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 0;
                        if (bit_idx == 3'd7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                S_STOP: begin
                    tx <= 1'b1;
                    if (baud_cnt == BAUD_DIV - 1) begin
                        baud_cnt <= 0;
                        state    <= S_IDLE;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
