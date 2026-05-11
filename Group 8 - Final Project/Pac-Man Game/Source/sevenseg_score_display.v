`timescale 1ns / 1ps


module sevenseg_score_display(
    input        clk,
    input        reset,

    input  [3:0] thousands,
    input  [3:0] hundreds,
    input  [3:0] tens,
    input  [3:0] ones,

    output [6:0] seg,
    output [7:0] an,
    output       dp
);

    //---------------------------------------------
    // Decimal point
    //---------------------------------------------
    assign dp = 1'b1;

    //---------------------------------------------
    // Digit scanner
    //---------------------------------------------
    wire [2:0] sel;

    count_3bit_select u_count_3bit_select(
        .clk(clk),
        .sel(sel)
    );

    //---------------------------------------------
    // Anode decoder
    //---------------------------------------------
    decode_enb_leds u_decode_enb_leds(
        .sel(sel),
        .enb_leds(an)
    );

    //---------------------------------------------
    // 8-to-1 BCD digit mux
    //---------------------------------------------
    wire [3:0] selected_digit;

    mux_4in_8to1 u_mux_4in_8to1(
        .in0(ones),
        .in1(tens),
        .in2(hundreds),
        .in3(thousands),
        .in4(4'hF),
        .in5(4'hF),
        .in6(4'hF),
        .in7(4'hF),
        .sel(sel),
        .out(selected_digit)
    );

    //---------------------------------------------
    // Seven-segment decoder
    //---------------------------------------------
    wire [6:0] inv_leds_class;

    seven_seg_decoder u_seven_seg_decoder(
        .b_in(selected_digit),
        .inv_leds(inv_leds_class)
    );

    //---------------------------------------------
    // Decoder output
    //---------------------------------------------
    assign seg = {
        inv_leds_class[0], // CA -> seg[6]
        inv_leds_class[1], // CB -> seg[5]
        inv_leds_class[2], // CC -> seg[4]
        inv_leds_class[3], // CD -> seg[3]
        inv_leds_class[4], // CE -> seg[2]
        inv_leds_class[5], // CF -> seg[1]
        inv_leds_class[6]  // CG -> seg[0]
    };

    wire unused_reset = reset;

endmodule
