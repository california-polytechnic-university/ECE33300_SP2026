`timescale 1ns / 1ps

module vga_top #(
    parameter TEST_PATTERN = 0
)(
    input  wire        clk,
    input  wire        rst,
    // Game state inputs
    input  wire [15:0] available_cases,
    input  wire [3:0]  current_selected_case,
    input  wire [3:0]  preview_case,
    input  wire        valid_selection,
    input  wire        invalid_selection,
    input  wire [31:0] banker_offer,
    input  wire        offer_valid,
    input  wire [31:0] opened_case_value,
    input  wire [31:0] remaining_total,
    input  wire [31:0] remaining_average,
    input  wire [3:0]  player_case,
    input  wire        player_case_locked,
    input  wire [3:0]  game_state,
    // VGA outputs
    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b
);

    // ?? Pixel clock - divide 100 MHz by 2 to get 50 MHz ??????????????????????
    wire pxl_clk;
        wire pll_locked;
    
        clk_wiz_0 pll_inst (
            .clk_in1  (clk),
            .clk_out1 (pxl_clk),
            .locked   (pll_locked)
        );
    
        wire int_rst = rst | ~pll_locked;

    // ?? Derive case_opened ????????????????????????????????????????????????????
    // Only mark a case as opened if:
    // - player has locked their case
    // - it is not the player's own case
    wire [15:0] case_opened = player_case_locked ?
                              (~available_cases & ~(16'h0001 << player_case)) :
                              16'h0000;

    // ?? Derive case_preview ???????????????????????????????????????????????????
    wire [15:0] case_preview = (16'h0001 << preview_case);

    // ?? VGA pixel position ????????????????????????????????????????????????????
    wire [11:0] hpos, vpos;
    wire        active;
    wire        vga_hs_live, vga_vs_live;
    wire [3:0]  vga_r_live, vga_g_live, vga_b_live;
    wire [3:0]  pixel_r, pixel_g, pixel_b;

    screen_renderer renderer_inst (
        .pix_clk          (pxl_clk),
        .hpos             (hpos),
        .vpos             (vpos),
        .active           (active),
        .case_opened      (case_opened),
        .case_preview     (case_preview),
        .valid_selection  (valid_selection),
        .invalid_selection(invalid_selection),
        .banker_offer     (banker_offer),
        .offer_valid      (offer_valid),
        .opened_case_value(opened_case_value),
        .remaining_total  (remaining_total),
        .remaining_average(remaining_average),
        .player_case      (player_case),
        .player_case_locked(player_case_locked),
        .game_state       (game_state),
        .pixel_r          (pixel_r),
        .pixel_g          (pixel_g),
        .pixel_b          (pixel_b)
    );

    Vga vga_inst (
        .CLK_I       (pxl_clk),
        .VGA_HS_O    (vga_hs_live),
        .VGA_VS_O    (vga_vs_live),
        .VGA_RED_O   (vga_r_live),
        .VGA_GREEN_O (vga_g_live),
        .VGA_BLUE_O  (vga_b_live),
        .HPOS_O      (hpos),
        .VPOS_O      (vpos),
        .ACTIVE_O    (active),
        .PIXEL_R_I   (pixel_r),
        .PIXEL_G_I   (pixel_g),
        .PIXEL_B_I   (pixel_b)
    );

    // ?? Test pattern ??????????????????????????????????????????????????????????


    // ?? Output mux ????????????????????????????????????????????????????????????
    assign vga_hsync = vga_hs_live;

    assign vga_vsync = vga_vs_live;

    assign vga_r     = vga_r_live;

    assign vga_g     = vga_g_live;

    assign vga_b     = vga_b_live;

endmodule