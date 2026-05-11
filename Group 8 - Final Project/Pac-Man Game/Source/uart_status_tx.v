`timescale 1ns / 1ps

module uart_status_tx(
    input        clk,
    input        reset,

    input  [3:0] thousands,
    input  [3:0] hundreds,
    input  [3:0] tens,
    input  [3:0] ones,

    input        power_mode,
    input  [3:0] speed_sel,

    output       tx
    );


    wire [(6*8)-1:0] message;

    pacman_score_to_ascii u_ascii(
        .message(message),
        .thousands(thousands),
        .hundreds(hundreds),
        .tens(tens),
        .ones(ones)
    );


    wire unused_power_mode = power_mode;
    wire [3:0] unused_speed_sel = speed_sel;

    //------------------------------------------------------------
    // FIFO connections.
    //------------------------------------------------------------
    reg        fifo_wr_en;
    reg [7:0]  fifo_wr_data;
    wire       fifo_full;

    wire       fifo_rd_en;
    wire [7:0] fifo_rd_data;
    wire       fifo_empty;
    wire [4:0] fifo_count;

    pacman_uart_fifo #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(4)
    ) u_uart_fifo (
        .clk(clk),
        .reset(reset),

        .wr_en(fifo_wr_en),
        .wr_data(fifo_wr_data),
        .full(fifo_full),

        .rd_en(fifo_rd_en),
        .rd_data(fifo_rd_data),
        .empty(fifo_empty),

        .fifo_count(fifo_count)
    );

    //------------------------------------------------------------
    // Message loader FSM.
    //------------------------------------------------------------
    localparam LOAD_IDLE = 2'd0;
    localparam LOAD_SEND = 2'd1;

    reg [1:0] load_state;
    reg [(6*8)-1:0] saved_message;
    reg [(6*8)-1:0] shift_message;
    reg [2:0] byte_count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            load_state    <= LOAD_IDLE;
            saved_message <= {(6*8){1'b0}};
            shift_message <= {(6*8){1'b0}};
            byte_count    <= 3'd0;
            fifo_wr_en    <= 1'b0;
            fifo_wr_data  <= 8'd0;
        end else begin
            fifo_wr_en <= 1'b0;

            case (load_state)

                LOAD_IDLE: begin
                    if (message != saved_message) begin
                        saved_message <= message;
                        shift_message <= message;
                        byte_count    <= 3'd6;
                        load_state    <= LOAD_SEND;
                    end
                end

                LOAD_SEND: begin
                    if (!fifo_full) begin
                        fifo_wr_en   <= 1'b1;
                        fifo_wr_data <= shift_message[47:40];

                        shift_message <= {shift_message[39:0], 8'h00};
                        byte_count    <= byte_count - 3'd1;

                        if (byte_count == 3'd1)
                            load_state <= LOAD_IDLE;
                    end
                end

                default: begin
                    load_state <= LOAD_IDLE;
                end

            endcase
        end
    end

    //------------------------------------------------------------
    // UART transmitter FSM.
    //------------------------------------------------------------
    wire uart_ready;
    wire uart_done;

    assign fifo_rd_en = uart_ready && !fifo_empty;

    uart_tx_vlog #(.CLKS_PER_BIT(10416)) u_uart_tx(
        .i_Clock(clk),
        .i_Tx_DV(fifo_rd_en),
        .i_Tx_Byte(fifo_rd_data),
        .o_Tx_Serial(tx),
        .o_Tx_Done(uart_done),
        .o_Tx_Ready(uart_ready)
    );

endmodule
