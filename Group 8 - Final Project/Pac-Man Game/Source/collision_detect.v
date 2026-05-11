`timescale 1ns / 1ps


module collision_detect(pacman_valid_moves,
                        ghost1_valid_moves,
                        ghost2_valid_moves,
                        ghost3_valid_moves,
                        ghost4_valid_moves,
                        pacman_x,
                        pacman_y,
                        ghost1_x,
                        ghost1_y,
                        ghost2_x,
                        ghost2_y,
                        ghost3_x,
                        ghost3_y,
                        ghost4_x,
                        ghost4_y,
                        map_num,
                        clk_100mhz,
                        clk_100mhz_phase);

    output [3:0] pacman_valid_moves;
    output [3:0] ghost1_valid_moves;
    output [3:0] ghost2_valid_moves;
    output [3:0] ghost3_valid_moves;
    output [3:0] ghost4_valid_moves;

    input [5:0] pacman_x;
    input [4:0] pacman_y;
    input [5:0] ghost1_x;
    input [4:0] ghost1_y;
    input [5:0] ghost2_x;
    input [4:0] ghost2_y;
    input [5:0] ghost3_x;
    input [4:0] ghost3_y;
    input [5:0] ghost4_x;
    input [4:0] ghost4_y;
    input [1:0] map_num;
    input clk_100mhz;
    input [1:0] clk_100mhz_phase;

    wire [1:0] unused_tile_p, unused_tile_g1, unused_tile_g2, unused_tile_g3, unused_tile_g4;
    wire unused_wall_p, unused_wall_g1, unused_wall_g2, unused_wall_g3, unused_wall_g4;
    wire unused_dot_p, unused_dot_g1, unused_dot_g2, unused_dot_g3, unused_dot_g4;

    map_rom pacman_map(
        .col(pacman_x), .row(pacman_y), .map_num(map_num),
        .tile(unused_tile_p), .is_wall(unused_wall_p), .is_dot(unused_dot_p),
        .valid_moves(pacman_valid_moves)
    );

    map_rom ghost1_map(
        .col(ghost1_x), .row(ghost1_y), .map_num(map_num),
        .tile(unused_tile_g1), .is_wall(unused_wall_g1), .is_dot(unused_dot_g1),
        .valid_moves(ghost1_valid_moves)
    );

    map_rom ghost2_map(
        .col(ghost2_x), .row(ghost2_y), .map_num(map_num),
        .tile(unused_tile_g2), .is_wall(unused_wall_g2), .is_dot(unused_dot_g2),
        .valid_moves(ghost2_valid_moves)
    );

    map_rom ghost3_map(
        .col(ghost3_x), .row(ghost3_y), .map_num(map_num),
        .tile(unused_tile_g3), .is_wall(unused_wall_g3), .is_dot(unused_dot_g3),
        .valid_moves(ghost3_valid_moves)
    );

    map_rom ghost4_map(
        .col(ghost4_x), .row(ghost4_y), .map_num(map_num),
        .tile(unused_tile_g4), .is_wall(unused_wall_g4), .is_dot(unused_dot_g4),
        .valid_moves(ghost4_valid_moves)
    );

endmodule
