// Converts UART bytes into paddle movement commands using a FIFO Action Queue.
// Also detects the cheat code "Up-Up-Down-Down" (WWSS) to reset blocks.

module uart_wasd_controller #(
    parameter integer CLK_FREQ_HZ       = 100000000,
    parameter integer BAUD_RATE         = 115200,
    parameter integer MOVE_TICKS_PER_KEY = 16
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       uart_rx,
    input  wire       move_tick,
    output reg  [3:0] move_dir,
    output reg        cheat_pulse // New output for the cheat code
);

    wire [7:0] rx_data;
    wire       rx_valid;
    
    // FIFO wires
    wire [7:0] fifo_out;
    wire       fifo_empty;
    wire       fifo_full;
    reg        fifo_rd_en;
    
    // Internal state
    reg [15:0] ticks_remaining;
    reg [3:0]  decoded_dir;
    reg        stop_command;
    reg [15:0] history_reg; // Stores the last 4 commands (4 bits each)

    // Instantiate UART Receiver
    uart_rx #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD_RATE   (BAUD_RATE)
    ) u_uart_rx (
        .clk        (clk),
        .rst        (rst),
        .rx         (uart_rx),
        .data       (rx_data),
        .data_valid (rx_valid)
    );

    // Instantiate FIFO (Action Queue)
    sync_fifo #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(4)
    ) u_fifo (
        .clk     (clk),
        .rst     (rst),
        .wr_en   (rx_valid),
        .wr_data (rx_data),
        .rd_en   (fifo_rd_en),
        .rd_data (fifo_out),
        .empty   (fifo_empty),
        .full    (fifo_full)
    );

    // Combinational Decoding of the FIFO output
    always @(*) begin
        decoded_dir  = 4'b0000;
        stop_command = 1'b0;

        case (fifo_out)
            8'h41, 8'h61: decoded_dir = 4'b0001; // A/a = left
            8'h53, 8'h73: decoded_dir = 4'b0010; // S/s = down
            8'h44, 8'h64: decoded_dir = 4'b0100; // D/d = right
            8'h57, 8'h77: decoded_dir = 4'b1000; // W/w = up
            8'h20, 8'h58, 8'h78: stop_command = 1'b1; // Space/X = stop
            default: decoded_dir = 4'b0000;
        endcase
    end

    // State Machine for Action Queue and Cheat Code
    reg [1:0] state;
    localparam IDLE = 2'b00, READ_FIFO = 2'b01, EXECUTE = 2'b10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            move_dir        <= 4'b0000;
            ticks_remaining <= 16'd0;
            fifo_rd_en      <= 1'b0;
            cheat_pulse     <= 1'b0;
            history_reg     <= 16'd0;
            state           <= IDLE;
        end else begin
            cheat_pulse <= 1'b0; // Default to 0, pulse high for 1 clock only

            case (state)
                IDLE: begin
                    if (!fifo_empty && ticks_remaining == 16'd0) begin
                        fifo_rd_en <= 1'b1;
                        state      <= READ_FIFO;
                    end
                end

                READ_FIFO: begin
                    fifo_rd_en <= 1'b0;
                    state      <= EXECUTE;
                end

                EXECUTE: begin
                    if (stop_command) begin
                        move_dir        <= 4'b0000;
                        ticks_remaining <= 16'd0;
                    end else if (decoded_dir != 4'b0000) begin
                        move_dir        <= decoded_dir;
                        ticks_remaining <= MOVE_TICKS_PER_KEY;
                        
                        // Shift the new command into the history register
                        history_reg <= {history_reg[11:0], decoded_dir};
                        
                        // Check for Cheat Code: Up(1000) - Up(1000) - Down(0010) - Down(0010)
                        if ({history_reg[11:0], decoded_dir} == 16'b1000_1000_0010_0010) begin
                            cheat_pulse <= 1'b1;
                        end
                    end
                    state <= IDLE;
                end
            endcase

            // Handle movement tick decrement outside the state machine
            if (move_tick && (ticks_remaining != 16'd0)) begin
                ticks_remaining <= ticks_remaining - 1'b1;
                if (ticks_remaining == 16'd1) begin
                    move_dir <= 4'b0000;
                end
            end
        end
    end

endmodule
