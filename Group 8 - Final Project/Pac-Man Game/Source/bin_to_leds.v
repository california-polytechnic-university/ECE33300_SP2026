`timescale 1ns / 1ps

module bin_to_leds(
    input  [3:0] b_in,
    output reg [6:0] leds
    );

    always @(*) begin
        case (b_in)
            4'd0: leds = 7'b0111111;
            4'd1: leds = 7'b0000110;
            4'd2: leds = 7'b1011011;
            4'd3: leds = 7'b1001111;
            4'd4: leds = 7'b1100110;
            4'd5: leds = 7'b1101101;
            4'd6: leds = 7'b1111101;
            4'd7: leds = 7'b0000111;
            4'd8: leds = 7'b1111111;
            4'd9: leds = 7'b1101111;
            4'hA: leds = 7'b1000000;   // minus sign (g only)
            default: leds = 7'b0000000;
        endcase
    end

endmodule
