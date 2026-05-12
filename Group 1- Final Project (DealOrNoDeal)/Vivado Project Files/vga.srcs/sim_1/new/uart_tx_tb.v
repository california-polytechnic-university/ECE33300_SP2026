`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05/11/2026 10:44:59 PM
// Design Name:
// Module Name: uart_tx_tb
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


module uart_tx_tb;

    reg clk;
    reg rst;
    reg [7:0] data_in;
    reg send;

    wire tx;
    wire busy;

    uart_tx dut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .send(send),
        .tx(tx),
        .busy(busy)
    );

    // 100 MHz clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $monitor("%0t send=%b data=%h tx=%b busy=%b",
                 $time, send, data_in, tx, busy);

        rst     = 1;
        send    = 0;
        data_in = 8'h00;
        #50;

        rst = 0;
        #50;

        data_in = "A";
        send = 1;
        #10;
        send = 0;

        wait(busy == 0);
        #50;

        data_in = "5";
        send = 1;
        #10;
        send = 0;

        wait(busy == 0);
        #50;

        data_in = 8'h0A;
        send = 1;
        #10;
        send = 0;

        wait(busy == 0);
        #50;

        data_in = "C";
        send = 1;
        #10;
        send = 0;

        #20;
        data_in = "1";
        send = 1;
        #10;
        send = 0;

        wait(busy == 0);
        #100;

        rst = 1;
        #50;

        $stop;
    end

endmodule