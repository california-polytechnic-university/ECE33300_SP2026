`timescale 1ns / 1ps


module map_controller(vga_out,
                      pixel_x,
                      pixel_y,
                      map_num,
                      is_dot,
                      hide_dot,
                      power_mode,
                      game_won,
                      reset,
                      clk_100mhz,
                      clk_100mhz_phase,
                      clk_50mhz,
                      clk_25mhz);

    output reg [2:0] vga_out;
    input  [9:0] pixel_x;
    input  [8:0] pixel_y;
    input  [1:0] map_num;
    output       is_dot;
    input        hide_dot;
    input        power_mode;
    input        game_won;
    input        reset;
    input        clk_100mhz, clk_50mhz, clk_25mhz;
    input  [1:0] clk_100mhz_phase;

    wire [5:0] tile_x = pixel_x[9:4];
    wire [4:0] tile_y = pixel_y[8:4];
    wire [3:0] local_x = pixel_x[3:0];
    wire [3:0] local_y = pixel_y[3:0];

    wire [1:0] tile;
    wire wall;
    wire dot;
    wire [3:0] unused_valid_moves;

    map_rom maze(
        .col(tile_x),
        .row(tile_y),
        .map_num(map_num),
        .tile(tile),
        .is_wall(wall),
        .is_dot(dot),
        .valid_moves(unused_valid_moves)
    );

    assign is_dot = dot;

    function is_power_tile;
        input [5:0] c;
        input [4:0] r;
        begin
            is_power_tile = ((c == 6'd1  && r == 5'd3)  ||
                             (c == 6'd26 && r == 5'd3)  ||
                             (c == 6'd1  && r == 5'd27) ||
                             (c == 6'd26 && r == 5'd27));
        end
    endfunction

    wire power_tile = is_power_tile(tile_x, tile_y);

    // Winner-state
    reg [24:0] win_flash_count;
    always @(posedge clk_50mhz or posedge reset) begin
        if (reset)
            win_flash_count <= 25'd0;
        else if (game_won)
            win_flash_count <= win_flash_count + 25'd1;
        else
            win_flash_count <= 25'd0;
    end

    wire win_flash = win_flash_count[24];

    wire power_pellet_pixel = power_tile && !hide_dot &&
                              (local_x >= 4'd4) && (local_x <= 4'd11) &&
                              (local_y >= 4'd4) && (local_y <= 4'd11) &&
                              !((local_x == 4'd4  && (local_y == 4'd4  || local_y == 4'd11)) ||
                                (local_x == 4'd11 && (local_y == 4'd4  || local_y == 4'd11)));

    wire small_dot_pixel = dot && !hide_dot && !power_tile &&
                           (local_x == 4'd7 || local_x == 4'd8) &&
                           (local_y == 4'd7 || local_y == 4'd8);

    always @(posedge clk_25mhz) begin
        if (reset) begin
            vga_out <= 3'b000;
        end else begin
            if (tile_x > 6'd27 || tile_y > 5'd30) begin
                vga_out <= 3'b000;
            end else if (wall) begin

                // Winner state 
                if (game_won)
                    vga_out <= win_flash ? 3'b001 : 3'b100; // red/blue
                else
                    vga_out <= power_mode ? 3'b110 : 3'b100;
            end else if (power_pellet_pixel) begin
                vga_out <= 3'b011; // yellow power pellet
            end else if (small_dot_pixel) begin
                vga_out <= 3'b111; // white dot
            end else begin
                vga_out <= 3'b000;
            end
        end
    end
endmodule
