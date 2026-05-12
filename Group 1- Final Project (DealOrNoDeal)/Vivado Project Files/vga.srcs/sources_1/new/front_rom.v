`timescale 1ns / 1ps

module font_rom (
    input  wire [3:0]  char_code,  // 0-9 for digits, 10 for $
    input  wire [2:0]  row,        // 0-6 (7 rows)
    output reg  [4:0]  bitmap      // 5 pixels wide
);
    always @(*) begin
        case (char_code)
            // 0
            4'd0: case (row)
                3'd0: bitmap = 5'b01110;
                3'd1: bitmap = 5'b10001;
                3'd2: bitmap = 5'b10011;
                3'd3: bitmap = 5'b10101;
                3'd4: bitmap = 5'b11001;
                3'd5: bitmap = 5'b10001;
                3'd6: bitmap = 5'b01110;
                default: bitmap = 5'b00000;
            endcase
            // 1
            4'd1: case (row)
                3'd0: bitmap = 5'b00100;
                3'd1: bitmap = 5'b01100;
                3'd2: bitmap = 5'b00100;
                3'd3: bitmap = 5'b00100;
                3'd4: bitmap = 5'b00100;
                3'd5: bitmap = 5'b00100;
                3'd6: bitmap = 5'b01110;
                default: bitmap = 5'b00000;
            endcase
            // 2
            4'd2: case (row)
                3'd0: bitmap = 5'b01110;
                3'd1: bitmap = 5'b10001;
                3'd2: bitmap = 5'b00001;
                3'd3: bitmap = 5'b00010;
                3'd4: bitmap = 5'b00100;
                3'd5: bitmap = 5'b01000;
                3'd6: bitmap = 5'b11111;
                default: bitmap = 5'b00000;
            endcase
            // 3
            4'd3: case (row)
                3'd0: bitmap = 5'b01110;
                3'd1: bitmap = 5'b10001;
                3'd2: bitmap = 5'b00001;
                3'd3: bitmap = 5'b00110;
                3'd4: bitmap = 5'b00001;
                3'd5: bitmap = 5'b10001;
                3'd6: bitmap = 5'b01110;
                default: bitmap = 5'b00000;
            endcase
            // 4
            4'd4: case (row)
                3'd0: bitmap = 5'b00010;
                3'd1: bitmap = 5'b00110;
                3'd2: bitmap = 5'b01010;
                3'd3: bitmap = 5'b10010;
                3'd4: bitmap = 5'b11111;
                3'd5: bitmap = 5'b00010;
                3'd6: bitmap = 5'b00010;
                default: bitmap = 5'b00000;
            endcase
            // 5
            4'd5: case (row)
                3'd0: bitmap = 5'b11111;
                3'd1: bitmap = 5'b10000;
                3'd2: bitmap = 5'b11110;
                3'd3: bitmap = 5'b00001;
                3'd4: bitmap = 5'b00001;
                3'd5: bitmap = 5'b10001;
                3'd6: bitmap = 5'b01110;
                default: bitmap = 5'b00000;
            endcase
            // 6
            4'd6: case (row)
                3'd0: bitmap = 5'b00110;
                3'd1: bitmap = 5'b01000;
                3'd2: bitmap = 5'b10000;
                3'd3: bitmap = 5'b11110;
                3'd4: bitmap = 5'b10001;
                3'd5: bitmap = 5'b10001;
                3'd6: bitmap = 5'b01110;
                default: bitmap = 5'b00000;
            endcase
            // 7
            4'd7: case (row)
                3'd0: bitmap = 5'b11111;
                3'd1: bitmap = 5'b00001;
                3'd2: bitmap = 5'b00010;
                3'd3: bitmap = 5'b00100;
                3'd4: bitmap = 5'b01000;
                3'd5: bitmap = 5'b01000;
                3'd6: bitmap = 5'b01000;
                default: bitmap = 5'b00000;
            endcase
            // 8
            4'd8: case (row)
                3'd0: bitmap = 5'b01110;
                3'd1: bitmap = 5'b10001;
                3'd2: bitmap = 5'b10001;
                3'd3: bitmap = 5'b01110;
                3'd4: bitmap = 5'b10001;
                3'd5: bitmap = 5'b10001;
                3'd6: bitmap = 5'b01110;
                default: bitmap = 5'b00000;
            endcase
            // 9
            4'd9: case (row)
                3'd0: bitmap = 5'b01110;
                3'd1: bitmap = 5'b10001;
                3'd2: bitmap = 5'b10001;
                3'd3: bitmap = 5'b01111;
                3'd4: bitmap = 5'b00001;
                3'd5: bitmap = 5'b00010;
                3'd6: bitmap = 5'b01100;
                default: bitmap = 5'b00000;
            endcase
            // $ (dollar sign)
            4'd10: case (row)
                3'd0: bitmap = 5'b00100;
                3'd1: bitmap = 5'b01110;
                3'd2: bitmap = 5'b10100;
                3'd3: bitmap = 5'b01110;
                3'd4: bitmap = 5'b00101;
                3'd5: bitmap = 5'b01110;
                3'd6: bitmap = 5'b00100;
                default: bitmap = 5'b00000;
            endcase
            default: bitmap = 5'b00000;
        endcase
    end
endmodule