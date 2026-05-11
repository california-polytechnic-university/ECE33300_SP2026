`include "defines.vh"
`timescale 1ns/1ps

module tb_top;

    reg        clk;
    reg        btnc, btnu, btnd, btnl, btnr;
    reg [15:0] sw;

    wire [15:0] led;
    wire [7:0]  an;
    wire [6:0]  seg;
    wire        dp;
    wire        vga_hs, vga_vs;
    wire [3:0]  vga_r, vga_g, vga_b;
    wire        uart_txd;

    top #(.SIM(1)) u_top (
        .clk(clk), .btnc(btnc),
        .btnu(btnu), .btnd(btnd),
        .btnl(btnl), .btnr(btnr),
        .sw(sw),
        .led(led), .an(an), .seg(seg), .dp(dp),
        .vga_hs(vga_hs), .vga_vs(vga_vs),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
        .uart_txd(uart_txd)
    );

    initial clk = 0;
    always #5 clk = ~clk;   // 100MHz

    // #1 delay after posedge ensures signal changes are seen cleanly
    // at the FOLLOWING posedge, avoiding delta-cycle race conditions

    task press_btn;
        input [4:0] which;
        begin
            @(posedge clk); #1;
            {btnu, btnd, btnl, btnr, btnc} = which;
            repeat(50) @(posedge clk);
            #1;
            {btnu, btnd, btnl, btnr, btnc} = 5'd0;
            repeat(10) @(posedge clk);
        end
    endtask

    task toggle_sw;
        input [3:0] idx;
        begin
            @(posedge clk); #1;
            sw[idx] = ~sw[idx];
        end
    endtask

    task wait_ticks;
        input [7:0] n;
        integer t;
        begin
            for(t = 0; t < n; t = t + 1)
                repeat(110) @(posedge clk);
        end
    endtask

    task check_state;
        input [1:0] expected;
        begin
            if(u_top.u_game.game_state !== expected)
                $display("FAIL: state=%0d expected=%0d at t=%0t",
                    u_top.u_game.game_state, expected, $time);
            else
                $display("PASS: state=%0d at t=%0t", expected, $time);
        end
    endtask

    task check_score;
        input [15:0] expected;
        begin
            if(u_top.u_game.score !== expected)
                $display("FAIL: score=%0d expected=%0d", u_top.u_game.score, expected);
            else
                $display("PASS: score=%0d", expected);
        end
    endtask

    integer j;

    initial begin
        j = 0;
        clk=0; btnc=0; btnu=0; btnd=0; btnl=0; btnr=0;
        sw = 16'd0;

        // reset -- #1 delay keeps assignment cleanly after the posedge
        @(posedge clk); #1; btnc=1;
        repeat(10) @(posedge clk); #1; btnc=0;
        repeat(10) @(posedge clk);
        check_state(0);   // IDLE

        // configure: 1 apple, speed level 1
        @(posedge clk); #1;
        sw[2]  = 1;
        sw[11] = 1;

        // start game
        toggle_sw(1);
        repeat(5) @(posedge clk);
        check_state(1);   // PLAYING

        // run several ticks moving right (default direction)
        wait_ticks(4);
        check_state(1);
        check_score(0);

        // test all 4 directions
        for(j = 0; j < 4; j = j + 1) begin
            case(j[1:0])
                2'd0: press_btn(5'b01000);   // down
                2'd1: press_btn(5'b00100);   // left
                2'd2: press_btn(5'b10000);   // up
                2'd3: press_btn(5'b00010);   // right
            endcase
            wait_ticks(2);
        end
        check_state(1);

        // pause via SW1
        toggle_sw(1);
        repeat(5) @(posedge clk);
        check_state(2);   // PAUSED

        // resume via SW1
        toggle_sw(1);
        repeat(5) @(posedge clk);
        check_state(1);   // PLAYING

        // enable deadly walls then steer into wall
        @(posedge clk); #1; sw[5] = 1;
        repeat(22) begin
            press_btn(5'b10000);   // up
            wait_ticks(1);
        end
        wait_ticks(2);
        check_state(3);   // GAME_OVER

        // return to IDLE
        toggle_sw(1);
        repeat(5) @(posedge clk);
        check_state(0);   // IDLE

        // restart and verify score reset
        toggle_sw(1);
        repeat(5) @(posedge clk);
        check_state(1);   // PLAYING
        check_score(0);

        $display("Simulation complete.");
        $finish;
    end

endmodule
