`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 05/04/2026 12:45:43 PM
// Design Name: Reaction Game
// Module Name: top_level_game
// Project Name: ECE 3300 Final
// Description: 
// Isaiah Okuma & Matthew Okuma
// ECE 3300 Final Project
//////////////////////////////////////////////////////////////////////////////////

`define SIMULATION
module top_level_game(
    input clk_100MHz,       
    input reset_btn,        
    input start_btn_pin,    
    input react_btn_pin,    
    input [8:0] sw,       
    output [8:0] led,     
    output [7:0] seg,     
    output [7:0] an,      
    output uart_txd_out,  
    output [3:0] vga_r, vga_g, vga_b,
    output vga_hs, vga_vs,
    
    output led16_r, led16_g, led16_b,
    output led17_r, led17_g, led17_b
);

    // --- 1. Internal Signals & Wires (Structural) ---
    wire clk_25MHz, start_db, react_db;
    wire [1:0] game_state;
    wire timer_en, fifo_wr, fifo_empty, uart_busy;
    wire [7:0] fifo_data_out;
    wire [15:0] val_to_show;
    wire [3:0] bcd3, bcd2, bcd1, bcd0;
    wire [15:0] decimal_val = {bcd3, bcd2, bcd1, bcd0};
    
    // --- 2. Reaction & High Score Logic ---
reg [15:0] reaction_timer;
reg [15:0] high_score = 16'h270F;
reg [16:0] ms_counter;

`ifdef SIMULATION
    wire ms_pulse = (ms_counter == 10);
`else
    wire ms_pulse = (ms_counter == 99999);
`endif

always @(posedge clk_100MHz) begin
    if (!reset_btn) begin
        reaction_timer <= 0;
        high_score <= 16'h270F; 
        ms_counter <= 0;
    end else begin
        if (ms_pulse) 
            ms_counter <= 0;
        else 
            ms_counter <= ms_counter + 1;

        // Timer and High Score logic
        if (game_state == 2'b00) begin
            reaction_timer <= 0;
        end else if (timer_en && ms_pulse) begin
            reaction_timer <= reaction_timer + 1;
        end

        // Update High Score at end of round 
        if (game_state == 2'b11 && reaction_timer > 0) begin
            if (reaction_timer < high_score) 
                high_score <= reaction_timer;
        end
    end
end
            

    // --- 3. I/O Logic (Dataflow) ---

    assign led = sw; 

    // RGB LED Color Logic: [Red, Green, Blue]
    // ST_DELAY (01) = Wait (Red LED); ST_ACTIVE (10) = React (Green LED)
    assign {led16_r, led16_g, led16_b} = (game_state == 2'b01) ? 3'b100 : 
                                        (game_state == 2'b10) ? 3'b010 : 3'b000;
    assign {led17_r, led17_g, led17_b} = {led16_r, led16_g, led16_b};

    // --- 4. Sub-Module Instantiations (Structural) ---

    // Choose between live score and high score for display
    score_selector display_mux (
        .live_timer(reaction_timer), .high_score(high_score),
        .sel(sw[8]), .final_display_val(val_to_show)
    );

    clk_wiz clk_gen
   (
    .clk_out1(clk_25MHz),    
    .resetn(reset_btn), 
    .clk_in1(clk_100MHz)
);

    // Clean up button signals
    debouncer start_unit (.clk(clk_100MHz), .btn_in(start_btn_pin), .btn_out(start_db));
    debouncer react_unit (.clk(clk_100MHz), .btn_in(react_btn_pin), .btn_out(react_db));

    // The Game Brain
    game_fsm brain (
        .clk(clk_100MHz), 
        .ms_pulse(ms_pulse),
        .reset(!reset_btn),
        .start_btn(start_db), 
        .react_btn(react_db),
        .rand_delay({sw[7:0], 8'hFF}),
        .state(game_state), 
        .timer_en(timer_en), 
        .fifo_wr_en(fifo_wr)
    );

    // Visuals for the monitor
    vga_controller visuals (
        .clk_25MHz(clk_25MHz), .game_state(game_state),
        .reaction_timer(decimal_val),
        .hsync(vga_hs), .vsync(vga_vs),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b)
    );

    // 7-Segment Display output
    display_controller seven_seg (
        .clk_100MHz(clk_100MHz), 
        .score(decimal_val),
        .an(an), 
        .seg(seg[6:0])
    );

// Converts binary to BCD
bin_to_bcd converter (
    .bin(val_to_show),
    .thousands(bcd3),
    .hundreds(bcd2),
    .tens(bcd1),
    .ones(bcd0)
);

    // Leaderboard Data Path
    score_fifo buffer (
        .clk(clk_100MHz), .wr_en(fifo_wr), .rd_en(!uart_busy && !fifo_empty),
        .din(reaction_timer[7:0]), .dout(fifo_data_out), .empty(fifo_empty)
    );

    uart_tx transmitter (
        .clk_100MHz(clk_100MHz), .data(fifo_data_out),
        .start(!fifo_empty && !uart_busy), .tx_pin(uart_txd_out), .busy(uart_busy)
    );

    assign seg[7] = 1'b1;

endmodule


