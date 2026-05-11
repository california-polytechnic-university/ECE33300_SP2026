

module sevenseg_driver(
    input clk,
    input [15:0] number,
    output reg [6:0] SEG,
    output reg [7:0] AN,
    output DP
);

    assign DP = 1'b1;

    reg [19:0] refresh = 0;
    reg [3:0] digit;

    wire [3:0] ones;
    wire [3:0] tens;
    wire [3:0] hundreds;
    wire [3:0] thousands;

    assign ones = number % 10;
    assign tens = (number / 10) % 10;
    assign hundreds = (number / 100) % 10;
    assign thousands = (number / 1000) % 10;

    always @(posedge clk) begin
   refresh <= refresh + 1;
    end

    always @(*) begin
        case (refresh[19:18])
      2'b00: begin
             AN = 8'b11111110;
           digit = ones;
         end

            2'b01: begin
            AN = 8'b11111101;
                digit = tens;
            end

            2'b10: begin
                AN = 8'b11111011;
                digit = hundreds;
            end

            2'b11: begin
                AN = 8'b11110111;
                digit = thousands;
            end
        endcase
    end

    always @(*) begin
        case (digit)
            4'd0: SEG = 7'b1000000;
            4'd1: SEG = 7'b1111001;
            4'd2: SEG = 7'b0100100;
            4'd3: SEG = 7'b0110000;
            4'd4: SEG = 7'b0011001;
            4'd5: SEG = 7'b0010010;
            4'd6: SEG = 7'b0000010;
            4'd7: SEG = 7'b1111000;
            4'd8: SEG = 7'b0000000;
            4'd9: SEG = 7'b0010000;
            default: SEG = 7'b1111111;
        endcase
    end

endmodule