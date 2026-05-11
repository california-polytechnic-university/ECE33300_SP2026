`timescale 1ns / 1ps

module vga_timing_1024_600(
    input  wire        clk,
    input  wire        rst,
    output wire        pixpulse,
    output reg  [10:0] hcount,
    output reg  [10:0] vcount,
    output reg         hsync,
    output reg         vsync,
    output reg         hblank,
    output reg         vblank
);

    localparam H_DISPLAY = 11'd1024;
    localparam H_FP      = 11'd24;
    localparam H_SYNC    = 11'd136;
    localparam H_BP      = 11'd160;
    localparam H_TOTAL   = H_DISPLAY + H_FP + H_SYNC + H_BP; // 1344

    localparam V_DISPLAY = 11'd600;
    localparam V_FP      = 11'd3;
    localparam V_SYNC    = 11'd6;
    localparam V_BP      = 11'd16;
    localparam V_TOTAL   = V_DISPLAY + V_FP + V_SYNC + V_BP; // 625

    // Sync pulses
    assign pixpulse = 1'b1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hcount <= 11'd0;
            vcount <= 11'd0;
        end else if (pixpulse) begin
            if (hcount == H_TOTAL - 1'b1) begin
                hcount <= 11'd0;

                if (vcount == V_TOTAL - 1'b1)
                    vcount <= 11'd0;
                else
                    vcount <= vcount + 11'd1;
            end else begin
                hcount <= hcount + 11'd1;
            end
        end
    end

    always @(*) begin
        hblank = (hcount >= H_DISPLAY);
        vblank = (vcount >= V_DISPLAY);
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else if (pixpulse) begin
            hsync <= ~((hcount >= (H_DISPLAY + H_FP)) &&
                       (hcount <  (H_DISPLAY + H_FP + H_SYNC)));

            vsync <= ~((vcount >= (V_DISPLAY + V_FP)) &&
                       (vcount <  (V_DISPLAY + V_FP + V_SYNC)));
        end
    end

endmodule
