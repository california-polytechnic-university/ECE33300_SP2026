`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/11/2026 10:08:05 AM
// Design Name: Reaction Game
// Module Name: tb_top_level
// Project Name: ECE 3300 Final
// Description: 
// Isaiah Okuma & Matthew Okuma
// ECE 3300 Final Project
//////////////////////////////////////////////////////////////////////////////////

`define SIMULATION

module tb_top_level();
    // --- 1. SIGNAL DECLARATIONS ---
    reg clk_100MHz = 0;
    reg reset_btn = 1;       
    reg start_btn_pin = 0;
    reg react_btn_pin = 0;
    reg [15:0] sw = 16'h0001; 

    wire [15:0] led;
    wire [7:0] seg, an;
    wire uart_txd_out;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hs, vga_vs;
    wire led16_r, led16_g, led16_b;
    wire led17_r, led17_g, led17_b;

    // --- 2. UNIT UNDER TEST (UUT) ---
    top_level_game uut (
        .clk_100MHz(clk_100MHz),
        .reset_btn(reset_btn),
        .start_btn_pin(start_btn_pin),
        .react_btn_pin(react_btn_pin),
        .sw(sw),
        .led(led),
        .seg(seg),
        .an(an),
        .uart_txd_out(uart_txd_out),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
        .vga_hs(vga_hs), .vga_vs(vga_vs),
        .led16_r(led16_r), .led16_g(led16_g), .led16_b(led16_b),
        .led17_r(led17_r), .led17_g(led17_g), .led17_b(led17_b)
    );

    // --- 3. CLOCK GENERATION ---
    always #5 clk_100MHz = ~clk_100MHz;

    // --- 4. VERIFICATION TASKS (Rubric Requirement) ---

    // Task: Simulate the Red Reset Button on the board
    task trigger_reset();
        begin
            $display("[TIME %t] Action: Pressing RESET", $time);
            reset_btn = 0; #100; 
            reset_btn = 1; #100; 
        end
    endtask

    // Task: Play a full game round
    task play_round();
        begin
            $display("[TIME %t] Action: Pressing START", $time);
            start_btn_pin = 1; #200; 
            start_btn_pin = 0;       

            // Wait until the hardware logic turns the LED Green
            wait(led16_g == 1); 
            $display("[TIME %t] SIGNAL DETECTED: Green LED is ON!", $time);
            
            #500; 

            $display("[TIME %t] Action: Pressing REACT", $time);
            react_btn_pin = 1; #200; 
            react_btn_pin = 0;
        end
    endtask

    // Task: The UART Monitor 
    task monitor_uart;
        integer i;
        reg [7:0] captured_data;
        begin
            // 1. Wait for Start Bit 
            @(negedge uart_txd_out); 
            
            // 2. Jump to the middle of the first data bit
            #156240; 
            
            // 3. Loop through 8 bits to reconstruct the score byte
            for (i = 0; i < 8; i = i + 1) begin
                captured_data[i] = uart_txd_out; 
                #104160; 
            end
            
            $display("---------------------------------------");
            $display("[SIM RESULT] UART captured score: %d", captured_data);
            $display("---------------------------------------");
        end
    endtask

    // --- 5. MAIN SIMULATION FLOW ---
    
    initial begin
        monitor_uart(); 
    end

    initial begin
        $display("--- Starting Master Testbench ---");
        
        trigger_reset(); 
        
        #1000;
        
        play_round(); 

        #200000; 

        $display("[TIME %t] Simulation Finished.", $time);
        $finish; 
    end

endmodule

