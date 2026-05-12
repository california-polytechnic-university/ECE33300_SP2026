`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05/09/2026 06:18:06 PM
// Design Name:
// Module Name: uart
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module top_tb;

    reg clk;
    reg rst;

    reg [15:0] sw;
    reg        case_confirm;

    reg        deal_button;
    reg        no_deal_button;

    wire [15:0] LED;
    wire [6:0]  seg;
    wire [7:0]  an;
    wire        dp;

    wire        uart_tx_pin;
    wire        vga_hsync;
    wire        vga_vsync;
    wire [3:0]  vga_r;
    wire [3:0]  vga_g;
    wire [3:0]  vga_b;

    top dut (
        .clk(clk),
        .rst(rst),

        .sw(sw),
        .case_confirm(case_confirm),

        .deal_button(deal_button),
        .no_deal_button(no_deal_button),

        .LED(LED),
        .seg(seg),
        .an(an),
        .dp(dp),

        .uart_tx_pin(uart_tx_pin),

        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // 100 MHz clock
    end

    integer k;

    initial begin
        $monitor("%0t state=%d sw=%h confirm=%b selected=%h player=%h opened=%d valid=%b invalid=%b offer=%d deal=%b game_over=%b LED=%h",
                 $time,
                 dut.game_state,
                 sw[3:0],
                 case_confirm,
                 dut.current_selected_case,
                 dut.player_case,
                 dut.opened_case_count,
                 dut.valid_selection,
                 dut.invalid_selection,
                 dut.banker_offer,
                 dut.deal_taken,
                 dut.game_over,
                 LED);

        rst            = 1'b1;
        sw             = 16'h0000;
        case_confirm   = 1'b0;
        deal_button    = 1'b0;
        no_deal_button = 1'b0;
        #50;

        rst = 1'b0;
        #50;

        // Choose player case: case 3
        sw = 16'h0003;
        #40;
        case_confirm = 1'b1;
        #20;
        case_confirm = 1'b0;
        #100;

        // Open case 5
        sw = 16'h0005;
        #40;
        case_confirm = 1'b1;
        #20;
        case_confirm = 1'b0;
        #100;

        // Open case 8
        sw = 16'h0008;
        #40;
        case_confirm = 1'b1;
        #20;
        case_confirm = 1'b0;
        #100;

        // Try opening case 5 again, should become invalid
        sw = 16'h0005;
        #40;
        case_confirm = 1'b1;
        #20;
        case_confirm = 1'b0;
        #100;

        // Open a few more cases
        for (k = 0; k < 4; k = k + 1) begin
            sw = k;
            #40;
            case_confirm = 1'b1;
            #20;
            case_confirm = 1'b0;
            #100;
        end

        // Simulate no deal
        no_deal_button = 1'b1;
        #20;
        no_deal_button = 1'b0;
        #100;

        // Open more cases
        sw = 16'h000A;
        #40;
        case_confirm = 1'b1;
        #20;
        case_confirm = 1'b0;
        #100;

        sw = 16'h000F;
        #40;
        case_confirm = 1'b1;
        #20;
        case_confirm = 1'b0;
        #100;

        // Simulate deal
        deal_button = 1'b1;
        #20;
        deal_button = 1'b0;
        #100;

        // Reset game
        rst = 1'b1;
        #50;
        rst = 1'b0;
        #50;

        // Pick another player case after reset
        sw = 16'h0007;
        #40;
        case_confirm = 1'b1;
        #20;
        case_confirm = 1'b0;
        #100;

        $stop;
    end

endmodule
