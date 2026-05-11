

`include "connect8_defs.vh"

module seven_seg_driver #(
    parameter SCAN_DIV = 17'd50000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        blink_tick,
    input  wire [2:0]  game_state,
    input  wire [6:0]  move_count,

    output reg  [7:0]  an,
    output reg  [6:0]  seg,
    output wire        dp
);

    localparam [4:0] CC_0   = 5'd0,  CC_1   = 5'd1,  CC_2   = 5'd2,  CC_3   = 5'd3,
                     CC_4   = 5'd4,  CC_5   = 5'd5,  CC_6   = 5'd6,  CC_7   = 5'd7,
                     CC_8   = 5'd8,  CC_9   = 5'd9,
                     CC_P   = 5'd10,
                     CC_DASH= 5'd11,
                     CC_BLK = 5'd31;

    reg [16:0] scan_cnt;
    wire       scan_tick = (scan_cnt == SCAN_DIV - 1'b1);

    always @(posedge clk) begin
        if (rst)            scan_cnt <= 0;
        else if (scan_tick) scan_cnt <= 0;
        else                scan_cnt <= scan_cnt + 1'b1;
    end

    reg [2:0] digit_idx;
    always @(posedge clk) begin
        if (rst)            digit_idx <= 0;
        else if (scan_tick) digit_idx <= digit_idx + 1'b1;
    end

    reg blink_state;
    always @(posedge clk) begin
        if (rst)              blink_state <= 1'b0;
        else if (blink_tick)  blink_state <= ~blink_state;
    end

    wire [3:0] move_tens = move_count / 7'd10;
    wire [3:0] move_ones = move_count - (move_tens * 4'd10);

    reg [4:0] cc [0:7];
    integer   d;

    always @* begin

        for (d = 0; d < 8; d = d + 1) cc[d] = CC_BLK;

        case (game_state)
            `STATE_PLAY_P1, `STATE_PLAY_P2: begin
                cc[7] = CC_P;
                cc[6] = (game_state == `STATE_PLAY_P1) ? CC_1 : CC_2;
                cc[1] = {1'b0, move_tens[2:0]};
                cc[0] = {1'b0, move_ones[3:0]};
            end

            `STATE_CHECK: begin

                cc[7] = CC_P;
                cc[6] = CC_BLK;
                cc[1] = {1'b0, move_tens[2:0]};
                cc[0] = {1'b0, move_ones[3:0]};
            end

            `STATE_WIN_P1: begin
                if (blink_state) begin
                    cc[7] = CC_P;
                    cc[6] = CC_1;
                end
            end

            `STATE_WIN_P2: begin
                if (blink_state) begin
                    cc[7] = CC_P;
                    cc[6] = CC_2;
                end
            end

            `STATE_DRAW: begin
                if (blink_state) begin
                    for (d = 0; d < 8; d = d + 1) cc[d] = CC_DASH;
                end
            end

            default: ;
        endcase
    end

    function [6:0] encode;
        input [4:0] code;
        begin
            case (code)
                CC_0:    encode = 7'b1000000;
                CC_1:    encode = 7'b1111001;
                CC_2:    encode = 7'b0100100;
                CC_3:    encode = 7'b0110000;
                CC_4:    encode = 7'b0011001;
                CC_5:    encode = 7'b0010010;
                CC_6:    encode = 7'b0000010;
                CC_7:    encode = 7'b1111000;
                CC_8:    encode = 7'b0000000;
                CC_9:    encode = 7'b0010000;
                CC_P:    encode = 7'b0001100;
                CC_DASH: encode = 7'b0111111;
                default: encode = 7'b1111111;
            endcase
        end
    endfunction

    wire [4:0] selected_cc = cc[digit_idx];

    always @* begin
        seg = encode(selected_cc);

        an  = ~(8'b00000001 << digit_idx);
    end

    assign dp = 1'b1;

endmodule
