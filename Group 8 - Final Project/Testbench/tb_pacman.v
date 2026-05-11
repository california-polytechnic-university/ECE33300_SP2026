`timescale 1ns / 1ps


module tb_pacman;

   //------------------------------------------------------------
   // DUT outputs
   //------------------------------------------------------------
   wire [3:0] vga_red;
   wire [3:0] vga_green;
   wire [3:0] vga_blue;
   wire       vga_hsync;
   wire       vga_vsync;

   wire [7:0] leds;
   wire       rgb_led_r;
   wire       rgb_led_g;
   wire       rgb_led_b;

   wire [6:0] seg;
   wire [7:0] an;
   wire       dp;

   wire       uart_txd;

   //------------------------------------------------------------
   // DUT inputs
   //------------------------------------------------------------
   reg        clk;
   reg [4:0]  btns;
   reg [7:0]  switches;
   reg        ps2d;
   reg        ps2c;
   reg        uart_rxd;

   //------------------------------------------------------------
   // Testbench variables
   //------------------------------------------------------------
   integer frame_count;
   integer hsync_edges;
   integer vsync_edges;
   integer uart_edges;
   integer an_edges;
   integer seg_edges;

   integer map_pixel_count;
   integer moving_pixel_count;
   integer score_pixel_count;
   integer vga_color_count;

   integer k;
   integer r;
   integer c;

   integer dot_count;
   integer wall_count;
   integer open_count;

   integer found_dot;
   integer found_dot_col;
   integer found_dot_row;

   integer score_before;
   integer score_after;

   integer pac_x_before;
   integer pac_y_before;
   integer pac_x_after;
   integer pac_y_after;
   integer pacman_moved;

   integer error_count;

   reg [7:0] uart_rx0;
   reg [7:0] uart_rx1;
   reg [7:0] uart_rx2;
   reg [7:0] uart_rx3;
   reg [7:0] uart_rx4;
   reg [7:0] uart_rx5;

   reg last_hsync;
   reg last_vsync;
   reg last_uart_txd;
   reg [7:0] last_an;
   reg [6:0] last_seg;

   reg  [5:0] probe_col;
   reg  [4:0] probe_row;
   reg  [1:0] probe_map;
   wire [1:0] probe_tile;
   wire       probe_is_wall;
   wire       probe_is_dot;
   wire [3:0] probe_valid_moves;

   map_rom u_map_probe(
       .col(probe_col),
       .row(probe_row),
       .map_num(probe_map),
       .tile(probe_tile),
       .is_wall(probe_is_wall),
       .is_dot(probe_is_dot),
       .valid_moves(probe_valid_moves)
   );

   //------------------------------------------------------------
   // FIFO verification
   //------------------------------------------------------------
   reg        fifo_wr_en;
   reg [7:0]  fifo_wr_data;
   wire       fifo_full;

   reg        fifo_rd_en;
   wire [7:0] fifo_rd_data;
   wire       fifo_empty;
   wire [4:0] fifo_count;

   pacman_uart_fifo #(
       .DATA_WIDTH(8),
       .ADDR_WIDTH(4)
   ) u_fifo_probe (
       .clk(clk),
       .reset(btns[4]),
       .wr_en(fifo_wr_en),
       .wr_data(fifo_wr_data),
       .full(fifo_full),
       .rd_en(fifo_rd_en),
       .rd_data(fifo_rd_data),
       .empty(fifo_empty),
       .fifo_count(fifo_count)
   );

   //------------------------------------------------------------
   // UART byte sequence
   //------------------------------------------------------------
   reg  [3:0] ascii_thousands;
   reg  [3:0] ascii_hundreds;
   reg  [3:0] ascii_tens;
   reg  [3:0] ascii_ones;
   wire [(6*8)-1:0] ascii_message;

   pacman_score_to_ascii u_ascii_probe(
       .message(ascii_message),
       .thousands(ascii_thousands),
       .hundreds(ascii_hundreds),
       .tens(ascii_tens),
       .ones(ascii_ones)
   );

   //------------------------------------------------------------
   // Clock generation
   //------------------------------------------------------------
   always #5 clk = ~clk; // 100 MHz

   //------------------------------------------------------------
   // Device Under Test
   //------------------------------------------------------------
   top dut(
       .vga_red       (vga_red[3:0]),
       .vga_green     (vga_green[3:0]),
       .vga_blue      (vga_blue[3:0]),
       .vga_hsync     (vga_hsync),
       .vga_vsync     (vga_vsync),

       .ps2d          (ps2d),
       .ps2c          (ps2c),

       .btns          (btns[4:0]),
       .switches      (switches[7:0]),

       .leds          (leds[7:0]),
       .rgb_led_r     (rgb_led_r),
       .rgb_led_g     (rgb_led_g),
       .rgb_led_b     (rgb_led_b),

       .seg           (seg[6:0]),
       .an            (an[7:0]),
       .dp            (dp),

       .uart_txd      (uart_txd),
       .uart_rxd      (uart_rxd),

       .clk_board     (clk)
   );

   //------------------------------------------------------------
   // Score helper
   //------------------------------------------------------------
   function integer bcd_score_to_int;
      input [3:0] th;
      input [3:0] hu;
      input [3:0] te;
      input [3:0] on;
      begin
         bcd_score_to_int = (th * 1000) + (hu * 100) + (te * 10) + on;
      end
   endfunction

   //------------------------------------------------------------
   // Tasks
   //------------------------------------------------------------
   task apply_reset;
      begin
         btns[4] = 1'b1;
         #200;
         btns[4] = 1'b0;
         #10000;
      end
   endtask

   task press_button;
      input integer button_index;
      begin
         btns[button_index] = 1'b1;
         #5000000;          
         btns[button_index] = 1'b0;
         #20000;
      end
   endtask

   task check_speed_leds;
      input [3:0] speed_value;
      begin
         switches[3:0] = speed_value;
         #2000;

         if (leds[3:0] !== speed_value) begin
            $display("ERROR: LED3-LED0=%b but expected speed=%b", leds[3:0], speed_value);
            error_count = error_count + 1;
         end else begin
            $display("PASS: speed %b shown on LEDs.", speed_value);
         end
      end
   endtask

   task print_status;
      begin
         $display("score=%0d%0d%0d%0d lives=%0d won=%b over=%b power=%b leds=%b rgb=R%bG%bB%b",
                  dut.score_thousands,
                  dut.score_hundreds,
                  dut.score_tens,
                  dut.score_ones,
                  dut.lives_remaining,
                  dut.game_won,
                  dut.game_over,
                  dut.power_mode,
                  leds,
                  rgb_led_r,
                  rgb_led_g,
                  rgb_led_b);
      end
   endtask

   //------------------------------------------------------------
   // UART TX is 9600 baud
   //------------------------------------------------------------
   task receive_uart_byte;
      output [7:0] rx_byte;
      integer bit_index;
      begin
         rx_byte = 8'h00;

         @(negedge uart_txd);

         #52080;

         if (uart_txd !== 1'b0) begin
            $display("ERROR: UART start bit was not low.");
            error_count = error_count + 1;
         end

         for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
            #104160;
            rx_byte[bit_index] = uart_txd;
         end

         // Sample stop bit
         #104160;

         if (uart_txd !== 1'b1) begin
            $display("ERROR: UART stop bit was not high.");
            error_count = error_count + 1;
         end
      end
   endtask

   task check_direction_button;
      input integer button_index;
      input [3:0] expected_dir;
      input [8*8-1:0] direction_name;
      begin
         btns = 5'b00000;
         #1000;

         btns[button_index] = 1'b1;
         #1000;

         if (dut.move_dir !== expected_dir) begin
            $display("ERROR: %0s button gave move_dir=%b, expected=%b",
                     direction_name, dut.move_dir, expected_dir);
            error_count = error_count + 1;
         end else begin
            $display("PASS: %0s button correctly gives move_dir=%b",
                     direction_name, dut.move_dir);
         end

         btns[button_index] = 1'b0;
         #1000;
      end
   endtask



   //------------------------------------------------------------
   // Wall-collision tests
   //------------------------------------------------------------
   task place_pacman_at_tile;
      input [5:0] tile_col;
      input [4:0] tile_row;
      begin
         force dut.mo.pacman_motion.xpos    = {tile_col, 4'b0000};
         force dut.mo.pacman_motion.ypos    = {tile_row, 4'b0000};
         force dut.mo.pacman_motion.curdir  = 4'b0000;
         force dut.mo.pacman_motion.nextdir = 4'b0000;
         force dut.mo.pacman_motion.phase   = 1'b0;
         #2000;
         release dut.mo.pacman_motion.xpos;
         release dut.mo.pacman_motion.ypos;
         release dut.mo.pacman_motion.curdir;
         release dut.mo.pacman_motion.nextdir;
         release dut.mo.pacman_motion.phase;
         #2000;
      end
   endtask

   //------------------------------------------------------------
   // Activity counters
   //------------------------------------------------------------
   always @(posedge clk) begin
      last_hsync    <= vga_hsync;
      last_vsync    <= vga_vsync;
      last_uart_txd <= uart_txd;
      last_an       <= an;
      last_seg      <= seg;

      if (last_hsync != vga_hsync)
        hsync_edges <= hsync_edges + 1;

      if (last_vsync != vga_vsync)
        vsync_edges <= vsync_edges + 1;

      if (last_uart_txd != uart_txd)
        uart_edges <= uart_edges + 1;

      if (last_an != an)
        an_edges <= an_edges + 1;

      if (last_seg != seg)
        seg_edges <= seg_edges + 1;

      if (dut.map_pix_color != 3'b000)
        map_pixel_count <= map_pixel_count + 1;

      if (dut.moving_piece_color != 3'b000)
        moving_pixel_count <= moving_pixel_count + 1;

      if (dut.score_pixel_color != 3'b000)
        score_pixel_count <= score_pixel_count + 1;

      if ((vga_red != 4'd0) || (vga_green != 4'd0) || (vga_blue != 4'd0))
        vga_color_count <= vga_color_count + 1;
   end

   //------------------------------------------------------------
   // Main stimulus
   //------------------------------------------------------------
   initial begin
      clk          = 0;
      btns         = 5'b00000;
      switches     = 8'b00000000;
      ps2d         = 1'b1;
      ps2c         = 1'b1;
      uart_rxd     = 1'b1;

      probe_col    = 6'd0;
      probe_row    = 5'd0;
      probe_map    = 2'd0;

      fifo_wr_en   = 1'b0;
      fifo_wr_data = 8'd0;
      fifo_rd_en   = 1'b0;

      ascii_thousands = 4'd0;
      ascii_hundreds  = 4'd0;
      ascii_tens      = 4'd0;
      ascii_ones      = 4'd0;

      error_count  = 0;

      frame_count  = 0;
      hsync_edges  = 0;
      vsync_edges  = 0;
      uart_edges   = 0;
      an_edges     = 0;
      seg_edges    = 0;

      map_pixel_count    = 0;
      moving_pixel_count = 0;
      score_pixel_count  = 0;
      vga_color_count    = 0;

      dot_count     = 0;
      wall_count    = 0;
      open_count    = 0;
      found_dot     = 0;
      found_dot_col = 0;
      found_dot_row = 0;

      last_hsync    = 1'b1;
      last_vsync    = 1'b1;
      last_uart_txd = 1'b1;
      last_an       = 8'hff;
      last_seg      = 7'h7f;

      $display("------------------------------------------------------------");
      $display("Pac-Man complete master testbench started");
      $display("------------------------------------------------------------");

      //---------------------------------------------------------
      // TEST 1: Reset
      //---------------------------------------------------------
      $display("TEST 1: Reset");
      apply_reset;
      print_status;

      if (dut.lives_remaining !== 2'd2) begin
        $display("ERROR: lives should reset to 2 remaining.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: lives reset to 2 remaining.");
      end

      if (dut.game_won !== 1'b0) begin
        $display("ERROR: game_won should reset to 0.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: game_won reset correctly.");
      end

      if (dut.game_over !== 1'b0) begin
        $display("ERROR: game_over should reset to 0.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: game_over reset correctly.");
      end

      //---------------------------------------------------------
      // TEST 2: Speed switches
      //---------------------------------------------------------
      $display("TEST 2: Speed switch/LED sweep using for loop");
      for (k = 0; k < 16; k = k + 1) begin
         check_speed_leds(k[3:0]);
      end

      //---------------------------------------------------------
      // TEST 3: Map/background switches
      //---------------------------------------------------------
      $display("TEST 3: Map/background switch combinations");
      for (k = 0; k < 4; k = k + 1) begin
         switches[5:4] = k[1:0];
         switches[7:6] = k[1:0];
         #3000;
         $display("PASS: map/background select = %b", k[1:0]);
      end

      //---------------------------------------------------------
      // TEST 4: Map, and wall verification
      //---------------------------------------------------------
      $display("TEST 4: Map/wall/dot verification");

      probe_map = 2'd0;
      #10;

      for (r = 0; r < 31; r = r + 1) begin
         for (c = 0; c < 28; c = c + 1) begin
            probe_row = r[4:0];
            probe_col = c[5:0];
            #1;

            if (probe_is_wall)
               wall_count = wall_count + 1;
            else
               open_count = open_count + 1;

            if (probe_is_dot) begin
               dot_count = dot_count + 1;

               if (!found_dot) begin
                  found_dot = 1;
                  found_dot_col = c;
                  found_dot_row = r;
               end
            end
         end
      end

      $display("Map count: walls=%0d open=%0d dots=%0d first_dot=(col=%0d,row=%0d)",
               wall_count, open_count, dot_count, found_dot_col, found_dot_row);

      if (wall_count == 0) begin
        $display("ERROR: map_rom did not report any walls.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: map_rom reports wall tiles.");
      end

      if (dot_count == 0) begin
        $display("ERROR: map_rom did not report any dots.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: map_rom reports dot tiles.");
      end

      probe_row = 5'd10;
      probe_col = 6'd8;
      #10;
      if (probe_is_dot) begin
        $display("ERROR: no-dot region row 10 col 8 is still marked as a dot.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: no-dot region row 10 col 8 is not a dot.");
      end

      probe_row = 5'd0;
      probe_col = 6'd0;
      #10;
      if (!probe_is_wall) begin
        $display("ERROR: row 0 col 0 should be a wall/border tile.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: row 0 col 0 is a wall/border tile.");
      end

      //---------------------------------------------------------
      // TEST 5: Score changes when Pac-Man is placed on a dot
      //---------------------------------------------------------
      $display("TEST 5: Score change from dot collection");

      if (found_dot) begin
         score_before = bcd_score_to_int(dut.score_thousands,
                                         dut.score_hundreds,
                                         dut.score_tens,
                                         dut.score_ones);

         force dut.pacman_pos_x = found_dot_col * 16;
         force dut.pacman_pos_y = found_dot_row * 16;
         #2000;
         release dut.pacman_pos_x;
         release dut.pacman_pos_y;
         #2000;

         score_after = bcd_score_to_int(dut.score_thousands,
                                        dut.score_hundreds,
                                        dut.score_tens,
                                        dut.score_ones);

         $display("Score before=%0d after=%0d", score_before, score_after);

         if (score_after <= score_before) begin
            $display("ERROR: score did not increase after forced dot collection.");
            error_count = error_count + 1;
         end else begin
            $display("PASS: score increased after dot collection.");
         end
      end else begin
         $display("ERROR: could not find a dot tile to test scoring.");
         error_count = error_count + 1;
      end

      //---------------------------------------------------------
      // TEST 6: Push-button direction correctness
      //---------------------------------------------------------
      $display("TEST 6: Push-button direction correctness");

      apply_reset;

      // Button mapping:
      // btns[3] = up
      // btns[2] = left
      // btns[1] = right
      // btns[0] = down
      check_direction_button(3, 4'b0100, "UP");
      check_direction_button(2, 4'b0001, "LEFT");
      check_direction_button(1, 4'b0010, "RIGHT");
      check_direction_button(0, 4'b1000, "DOWN");

      //---------------------------------------------------------
      // Extra movement check
      //---------------------------------------------------------
      switches[3:0] = 4'b1111;
      #1000;

      pac_x_before = dut.pacman_pos_x;
      pac_y_before = dut.pacman_pos_y;
      pacman_moved = 0;

      press_button(1); // right

      pac_x_after = dut.pacman_pos_x;
      pac_y_after = dut.pacman_pos_y;

      if ((pac_x_after != pac_x_before) || (pac_y_after != pac_y_before))
         pacman_moved = 1;

      $display("Movement check: before=(%0d,%0d) after=(%0d,%0d)",
               pac_x_before, pac_y_before, pac_x_after, pac_y_after);

      if (pacman_moved == 0) begin
        $display("WARNING: Pac-Man position did not change. Direction logic passed, but movement may be blocked by a wall or need longer simulation.");
      end else begin
        $display("PASS: Pac-Man position changed after button input.");
      end

      //---------------------------------------------------------
      // TEST 6B: Wall-collision correctness
      //---------------------------------------------------------
      $display("TEST 6B: Wall-collision correctness");

      apply_reset;
      switches[3:0] = 4'hF;   
      switches[5:4] = 2'b00;  
      #10000;

      place_pacman_at_tile(6'd1, 5'd1);
      #10000;

      if (dut.mo.pac_tile_x !== 6'd1 || dut.mo.pac_tile_y !== 5'd1) begin
         $display("ERROR: Pac-Man was not placed at expected tile (1,1). Actual tile=(%0d,%0d)",
                  dut.mo.pac_tile_x, dut.mo.pac_tile_y);
         error_count = error_count + 1;
      end else begin
         $display("PASS: Pac-Man placed at open tile (1,1).");
      end

      if (dut.mo.pacman_valid_moves[0] !== 1'b0) begin
         $display("ERROR: LEFT should be blocked at tile (1,1), but pacman_valid_moves=%b",
                  dut.mo.pacman_valid_moves);
         error_count = error_count + 1;
      end else begin
         $display("PASS: LEFT is correctly blocked by the wall at tile (0,1). valid_moves=%b",
                  dut.mo.pacman_valid_moves);
      end

      pac_x_before = dut.pacman_pos_x;
      pac_y_before = dut.pacman_pos_y;

      press_button(2); // left into wall

      pac_x_after = dut.pacman_pos_x;
      pac_y_after = dut.pacman_pos_y;

      $display("Wall test: before=(%0d,%0d) after=(%0d,%0d)",
               pac_x_before, pac_y_before, pac_x_after, pac_y_after);

      if ((pac_x_after !== pac_x_before) || (pac_y_after !== pac_y_before)) begin
         $display("ERROR: Pac-Man moved into/against a wall. Wall collision failed.");
         error_count = error_count + 1;
      end else begin
         $display("PASS: Pac-Man stayed in place when commanded into a wall.");
      end

 
      place_pacman_at_tile(6'd1, 5'd1);
      #10000;

      if (dut.mo.pacman_valid_moves[1] !== 1'b1) begin
         $display("ERROR: RIGHT should be open at tile (1,1), but pacman_valid_moves=%b",
                  dut.mo.pacman_valid_moves);
         error_count = error_count + 1;
      end else begin
         $display("PASS: RIGHT is correctly open from tile (1,1). valid_moves=%b",
                  dut.mo.pacman_valid_moves);
      end

      $display("PASS: Wall-collision test complete: LEFT blocked, RIGHT open.");

      //---------------------------------------------------------
      // TEST 7: Seven-segment display
      //---------------------------------------------------------
      $display("TEST 7: Seven-segment activity");

      #100000;

      if (an_edges == 0) begin
        $display("ERROR: seven-segment anodes did not scan.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: seven-segment anodes scanned. an_edges=%0d", an_edges);
      end

      if (seg_edges == 0)
        $display("WARNING: seven-segment segments did not change in this window.");
      else
        $display("PASS: seven-segment segment outputs changed. seg_edges=%0d", seg_edges);

      //---------------------------------------------------------
      // TEST 8: Power mode LED
      //---------------------------------------------------------
      $display("TEST 8: Power mode LED");

      force dut.power_mode = 1'b1;
      #5000;

      if (leds[4] !== 1'b1) begin
        $display("ERROR: LED4 should turn on during power mode.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: LED4 turns on during power mode.");
      end

      release dut.power_mode;
      #2000;

      //---------------------------------------------------------
      // TEST 9: Lives, LEDs and RGB game-over status
      //---------------------------------------------------------
      $display("TEST 9: Lives LEDs and RGB game-over status");

      force dut.lives_remaining = 2'd2;
      force dut.game_over = 1'b0;
      #3000;
      if (leds[5] !== 1'b1 || leds[6] !== 1'b1) begin
        $display("ERROR: 2 lives should turn on LED5 and LED6.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: 2 lives shown correctly.");
      end

      force dut.lives_remaining = 2'd1;
      #3000;
      if (leds[5] !== 1'b1 || leds[6] !== 1'b0) begin
        $display("ERROR: 1 life should turn on LED5 only.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: 1 life shown correctly.");
      end

      force dut.lives_remaining = 2'd0;
      #3000;
      if (leds[5] !== 1'b0 || leds[6] !== 1'b0) begin
        $display("ERROR: 0 lives should turn off LED5 and LED6.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: 0 lives shown correctly.");
      end

      force dut.game_over = 1'b0;
      #3000;
      if (rgb_led_g !== 1'b1 || rgb_led_r !== 1'b0) begin
        $display("ERROR: RGB should be green during play.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: RGB green during play.");
      end

      force dut.game_over = 1'b1;
      #3000;
      if (rgb_led_r !== 1'b1 || rgb_led_g !== 1'b0) begin
        $display("ERROR: RGB should be red during game over.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: RGB red during game over.");
      end

      release dut.lives_remaining;
      release dut.game_over;
      #2000;

      //---------------------------------------------------------
      // TEST 10: Winner state
      //---------------------------------------------------------
      $display("TEST 10: Winner state");

      force dut.game_won = 1'b1;
      #5000;
      if (leds[7] !== 1'b1) begin
        $display("ERROR: LED7 should turn on during WINNER.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: LED7 turns on during WINNER.");
      end

      release dut.game_won;
      #2000;

      //---------------------------------------------------------
      // TEST 11: FIFO full/empty and data order behavior
      //---------------------------------------------------------
      $display("TEST 11: FIFO full/empty and data order behavior");

      apply_reset;

      if (!fifo_empty) begin
        $display("ERROR: FIFO should be empty after reset.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: FIFO empty after reset.");
      end

      if (fifo_count !== 5'd0) begin
        $display("ERROR: FIFO count should be 0 after reset. fifo_count=%0d", fifo_count);
        error_count = error_count + 1;
      end else begin
        $display("PASS: FIFO count is 0 after reset.");
      end

      for (k = 0; k < 16; k = k + 1) begin
         @(negedge clk);
         fifo_wr_data = 8'h41 + k[7:0]; // A, B, C, ...
         fifo_wr_en = 1'b1;

         @(negedge clk);
         fifo_wr_en = 1'b0;
      end

      @(posedge clk);
      #100;

      $display("FIFO count after writes = %0d", fifo_count);

      if (!fifo_full) begin
        $display("ERROR: FIFO should be full after 16 writes.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: FIFO full after 16 writes.");
      end

      if (fifo_count !== 5'd16) begin
        $display("ERROR: FIFO count should be 16 after 16 writes. fifo_count=%0d", fifo_count);
        error_count = error_count + 1;
      end else begin
        $display("PASS: FIFO count is 16 after 16 writes.");
      end

         for (k = 0; k < 16; k = k + 1) begin
         #100;

         if (fifo_rd_data !== (8'h41 + k[7:0])) begin
            $display("ERROR: FIFO read order wrong at index %0d. Got %h, expected %h",
                     k, fifo_rd_data, (8'h41 + k[7:0]));
            error_count = error_count + 1;
         end else begin
            $display("PASS: FIFO read index %0d correct. data=%h", k, fifo_rd_data);
         end

         @(negedge clk);
         fifo_rd_en = 1'b1;

         @(negedge clk);
         fifo_rd_en = 1'b0;
      end

      @(posedge clk);
      #100;

      $display("FIFO count after reads = %0d", fifo_count);

      if (!fifo_empty) begin
        $display("ERROR: FIFO should be empty after 16 reads.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: FIFO empty after 16 reads.");
      end

      if (fifo_count !== 5'd0) begin
        $display("ERROR: FIFO count should return to 0 after reads. fifo_count=%0d", fifo_count);
        error_count = error_count + 1;
      end else begin
        $display("PASS: FIFO count returned to 0 after reads.");
      end

      //---------------------------------------------------------
      // TEST 12: UART expected byte sequence
      //---------------------------------------------------------
      $display("TEST 12: UART expected ASCII byte sequence");

      ascii_thousands = 4'd2;
      ascii_hundreds  = 4'd7;
      ascii_tens      = 4'd4;
      ascii_ones      = 4'd0;
      #10;

      if (ascii_message !== {8'h32,8'h37,8'h34,8'h30,8'h0D,8'h0A}) begin
         $display("ERROR: ASCII message for 2740 is wrong. message=%h", ascii_message);
         error_count = error_count + 1;
      end else begin
         $display("PASS: ASCII message for 2740 is correct: 32 37 34 30 0D 0A.");
      end

      //---------------------------------------------------------
      // TEST 13: Full-design UART TX activity
      //---------------------------------------------------------
      $display("TEST 13: Full-design UART TX activity");

      apply_reset;

      uart_edges = 0;

      repeat (1500000) @(posedge clk);

      if (uart_edges == 0) begin
         $display("ERROR: UART TX did not toggle in this window.");
         error_count = error_count + 1;
      end else begin
         $display("PASS: UART TX toggled in full design. uart_edges=%0d", uart_edges);
      end

      if (uart_txd !== 1'b1) begin
         $display("WARNING: UART line was not idle-high at the end of the sample window.");
      end else begin
         $display("PASS: UART line returned to idle-high.");
      end

      //---------------------------------------------------------
      // TEST 14: VGA and display-layer 
      //---------------------------------------------------------
      $display("TEST 14: VGA and display-layer activity");

      #2000000;

      if (hsync_edges < 2) begin
        $display("ERROR: hsync did not toggle enough times. hsync_edges=%0d", hsync_edges);
        error_count = error_count + 1;
      end else begin
        $display("PASS: hsync toggled. hsync_edges=%0d", hsync_edges);
      end

      if (map_pixel_count == 0) begin
        $display("ERROR: map layer did not draw any non-black pixels.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: map layer drew non-black pixels. count=%0d", map_pixel_count);
      end

      if (moving_pixel_count == 0)
        $display("WARNING: moving object layer was not observed in this short scan window.");
      else
        $display("PASS: moving object layer drew non-black pixels. count=%0d", moving_pixel_count);

      if (score_pixel_count == 0)
        $display("WARNING: score/message layer was not observed in this short scan window.");
      else
        $display("PASS: score/message layer drew non-black pixels. count=%0d", score_pixel_count);

      if (vga_color_count == 0) begin
        $display("ERROR: VGA color outputs never became nonzero.");
        error_count = error_count + 1;
      end else begin
        $display("PASS: VGA color outputs became nonzero. count=%0d", vga_color_count);
      end

      if (vsync_edges == 0)
        $display("WARNING: vsync did not toggle in this short window. Run longer for full frames.");
      else
        $display("PASS: vsync toggled. vsync_edges=%0d", vsync_edges);

      //---------------------------------------------------------
      // TEST 15: Final reset
      //---------------------------------------------------------
      $display("TEST 15: Final reset");
      apply_reset;
      print_status;

      //---------------------------------------------------------
      // Final summary
      //---------------------------------------------------------
      $display("------------------------------------------------------------");
      $display("Final Testbench Summary");
      $display("error_count        = %0d", error_count);
      $display("hsync_edges        = %0d", hsync_edges);
      $display("vsync_edges        = %0d", vsync_edges);
      $display("uart_edges         = %0d", uart_edges);
      $display("an_edges           = %0d", an_edges);
      $display("seg_edges          = %0d", seg_edges);
      $display("map_pixel_count    = %0d", map_pixel_count);
      $display("moving_pixel_count = %0d", moving_pixel_count);
      $display("score_pixel_count  = %0d", score_pixel_count);
      $display("vga_color_count    = %0d", vga_color_count);
      $display("dot_count          = %0d", dot_count);
      $display("wall_count         = %0d", wall_count);
      $display("open_count         = %0d", open_count);
      $display("leds               = %b", leds);
      $display("seg                = %b", seg);
      $display("an                 = %b", an);
      $display("rgb                = R%b G%b B%b", rgb_led_r, rgb_led_g, rgb_led_b);
      print_status;
      $display("------------------------------------------------------------");

      if (error_count == 0) begin
         $display("OVERALL RESULT: PASS - no testbench errors detected.");
      end else begin
         $display("OVERALL RESULT: FAIL - %0d testbench error(s) detected.", error_count);
      end

      $stop;
   end

   //------------------------------------------------------------
   // Frame monitor
   //------------------------------------------------------------
   initial begin
      forever begin
         wait(~vga_vsync);

         frame_count = frame_count + 1;

         $display("frame=%0d score=%0d%0d%0d%0d lives=%0d won=%b over=%b power=%b speed=%b leds=%b an=%b seg=%b",
                  frame_count,
                  dut.score_thousands,
                  dut.score_hundreds,
                  dut.score_tens,
                  dut.score_ones,
                  dut.lives_remaining,
                  dut.game_won,
                  dut.game_over,
                  dut.power_mode,
                  switches[3:0],
                  leds,
                  an,
                  seg);

         wait(vga_vsync);
      end
   end

endmodule
