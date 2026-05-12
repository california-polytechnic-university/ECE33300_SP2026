`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2026 04:20:10 PM
// Design Name: 
// Module Name: tb_uart_cmd_fifo
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

module tb_uart_cmd_fifo;

    reg clk;
    reg reset;
    reg wr_en;
    reg rd_en;
    reg  [`FIFO_WIDTH-1:0] din;

    wire [`FIFO_WIDTH-1:0] dout;
    wire empty;
    wire full;
    wire [`FIFO_ADDR_W:0] count;

    uart_cmd_fifo #(
        .WIDTH (`FIFO_WIDTH),
        .DEPTH (`FIFO_DEPTH),
        .ADDR_W(`FIFO_ADDR_W)
    ) dut (
        .clk   (clk),
        .reset (reset),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .din   (din),
        .dout  (dout),
        .empty (empty),
        .full  (full),
        .count (count)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic wait_clks;
        input integer num;
        integer i;
        begin
            for (i = 0; i < num; i = i + 1)
                @(posedge clk);
        end
    endtask

    task automatic fifo_reset;
        begin
            reset = 1'b1;
            wr_en = 1'b0;
            rd_en = 1'b0;
            din   = 8'h00;
            wait_clks(4);
            reset = 1'b0;
            wait_clks(2);
        end
    endtask

    task automatic fifo_write;
        input [7:0] value;
        begin
            @(posedge clk);
            wr_en <= 1'b1;
            rd_en <= 1'b0;
            din   <= value;
            @(posedge clk);
            wr_en <= 1'b0;
            din   <= 8'h00;
        end
    endtask

    task automatic fifo_read;
        begin
            @(posedge clk);
            wr_en <= 1'b0;
            rd_en <= 1'b1;
            @(posedge clk);
            rd_en <= 1'b0;
        end
    endtask

    task automatic expect_count;
        input [`FIFO_ADDR_W:0] expected;
        input [255:0] msg;
        begin
            if (count !== expected)
                $display("[FAIL] %0t %0s | count actual=%0d expected=%0d", $time, msg, count, expected);
            else
                $display("[PASS] %0t %0s | count=%0d", $time, msg, count);
        end
    endtask

    task automatic expect_data;
        input [7:0] expected;
        input [255:0] msg;
        begin
            if (dout !== expected)
                $display("[FAIL] %0t %0s | dout actual=0x%0h expected=0x%0h", $time, msg, dout, expected);
            else
                $display("[PASS] %0t %0s | dout=0x%0h", $time, msg, dout);
        end
    endtask

    integer i;
    initial begin
        $dumpfile("tb_uart_cmd_fifo.vcd");
        $dumpvars(0, tb_uart_cmd_fifo);

        reset = 1'b0;
        wr_en = 1'b0;
        rd_en = 1'b0;
        din   = 8'h00;

        $display("==============================================");
        $display("Starting tb_uart_cmd_fifo");
        $display("==============================================");

        // Test 1: reset
        fifo_reset();
        if (!empty) $display("[FAIL] FIFO not empty after reset");
        else        $display("[PASS] FIFO empty after reset");
        if (full)   $display("[FAIL] FIFO full after reset");
        else        $display("[PASS] FIFO not full after reset");
        expect_count(0, "FIFO count zero after reset");

        // Test 2: basic write/read ordering
        fifo_write(8'h4C); // 'L'
        wait_clks(1);
        expect_count(1, "count is 1 after first write");
        expect_data(8'h4C, "front element is L");

        fifo_write(8'h52); // 'R'
        wait_clks(1);
        expect_count(2, "count is 2 after second write");
        expect_data(8'h4C, "front stays oldest element");

        fifo_read();
        wait_clks(1);
        expect_count(1, "count is 1 after one read");
        expect_data(8'h52, "front advances to second element");

        fifo_read();
        wait_clks(1);
        expect_count(0, "count returns to zero after second read");
        if (!empty) $display("[FAIL] FIFO not empty after draining");
        else        $display("[PASS] FIFO empty after draining");

        // Test 3: fill and drain using FOR loops
        for (i = 0; i < `FIFO_DEPTH; i = i + 1)
            fifo_write(i[7:0]);
        wait_clks(1);
        expect_count(`FIFO_DEPTH, "count reaches FIFO depth when full");
        if (!full) $display("[FAIL] FIFO full flag did not assert");
        else       $display("[PASS] FIFO full flag asserted");

        for (i = 0; i < `FIFO_DEPTH; i = i + 1)
            fifo_read();
        wait_clks(1);
        expect_count(0, "count returns to zero after full drain");
        if (!empty) $display("[FAIL] FIFO empty flag did not assert after full drain");
        else        $display("[PASS] FIFO empty flag asserted after full drain");

        $display("==============================================");
        $display("tb_uart_cmd_fifo complete");
        $display("==============================================");
        wait_clks(10);
        $finish;
    end
endmodule

