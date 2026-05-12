`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2026 04:21:15 PM
// Design Name: 
// Module Name: tb_uart_loopback
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

module tb_uart_loopback;

    reg clk;
    reg tx_dv;
    reg [7:0] tx_byte;

    wire tx_active;
    wire serial_line;
    wire tx_done;

    wire rx_dv;
    wire [7:0] rx_byte;

    //====================================================
    // DUTs
    //====================================================
    transmitter #(
        .FREQUENCY(`UART_DIV)
    ) dut_tx (
        .clk          (clk),
        .i_DV         (tx_dv),
        .i_Byte       (tx_byte),
        .o_Sig_Active (tx_active),
        .o_Serial_Data(serial_line),
        .o_Sig_Done   (tx_done)
    );

    receiver #(
        .FREQUENCY(`UART_DIV)
    ) dut_rx (
        .clk           (clk),
        .i_Serial_Data (serial_line),
        .o_DV          (rx_dv),
        .o_Byte        (rx_byte)
    );

    //====================================================
    // Clock generation
    // Use 50 MHz to match your pong_top UART clock domain
    //====================================================
    initial clk = 1'b0;
    always #10 clk = ~clk;   // 50 MHz

    //====================================================
    // Wait task
    //====================================================
    task automatic wait_clks;
        input integer num;
        integer i;
        begin
            for (i = 0; i < num; i = i + 1)
                @(posedge clk);
        end
    endtask

    //====================================================
    // Safer UART launch task
    //====================================================
    task automatic loopback_byte;
        input [7:0] value;
        begin
            // make sure previous transmission is idle
            while (tx_active)
                @(posedge clk);

            // setup data before sampling edge
            @(negedge clk);
            tx_byte = value;
            tx_dv   = 1'b1;

            // transmitter samples here
            @(posedge clk);

            // remove pulse cleanly
            @(negedge clk);
            tx_dv = 1'b0;

            // wait until receiver says a byte arrived
            wait (rx_dv == 1'b1);

            // small delay to stabilize display/check
            @(posedge clk);

            if (rx_byte !== value)
                $display("[FAIL] %0t loopback mismatch: expected=0x%0h received=0x%0h",
                         $time, value, rx_byte);
            else
                $display("[PASS] %0t loopback matched: 0x%0h",
                         $time, value);

            wait_clks(8);
        end
    endtask

    //====================================================
    // Test sequence
    //====================================================
    integer i;
    reg [7:0] seq [0:4];

    initial begin
        $dumpfile("tb_uart_loopback.vcd");
        $dumpvars(0, tb_uart_loopback);

        tx_dv   = 1'b0;
        tx_byte = 8'h00;

        seq[0] = `ASCII_A_UPPER;   // 41
        seq[1] = `ASCII_D_UPPER;   // 44
        seq[2] = `ASCII_S_UPPER;   // 53
        seq[3] = 8'h55;
        seq[4] = 8'hA3;

        $display("==============================================");
        $display("Starting tb_uart_loopback");
        $display("==============================================");

        wait_clks(10);

        for (i = 0; i < 5; i = i + 1)
            loopback_byte(seq[i]);

        $display("==============================================");
        $display("tb_uart_loopback complete");
        $display("==============================================");

        wait_clks(20);
        $finish;
    end

endmodule

