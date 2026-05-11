`timescale 1ns / 1ps

module top(
    output [3:0] vga_red,
    output [3:0] vga_green,
    output [3:0] vga_blue,
    output       vga_hsync,
    output       vga_vsync,
    input        ps2d,
    input        ps2c,
    input  [4:0] btns,
    input  [7:0] switches,
    output [7:0] leds,
    output       rgb_led_r,
    output       rgb_led_g,
    output       rgb_led_b,
    output [6:0] seg,
    output [7:0] an,
    output       dp,
    output       uart_txd,
    input        uart_rxd,
    input        clk_board
);

    //------------------------------------------------------------
    // Colors
    //------------------------------------------------------------
    localparam [11:0] BLACK = 12'h000;
    localparam [11:0] RED   = 12'hf00;
    localparam [11:0] GREEN = 12'h0f0;
    localparam [11:0] BLUE  = 12'h00f;
    localparam [11:0] WHITE = 12'hfff;
    localparam [11:0] CYAN  = 12'h0ff;
    localparam [11:0] PINK  = 12'hf0f;
    localparam [11:0] YELL  = 12'hff0;

    //------------------------------------------------------------
    // Clocking
    //------------------------------------------------------------
    wire clk_6hz;
    wire clk_24hz;
    wire clk_25mhz;
    wire clk_50mhz;
    wire clk_100mhz;
    wire [1:0] clk_100mhz_phase;

    clock_manager clocking(
        clk_100mhz,
        clk_50mhz,
        clk_100mhz_phase,
        clk_25mhz,
        clk_6hz,
        clk_24hz,
        clk_board,
        1'b0
    );

    //------------------------------------------------------------
    // VGA timing signals
    //------------------------------------------------------------
    wire [10:0] hcount;
    wire [10:0] vcount;
    wire        hblank;
    wire        vblank;
    wire        pixpulse;

    reg [11:0] current_pixel;

    vga_timing_1024_600 vga_gen(
        .clk      (clk_50mhz),
        .rst      (btns[4]),
        .pixpulse (pixpulse),
        .hcount   (hcount),
        .vcount   (vcount),
        .hsync    (vga_hsync),
        .vsync    (vga_vsync),
        .hblank   (hblank),
        .vblank   (vblank)
    );

    wire blank = hblank | vblank;

    //------------------------------------------------------------
    // Game screen placement
    //------------------------------------------------------------
    localparam [9:0] GAME_X_OFFSET = 10'd288;
    localparam [9:0] GAME_Y_OFFSET = 10'd52;
    localparam [9:0] GAME_W        = 10'd448;
    localparam [9:0] GAME_H        = 10'd496;

    wire in_game_x = (hcount[9:0] >= GAME_X_OFFSET) &&
                     (hcount[9:0] <  (GAME_X_OFFSET + GAME_W));

    wire in_game_y = (vcount[9:0] >= GAME_Y_OFFSET) &&
                     (vcount[9:0] <  (GAME_Y_OFFSET + GAME_H));

    wire [9:0] game_x = in_game_x ? (hcount[9:0] - GAME_X_OFFSET) : 10'd600;
    wire [9:0] game_y_wide = vcount[9:0] - GAME_Y_OFFSET;
    wire [8:0] game_y = in_game_y ? game_y_wide[8:0] : 9'd511;

    //------------------------------------------------------------
    // Game signals
    //------------------------------------------------------------
    wire [2:0] map_pix_color;
    wire [2:0] score_pixel_color;
    wire [2:0] moving_piece_color;
    wire [2:0] background_pixel_color;

    wire map_ctrl_is_dot;
    wire map_ctrl_hide_dot;

    wire [9:0] pacman_pos_x;
    wire [8:0] pacman_pos_y;

    wire power_mode;
    wire game_won;
    wire game_over;
    wire [1:0] lives_remaining;

    wire [3:0] score_thousands;
    wire [3:0] score_hundreds;
    wire [3:0] score_tens;
    wire [3:0] score_ones;

    reg  [1:0] map_num;
    reg  [3:0] move_dir;

    //------------------------------------------------------------
    // Switches and LEDs
    //------------------------------------------------------------
    wire [3:0] speed_sel = switches[3:0];
    wire [2:0] enable_effect = {switches[7:6], 1'b0};

    pacman_led_output u_leds(
        .clk             (clk_50mhz),
        .reset           (btns[4]),
        .speed_sel       (speed_sel),
        .power_mode      (power_mode),
        .game_won        (game_won),
        .game_over       (game_over),
        .lives_remaining (lives_remaining),
        .leds            (leds),
        .rgb_led_r       (rgb_led_r),
        .rgb_led_g       (rgb_led_g),
        .rgb_led_b       (rgb_led_b)
    );

    //------------------------------------------------------------
    // Button direction logic
    //------------------------------------------------------------
    always @(posedge clk_50mhz or posedge btns[4]) begin
        if (btns[4]) begin
            move_dir <= 4'b0000;
        end else if (game_over || game_won) begin
            move_dir <= 4'b0000;
        end else if (btns[3]) begin
            move_dir <= 4'b0100; // up
        end else if (btns[2]) begin
            move_dir <= 4'b0001; // left
        end else if (btns[1]) begin
            move_dir <= 4'b0010; // right
        end else if (btns[0]) begin
            move_dir <= 4'b1000; // down
        end
    end

    //------------------------------------------------------------
    // Map select
    //------------------------------------------------------------
    always @(posedge clk_50mhz or posedge btns[4]) begin
        if (btns[4]) begin
            map_num <= 2'b00;
        end else begin
            case (switches[5:4])
                2'b00:   map_num <= 2'b00;
                2'b01:   map_num <= 2'b01;
                default: map_num <= map_num;
            endcase
        end
    end

    //------------------------------------------------------------
    // Variable movement clock
    //------------------------------------------------------------
    reg [21:0] speed_count;
    reg        game_move_clk;
    reg [21:0] speed_half_period;

    always @(*) begin
        case (speed_sel)
            4'h0: speed_half_period = 22'd260416;
            4'h1: speed_half_period = 22'd240384;
            4'h2: speed_half_period = 22'd223214;
            4'h3: speed_half_period = 22'd208333;
            4'h4: speed_half_period = 22'd195312;
            4'h5: speed_half_period = 22'd183823;
            4'h6: speed_half_period = 22'd173611;
            4'h7: speed_half_period = 22'd164474;
            4'h8: speed_half_period = 22'd156250;
            4'h9: speed_half_period = 22'd148810;
            4'hA: speed_half_period = 22'd142045;
            4'hB: speed_half_period = 22'd135870;
            4'hC: speed_half_period = 22'd127551;
            4'hD: speed_half_period = 22'd120192;
            4'hE: speed_half_period = 22'd111607;
            4'hF: speed_half_period = 22'd104166;
            default: speed_half_period = 22'd260416;
        endcase
    end

    always @(posedge clk_50mhz or posedge btns[4]) begin
        if (btns[4]) begin
            speed_count   <= 22'd0;
            game_move_clk <= 1'b0;
        end else begin
            if (speed_count >= speed_half_period) begin
                speed_count   <= 22'd0;
                game_move_clk <= ~game_move_clk;
            end else begin
                speed_count <= speed_count + 22'd1;
            end
        end
    end

    //------------------------------------------------------------
    // Game modules
    //------------------------------------------------------------
    wire [3:0] enable_ghosts = 4'b1111;
    wire [3:0] ghost_1_move  = 4'b0000;

    background_effects be(
        background_pixel_color,
        hcount[9:0],
        vcount[8:0],
        enable_effect,
        clk_50mhz,
        clk_6hz
    );

    map_controller mc(
        map_pix_color,
        game_x,
        game_y,
        map_num,
        map_ctrl_is_dot,
        map_ctrl_hide_dot,
        power_mode,
        game_won,
        btns[4],
        clk_100mhz,
        clk_100mhz_phase,
        clk_50mhz,
        clk_50mhz
    );

    moving_objects mo(
        moving_piece_color,
        pacman_pos_x,
        pacman_pos_y,
        lives_remaining,
        game_over,
        game_x,
        game_y,
        move_dir,
        map_num,
        enable_ghosts,
        ghost_1_move,
        power_mode,
        game_won,
        clk_100mhz,
        clk_100mhz_phase,
        clk_50mhz,
        clk_50mhz,
        game_move_clk,
        clk_6hz,
        btns[4]
    );

    score_controller sc(
        .pixel_color(score_pixel_color),
        .pixel_x(game_x),
        .pixel_y(game_y),
        .screen_x(hcount[9:0]),
        .screen_y(vcount[9:0]),
        .pacman_x(pacman_pos_x),
        .pacman_y(pacman_pos_y),
        .i_map_ctrl_is_dot(map_ctrl_is_dot),
        .o_map_ctrl_hide_dot(map_ctrl_hide_dot),
        .power_mode(power_mode),
        .game_won(game_won),
        .lives_remaining(lives_remaining),
        .game_over(game_over),
        .score_thousands(score_thousands),
        .score_hundreds(score_hundreds),
        .score_tens(score_tens),
        .score_ones(score_ones),
        .map_num(map_num),
        .clk_100mhz(clk_100mhz),
        .clk_100mhz_phase(clk_100mhz_phase),
        .clk_50mhz(clk_50mhz),
        .clk_25mhz(clk_50mhz),
        .reset(btns[4])
    );

    sevenseg_score_display ssd(
        .clk(clk_100mhz),
        .reset(btns[4]),
        .thousands(score_thousands),
        .hundreds(score_hundreds),
        .tens(score_tens),
        .ones(score_ones),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

    uart_status_tx uart0(
        .clk(clk_100mhz),
        .reset(btns[4]),
        .thousands(score_thousands),
        .hundreds(score_hundreds),
        .tens(score_tens),
        .ones(score_ones),
        .power_mode(power_mode),
        .speed_sel(speed_sel),
        .tx(uart_txd)
    );

    wire unused_uart_rxd = uart_rxd;
    wire unused_ps2d = ps2d;
    wire unused_ps2c = ps2c;

    //------------------------------------------------------------
    // Converting game colors 
    //------------------------------------------------------------
    function [11:0] color3_to_12;
        input [2:0] color3;
        begin
            case (color3)
                3'b000: color3_to_12 = BLACK;
                3'b001: color3_to_12 = RED;
                3'b010: color3_to_12 = GREEN;
                3'b011: color3_to_12 = YELL;
                3'b100: color3_to_12 = BLUE;
                3'b101: color3_to_12 = PINK;
                3'b110: color3_to_12 = CYAN;
                3'b111: color3_to_12 = WHITE;
                default: color3_to_12 = BLACK;
            endcase
        end
    endfunction

    //------------------------------------------------------------
    // Priority mux
    //------------------------------------------------------------
    always @(posedge clk_50mhz or posedge btns[4]) begin
        if (btns[4]) begin
            current_pixel <= BLACK;
        end else if (pixpulse) begin
            if (blank)
                current_pixel <= BLACK;
            else if (score_pixel_color != 3'b000)
                current_pixel <= color3_to_12(score_pixel_color);
            else if (moving_piece_color != 3'b000)
                current_pixel <= color3_to_12(moving_piece_color);
            else if (map_pix_color != 3'b000)
                current_pixel <= color3_to_12(map_pix_color);
            else
                current_pixel <= color3_to_12(background_pixel_color);
        end
    end

    assign vga_red   = current_pixel[11:8];
    assign vga_green = current_pixel[7:4];
    assign vga_blue  = current_pixel[3:0];

endmodule
