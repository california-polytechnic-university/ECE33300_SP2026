module top_vga(
               input  wire       clk,          // 100 MHz board clock
               input  wire       rst,          // reset, active-high 
               input  wire [3:0] move_dir,     // Buttons: {up, right, down, left}
               input  wire       score_select, // SW0: 0 = current cycle score, 1 = cumulative score
               input  wire       uart_rx,      // USB-UART RX from laptop/TeraTerm
               // VGA outputs
               output wire [3:0] vgaRed,
               output wire [3:0] vgaGreen,
               output wire [3:0] vgaBlue,
               output wire       hsync,
               output wire       vsync,
               // Life display outputs
               output wire [2:0] led,
               // 7-segment display outputs, active-low on Nexys A7
               output wire [6:0] seg,
               output wire [7:0] an,
               output wire       dp
               );

   wire [9:0] hcount;
   wire [9:0] vcount;
   wire       hblank;
   wire       vblank;
   wire       pixpulse;
   wire       is_a_wall;
   wire       draw_ball;

   wire       move;
   wire       frame_tick;
   wire       move_tick;
   reg [11:0] current_pixel;
   reg        vblank_d1;

   wire [23:0] draw_block;
   wire [23:0] broken;
   wire        any_block;
   wire        all_broken;
   wire        unbreak;

   wire        cheat_pulse;
   reg  [3:0] cheat_reset_counter;
   wire       cheat_reset_blocks;

   wire        draw_paddle;
   wire [9:0] paddle_xloc, paddle_yloc;
   wire [9:0] ball_xloc, ball_yloc;

   wire        ballEmpty;
   wire        blockEmpty;
   wire        paddleEmpty;

   wire        respawn_ball;
   wire        game_over;
   wire        reset_blocks;

   // Physical buttons and UART keyboard commands are merged before they reach paddle.v. The paddle module expects one-hot {up,right,down,left}.
   // Buttons take priority whenever at least one button is pressed.
   wire [3:0] button_move_dir;
   wire [3:0] uart_move_dir;
   wire [3:0] effective_move_dir;

   localparam WALL_COLOR  = 12'h00f;
   localparam BALL_COLOR  = 12'h0f0;
   localparam EMPTY_COLOR = 12'h700;

   localparam integer UART_BAUD_RATE          = 115200;
   localparam integer UART_MOVE_TICKS_PER_KEY = 16;

  // Hold the one-clock UART cheat pulse long enough for pixpulse-based block
  // modules to see it. This preserves main's cheat-reset function reliably.
   localparam [3:0] CHEAT_RESET_HOLD_COUNT = 4'd8;

   assign any_block          = |draw_block;
   assign all_broken         = &broken;
   assign cheat_reset_blocks = (cheat_reset_counter != 4'd0);
   assign unbreak            = all_broken | cheat_reset_blocks | reset_blocks;

   
   // VGA Timing Generator
   vga_timing vga_gen (
      .clk      (clk),
      .pixpulse (pixpulse),
      .rst      (rst),
      .hcount   (hcount[9:0]),
      .vcount   (vcount[9:0]),
      .hsync    (hsync),
      .vsync    (vsync),
      .hblank   (hblank),
      .vblank   (vblank)
   );

   // UART keyboard controller
   // TeraTerm sends ASCII bytes. The uart_wasd_controller decodes W/A/S/D and
   // produces the same one-hot direction format used by the pushbuttons.
   uart_wasd_controller #(
      .CLK_FREQ_HZ         (100000000),
      .BAUD_RATE           (UART_BAUD_RATE),
      .MOVE_TICKS_PER_KEY  (UART_MOVE_TICKS_PER_KEY)
   ) u_uart_wasd_controller (
      .clk         (clk),
      .rst         (rst),
      .uart_rx     (uart_rx),
      .move_tick   (move_tick),
      .move_dir    (uart_move_dir),
      .cheat_pulse (cheat_pulse)
   );

   always @(posedge clk or posedge rst) begin
      if (rst) begin
         cheat_reset_counter <= 4'd0;
      end else if (cheat_pulse) begin
         cheat_reset_counter <= CHEAT_RESET_HOLD_COUNT;
      end else if (cheat_reset_counter != 4'd0) begin
         cheat_reset_counter <= cheat_reset_counter - 1'b1;
      end
   end

   // Convert button presses into a single legal one-hot value.
   // Priority, from highest to lowest, is up, right, down, left.
   assign button_move_dir = move_dir[3] ? 4'b1000 :
                            move_dir[2] ? 4'b0100 :
                            move_dir[1] ? 4'b0010 :
                            move_dir[0] ? 4'b0001 :
                                          4'b0000;

   assign effective_move_dir = (button_move_dir != 4'b0000) ? button_move_dir : uart_move_dir;

   paddle #(320,400,5,2) u_paddle (
      .clk         (clk),
      .pixpulse    (pixpulse),
      .rst         (rst),
      .hcount      (hcount),
      .vcount      (vcount),
      .empty       (paddleEmpty),
      .move        (move),
      .move_dir    (effective_move_dir),
      .draw_paddle (draw_paddle),
      .xloc        (paddle_xloc),
      .yloc        (paddle_yloc)
   );

   
   // Score calculation
   // current_score is the number of blocks currently broken in this cycle.
   // returns to 0 when all blocks are broken, the cheat reset is used, or
  // the life system resets the block array after game over (out of lives).
   reg [4:0] current_score;
   integer i;

   always @(*) begin
      current_score = 5'd0;
      for (i = 0; i < 24; i = i + 1)
         current_score = current_score + {4'd0, broken[i]};
   end

   // cumulative_score counts every new block break 
  // doess not reset when the block array is automatically restored for the next game cycle (finisih game)
  // or when the life system resets the current-cycle score (out of lives). 
   // It only resets when the board reset input rst is asserted.
   localparam [26:0] CUMULATIVE_SCORE_MAX = 27'd99999999;

   reg  [26:0] cumulative_score;
   reg  [23:0] broken_d1;
   wire [23:0] newly_broken;
   reg  [4:0]  new_break_count;
   wire [26:0] new_break_count_ext;
   wire [26:0] display_score;
   integer j;

   assign newly_broken        = broken & ~broken_d1;
   assign new_break_count_ext = {22'd0, new_break_count};
   assign display_score       = score_select ? cumulative_score : {22'd0, current_score};

   always @(*) begin
      new_break_count = 5'd0;
      for (j = 0; j < 24; j = j + 1)
         new_break_count = new_break_count + {4'd0, newly_broken[j]};
   end

   always @(posedge clk or posedge rst) begin
      if (rst) begin
         broken_d1        <= 24'd0;
         cumulative_score <= 27'd0;
      end else begin
         broken_d1 <= broken;

         if (new_break_count != 5'd0) begin
            if (cumulative_score >= (CUMULATIVE_SCORE_MAX - new_break_count_ext))
               cumulative_score <= CUMULATIVE_SCORE_MAX;
            else
               cumulative_score <= cumulative_score + new_break_count_ext;
         end
      end
   end

   // SW0: score_select controls what the 7-segment display shows:
   //   score_select = 0: current round score
   //   score_select = 1: cumulative score across cycles/lives
   sevenseg_score u_score_display (
      .clk   (clk),
      .rst   (rst),
      .score (display_score),
      .seg   (seg),
      .an    (an),
      .dp    (dp)
   );

   // Add 24 blocks in two rows of 12.
   genvar row, col;
   generate
      for (row = 0; row < 2; row = row + 1) begin : ROWS
         for (col = 0; col < 12; col = col + 1) begin : COLS
            block #(
               .xloc        (col * 50 + 40),
               .yloc        (row * 30 + 70),
               .xsize_div_2 (20),
               .ysize_div_2 (10)
            ) blok (
               .clk        (clk),
               .pixpulse   (pixpulse),
               .rst        (rst),
               .hcount     (hcount),
               .vcount     (vcount),
               .empty      (blockEmpty),
               .move       (move),
               .unbreak    (unbreak),
               .draw_block (draw_block[row * 12 + col]),
               .broken     (broken[row * 12 + col])
            );
         end
      end
   endgenerate

   ball #(320,240,0,0) u_ball_1 (
      .draw_ball (draw_ball),
      .xloc      (ball_xloc),
      .yloc      (ball_yloc),
      .clk       (clk),
      .pixpulse  (pixpulse),
      .rst       (rst),
      .hcount    (hcount[9:0]),
      .vcount    (vcount[9:0]),
      .empty     (ballEmpty),
      .move      (move),
      .respawn   (respawn_ball)
   );

   
   // Life system 
   life_fsm u_life_fsm (
      .clk          (clk),
      .rst          (rst),
      .move         (frame_tick),
      .ball_yloc    (ball_yloc),
      .led          (led),
      .respawn_ball (respawn_ball),
      .game_over    (game_over),
      .reset_blocks (reset_blocks)
   );

   assign is_a_wall = ((hcount < 5) | (hcount > 625) | (vcount < 5) | (vcount > 475));

   assign blockEmpty  = ~(is_a_wall | draw_ball | draw_paddle);
   assign paddleEmpty = ~is_a_wall;
   assign ballEmpty   = ~(is_a_wall | any_block | draw_paddle);

   // Move game objects at the start of vertical blanking. During game over,
   // life_fsm still sees frame_tick, but game objects are frozen until respawn.
   assign frame_tick = (vblank & ~vblank_d1);
   assign move       = frame_tick & ~game_over;
   assign move_tick  = pixpulse & frame_tick;

   always @(posedge clk or posedge rst) begin
      if (rst) begin
         vblank_d1 <= 1'b0;
      end else if (pixpulse) begin
         vblank_d1 <= vblank;
      end
   end

   // Register the current VGA pixel. The score is not part of this priority
   // chain, so it does not appear in the top-left corner of the VGA screen.
   always @(posedge clk) begin
      if (pixpulse)
         current_pixel <= (is_a_wall)   ? WALL_COLOR  :
                          (any_block)   ? 12'hff0     : // yellow
                          (draw_paddle) ? 12'h0ff     : // cyan
                          (draw_ball)   ? BALL_COLOR  :
                                          EMPTY_COLOR;
   end

   // Map 12-bit to 4:4:4 VGA.
   assign vgaRed   = (~hblank && ~vblank) ? current_pixel[11:8] : 4'b0;
   assign vgaGreen = (~hblank && ~vblank) ? current_pixel[7:4]  : 4'b0;
   assign vgaBlue  = (~hblank && ~vblank) ? current_pixel[3:0]  : 4'b0;

endmodule
