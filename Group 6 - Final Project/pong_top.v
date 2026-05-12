`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/08/2026 07:16:30 PM
// Design Name: 
// Module Name: pong_top
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

module pong_top
(
    input   clk,
    input   reset_clk,
    input   reset,
    input   [1:0] btn,
    input   btn_pause,
    input   uart_rx,
    output  uart_tx,
    output  hsync,
    output  vsync,
    output  [6:0] LED,
    output  [11:0] rgb,
    output  [7:0] an,
    output  [7:0] seg,
    output  light,
    output  lights,
    output  LED16_R,
    output  LED16_G,
    output  LED16_B,
    output  LED17_R,
    output  LED17_G,
    output  LED17_B
);

   wire [9:0] pixel_x, pixel_y;
   wire video_on, pixel_tick;
   reg  [11:0] rgb_reg;
   wire [11:0] rgb_next;
   wire clk_50mhz;

   wire       rx_dv;
   wire [7:0] rx_byte;

   reg        tx_dv;
   reg [7:0]  tx_byte;
   wire       tx_active;
   wire       tx_done;

   reg        echo_pending;
   reg [7:0]  echo_pending_byte;

   reg uart_left;
   reg uart_right;
   wire [1:0] ctrl_btn;

   wire        paddle_hit_pulse;
   wire        miss_pulse;
   reg [31:0]  score_bcd;

   reg led_red_reg;
   reg led_green_reg;
   reg led_blue_reg;

   reg        fifo_wr_en;
   reg        fifo_rd_en;
   reg [7:0]  fifo_din;
   wire [7:0] fifo_dout;
   wire       fifo_empty;
   wire       fifo_full;
   wire [4:0] fifo_count;

   // Pause button synchronizer / edge detect
   reg pause_sync_0, pause_sync_1;
   reg pause_prev;
   reg paused;

   assign light  = reset;
   assign lights = reset_clk;

   //====================================================
   // BCD add 5 function
   //====================================================
   function [31:0] bcd_add_5;
      input [31:0] bcd_in;
      reg [3:0] d0, d1, d2, d3, d4, d5, d6, d7;
      begin
         d0 = bcd_in[3:0];
         d1 = bcd_in[7:4];
         d2 = bcd_in[11:8];
         d3 = bcd_in[15:12];
         d4 = bcd_in[19:16];
         d5 = bcd_in[23:20];
         d6 = bcd_in[27:24];
         d7 = bcd_in[31:28];

         d0 = d0 + `SCORE_INC;

         if (d0 >= 10) begin d0 = d0 - 10; d1 = d1 + 1; end
         if (d1 >= 10) begin d1 = d1 - 10; d2 = d2 + 1; end
         if (d2 >= 10) begin d2 = d2 - 10; d3 = d3 + 1; end
         if (d3 >= 10) begin d3 = d3 - 10; d4 = d4 + 1; end
         if (d4 >= 10) begin d4 = d4 - 10; d5 = d5 + 1; end
         if (d5 >= 10) begin d5 = d5 - 10; d6 = d6 + 1; end
         if (d6 >= 10) begin d6 = d6 - 10; d7 = d7 + 1; end
         if (d7 >= 10) begin d7 = d7 - 10; end

         bcd_add_5 = {d7,d6,d5,d4,d3,d2,d1,d0};
      end
   endfunction

   //====================================================
   // Clock generator
   //====================================================
   clk_50MHz_generator clk_gen (
       .clk(clk),
       .reset_clk(reset_clk),
       .clk_50mhz(clk_50mhz)
   );

   //====================================================
   // UART RX / TX
   //====================================================
   receiver #(
       .FREQUENCY(`UART_DIV)
   ) uart_receiver (
       .clk(clk_50mhz),
       .i_Serial_Data(uart_rx),
       .o_DV(rx_dv),
       .o_Byte(rx_byte)
   );

   transmitter #(
       .FREQUENCY(`UART_DIV)
   ) uart_transmitter (
       .clk(clk_50mhz),
       .i_DV(tx_dv),
       .i_Byte(tx_byte),
       .o_Sig_Active(tx_active),
       .o_Serial_Data(uart_tx),
       .o_Sig_Done(tx_done)
   );

   //====================================================
   // UART command FIFO
   //====================================================
   uart_cmd_fifo #(
      .WIDTH(8),
      .DEPTH(16),
      .ADDR_W(4)
   ) cmd_fifo (
      .clk   (clk_50mhz),
      .reset (reset),
      .wr_en (fifo_wr_en),
      .rd_en (fifo_rd_en),
      .din   (fifo_din),
      .dout  (fifo_dout),
      .empty (fifo_empty),
      .full  (fifo_full),
      .count (fifo_count)
   );

   //====================================================
   // Pause button synchronizer + toggle
   //====================================================
   always @(posedge clk_50mhz or posedge reset) begin
      if (reset) begin
         pause_sync_0 <= 1'b0;
         pause_sync_1 <= 1'b0;
         pause_prev   <= 1'b0;
         paused       <= 1'b0;
      end
      else begin
         pause_sync_0 <= btn_pause;
         pause_sync_1 <= pause_sync_0;
         pause_prev   <= pause_sync_1;

         if (pause_sync_1 && !pause_prev)
            paused <= ~paused;
      end
   end

   //====================================================
   // UART decode -> FIFO write
   // FIFO read -> movement latch
   //====================================================
   always @(posedge clk_50mhz or posedge reset) begin
      if (reset) begin
         uart_left         <= 1'b0;
         uart_right        <= 1'b0;
         tx_dv             <= 1'b0;
         tx_byte           <= 8'h00;
         echo_pending      <= 1'b0;
         echo_pending_byte <= 8'h00;

         fifo_wr_en        <= 1'b0;
         fifo_rd_en        <= 1'b0;
         fifo_din          <= 8'h00;
      end
      else begin
         tx_dv      <= 1'b0;
         fifo_wr_en <= 1'b0;
         fifo_rd_en <= 1'b0;

         //-------------------------------------------------
         // Decode UART bytes and enqueue semantic command
         //-------------------------------------------------
         if (rx_dv) begin
            case (rx_byte)
               `ASCII_A_UPPER, `ASCII_A_LOWER: begin
                  if (!fifo_full) begin
                     fifo_din   <= `CMD_LEFT;
                     fifo_wr_en <= 1'b1;
                  end

                  if (!tx_active) begin
                     tx_byte <= `CMD_LEFT;
                     tx_dv   <= 1'b1;
                  end
                  else begin
                     echo_pending      <= 1'b1;
                     echo_pending_byte <= `CMD_LEFT;
                  end
               end

               `ASCII_D_UPPER, `ASCII_D_LOWER: begin
                  if (!fifo_full) begin
                     fifo_din   <= `CMD_RIGHT;
                     fifo_wr_en <= 1'b1;
                  end

                  if (!tx_active) begin
                     tx_byte <= `CMD_RIGHT;
                     tx_dv   <= 1'b1;
                  end
                  else begin
                     echo_pending      <= 1'b1;
                     echo_pending_byte <= `CMD_RIGHT;
                  end
               end

               `ASCII_S_UPPER, `ASCII_S_LOWER, `ASCII_SPACE: begin
                  if (!fifo_full) begin
                     fifo_din   <= `CMD_STOP;
                     fifo_wr_en <= 1'b1;
                  end

                  if (!tx_active) begin
                     tx_byte <= `CMD_STOP;
                     tx_dv   <= 1'b1;
                  end
                  else begin
                     echo_pending      <= 1'b1;
                     echo_pending_byte <= `CMD_STOP;
                  end
               end

               default: begin
                  fifo_wr_en <= 1'b0;
               end
            endcase
         end
         else if (!tx_active && echo_pending) begin
            tx_byte      <= echo_pending_byte;
            tx_dv        <= 1'b1;
            echo_pending <= 1'b0;
         end

         //-------------------------------------------------
         // Consume FIFO command when not paused
         //-------------------------------------------------
         if (!paused && !fifo_empty) begin
            fifo_rd_en <= 1'b1;

            case (fifo_dout)
               `CMD_LEFT: begin
                  uart_left  <= 1'b1;
                  uart_right <= 1'b0;
               end

               `CMD_RIGHT: begin
                  uart_left  <= 1'b0;
                  uart_right <= 1'b1;
               end

               `CMD_STOP: begin
                  uart_left  <= 1'b0;
                  uart_right <= 1'b0;
               end

               default: begin
                  uart_left  <= uart_left;
                  uart_right <= uart_right;
               end
            endcase
         end
      end
   end

   //====================================================
   // Regular LEDs
   //====================================================
   assign LED[0]   = fifo_empty;
   assign LED[1]   = fifo_full;
   assign LED[5:2] = fifo_count[3:0];
   assign LED[6]   = paused;

   //====================================================
   // Score logic
   //====================================================
   always @(posedge clk_50mhz or posedge reset) begin
      if (reset)
         score_bcd <= 32'h00000000;
      else if (miss_pulse)
         score_bcd <= 32'h00000000;
      else if (paddle_hit_pulse)
         score_bcd <= bcd_add_5(score_bcd);
   end

   //====================================================
   // RGB LEDs: green on hit, red on miss
   //====================================================
   always @(posedge clk_50mhz or posedge reset) begin
      if (reset) begin
         led_red_reg   <= 1'b0;
         led_green_reg <= 1'b0;
         led_blue_reg  <= 1'b0;
      end
      else if (miss_pulse) begin
         led_red_reg   <= 1'b1;
         led_green_reg <= 1'b0;
         led_blue_reg  <= 1'b0;
      end
      else if (paddle_hit_pulse) begin
         led_red_reg   <= 1'b0;
         led_green_reg <= 1'b1;
         led_blue_reg  <= 1'b0;
      end
   end

   assign LED16_R = led_red_reg;
   assign LED16_G = led_green_reg;
   assign LED16_B = led_blue_reg;

   assign LED17_R = led_red_reg;
   assign LED17_G = led_green_reg;
   assign LED17_B = led_blue_reg;

   //====================================================
   // Control combine
   //====================================================
   assign ctrl_btn[0] = btn[0] | uart_left;
   assign ctrl_btn[1] = btn[1] | uart_right;

   //====================================================
   // VGA sync
   //====================================================
   vga_sync vga_sync_unit (
      .clk(clk_50mhz),
      .reset(reset),
      .hsync(hsync),
      .vsync(vsync),
      .video_on(video_on),
      .p_tick(pixel_tick),
      .pixel_x(pixel_x),
      .pixel_y(pixel_y)
   );

   //====================================================
   // Game / graphics
   //====================================================
   pong_animate_unit pong_animation (
      .clk(clk_50mhz),
      .reset(reset),
      .video_on(video_on),
      .pause(paused),
      .btn(ctrl_btn),
      .pix_x(pixel_x),
      .pix_y(pixel_y),
      .score_bcd(score_bcd),
      .graph_rgb(rgb_next),
      .paddle_hit_pulse(paddle_hit_pulse),
      .miss_pulse(miss_pulse)
   );

   //====================================================
   // 7-seg score display
   //====================================================
   seven_seg_controller score_display (
      .clk(clk_50mhz),
      .reset(reset),
      .bcd_count(score_bcd),
      .an(an),
      .seg(seg)
   );

   //====================================================
   // RGB output register
   //====================================================
   always @(posedge clk_50mhz) begin
      if (pixel_tick)
         rgb_reg <= rgb_next;
   end

   assign rgb = rgb_reg;

endmodule

