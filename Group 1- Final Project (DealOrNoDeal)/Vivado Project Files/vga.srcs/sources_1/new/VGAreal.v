`timescale 1ns / 1ps

module Vga (
    input  wire        CLK_I,
    output wire        VGA_HS_O,
    output wire        VGA_VS_O,
    output wire [3:0]  VGA_RED_O,
    output wire [3:0]  VGA_GREEN_O,
    output wire [3:0]  VGA_BLUE_O,
    output wire [11:0] HPOS_O,
    output wire [11:0] VPOS_O,
    output wire        ACTIVE_O,
    input  wire [3:0]  PIXEL_R_I,
    input  wire [3:0]  PIXEL_G_I,
    input  wire [3:0]  PIXEL_B_I
);

    localparam FRAME_WIDTH  = 1280;
    localparam FRAME_HEIGHT = 1024;
    localparam H_FP         = 48;
    localparam H_PW         = 112;
    localparam H_MAX        = 1688;
    localparam V_FP         = 1;
    localparam V_PW         = 3;
    localparam V_MAX        = 1066;
    localparam H_POL        = 1'b1;
    localparam V_POL        = 1'b1;

    wire pxl_clk;
    assign pxl_clk = CLK_I;

    reg [11:0] h_cntr_reg     = 12'h000;
    reg [11:0] v_cntr_reg     = 12'h000;
    reg [11:0] h_cntr_reg_dly = 12'h000;
    reg [11:0] v_cntr_reg_dly = 12'h000;

    reg h_sync_reg     = ~H_POL;
    reg v_sync_reg     = ~V_POL;
    reg h_sync_reg_dly = ~H_POL;
    reg v_sync_reg_dly = ~V_POL;

    wire active = (h_cntr_reg_dly < FRAME_WIDTH) &&
                  (v_cntr_reg_dly < FRAME_HEIGHT);

    reg [3:0] vga_red_reg   = 0;
    reg [3:0] vga_green_reg = 0;
    reg [3:0] vga_blue_reg  = 0;

    // ?? Horizontal counter ????????????????????????????????????????????????????
    always @(posedge pxl_clk) begin
        if (h_cntr_reg == H_MAX - 1)
            h_cntr_reg <= 12'h000;
        else
            h_cntr_reg <= h_cntr_reg + 1;
    end

    // ?? Vertical counter ??????????????????????????????????????????????????????
    always @(posedge pxl_clk) begin
        if (h_cntr_reg == H_MAX - 1 && v_cntr_reg == V_MAX - 1)
            v_cntr_reg <= 12'h000;
        else if (h_cntr_reg == H_MAX - 1)
            v_cntr_reg <= v_cntr_reg + 1;
    end

    // ?? Horizontal sync ???????????????????????????????????????????????????????
    always @(posedge pxl_clk) begin
        if (h_cntr_reg >= (FRAME_WIDTH + H_FP) &&
            h_cntr_reg <  (FRAME_WIDTH + H_FP + H_PW))
            h_sync_reg <= H_POL;
        else
            h_sync_reg <= ~H_POL;
    end

    // ?? Vertical sync ?????????????????????????????????????????????????????????
    always @(posedge pxl_clk) begin
        if (v_cntr_reg >= (FRAME_HEIGHT + V_FP) &&
            v_cntr_reg <  (FRAME_HEIGHT + V_FP + V_PW))
            v_sync_reg <= V_POL;
        else
            v_sync_reg <= ~V_POL;
    end

    // ?? Delay counters ????????????????????????????????????????????????????????
    always @(posedge pxl_clk) begin
        h_cntr_reg_dly <= h_cntr_reg;
        v_cntr_reg_dly <= v_cntr_reg;
    end

    assign HPOS_O   = h_cntr_reg_dly;
    assign VPOS_O   = v_cntr_reg_dly;
    assign ACTIVE_O = active;

    // ?? Register outputs ??????????????????????????????????????????????????????
    always @(posedge pxl_clk) begin
        h_sync_reg_dly <= h_sync_reg;
        v_sync_reg_dly <= v_sync_reg;
        vga_red_reg    <= {4{active}} & PIXEL_R_I;
        vga_green_reg  <= {4{active}} & PIXEL_G_I;
        vga_blue_reg   <= {4{active}} & PIXEL_B_I;
    end

    assign VGA_HS_O    = h_sync_reg_dly;
    assign VGA_VS_O    = v_sync_reg_dly;
    assign VGA_RED_O   = vga_red_reg;
    assign VGA_GREEN_O = vga_green_reg;
    assign VGA_BLUE_O  = vga_blue_reg;

endmodule