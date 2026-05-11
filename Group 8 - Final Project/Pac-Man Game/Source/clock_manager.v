`timescale 1ns / 1ps

module clock_manager(clk_100mhz, clk_50mhz, clk_100mhz_phase,
                     clk_25mhz, clk_6hz, clk_24hz,
                     clk_in, reset);

    output clk_100mhz;
    output clk_50mhz;
    output [1:0] clk_100mhz_phase;
    output clk_25mhz;
    output clk_6hz;
    output clk_24hz;

    input  clk_in;   // 100 MHz board clock from Nexys A7
    input  reset;

    wire clk_100mhz_mmcm;
    wire clk_50mhz_mmcm;
    wire clk_25mhz_mmcm;
    wire clkfb;
    wire locked;


    MMCME2_BASE #(
        .CLKIN1_PERIOD    (10.0),  // 100 MHz input
        .CLKFBOUT_MULT_F  (10.0), // VCO = 1000 MHz
        .DIVCLK_DIVIDE    (1),
        .CLKOUT0_DIVIDE_F (10.0), // 100 MHz
        .CLKOUT1_DIVIDE   (20),   //  50 MHz
        .CLKOUT2_DIVIDE   (40),   //  25 MHz
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKFBOUT_PHASE   (0.0),
        .STARTUP_WAIT     ("FALSE"),
        .REF_JITTER1      (0.01)
    ) mmcm_inst (
        .CLKIN1   (clk_in),
        .CLKFBIN  (clkfb),
        .CLKFBOUT (clkfb),
        .CLKOUT0  (clk_100mhz_mmcm),
        .CLKOUT1  (clk_50mhz_mmcm),
        .CLKOUT2  (clk_25mhz_mmcm),
        .CLKOUT3  (),
        .CLKOUT3B (),
        .CLKOUT4  (),
        .CLKOUT5  (),
        .CLKOUT6  (),
        .CLKFBOUTB(),
        .CLKOUT0B (),
        .CLKOUT1B (),
        .CLKOUT2B (),
        .LOCKED   (locked),
        .PWRDWN   (1'b0),
        .RST      (reset)
    );

    BUFG bufg_100 (.I(clk_100mhz_mmcm), .O(clk_100mhz));
    BUFG bufg_50  (.I(clk_50mhz_mmcm),  .O(clk_50mhz));
    BUFG bufg_25  (.I(clk_25mhz_mmcm),  .O(clk_25mhz));

    reg [1:0] clk_100mhz_phase;
    always @(posedge clk_100mhz) begin
        clk_100mhz_phase <= clk_100mhz_phase + 1;
    end

    clock_divider slow_clk(clk_6hz, clk_24hz, clk_50mhz);

endmodule
