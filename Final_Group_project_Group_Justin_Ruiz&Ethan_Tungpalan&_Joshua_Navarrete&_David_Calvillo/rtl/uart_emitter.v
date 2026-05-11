

`include "connect8_defs.vh"

module uart_emitter #(
    parameter LOG_DEPTH = 64
)(
    input  wire        clk,
    input  wire        rst,

    input  wire        single_req,
    input  wire        dump_req,

    output reg  [5:0]  read_idx,
    input  wire [6:0]  read_data,
    input  wire [6:0]  cur_ptr_in,

    output reg         tx_wr_en,
    output reg  [7:0]  tx_din,
    input  wire        tx_full,

    output wire        busy
);

    localparam IDX_W = 6;

    localparam [1:0] S_IDLE = 2'd0,
                     S_BYTE = 2'd1,
                     S_NEXT = 2'd2;

    reg [1:0]       state;
    reg [2:0]       byte_idx;
    reg [IDX_W-1:0] last_idx;

    assign busy = (state != S_IDLE);

    wire        player_bit = read_data[6];
    wire [2:0]  col_val    = read_data[2:0];

    reg [7:0] byte_to_send;
    always @* begin
        case (byte_idx)
            3'd0:    byte_to_send = "P";
            3'd1:    byte_to_send = player_bit ? "2" : "1";
            3'd2:    byte_to_send = ":";
            3'd3:    byte_to_send = 8'h30 + {5'd0, col_val};
            3'd4:    byte_to_send = 8'h0D;
            3'd5:    byte_to_send = 8'h0A;
            default: byte_to_send = " ";
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            byte_idx <= 0;
            read_idx <= 0;
            last_idx <= 0;
            tx_wr_en <= 1'b0;
            tx_din   <= 8'd0;
        end else begin
            tx_wr_en <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (single_req && (cur_ptr_in != 0)) begin
                        read_idx <= cur_ptr_in[IDX_W-1:0] - 1'b1;
                        last_idx <= cur_ptr_in[IDX_W-1:0] - 1'b1;
                        byte_idx <= 0;
                        state    <= S_BYTE;
                    end else if (dump_req && (cur_ptr_in != 0)) begin
                        read_idx <= 0;
                        last_idx <= cur_ptr_in[IDX_W-1:0] - 1'b1;
                        byte_idx <= 0;
                        state    <= S_BYTE;
                    end
                end

                S_BYTE: begin
                    if (!tx_full) begin
                        tx_wr_en <= 1'b1;
                        tx_din   <= byte_to_send;
                        if (byte_idx == 3'd5) begin
                            state <= S_NEXT;
                        end else begin
                            byte_idx <= byte_idx + 1'b1;
                        end
                    end
                end

                S_NEXT: begin
                    if (read_idx == last_idx) begin
                        state <= S_IDLE;
                    end else begin
                        read_idx <= read_idx + 1'b1;
                        byte_idx <= 0;
                        state    <= S_BYTE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
