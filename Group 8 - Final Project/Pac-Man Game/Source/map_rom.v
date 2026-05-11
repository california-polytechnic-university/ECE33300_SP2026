`timescale 1ns / 1ps


module map_rom(
    input  wire [5:0] col,
    input  wire [4:0] row,
    input  wire [1:0] map_num,
    output reg  [1:0] tile,
    output wire       is_wall,
    output wire       is_dot,
    output wire [3:0] valid_moves
);

    localparam EMPTY = 2'b00;
    localparam WALL  = 2'b01;
    localparam DOT   = 2'b10;

    localparam [5:0] LAST_COL = 6'd27;
    localparam [4:0] LAST_ROW = 5'd30;

    // 1 = wall, 0 = open path
    function [27:0] row_bits;
        input [4:0] r;
        begin
            case (r)
                5'd0:  row_bits =  28'b1111111111111111111111111111;
                5'd1:  row_bits =  28'b1000000000000110000000000001;
                5'd2:  row_bits =  28'b1011110111110110111110111101;
                5'd3:  row_bits =  28'b1011110111110110111110111101;
                5'd4:  row_bits =  28'b1011110111110110111110111101;
                5'd5:  row_bits =  28'b1000000000000000000000000001;
                5'd6:  row_bits =  28'b1011110110111111110110111101;
                5'd7:  row_bits =  28'b1011110110111111110110111101;
                5'd8:  row_bits =  28'b1000000110000110000110000001;
                5'd9:  row_bits =  28'b1111110111110110111110111111;
                5'd10:  row_bits = 28'b1111110111110110111110111111;
                5'd11:  row_bits = 28'b1111110110000000000110111111;
                5'd12:  row_bits = 28'b1111110110111001110110111111;
                5'd13:  row_bits = 28'b1111110110100000010110111111;
                5'd14:  row_bits = 28'b0000000000100000010000000000;
		5'd15:  row_bits = 28'b1111110110100000010110111111;
                5'd16:  row_bits = 28'b1111110110111111110110111111;
                5'd17:  row_bits = 28'b1111110110000000000110111111;
                5'd18:  row_bits = 28'b1111110110111111110110111111;
                5'd19:  row_bits = 28'b1111110110111111110110111111;
                5'd20:  row_bits = 28'b1000000000000110000000000001;
                5'd21:  row_bits = 28'b1011110111110110111110111101;
                5'd22:  row_bits = 28'b1011110111110110111110111101;
                5'd23:  row_bits = 28'b1000110000000000000000110001;
                5'd24:  row_bits = 28'b1110110110111111110110110111;
                5'd25:  row_bits = 28'b1110110110111111110110110111;
                5'd26:  row_bits = 28'b1000000110000110000110000001;
                5'd27:  row_bits = 28'b1011111111110110111111111101;
                5'd28:  row_bits = 28'b1011111111110110111111111101;
                5'd29:  row_bits = 28'b1000000000000000000000000001;
                5'd30:  row_bits = 28'b1111111111111111111111111111;
                default: row_bits = 28'b1111111111111111111111111111;
            endcase
        end
    endfunction

    function wall_at;
        input [5:0] c;
        input [4:0] r;
        reg [27:0] bits;
        begin
            if (c > LAST_COL || r > LAST_ROW) begin
                wall_at = 1'b1;
            end else begin
                bits = row_bits(r);
                wall_at = bits[27 - c];
            end
        end
    endfunction

    wire wall_here  = wall_at(col, row);

    wire tunnel_row = (row == 5'd14);

    wire wall_left  = (col == 6'd0)     ? ~tunnel_row : wall_at(col - 6'd1, row);
    wire wall_right = (col >= LAST_COL) ? ~tunnel_row : wall_at(col + 6'd1, row);
    wire wall_up    = (row == 5'd0)     ? 1'b1 : wall_at(col, row - 5'd1);
    wire wall_down  = (row >= LAST_ROW) ? 1'b1 : wall_at(col, row + 5'd1);

    assign is_wall = wall_here;
    assign is_dot  = (tile == DOT);

    assign valid_moves = wall_here ? 4'b0000 :
                         {~wall_down, ~wall_up, ~wall_right, ~wall_left};

    // No-dot areas
    wire no_dot_ghost_house = (row >= 5'd13 && row <= 5'd16) &&
                              (col >= 6'd11 && col <= 6'd16);

    wire no_dot_user_box    = (row >= 5'd9 && row <= 5'd19) &&
                              (col >= 6'd7  && col <= 6'd20);

    always @(*) begin
        if (wall_here) begin
            tile = WALL;
        end else begin
            if (no_dot_ghost_house || no_dot_user_box)
                tile = EMPTY;
            else
                tile = DOT;
        end
    end

endmodule
