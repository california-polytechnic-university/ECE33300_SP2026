`timescale 1ns / 1ps

`define SPEED_LED_COUNT 4

module pacman_led_output(
    input        clk,
    input        reset,
    input  [3:0] speed_sel,
    input        power_mode,
    input        game_won,
    input        game_over,
    input  [1:0] lives_remaining,
    output [7:0] leds,
    output       rgb_led_r,
    output       rgb_led_g,
    output       rgb_led_b
    );

    wire unused_clk   = clk;
    wire unused_reset = reset;

    genvar i;
    generate
        for (i = 0; i < `SPEED_LED_COUNT; i = i + 1) begin : speed_led_gen
            buf u_speed_led_buf(leds[i], speed_sel[i]);
        end
    endgenerate

    buf u_power_led (leds[4], power_mode);

    // LED5 is on when lives_remaining is 1 or 2.
    or  u_life1_led (leds[5], lives_remaining[0], lives_remaining[1]);

    // LED6 is on only when lives_remaining is 2.
    buf u_life2_led (leds[6], lives_remaining[1]);

    buf u_winner_led(leds[7], game_won);

    wire not_game_over;
    wire zero_wire;

    not u_not_game_over(not_game_over, game_over);
    buf u_rgb_red      (rgb_led_r, game_over);
    buf u_rgb_green    (rgb_led_g, not_game_over);

    assign zero_wire = 1'b0;
    buf u_rgb_blue     (rgb_led_b, zero_wire);

endmodule
