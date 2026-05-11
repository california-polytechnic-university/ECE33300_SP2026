//UART receiver for 8-N-1 serial data.
//
// TeraTerm configuration of 115200 baud, 8 data bits, no parity, 1 stop bit.
//
// rx is the UART serial input from the USB-UART bridge.
// data_valid pulses high for one clk cycle whenever a valid byte is received.

module uart_rx #(
    parameter integer CLK_FREQ_HZ = 100000000,
    parameter integer BAUD_RATE   = 115200
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        data_valid
);

    localparam integer CLKS_PER_BIT      = CLK_FREQ_HZ / BAUD_RATE;
    localparam integer HALF_CLKS_PER_BIT = CLKS_PER_BIT / 2;

    localparam [1:0] STATE_IDLE  = 2'd0;
    localparam [1:0] STATE_START = 2'd1;
    localparam [1:0] STATE_DATA  = 2'd2;
    localparam [1:0] STATE_STOP  = 2'd3;

    reg [1:0]  state;
    reg [31:0] baud_count;
    reg [2:0]  bit_index;

    // Synchronize asynchronous UART input into FPGA clock domain.
    reg rx_meta;
    reg rx_sync;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= STATE_IDLE;
            baud_count <= 32'd0;
            bit_index  <= 3'd0;
            data       <= 8'd0;
            data_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    baud_count <= 32'd0;
                    bit_index  <= 3'd0;

                    // A falling edge starts a byte.
                    if (rx_sync == 1'b0)
                        state <= STATE_START;
                end

                STATE_START: begin
                    // Sample in the middle of the start bit. If the line is
                    // still low, treat it as a real start bit; otherwise it
                    // was probably noise and we return to idle.
                    if (baud_count == (HALF_CLKS_PER_BIT - 1)) begin
                        baud_count <= 32'd0;

                        if (rx_sync == 1'b0)
                            state <= STATE_DATA;
                        else
                            state <= STATE_IDLE;
                    end else begin
                        baud_count <= baud_count + 1'b1;
                    end
                end

                STATE_DATA: begin
                    if (baud_count == (CLKS_PER_BIT - 1)) begin
                        baud_count       <= 32'd0;
                        data[bit_index]  <= rx_sync;

                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state     <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        baud_count <= baud_count + 1'b1;
                    end
                end

                STATE_STOP: begin
                    if (baud_count == (CLKS_PER_BIT - 1)) begin
                        baud_count <= 32'd0;
                        state      <= STATE_IDLE;

                        
                        if (rx_sync == 1'b1)
                            data_valid <= 1'b1;
                    end else begin
                        baud_count <= baud_count + 1'b1;
                    end
                end

                default: begin
                    state      <= STATE_IDLE;
                    baud_count <= 32'd0;
                    bit_index  <= 3'd0;
                end
            endcase
        end
    end

endmodule
