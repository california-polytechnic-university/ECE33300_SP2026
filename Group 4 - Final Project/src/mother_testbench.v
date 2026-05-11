`timescale 1ns / 1ps

module tb_mother_top_vga_waveform;

    reg clk;
    reg rst;
    reg [3:0] move_dir;
    reg score_select;
    reg uart_rx;

    wire [3:0] vgaRed;
    wire [3:0] vgaGreen;
    wire [3:0] vgaBlue;
    wire hsync;
    wire vsync;
    wire [2:0] led;
    wire [6:0] seg;
    wire [7:0] an;
    wire dp;

    integer i;

    top_vga dut (
        .clk(clk),
        .rst(rst),
        .move_dir(move_dir),
        .score_select(score_select),
        .uart_rx(uart_rx),
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue),
        .hsync(hsync),
        .vsync(vsync),
        .led(led),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task send_uart_byte;
        input [7:0] data;
        integer bit_num;
        begin
            uart_rx = 0;
            #8680;

            for (bit_num = 0; bit_num < 8; bit_num = bit_num + 1) begin
                uart_rx = data[bit_num];
                #8680;
            end

            uart_rx = 1;
            #8680;
        end
    endtask

    initial begin
        rst = 1;
        move_dir = 4'b0000;
        score_select = 0;
        uart_rx = 1;

        #200;
        rst = 0;

        #200;

        force dut.broken = 24'h00000f;
        force dut.cumulative_score = 27'd36;

        score_select = 0;
        #1000;

        score_select = 1;
        #1000;

        release dut.broken;
        release dut.cumulative_score;

        #500;

        for (i = 0; i < 4; i = i + 1) begin
            move_dir = 4'b0001 << i;
            #1000;
            move_dir = 4'b0000;
            #500;
        end

        force dut.u_life_fsm.state = 2'd3;
        #1000;

        force dut.u_life_fsm.state = 2'd2;
        #1000;

        force dut.u_life_fsm.state = 2'd1;
        #1000;

        force dut.u_life_fsm.state = 2'd0;
        #1000;

        release dut.u_life_fsm.state;

        #500;
        
        send_uart_byte("w");
        #10000;

        send_uart_byte("w");
        #10000;

        send_uart_byte("s");
        #10000;

        send_uart_byte("s");
        #10000;

        move_dir = 4'b0000;
        score_select = 0;

        #100000;

        $stop;
    end
endmodule