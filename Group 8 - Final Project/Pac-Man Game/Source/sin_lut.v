`timescale 1ns / 1ps

module sin_lut(out, in);

    input  [5:0] in;
    output reg [4:0] out;

    always @(*) begin
        case (in)
            6'd0:  out = 5'd15;
            6'd1:  out = 5'd17;
            6'd2:  out = 5'd19;
            6'd3:  out = 5'd21;
            6'd4:  out = 5'd23;
            6'd5:  out = 5'd25;
            6'd6:  out = 5'd26;
            6'd7:  out = 5'd27;
            6'd8:  out = 5'd28;
            6'd9:  out = 5'd29;
            6'd10: out = 5'd29;
            6'd11: out = 5'd29;
            6'd12: out = 5'd28;
            6'd13: out = 5'd27;
            6'd14: out = 5'd26;
            6'd15: out = 5'd25;
            6'd16: out = 5'd23;
            6'd17: out = 5'd21;
            6'd18: out = 5'd19;
            6'd19: out = 5'd17;
            6'd20: out = 5'd15;
            6'd21: out = 5'd12;
            6'd22: out = 5'd10;
            6'd23: out = 5'd8;
            6'd24: out = 5'd6;
            6'd25: out = 5'd4;
            6'd26: out = 5'd3;
            6'd27: out = 5'd2;
            6'd28: out = 5'd1;
            6'd29: out = 5'd0;
            6'd30: out = 5'd0;
            6'd31: out = 5'd0;
            6'd32: out = 5'd1;
            6'd33: out = 5'd2;
            6'd34: out = 5'd3;
            6'd35: out = 5'd4;
            6'd36: out = 5'd6;
            6'd37: out = 5'd8;
            6'd38: out = 5'd10;
            6'd39: out = 5'd12;
            default: out = 5'd0;
        endcase
    end

endmodule