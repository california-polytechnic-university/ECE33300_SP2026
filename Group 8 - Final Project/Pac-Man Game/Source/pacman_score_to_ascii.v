`timescale 1ns / 1ps

module pacman_score_to_ascii(
    output [(6*8)-1:0] message,

    input  [3:0] thousands,
    input  [3:0] hundreds,
    input  [3:0] tens,
    input  [3:0] ones
    );

    function [7:0] bcd_to_ascii;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: bcd_to_ascii = 8'h30;
                4'd1: bcd_to_ascii = 8'h31;
                4'd2: bcd_to_ascii = 8'h32;
                4'd3: bcd_to_ascii = 8'h33;
                4'd4: bcd_to_ascii = 8'h34;
                4'd5: bcd_to_ascii = 8'h35;
                4'd6: bcd_to_ascii = 8'h36;
                4'd7: bcd_to_ascii = 8'h37;
                4'd8: bcd_to_ascii = 8'h38;
                4'd9: bcd_to_ascii = 8'h39;
                default: bcd_to_ascii = 8'h30;
            endcase
        end
    endfunction

    assign message = {
        bcd_to_ascii(thousands),
        bcd_to_ascii(hundreds),
        bcd_to_ascii(tens),
        bcd_to_ascii(ones),
        8'h0D,
        8'h0A
    };

endmodule
