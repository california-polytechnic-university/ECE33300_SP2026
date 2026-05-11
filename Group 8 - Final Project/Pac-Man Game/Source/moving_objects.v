`timescale 1ns / 1ps

module moving_objects(
    output [2:0] pixel_color,
    output [9:0] pacman_pos_x,
    output [8:0] pacman_pos_y,
    output [1:0] lives_remaining,
    output       game_over,
    input  [9:0] pixel_x,
    input  [8:0] pixel_y,
    input  [3:0] move_dir,
    input  [1:0] map_num,
    input  [3:0] enable_ghosts,
    input  [3:0] ghost_1_move,
    input        power_mode,
    input        game_won,
    input        clk_100mhz,
    input  [1:0] clk_100mhz_phase,
    input        clk_50mhz,
    input        clk_25mhz,
    input        clk_24hz,
    input        clk_6hz,
    input        reset
);

    localparam LEFT  = 4'b0001;
    localparam RIGHT = 4'b0010;
    localparam UP    = 4'b0100;
    localparam DOWN  = 4'b1000;

    localparam [5:0] G1_HOME_X = 6'd12;
    localparam [4:0] G1_HOME_Y = 5'd14;
    localparam [5:0] G2_HOME_X = 6'd15;
    localparam [4:0] G2_HOME_Y = 5'd14;
    localparam [5:0] G3_HOME_X = 6'd12;
    localparam [4:0] G3_HOME_Y = 5'd15;
    localparam [5:0] G4_HOME_X = 6'd15;
    localparam [4:0] G4_HOME_Y = 5'd15;

    reg clk_3hz;
    always @(posedge clk_6hz or posedge reset) begin
        if (reset) clk_3hz <= 1'b0;
        else       clk_3hz <= ~clk_3hz;
    end

    wire [3:0] pacman_cur_dir;

    wire [9:0] ghost1_pos_x;
    wire [8:0] ghost1_pos_y;
    wire [3:0] ghost1_cur_dir;
    wire [9:0] ghost2_pos_x;
    wire [8:0] ghost2_pos_y;
    wire [3:0] ghost2_cur_dir;
    wire [9:0] ghost3_pos_x;
    wire [8:0] ghost3_pos_y;
    wire [3:0] ghost3_cur_dir;
    wire [9:0] ghost4_pos_x;
    wire [8:0] ghost4_pos_y;
    wire [3:0] ghost4_cur_dir;

    wire [3:0] pacman_valid_moves;
    wire [3:0] ghost1_valid_moves;
    wire [3:0] ghost2_valid_moves;
    wire [3:0] ghost3_valid_moves;
    wire [3:0] ghost4_valid_moves;

    reg pacman_dead;
    reg [3:0] pacman_death_dir;
    reg [3:0] ghost_eaten;
    reg [1:0] lives_left;
    reg game_over_reg;
    reg position_reset_pulse;

    // Pac-man Death Delay
    localparam [27:0] DEATH_DELAY_COUNT = 28'd150000000;
    reg        death_delay_active;
    reg [27:0] death_delay_counter;

    assign lives_remaining = lives_left;
    assign game_over = game_over_reg;

    wire position_reset = reset | position_reset_pulse;

    wire [5:0] pac_tile_x = pacman_pos_x[9:4];
    wire [4:0] pac_tile_y = pacman_pos_y[8:4];

    wire [5:0] g1_tile_x = ghost1_pos_x[9:4];
    wire [4:0] g1_tile_y = ghost1_pos_y[8:4];
    wire [5:0] g2_tile_x = ghost2_pos_x[9:4];
    wire [4:0] g2_tile_y = ghost2_pos_y[8:4];
    wire [5:0] g3_tile_x = ghost3_pos_x[9:4];
    wire [4:0] g3_tile_y = ghost3_pos_y[8:4];
    wire [5:0] g4_tile_x = ghost4_pos_x[9:4];
    wire [4:0] g4_tile_y = ghost4_pos_y[8:4];

    localparam [9:0] HITBOX_HALF_X = 10'd7;
    localparam [8:0] HITBOX_HALF_Y = 9'd7;

    function [9:0] abs10;
        input [9:0] a;
        input [9:0] b;
        begin
            abs10 = (a >= b) ? (a - b) : (b - a);
        end
    endfunction

    function [8:0] abs9;
        input [8:0] a;
        input [8:0] b;
        begin
            abs9 = (a >= b) ? (a - b) : (b - a);
        end
    endfunction

    wire [9:0] pac_center_x = pacman_pos_x + 10'd8;
    wire [8:0] pac_center_y = pacman_pos_y + 9'd8;

    wire [9:0] g1_center_x = ghost1_pos_x + 10'd8;
    wire [8:0] g1_center_y = ghost1_pos_y + 9'd8;
    wire [9:0] g2_center_x = ghost2_pos_x + 10'd8;
    wire [8:0] g2_center_y = ghost2_pos_y + 9'd8;
    wire [9:0] g3_center_x = ghost3_pos_x + 10'd8;
    wire [8:0] g3_center_y = ghost3_pos_y + 9'd8;
    wire [9:0] g4_center_x = ghost4_pos_x + 10'd8;
    wire [8:0] g4_center_y = ghost4_pos_y + 9'd8;

    wire g1_touch = (abs10(pac_center_x, g1_center_x) <= HITBOX_HALF_X) &&
                    (abs9 (pac_center_y, g1_center_y) <= HITBOX_HALF_Y);
    wire g2_touch = (abs10(pac_center_x, g2_center_x) <= HITBOX_HALF_X) &&
                    (abs9 (pac_center_y, g2_center_y) <= HITBOX_HALF_Y);
    wire g3_touch = (abs10(pac_center_x, g3_center_x) <= HITBOX_HALF_X) &&
                    (abs9 (pac_center_y, g3_center_y) <= HITBOX_HALF_Y);
    wire g4_touch = (abs10(pac_center_x, g4_center_x) <= HITBOX_HALF_X) &&
                    (abs9 (pac_center_y, g4_center_y) <= HITBOX_HALF_Y);

    wire g1_home = (g1_tile_x == G1_HOME_X) && (g1_tile_y == G1_HOME_Y);
    wire g2_home = (g2_tile_x == G2_HOME_X) && (g2_tile_y == G2_HOME_Y);
    wire g3_home = (g3_tile_x == G3_HOME_X) && (g3_tile_y == G3_HOME_Y);
    wire g4_home = (g4_tile_x == G4_HOME_X) && (g4_tile_y == G4_HOME_Y);

    always @(posedge clk_3hz or posedge reset) begin
        if (reset) begin
            pacman_death_dir <= RIGHT;
        end else if (pacman_dead) begin
            case (pacman_death_dir)
                RIGHT: pacman_death_dir <= DOWN;
                DOWN:  pacman_death_dir <= LEFT;
                LEFT:  pacman_death_dir <= UP;
                UP:    pacman_death_dir <= RIGHT;
                default: pacman_death_dir <= RIGHT;
            endcase
        end
    end

    wire bad_ghost_touch = (g1_touch && !ghost_eaten[0]) ||
                           (g2_touch && !ghost_eaten[1]) ||
                           (g3_touch && !ghost_eaten[2]) ||
                           (g4_touch && !ghost_eaten[3]);

    always @(posedge clk_50mhz or posedge reset) begin
        if (reset) begin
            pacman_dead <= 1'b0;
            ghost_eaten <= 4'b0000;
            lives_left <= 2'd2;          // shows 2 lives remaining at game start
            game_over_reg <= 1'b0;
            position_reset_pulse <= 1'b0;
            death_delay_active <= 1'b0;
            death_delay_counter <= 28'd0;
        end else begin
            position_reset_pulse <= 1'b0;

            if (!death_delay_active) begin
                if (ghost_eaten[0] && g1_home) ghost_eaten[0] <= 1'b0;
                if (ghost_eaten[1] && g2_home) ghost_eaten[1] <= 1'b0;
                if (ghost_eaten[2] && g3_home) ghost_eaten[2] <= 1'b0;
                if (ghost_eaten[3] && g4_home) ghost_eaten[3] <= 1'b0;
            end

            if (death_delay_active) begin
                if (death_delay_counter >= DEATH_DELAY_COUNT) begin
                    death_delay_active <= 1'b0;
                    death_delay_counter <= 28'd0;
                    pacman_dead <= 1'b0;
                    ghost_eaten <= 4'b0000;
                    position_reset_pulse <= 1'b1;
                end else begin
                    death_delay_counter <= death_delay_counter + 28'd1;
                    pacman_dead <= 1'b1;
                end
            end else if (!game_over_reg && !game_won) begin
                if (power_mode) begin
                    if (g1_touch && !ghost_eaten[0]) ghost_eaten[0] <= 1'b1;
                    if (g2_touch && !ghost_eaten[1]) ghost_eaten[1] <= 1'b1;
                    if (g3_touch && !ghost_eaten[2]) ghost_eaten[2] <= 1'b1;
                    if (g4_touch && !ghost_eaten[3]) ghost_eaten[3] <= 1'b1;
                end else if (!pacman_dead && bad_ghost_touch) begin
                    if (lives_left != 2'd0) begin
                        lives_left <= lives_left - 2'd1;
                        pacman_dead <= 1'b1;
                        death_delay_active <= 1'b1;
                        death_delay_counter <= 28'd0;
                        ghost_eaten <= 4'b0000;
                    end else begin
                        // Final death: stay in death animation and shows GAME OVER.
                        game_over_reg <= 1'b1;
                        pacman_dead <= 1'b1;
                        death_delay_active <= 1'b0;
                        death_delay_counter <= 28'd0;
                    end
                end
            end
        end
    end

    function [5:0] clamp_x;
        input [6:0] x;
        begin
            if (x[6] == 1'b1) clamp_x = 6'd0;
            else if (x > 7'd27) clamp_x = 6'd27;
            else clamp_x = x[5:0];
        end
    endfunction

    function [4:0] clamp_y;
        input [5:0] y;
        begin
            if (y[5] == 1'b1) clamp_y = 5'd0;
            else if (y > 6'd30) clamp_y = 5'd30;
            else clamp_y = y[4:0];
        end
    endfunction


    function [5:0] abs_x_dist;
        input [5:0] a;
        input [5:0] b;
        begin
            abs_x_dist = (a >= b) ? (a - b) : (b - a);
        end
    endfunction

    function [5:0] abs_y_dist;
        input [4:0] a;
        input [4:0] b;
        begin
            abs_y_dist = (a >= b) ? ({1'b0,a} - {1'b0,b}) : ({1'b0,b} - {1'b0,a});
        end
    endfunction

    function [7:0] manhattan;
        input [5:0] x;
        input [4:0] y;
        input [5:0] tx;
        input [4:0] ty;
        begin
            manhattan = {2'b00, abs_x_dist(x, tx)} + {2'b00, abs_y_dist(y, ty)};
        end
    endfunction

    function [3:0] opposite_dir;
        input [3:0] dir;
        begin
            case (dir)
                LEFT:  opposite_dir = RIGHT;
                RIGHT: opposite_dir = LEFT;
                UP:    opposite_dir = DOWN;
                DOWN:  opposite_dir = UP;
                default: opposite_dir = 4'b0000;
            endcase
        end
    endfunction

    function [3:0] choose_best_dir;
        input [5:0] gx;
        input [4:0] gy;
        input [5:0] tx;
        input [4:0] ty;
        input [3:0] valid;
        input [3:0] curdir;
        input [1:0] personality;

        reg [3:0] allowed;
        reg [7:0] best_dist;
        reg [7:0] d_left;
        reg [7:0] d_right;
        reg [7:0] d_up;
        reg [7:0] d_down;
        begin

            allowed = valid & ~opposite_dir(curdir);
            if (allowed == 4'b0000)
                allowed = valid;

            d_left  = (gx > 6'd0)  ? manhattan(gx - 6'd1, gy, tx, ty) : 8'hff;
            d_right = (gx < 6'd27) ? manhattan(gx + 6'd1, gy, tx, ty) : 8'hff;
            d_up    = (gy > 5'd0)  ? manhattan(gx, gy - 5'd1, tx, ty) : 8'hff;
            d_down  = (gy < 5'd30) ? manhattan(gx, gy + 5'd1, tx, ty) : 8'hff;

            best_dist = 8'hff;
            choose_best_dir = 4'b0000;

            // Path selection
            case (personality)
                2'd0: begin // red: vertical preference
                    if (allowed[2] && d_up    <= best_dist) begin best_dist = d_up;    choose_best_dir = UP;    end
                    if (allowed[3] && d_down  <  best_dist) begin best_dist = d_down;  choose_best_dir = DOWN;  end
                    if (allowed[0] && d_left  <  best_dist) begin best_dist = d_left;  choose_best_dir = LEFT;  end
                    if (allowed[1] && d_right <  best_dist) begin best_dist = d_right; choose_best_dir = RIGHT; end
                end
                2'd1: begin // pink: horizontal preference
                    if (allowed[0] && d_left  <= best_dist) begin best_dist = d_left;  choose_best_dir = LEFT;  end
                    if (allowed[1] && d_right <  best_dist) begin best_dist = d_right; choose_best_dir = RIGHT; end
                    if (allowed[2] && d_up    <  best_dist) begin best_dist = d_up;    choose_best_dir = UP;    end
                    if (allowed[3] && d_down  <  best_dist) begin best_dist = d_down;  choose_best_dir = DOWN;  end
                end
                2'd2: begin // cyan: right/up preference
                    if (allowed[1] && d_right <= best_dist) begin best_dist = d_right; choose_best_dir = RIGHT; end
                    if (allowed[2] && d_up    <  best_dist) begin best_dist = d_up;    choose_best_dir = UP;    end
                    if (allowed[0] && d_left  <  best_dist) begin best_dist = d_left;  choose_best_dir = LEFT;  end
                    if (allowed[3] && d_down  <  best_dist) begin best_dist = d_down;  choose_best_dir = DOWN;  end
                end
                default: begin // green: left/down preference
                    if (allowed[0] && d_left  <= best_dist) begin best_dist = d_left;  choose_best_dir = LEFT;  end
                    if (allowed[3] && d_down  <  best_dist) begin best_dist = d_down;  choose_best_dir = DOWN;  end
                    if (allowed[1] && d_right <  best_dist) begin best_dist = d_right; choose_best_dir = RIGHT; end
                    if (allowed[2] && d_up    <  best_dist) begin best_dist = d_up;    choose_best_dir = UP;    end
                end
            endcase
        end
    endfunction

    wire g1_in_house = (g1_tile_x >= 6'd11 && g1_tile_x <= 6'd16 && g1_tile_y >= 5'd12 && g1_tile_y <= 5'd15);
    wire g2_in_house = (g2_tile_x >= 6'd11 && g2_tile_x <= 6'd16 && g2_tile_y >= 5'd12 && g2_tile_y <= 5'd15);
    wire g3_in_house = (g3_tile_x >= 6'd11 && g3_tile_x <= 6'd16 && g3_tile_y >= 5'd12 && g3_tile_y <= 5'd15);
    wire g4_in_house = (g4_tile_x >= 6'd11 && g4_tile_x <= 6'd16 && g4_tile_y >= 5'd12 && g4_tile_y <= 5'd15);

    // Separate ghost lanes
    localparam [5:0] G1_EXIT_X = 6'd13;
    localparam [4:0] G1_EXIT_Y = 5'd11;
    localparam [5:0] G2_EXIT_X = 6'd14;
    localparam [4:0] G2_EXIT_Y = 5'd11;
    localparam [5:0] G3_EXIT_X = 6'd13;
    localparam [4:0] G3_EXIT_Y = 5'd11;
    localparam [5:0] G4_EXIT_X = 6'd14;
    localparam [4:0] G4_EXIT_Y = 5'd11;

   
    wire [5:0] red_chase_x = pac_tile_x;
    wire [4:0] red_chase_y = pac_tile_y;

    wire [5:0] pink_chase_x =
        (pacman_cur_dir == RIGHT) ? clamp_x({1'b0,pac_tile_x} + 7'd4) :
        (pacman_cur_dir == LEFT)  ? clamp_x({1'b0,pac_tile_x} - 7'd4) : pac_tile_x;
    wire [4:0] pink_chase_y =
        (pacman_cur_dir == DOWN) ? clamp_y({1'b0,pac_tile_y} + 6'd4) :
        (pacman_cur_dir == UP)   ? clamp_y({1'b0,pac_tile_y} - 6'd4) : pac_tile_y;

    wire [5:0] cyan_chase_x =
        (pacman_cur_dir == RIGHT) ? clamp_x({1'b0,pac_tile_x} + 7'd2) :
        (pacman_cur_dir == LEFT)  ? clamp_x({1'b0,pac_tile_x} - 7'd2) :
        (pacman_cur_dir == UP)    ? clamp_x({1'b0,pac_tile_x} - 7'd2) : clamp_x({1'b0,pac_tile_x} + 7'd2);
    wire [4:0] cyan_chase_y =
        (pacman_cur_dir == RIGHT) ? clamp_y({1'b0,pac_tile_y} - 6'd2) :
        (pacman_cur_dir == LEFT)  ? clamp_y({1'b0,pac_tile_y} + 6'd2) :
        (pacman_cur_dir == UP)    ? clamp_y({1'b0,pac_tile_y} - 6'd2) : clamp_y({1'b0,pac_tile_y} + 6'd2);

    wire [5:0] g4_dx = (g4_tile_x >= pac_tile_x) ? (g4_tile_x - pac_tile_x) : (pac_tile_x - g4_tile_x);
    wire [4:0] g4_dy = (g4_tile_y >= pac_tile_y) ? (g4_tile_y - pac_tile_y) : (pac_tile_y - g4_tile_y);
    wire green_scatter = ({1'b0,g4_dx} + {2'b0,g4_dy}) <= 7'd5;
    wire [5:0] green_chase_x = green_scatter ? 6'd1  : pac_tile_x;
    wire [4:0] green_chase_y = green_scatter ? 5'd29 : pac_tile_y;

    wire [5:0] g1_return_x = G1_HOME_X;
    wire [4:0] g1_return_y = G1_HOME_Y;
    wire [5:0] g2_return_x = G2_HOME_X;
    wire [4:0] g2_return_y = G2_HOME_Y;
    wire [5:0] g3_return_x = G3_HOME_X;
    wire [4:0] g3_return_y = G3_HOME_Y;
    wire [5:0] g4_return_x = G4_HOME_X;
    wire [4:0] g4_return_y = G4_HOME_Y;


    wire [5:0] g1_target_x = ghost_eaten[0] ? g1_return_x : (g1_in_house ? G1_EXIT_X : red_chase_x);
    wire [4:0] g1_target_y = ghost_eaten[0] ? g1_return_y : (g1_in_house ? G1_EXIT_Y : red_chase_y);

    wire [5:0] g2_target_x = ghost_eaten[1] ? g2_return_x : (g2_in_house ? G2_EXIT_X : pink_chase_x);
    wire [4:0] g2_target_y = ghost_eaten[1] ? g2_return_y : (g2_in_house ? G2_EXIT_Y : pink_chase_y);

    wire [5:0] g3_target_x = ghost_eaten[2] ? g3_return_x : (g3_in_house ? G3_EXIT_X : cyan_chase_x);
    wire [4:0] g3_target_y = ghost_eaten[2] ? g3_return_y : (g3_in_house ? G3_EXIT_Y : cyan_chase_y);

    wire [5:0] g4_target_x = ghost_eaten[3] ? g4_return_x : (g4_in_house ? G4_EXIT_X : green_chase_x);
    wire [4:0] g4_target_y = ghost_eaten[3] ? g4_return_y : (g4_in_house ? G4_EXIT_Y : green_chase_y);

    wire [3:0] ghost1_motion_valid = ghost_eaten[0] ? 4'b1111 : ghost1_valid_moves;
    wire [3:0] ghost2_motion_valid = ghost_eaten[1] ? 4'b1111 : ghost2_valid_moves;
    wire [3:0] ghost3_motion_valid = ghost_eaten[2] ? 4'b1111 : ghost3_valid_moves;
    wire [3:0] ghost4_motion_valid = ghost_eaten[3] ? 4'b1111 : ghost4_valid_moves;


    wire [3:0] ghost1_cmd_dir = choose_best_dir(g1_tile_x, g1_tile_y, g1_target_x, g1_target_y, ghost1_motion_valid, ghost_eaten[0] ? 4'b0000 : ghost1_cur_dir, 2'd0);
    wire [3:0] ghost2_cmd_dir = choose_best_dir(g2_tile_x, g2_tile_y, g2_target_x, g2_target_y, ghost2_motion_valid, ghost_eaten[1] ? 4'b0000 : ghost2_cur_dir, 2'd1);
    wire [3:0] ghost3_cmd_dir = choose_best_dir(g3_tile_x, g3_tile_y, g3_target_x, g3_target_y, ghost3_motion_valid, ghost_eaten[2] ? 4'b0000 : ghost3_cur_dir, 2'd2);
    wire [3:0] ghost4_cmd_dir = choose_best_dir(g4_tile_x, g4_tile_y, g4_target_x, g4_target_y, ghost4_motion_valid, ghost_eaten[3] ? 4'b0000 : ghost4_cur_dir, 2'd3);

    defparam pacman_motion.def_pos_x = 10'd208; // col 13
    defparam pacman_motion.def_pos_y = 9'd368;  // row 23
    motion_handler pacman_motion(pacman_pos_x, pacman_pos_y, pacman_cur_dir,
                                 (pacman_dead | game_over_reg | game_won) ? 4'b0000 : move_dir,
                                 pacman_valid_moves,
                                 10'd208, 9'd368, clk_24hz, position_reset);

    defparam ghost1_motion.def_pos_x = 10'd192; // col 12
    defparam ghost1_motion.def_pos_y = 9'd224;  // row 14
    motion_handler ghost1_motion(ghost1_pos_x, ghost1_pos_y, ghost1_cur_dir,
                                 (pacman_dead | game_over_reg | game_won) ? 4'b0000 : (enable_ghosts[0] ? ghost1_cmd_dir : ghost_1_move),
                                 ghost1_motion_valid,
                                 10'd192, 9'd224, clk_24hz, position_reset);

    defparam ghost2_motion.def_pos_x = 10'd240; // col 15
    defparam ghost2_motion.def_pos_y = 9'd224;  // row 14
    motion_handler ghost2_motion(ghost2_pos_x, ghost2_pos_y, ghost2_cur_dir,
                                 ((pacman_dead | game_over_reg | game_won | ~enable_ghosts[1]) ? 4'b0000 : ghost2_cmd_dir),
                                 ghost2_motion_valid,
                                 10'd240, 9'd224, clk_24hz, position_reset);

    defparam ghost3_motion.def_pos_x = 10'd192; // col 12
    defparam ghost3_motion.def_pos_y = 9'd240;  // row 15
    motion_handler ghost3_motion(ghost3_pos_x, ghost3_pos_y, ghost3_cur_dir,
                                 ((pacman_dead | game_over_reg | game_won | ~enable_ghosts[2]) ? 4'b0000 : ghost3_cmd_dir),
                                 ghost3_motion_valid,
                                 10'd192, 9'd240, clk_24hz, position_reset);

    defparam ghost4_motion.def_pos_x = 10'd240; // col 15
    defparam ghost4_motion.def_pos_y = 9'd240;  // row 15
    motion_handler ghost4_motion(ghost4_pos_x, ghost4_pos_y, ghost4_cur_dir,
                                 ((pacman_dead | game_over_reg | game_won | ~enable_ghosts[3]) ? 4'b0000 : ghost4_cmd_dir),
                                 ghost4_motion_valid,
                                 10'd240, 9'd240, clk_24hz, position_reset);

    moving_object_sprite_gen mo_sg(pixel_color,
                                   pixel_x,
                                   pixel_y,
                                   pacman_pos_x,
                                   pacman_pos_y,
                                   pacman_dead ? pacman_death_dir : pacman_cur_dir,
                                   ghost1_pos_x,
                                   ghost1_pos_y,
                                   ghost1_cur_dir,
                                   ghost2_pos_x,
                                   ghost2_pos_y,
                                   ghost2_cur_dir,
                                   ghost3_pos_x,
                                   ghost3_pos_y,
                                   ghost3_cur_dir,
                                   ghost4_pos_x,
                                   ghost4_pos_y,
                                   ghost4_cur_dir,
                                   ghost_eaten,
                                   power_mode,
                                   clk_3hz,
                                   clk_25mhz,
                                   clk_100mhz_phase);

    collision_detect cd(pacman_valid_moves,
                        ghost1_valid_moves,
                        ghost2_valid_moves,
                        ghost3_valid_moves,
                        ghost4_valid_moves,
                        pac_tile_x,
                        pac_tile_y,
                        g1_tile_x,
                        g1_tile_y,
                        g2_tile_x,
                        g2_tile_y,
                        g3_tile_x,
                        g3_tile_y,
                        g4_tile_x,
                        g4_tile_y,
                        map_num,
                        clk_100mhz,
                        clk_100mhz_phase);

endmodule
