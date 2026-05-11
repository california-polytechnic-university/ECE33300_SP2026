`timescale 1ns / 1ps


module score_controller(
    output reg [2:0] pixel_color,
    input      [9:0] pixel_x,
    input      [8:0] pixel_y,
    input      [9:0] screen_x,
    input      [9:0] screen_y,
    input      [9:0] pacman_x,
    input      [8:0] pacman_y,
    input            i_map_ctrl_is_dot,
    output           o_map_ctrl_hide_dot,
    output reg       power_mode,
    output reg       game_won,
    input      [1:0] lives_remaining,
    input            game_over,
    output     [3:0] score_thousands,
    output     [3:0] score_hundreds,
    output     [3:0] score_tens,
    output     [3:0] score_ones,
    input      [1:0] map_num,
    input            clk_100mhz,
    input      [1:0] clk_100mhz_phase,
    input            clk_50mhz,
    input            clk_25mhz,
    input            reset
);

    localparam BLACK  = 3'b000;
    localparam RED    = 3'b001;
    localparam GREEN  = 3'b010;
    localparam YELLOW = 3'b011;
    localparam CYAN   = 3'b110;
    localparam WHITE  = 3'b111;

    // About 5 seconds at 50 MHz.
    localparam [27:0] POWER_TIME = 28'd250000000;

    localparam [9:0] TOTAL_DOTS = 10'd258;


    localparam [3:0] WIN_SCORE_THOUSANDS = 4'd2;
    localparam [3:0] WIN_SCORE_HUNDREDS  = 4'd7;
    localparam [3:0] WIN_SCORE_TENS      = 4'd4;
    localparam [3:0] WIN_SCORE_ONES      = 4'd0;

    localparam [15:0] WIN_SCORE_BCD = {
        WIN_SCORE_THOUSANDS,
        WIN_SCORE_HUNDREDS,
        WIN_SCORE_TENS,
        WIN_SCORE_ONES
    };

    reg [27:0] eaten [0:30];
    integer i;

    reg [3:0] thousands;
    reg [3:0] hundreds;
    reg [3:0] tens;
    reg [3:0] ones;
    reg [27:0] power_timer;
    reg [9:0] dots_remaining;

    assign score_thousands = thousands;
    assign score_hundreds  = hundreds;
    assign score_tens      = tens;
    assign score_ones      = ones;

    wire [5:0] scan_col = pixel_x[9:4];
    wire [4:0] scan_row = pixel_y[8:4];
    wire [5:0] pac_col  = pacman_x[9:4];
    wire [4:0] pac_row  = pacman_y[8:4];

    wire scan_inside = (scan_col <= 6'd27) && (scan_row <= 5'd30);
    wire pac_inside  = (pac_col  <= 6'd27) && (pac_row  <= 5'd30);

    assign o_map_ctrl_hide_dot = scan_inside ? eaten[scan_row][27 - scan_col] : 1'b0;

    wire pac_tile_aligned = (pacman_x[3:0] == 4'd0) && (pacman_y[3:0] == 4'd0);
    wire pac_dot_already_eaten = pac_inside ? eaten[pac_row][27 - pac_col] : 1'b1;

    wire [1:0] pac_tile;
    wire pac_tile_is_wall;
    wire pac_tile_is_dot;
    wire [3:0] pac_unused_valid_moves;

    map_rom score_pac_tile_rom(
        .col(pac_col),
        .row(pac_row),
        .map_num(map_num),
        .tile(pac_tile),
        .is_wall(pac_tile_is_wall),
        .is_dot(pac_tile_is_dot),
        .valid_moves(pac_unused_valid_moves)
    );

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

    wire pac_on_power_tile = is_power_tile(pac_col, pac_row);

    function [15:0] add_bcd_tens;
        input [3:0] cur_thousands;
        input [3:0] cur_hundreds;
        input [3:0] cur_tens;
        input [3:0] cur_ones;
        input [3:0] add_tens;
        reg [4:0] t_sum;
        reg [4:0] h_sum;
        reg [4:0] th_sum;
        reg [3:0] ntens;
        reg [3:0] nhundreds;
        reg [3:0] nthousands;
        begin
            t_sum = {1'b0, cur_tens} + {1'b0, add_tens};
            if (t_sum >= 5'd10) begin
                ntens = t_sum - 5'd10;
                h_sum = {1'b0, cur_hundreds} + 5'd1;
            end else begin
                ntens = t_sum[3:0];
                h_sum = {1'b0, cur_hundreds};
            end

            if (h_sum >= 5'd10) begin
                nhundreds = h_sum - 5'd10;
                th_sum = {1'b0, cur_thousands} + 5'd1;
            end else begin
                nhundreds = h_sum[3:0];
                th_sum = {1'b0, cur_thousands};
            end

            if (th_sum >= 5'd10) begin
                nthousands = 4'd9;
                nhundreds  = 4'd9;
                ntens      = 4'd9;
            end else begin
                nthousands = th_sum[3:0];
            end

            add_bcd_tens = {nthousands, nhundreds, ntens, cur_ones};
        end
    endfunction


    function score_bcd_ge;
        input [15:0] score_bcd;
        input [15:0] target_bcd;
        begin
            score_bcd_ge =
                (score_bcd[15:12] > target_bcd[15:12]) ||

                ((score_bcd[15:12] == target_bcd[15:12]) &&
                 (score_bcd[11:8]  >  target_bcd[11:8])) ||

                ((score_bcd[15:12] == target_bcd[15:12]) &&
                 (score_bcd[11:8]  == target_bcd[11:8])  &&
                 (score_bcd[7:4]   >  target_bcd[7:4])) ||

                ((score_bcd[15:12] == target_bcd[15:12]) &&
                 (score_bcd[11:8]  == target_bcd[11:8])  &&
                 (score_bcd[7:4]   == target_bcd[7:4])   &&
                 (score_bcd[3:0]   >= target_bcd[3:0]));
        end
    endfunction

    wire [15:0] score_plus_dot   = add_bcd_tens(thousands, hundreds, tens, ones, 4'd1); // +10
    wire [15:0] score_plus_power = add_bcd_tens(thousands, hundreds, tens, ones, 4'd5); // +50

    wire current_score_reached_win = score_bcd_ge({thousands, hundreds, tens, ones}, WIN_SCORE_BCD);
    wire dot_score_reached_win     = score_bcd_ge(score_plus_dot, WIN_SCORE_BCD);
    wire power_score_reached_win   = score_bcd_ge(score_plus_power, WIN_SCORE_BCD);

    always @(posedge clk_50mhz or posedge reset) begin
        if (reset) begin
            thousands <= 4'd0;
            hundreds  <= 4'd0;
            tens      <= 4'd0;
            ones      <= 4'd0;
            power_mode <= 1'b0;
            game_won <= 1'b0;
            power_timer <= 28'd0;
            dots_remaining <= TOTAL_DOTS;
            for (i = 0; i < 31; i = i + 1)
                eaten[i] <= 28'b0;
        end else begin
            if (!game_won && current_score_reached_win)
                game_won <= 1'b1;

            if (power_timer != 28'd0) begin
                power_timer <= power_timer - 28'd1;
                power_mode <= 1'b1;
            end else begin
                power_mode <= 1'b0;
            end

            if (!game_won && !game_over && pac_inside && pac_tile_aligned && pac_tile_is_dot && !pac_dot_already_eaten) begin
                eaten[pac_row][27 - pac_col] <= 1'b1;

                if (dots_remaining != 10'd0)
                    dots_remaining <= dots_remaining - 10'd1;

                if (pac_on_power_tile) begin
                    thousands <= score_plus_power[15:12];
                    hundreds  <= score_plus_power[11:8];
                    tens      <= score_plus_power[7:4];
                    ones      <= score_plus_power[3:0];

                    if (power_score_reached_win)
                        game_won <= 1'b1;

                    power_timer <= POWER_TIME;
                    power_mode <= 1'b1;
                end else begin
                    thousands <= score_plus_dot[15:12];
                    hundreds  <= score_plus_dot[11:8];
                    tens      <= score_plus_dot[7:4];
                    ones      <= score_plus_dot[3:0];

                    if (dot_score_reached_win)
                        game_won <= 1'b1;
                end
            end
        end
    end

    function [7:0] digit_row;
        input [3:0] digit;
        input [2:0] row;
        begin
            case ({digit, row})
                7'h00: digit_row = 8'b00111100; 7'h01: digit_row = 8'b01000010;
                7'h02: digit_row = 8'b01000110; 7'h03: digit_row = 8'b01001010;
                7'h04: digit_row = 8'b01010010; 7'h05: digit_row = 8'b01100010;
                7'h06: digit_row = 8'b01000010; 7'h07: digit_row = 8'b00111100;

                7'h08: digit_row = 8'b00010000; 7'h09: digit_row = 8'b00110000;
                7'h0a: digit_row = 8'b01010000; 7'h0b: digit_row = 8'b00010000;
                7'h0c: digit_row = 8'b00010000; 7'h0d: digit_row = 8'b00010000;
                7'h0e: digit_row = 8'b00010000; 7'h0f: digit_row = 8'b01111100;

                7'h10: digit_row = 8'b00111100; 7'h11: digit_row = 8'b01000010;
                7'h12: digit_row = 8'b00000010; 7'h13: digit_row = 8'b00001100;
                7'h14: digit_row = 8'b00110000; 7'h15: digit_row = 8'b01000000;
                7'h16: digit_row = 8'b01000000; 7'h17: digit_row = 8'b01111110;

                7'h18: digit_row = 8'b00111100; 7'h19: digit_row = 8'b01000010;
                7'h1a: digit_row = 8'b00000010; 7'h1b: digit_row = 8'b00011100;
                7'h1c: digit_row = 8'b00000010; 7'h1d: digit_row = 8'b00000010;
                7'h1e: digit_row = 8'b01000010; 7'h1f: digit_row = 8'b00111100;

                7'h20: digit_row = 8'b00000100; 7'h21: digit_row = 8'b00001100;
                7'h22: digit_row = 8'b00010100; 7'h23: digit_row = 8'b00100100;
                7'h24: digit_row = 8'b01000100; 7'h25: digit_row = 8'b01111110;
                7'h26: digit_row = 8'b00000100; 7'h27: digit_row = 8'b00000100;

                7'h28: digit_row = 8'b01111110; 7'h29: digit_row = 8'b01000000;
                7'h2a: digit_row = 8'b01000000; 7'h2b: digit_row = 8'b01111100;
                7'h2c: digit_row = 8'b00000010; 7'h2d: digit_row = 8'b00000010;
                7'h2e: digit_row = 8'b01000010; 7'h2f: digit_row = 8'b00111100;

                7'h30: digit_row = 8'b00111100; 7'h31: digit_row = 8'b01000000;
                7'h32: digit_row = 8'b01000000; 7'h33: digit_row = 8'b01111100;
                7'h34: digit_row = 8'b01000010; 7'h35: digit_row = 8'b01000010;
                7'h36: digit_row = 8'b01000010; 7'h37: digit_row = 8'b00111100;

                7'h38: digit_row = 8'b01111110; 7'h39: digit_row = 8'b00000010;
                7'h3a: digit_row = 8'b00000100; 7'h3b: digit_row = 8'b00001000;
                7'h3c: digit_row = 8'b00010000; 7'h3d: digit_row = 8'b00100000;
                7'h3e: digit_row = 8'b00100000; 7'h3f: digit_row = 8'b00100000;

                7'h40: digit_row = 8'b00111100; 7'h41: digit_row = 8'b01000010;
                7'h42: digit_row = 8'b01000010; 7'h43: digit_row = 8'b00111100;
                7'h44: digit_row = 8'b01000010; 7'h45: digit_row = 8'b01000010;
                7'h46: digit_row = 8'b01000010; 7'h47: digit_row = 8'b00111100;

                7'h48: digit_row = 8'b00111100; 7'h49: digit_row = 8'b01000010;
                7'h4a: digit_row = 8'b01000010; 7'h4b: digit_row = 8'b00111110;
                7'h4c: digit_row = 8'b00000010; 7'h4d: digit_row = 8'b00000010;
                7'h4e: digit_row = 8'b01000010; 7'h4f: digit_row = 8'b00111100;

                default: digit_row = 8'b00000000;
            endcase
        end
    endfunction


    function [7:0] letter_row;
        input [3:0] ch;
        input [2:0] row;
        begin
            case ({ch,row})
                // 0: blank
                7'h00: letter_row=8'b00000000; 7'h01: letter_row=8'b00000000; 7'h02: letter_row=8'b00000000; 7'h03: letter_row=8'b00000000;
                7'h04: letter_row=8'b00000000; 7'h05: letter_row=8'b00000000; 7'h06: letter_row=8'b00000000; 7'h07: letter_row=8'b00000000;
                // 1: W
                7'h08: letter_row=8'b01000010; 7'h09: letter_row=8'b01000010; 7'h0a: letter_row=8'b01000010; 7'h0b: letter_row=8'b01011010;
                7'h0c: letter_row=8'b01011010; 7'h0d: letter_row=8'b01100110; 7'h0e: letter_row=8'b01000010; 7'h0f: letter_row=8'b00000000;
                // 2: I
                7'h10: letter_row=8'b01111110; 7'h11: letter_row=8'b00011000; 7'h12: letter_row=8'b00011000; 7'h13: letter_row=8'b00011000;
                7'h14: letter_row=8'b00011000; 7'h15: letter_row=8'b00011000; 7'h16: letter_row=8'b01111110; 7'h17: letter_row=8'b00000000;
                // 3: N
                7'h18: letter_row=8'b01000010; 7'h19: letter_row=8'b01100010; 7'h1a: letter_row=8'b01010010; 7'h1b: letter_row=8'b01001010;
                7'h1c: letter_row=8'b01000110; 7'h1d: letter_row=8'b01000010; 7'h1e: letter_row=8'b01000010; 7'h1f: letter_row=8'b00000000;
                // 4: E
                7'h20: letter_row=8'b01111110; 7'h21: letter_row=8'b01000000; 7'h22: letter_row=8'b01000000; 7'h23: letter_row=8'b01111100;
                7'h24: letter_row=8'b01000000; 7'h25: letter_row=8'b01000000; 7'h26: letter_row=8'b01111110; 7'h27: letter_row=8'b00000000;
                // 5: R
                7'h28: letter_row=8'b01111100; 7'h29: letter_row=8'b01000010; 7'h2a: letter_row=8'b01000010; 7'h2b: letter_row=8'b01111100;
                7'h2c: letter_row=8'b01001000; 7'h2d: letter_row=8'b01000100; 7'h2e: letter_row=8'b01000010; 7'h2f: letter_row=8'b00000000;
                // 6: G
                7'h30: letter_row=8'b00111100; 7'h31: letter_row=8'b01000010; 7'h32: letter_row=8'b01000000; 7'h33: letter_row=8'b01001110;
                7'h34: letter_row=8'b01000010; 7'h35: letter_row=8'b01000010; 7'h36: letter_row=8'b00111100; 7'h37: letter_row=8'b00000000;
                // 7: A
                7'h38: letter_row=8'b00111100; 7'h39: letter_row=8'b01000010; 7'h3a: letter_row=8'b01000010; 7'h3b: letter_row=8'b01111110;
                7'h3c: letter_row=8'b01000010; 7'h3d: letter_row=8'b01000010; 7'h3e: letter_row=8'b01000010; 7'h3f: letter_row=8'b00000000;
                // 8: M
                7'h40: letter_row=8'b01000010; 7'h41: letter_row=8'b01100110; 7'h42: letter_row=8'b01011010; 7'h43: letter_row=8'b01011010;
                7'h44: letter_row=8'b01000010; 7'h45: letter_row=8'b01000010; 7'h46: letter_row=8'b01000010; 7'h47: letter_row=8'b00000000;
                // 9: O
                7'h48: letter_row=8'b00111100; 7'h49: letter_row=8'b01000010; 7'h4a: letter_row=8'b01000010; 7'h4b: letter_row=8'b01000010;
                7'h4c: letter_row=8'b01000010; 7'h4d: letter_row=8'b01000010; 7'h4e: letter_row=8'b00111100; 7'h4f: letter_row=8'b00000000;
                // A: V
                7'h50: letter_row=8'b01000010; 7'h51: letter_row=8'b01000010; 7'h52: letter_row=8'b01000010; 7'h53: letter_row=8'b01000010;
                7'h54: letter_row=8'b00100100; 7'h55: letter_row=8'b00100100; 7'h56: letter_row=8'b00011000; 7'h57: letter_row=8'b00000000;
                // B: S
                7'h58: letter_row=8'b00111100; 7'h59: letter_row=8'b01000010; 7'h5a: letter_row=8'b01000000; 7'h5b: letter_row=8'b00111100;
                7'h5c: letter_row=8'b00000010; 7'h5d: letter_row=8'b01000010; 7'h5e: letter_row=8'b00111100; 7'h5f: letter_row=8'b00000000;
                // C: L
                7'h60: letter_row=8'b01000000; 7'h61: letter_row=8'b01000000; 7'h62: letter_row=8'b01000000; 7'h63: letter_row=8'b01000000;
                7'h64: letter_row=8'b01000000; 7'h65: letter_row=8'b01000000; 7'h66: letter_row=8'b01111110; 7'h67: letter_row=8'b00000000;
                // D: !
                7'h68: letter_row=8'b00011000; 7'h69: letter_row=8'b00011000; 7'h6a: letter_row=8'b00011000; 7'h6b: letter_row=8'b00011000;
                7'h6c: letter_row=8'b00011000; 7'h6d: letter_row=8'b00000000; 7'h6e: letter_row=8'b00011000; 7'h6f: letter_row=8'b00000000;
                default: letter_row=8'b00000000;
            endcase
        end
    endfunction

    // Right-side score
    localparam [9:0] SCORE_X = 10'd800;
    localparam [9:0] SCORE_Y = 10'd70;

    wire in_score_box = (screen_x >= SCORE_X) && (screen_x < SCORE_X + 10'd64) &&
                        (screen_y >= SCORE_Y) && (screen_y < SCORE_Y + 10'd16);
    wire in_power_box = power_mode &&
                        (screen_x >= SCORE_X) && (screen_x < SCORE_X + 10'd64) &&
                        (screen_y >= SCORE_Y + 10'd28) && (screen_y < SCORE_Y + 10'd38);

    wire [6:0] sx = screen_x - SCORE_X;
    wire [5:0] sy = screen_y - SCORE_Y;
    wire [3:0] active_digit = (sx < 7'd16) ? thousands :
                              (sx < 7'd32) ? hundreds  :
                              (sx < 7'd48) ? tens      : ones;
    wire [2:0] font_row = sy[3:1];
    wire [2:0] font_col = sx[3:1];
    wire [7:0] score_row_bits = digit_row(active_digit, font_row);
    wire draw_score_pixel = in_score_box && score_row_bits[7 - font_col];

    // Left-side lives indicator
    localparam [9:0] LIVES_X = 10'd80;
    localparam [9:0] LIVES_Y = 10'd70;
    wire in_lives_digit_box = (screen_x >= LIVES_X) && (screen_x < LIVES_X + 10'd16) &&
                              (screen_y >= LIVES_Y + 10'd28) && (screen_y < LIVES_Y + 10'd44);
    wire [6:0] lx = screen_x - LIVES_X;
    wire [5:0] ly = screen_y - (LIVES_Y + 10'd28);
    wire [7:0] lives_digit_bits = digit_row({2'b00, lives_remaining}, ly[3:1]);
    wire draw_lives_digit = in_lives_digit_box && lives_digit_bits[7 - lx[3:1]];

    wire in_lives_label = (screen_x >= LIVES_X) && (screen_x < LIVES_X + 10'd80) &&
                          (screen_y >= LIVES_Y) && (screen_y < LIVES_Y + 10'd16);
    wire [6:0] labx = screen_x - LIVES_X;
    wire [5:0] laby = screen_y - LIVES_Y;
    wire [3:0] lives_letter = (labx < 7'd16) ? 4'hC :  // L
                              (labx < 7'd32) ? 4'h2 :  // I
                              (labx < 7'd48) ? 4'hA :  // V
                              (labx < 7'd64) ? 4'h4 :  // E
                                               4'hB;   // S
    wire [7:0] lives_label_bits = letter_row(lives_letter, laby[3:1]);
    wire draw_lives_label = in_lives_label && lives_label_bits[7 - labx[3:1]];

    // Center messages
    localparam [9:0] WIN_X = 10'd448;
    localparam [9:0] WIN_Y = 10'd280;
    localparam [9:0] OVER_X = 10'd440;
    localparam [9:0] OVER_Y = 10'd280;

    wire in_win_msg = game_won && (screen_x >= WIN_X) && (screen_x < WIN_X + 10'd128) &&
                      (screen_y >= WIN_Y) && (screen_y < WIN_Y + 10'd16);
    wire [6:0] wx = screen_x - WIN_X;
    wire [5:0] wy = screen_y - WIN_Y;
    wire [3:0] win_letter = (wx < 7'd16)  ? 4'h1 : // W
                            (wx < 7'd32)  ? 4'h2 : // I
                            (wx < 7'd48)  ? 4'h3 : // N
                            (wx < 7'd64)  ? 4'h3 : // N
                            (wx < 7'd80)  ? 4'h4 : // E
                            (wx < 7'd96)  ? 4'h5 : // R
                            (wx < 7'd112) ? 4'hD : // !
                                             4'hD;  // !
    wire [7:0] win_bits = letter_row(win_letter, wy[3:1]);
    wire draw_win = in_win_msg && win_bits[7 - wx[3:1]];

    wire in_over_msg = game_over && (screen_x >= OVER_X) && (screen_x < OVER_X + 10'd144) &&
                       (screen_y >= OVER_Y) && (screen_y < OVER_Y + 10'd16);
    wire [7:0] ox = screen_x - OVER_X;
    wire [5:0] oy = screen_y - OVER_Y;
    wire [3:0] over_letter = (ox < 8'd16)  ? 4'h6 : // G
                             (ox < 8'd32)  ? 4'h7 : // A
                             (ox < 8'd48)  ? 4'h8 : // M
                             (ox < 8'd64)  ? 4'h4 : // E
                             (ox < 8'd80)  ? 4'h0 : // space
                             (ox < 8'd96)  ? 4'h9 : // O
                             (ox < 8'd112) ? 4'hA : // V
                             (ox < 8'd128) ? 4'h4 : // E
                                             4'h5;  // R
    wire [7:0] over_bits = letter_row(over_letter, oy[3:1]);
    wire draw_over = in_over_msg && over_bits[7 - ox[3:1]];

    always @(posedge clk_25mhz) begin
        if (draw_win)
            pixel_color <= YELLOW;
        else if (draw_over)
            pixel_color <= RED;
        else if (draw_lives_label || draw_lives_digit)
            pixel_color <= WHITE;
        else if (draw_score_pixel)
            pixel_color <= WHITE;
        else if (in_power_box)
            pixel_color <= YELLOW;
        else
            pixel_color <= BLACK;
    end

endmodule
