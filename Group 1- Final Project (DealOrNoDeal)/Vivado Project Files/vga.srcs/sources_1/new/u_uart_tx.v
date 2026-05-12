`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 3_000_000
)(
    input        clk,
    input        rst,
    input  [7:0] data_in,
    input        send,
    output reg   tx,
    output reg   busy
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] tx_shift;

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx_shift  <= 0;
            tx        <= 1'b1;   // UART idle is high
            busy      <= 1'b0;
        end else begin
            case (state)

                IDLE: begin
                    tx        <= 1'b1;
                    busy      <= 1'b0;
                    clk_count <= 0;
                    bit_index <= 0;

                    if (send) begin
                        tx_shift <= data_in;
                        busy     <= 1'b1;
                        state    <= START;
                    end
                end

                START: begin
                    tx <= 1'b0; // start bit

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= DATA;
                    end
                end

                DATA: begin
                    tx <= tx_shift[bit_index];

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;

                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1; // stop bit

                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= IDLE;
                        busy      <= 1'b0;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule