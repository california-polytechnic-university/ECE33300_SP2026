`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2026 04:17:55 PM
// Design Name: 
// Module Name: tb_master_pong
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

`include "project_defs.vh"


module tb_master_pong;

    `include "tb_master_helpers.vh"

    //====================================================
    // DUT
    //====================================================
    pong_top dut (
        .clk      (clk),
        .reset_clk(reset_clk),
        .reset    (reset),
        .btn      (btn),
        .btn_pause(btn_pause),
        .uart_rx  (uart_rx),
        .uart_tx  (uart_tx),
        .hsync    (hsync),
        .vsync    (vsync),
        .LED      (LED),
        .rgb      (rgb),
        .an       (an),
        .seg      (seg),
        .light    (light),
        .lights   (lights),
        .LED16_R  (LED16_R),
        .LED16_G  (LED16_G),
        .LED16_B  (LED16_B),
        .LED17_R  (LED17_R),
        .LED17_G  (LED17_G),
        .LED17_B  (LED17_B)
    );

    //====================================================
    // 100 MHz input clock
    //====================================================
    initial clk = 1'b0;
    always #5 clk = ~clk;

    integer k;
    reg [7:0] cmd_seq [0:2];

    initial begin
        $dumpfile("tb_master_pong.vcd");
        $dumpvars(0, tb_master_pong);

        cmd_seq[0] = `ASCII_A_UPPER;
        cmd_seq[1] = `ASCII_D_UPPER;
        cmd_seq[2] = `ASCII_S_UPPER;

        reset_clk = 1'b0;
        reset     = 1'b0;
        btn       = 2'b00;
        btn_pause = 1'b0;
        uart_rx   = 1'b1;

        $display("==============================================");
        $display("Starting tb_master_pong");
        $display("==============================================");

        //-------------------------------------------------
        // TEST 1: Initial global reset / startup state
        //-------------------------------------------------
        apply_reset();

        expect_equal_1bit(dut.paused, 1'b0, "paused clears after startup reset");
        expect_fifo_empty_flag(dut.fifo_empty, 1'b1, "FIFO empty after startup reset");
        expect_fifo_count_value(dut.fifo_count, 5'd0, "FIFO count zero after startup reset");
        expect_equal_32bit(dut.score_bcd, 32'h0000_0000, "score zero after startup reset");
        expect_equal_1bit(dut.uart_left, 1'b0, "uart_left clears after startup reset");
        expect_equal_1bit(dut.uart_right, 1'b0, "uart_right clears after startup reset");

        //-------------------------------------------------
        // TEST 2: UART commands update movement state
        //-------------------------------------------------
        send_left_cmd();
        wait_clks(`UART_DIV*12);
        expect_equal_1bit(dut.uart_left,  1'b1, "uart_left asserted after A command");
        expect_equal_1bit(dut.uart_right, 1'b0, "uart_right cleared after A command");

        send_right_cmd();
        wait_clks(`UART_DIV*12);
        expect_equal_1bit(dut.uart_left,  1'b0, "uart_left cleared after D command");
        expect_equal_1bit(dut.uart_right, 1'b1, "uart_right asserted after D command");

        send_stop_cmd();
        wait_clks(`UART_DIV*12);
        expect_equal_1bit(dut.uart_left,  1'b0, "uart_left cleared after S command");
        expect_equal_1bit(dut.uart_right, 1'b0, "uart_right cleared after S command");
        expect_fifo_empty_flag(dut.fifo_empty, 1'b1, "FIFO drains after command processing");

        //-------------------------------------------------
        // TEST 3: FOR-loop UART burst
        //-------------------------------------------------
        for (k = 0; k < 3; k = k + 1) begin
            send_uart_byte(cmd_seq[k]);
            wait_clks(`UART_DIV*6);
        end
        wait_clks(`UART_DIV*12);
        expect_fifo_empty_flag(dut.fifo_empty, 1'b1, "FIFO drains after burst sequence");

        //-------------------------------------------------
        // TEST 4: Pause button toggle
        //-------------------------------------------------
        pulse_pause_button();
        expect_equal_1bit(dut.paused, 1'b1, "pause toggles ON");

        send_left_cmd();
        wait_clks(`UART_DIV*6);
        expect_fifo_empty_flag(dut.fifo_empty, 1'b0, "FIFO queues command while paused");
        expect_fifo_count_value(dut.fifo_count, 5'd1, "FIFO count increments while paused");

        pulse_pause_button();
        expect_equal_1bit(dut.paused, 1'b0, "pause toggles OFF");
        wait_clks(`UART_DIV*8);
        expect_fifo_empty_flag(dut.fifo_empty, 1'b1, "FIFO drains after unpause");

        //-------------------------------------------------
        // TEST 5: Physical left/right buttons
        //-------------------------------------------------
        press_btn_left(20);
        press_btn_right(20);
        $display("[INFO] %0t Physical button tasks executed.", $time);

        //-------------------------------------------------
        // TEST 6: Score increments by +5 on paddle hit
        //-------------------------------------------------
        expect_equal_32bit(dut.score_bcd, 32'h0000_0000, "score starts at zero before hit injection");

        inject_paddle_hit();
        wait_clks(8);
        expect_equal_32bit(dut.score_bcd, 32'h0000_0005, "score increments to 5 after first hit");
        expect_equal_1bit(LED16_G, 1'b1, "RGB LED green on hit");
        expect_equal_1bit(LED16_R, 1'b0, "RGB LED red off on hit");

        inject_paddle_hit();
        wait_clks(8);
        expect_equal_32bit(dut.score_bcd, 32'h0000_0010, "score increments to 10 after second hit");

        //-------------------------------------------------
        // TEST 7: Miss event resets score
        //-------------------------------------------------
        inject_miss();
        wait_clks(8);
        expect_equal_32bit(dut.score_bcd, 32'h0000_0000, "score resets to zero on miss");
        expect_equal_1bit(LED16_R, 1'b1, "RGB LED red on miss");
        expect_equal_1bit(LED16_G, 1'b0, "RGB LED green off on miss");

        //-------------------------------------------------
        // TEST 8: Runtime GLOBAL reset
        // This should clear system state.
        //-------------------------------------------------
        send_right_cmd();
        wait_clks(`UART_DIV*12);
        pulse_pause_button();
        wait_clks(8);

        // create non-zero score
        inject_paddle_hit();
        wait_clks(8);
        expect_equal_32bit(dut.score_bcd, 32'h0000_0005, "score non-zero before runtime reset");

        pulse_global_reset();

        expect_equal_1bit(dut.paused, 1'b0, "paused clears after runtime global reset");
        expect_fifo_empty_flag(dut.fifo_empty, 1'b1, "FIFO empty after runtime global reset");
        expect_fifo_count_value(dut.fifo_count, 5'd0, "FIFO count zero after runtime global reset");
        expect_equal_32bit(dut.score_bcd, 32'h0000_0000, "score zero after runtime global reset");
        expect_equal_1bit(dut.uart_left, 1'b0, "uart_left clears after runtime global reset");
        expect_equal_1bit(dut.uart_right, 1'b0, "uart_right clears after runtime global reset");

        //-------------------------------------------------
        // TEST 9: Runtime reset_clk pulse
        // This resets the clock divider only.
        // We verify the design still works afterward.
        //-------------------------------------------------
        send_left_cmd();
        wait_clks(`UART_DIV*12);
        expect_equal_1bit(dut.uart_left, 1'b1, "uart_left works before reset_clk pulse");

        pulse_reset_clk_only();

        // After clock-divider reset, the system should continue functioning.
        send_right_cmd();
        wait_clks(`UART_DIV*16);
        expect_equal_1bit(dut.uart_left,  1'b0, "uart_left clears after post-reset_clk right command");
        expect_equal_1bit(dut.uart_right, 1'b1, "uart_right still works after reset_clk pulse");

        //-------------------------------------------------
        // TEST 10: Final stop command after all resets
        //-------------------------------------------------
        send_stop_cmd();
        wait_clks(`UART_DIV*12);
        expect_equal_1bit(dut.uart_left,  1'b0, "uart_left cleared at end");
        expect_equal_1bit(dut.uart_right, 1'b0, "uart_right cleared at end");

        $display("==============================================");
        $display("tb_master_pong complete");
        $display("==============================================");

        wait_clks(50);
        $finish;
    end

endmodule
