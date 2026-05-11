`timescale 1ns / 1ps

module decode_enb_leds(
    input [2:0] sel,
    output reg [7:0] enb_leds
    );

    always @(*) begin
        case (sel)
            3'b000: enb_leds = 8'b11111110;
            3'b001: enb_leds = 8'b11111101;
            3'b010: enb_leds = 8'b11111011;
            3'b011: enb_leds = 8'b11110111;
            3'b100: enb_leds = 8'b11101111;
            3'b101: enb_leds = 8'b11011111;
            3'b110: enb_leds = 8'b10111111;
            3'b111: enb_leds = 8'b01111111;
            default: enb_leds = 8'b11111111;
        endcase
    end

endmodule
