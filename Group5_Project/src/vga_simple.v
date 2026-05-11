DELETEEEEEEEE

module vga_simple(
    input clk,
    input [3:0] game_state,
    input [2:0] direction,

    input btnU,
    input btnD,
    input btnL,
    input btnR,
    input btnC,

    input win,
    input lose,
    input wrong_flash,

    output Hsync,
    output Vsync,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue
);

    
    reg [1:0] clk_div = 0;

    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end

    wire pix_clk;
    assign pix_clk = clk_div[1];

   
    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    always @(posedge pix_clk) begin
        if (h_count == 799) begin
            h_count <= 0;

            if (v_count == 524)
                v_count <= 0;
  else
                v_count <= v_count + 1;

        end else begin
     h_count <= h_count + 1;
        end
    end

    assign Hsync = ~((h_count >= 656) && (h_count < 752));
    assign Vsync = ~((v_count >= 490) && (v_count < 492));

    wire visible;
    assign visible = (h_count < 640) && (v_count < 480);

    // D-pad 
    wire up_box;
    wire down_box;
    wire left_box;
    wire right_box;
    wire center_box;
    wire dpad_area;

    assign up_box =
        (h_count >= 270 && h_count <= 370 &&
         v_count >= 70  && v_count <= 190);

    assign down_box =
        (h_count >= 270 && h_count <= 370 &&
         v_count >= 290 && v_count <= 410);

    assign left_box =
        (h_count >= 120 && h_count <= 270 &&
         v_count >= 190 && v_count <= 290);

    assign right_box =
        (h_count >= 370 && h_count <= 520 &&
         v_count >= 190 && v_count <= 290);

    assign center_box =
        (h_count >= 270 && h_count <= 370 &&
         v_count >= 190 && v_count <= 290);

    assign dpad_area = up_box | down_box | left_box | right_box | center_box;

    // Center button 
    wire center_button;
    assign center_button =
        (h_count >= 295 && h_count <= 345 &&
         v_count >= 215 && v_count <= 265);

    // Arrow shapes
    wire arrow_up;
    wire arrow_down;
    wire arrow_left;
    wire arrow_right;

    assign arrow_up =
        ((h_count >= 310 && h_count <= 330 && v_count >= 95  && v_count <= 120) ||
         (h_count >= 300 && h_count <= 340 && v_count >= 120 && v_count <= 140) ||
         (h_count >= 290 && h_count <= 350 && v_count >= 140 && v_count <= 160) ||
         (h_count >= 315 && h_count <= 325 && v_count >= 160 && v_count <= 180));

    assign arrow_down =
        ((h_count >= 315 && h_count <= 325 && v_count >= 300 && v_count <= 320) ||
         (h_count >= 290 && h_count <= 350 && v_count >= 320 && v_count <= 340) ||
         (h_count >= 300 && h_count <= 340 && v_count >= 340 && v_count <= 360) ||
         (h_count >= 310 && h_count <= 330 && v_count >= 360 && v_count <= 385));

    assign arrow_left =
        ((h_count >= 145 && h_count <= 170 && v_count >= 230 && v_count <= 250) ||
         (h_count >= 170 && h_count <= 195 && v_count >= 220 && v_count <= 260) ||
         (h_count >= 195 && h_count <= 220 && v_count >= 210 && v_count <= 270) ||
         (h_count >= 220 && h_count <= 250 && v_count >= 235 && v_count <= 245));

    assign arrow_right =
        ((h_count >= 390 && h_count <= 420 && v_count >= 235 && v_count <= 245) ||
         (h_count >= 420 && h_count <= 445 && v_count >= 210 && v_count <= 270) ||
         (h_count >= 445 && h_count <= 470 && v_count >= 220 && v_count <= 260) ||
         (h_count >= 470 && h_count <= 495 && v_count >= 230 && v_count <= 250));

    //  target arrow/button
    wire selected_arrow;
    assign selected_arrow =
        (direction == 3'd0 && arrow_up) ||
        (direction == 3'd1 && arrow_down) ||
        (direction == 3'd2 && arrow_left) ||
        (direction == 3'd3 && arrow_right) ||
        (direction == 3'd4 && center_button);

    // Pressed arrow/button
    wire pressed_arrow;
    assign pressed_arrow =
        (btnU && arrow_up) ||
        (btnD && arrow_down) ||
        (btnL && arrow_left) ||
        (btnR && arrow_right) ||
        (btnC && center_button);

    
   
 

    wire you_win_text;

    assign you_win_text =
        // Y
        ((h_count >= 90  && h_count <= 110 && v_count >= 150 && v_count <= 190) ||
         (h_count >= 130 && h_count <= 150 && v_count >= 150 && v_count <= 190) ||
         (h_count >= 110 && h_count <= 130 && v_count >= 190 && v_count <= 250)) ||

        // O
        ((h_count >= 170 && h_count <= 230 && v_count >= 150 && v_count <= 170) ||
         (h_count >= 170 && h_count <= 230 && v_count >= 230 && v_count <= 250) ||
         (h_count >= 170 && h_count <= 190 && v_count >= 150 && v_count <= 250) ||
         (h_count >= 210 && h_count <= 230 && v_count >= 150 && v_count <= 250)) ||

        // U
        ((h_count >= 250 && h_count <= 270 && v_count >= 150 && v_count <= 250) ||
         (h_count >= 310 && h_count <= 330 && v_count >= 150 && v_count <= 250) ||
         (h_count >= 250 && h_count <= 330 && v_count >= 230 && v_count <= 250)) ||

        // W
        ((h_count >= 120 && h_count <= 140 && v_count >= 290 && v_count <= 390) ||
         (h_count >= 180 && h_count <= 200 && v_count >= 290 && v_count <= 390) ||
         (h_count >= 145 && h_count <= 155 && v_count >= 350 && v_count <= 390) ||
         (h_count >= 165 && h_count <= 175 && v_count >= 350 && v_count <= 390)) ||

        // I
        ((h_count >= 240 && h_count <= 300 && v_count >= 290 && v_count <= 310) ||
         (h_count >= 260 && h_count <= 280 && v_count >= 290 && v_count <= 390) ||
         (h_count >= 240 && h_count <= 300 && v_count >= 370 && v_count <= 390)) ||

        // N
        ((h_count >= 340 && h_count <= 360 && v_count >= 290 && v_count <= 390) ||
         (h_count >= 400 && h_count <= 420 && v_count >= 290 && v_count <= 390) ||
         (h_count >= 365 && h_count <= 375 && v_count >= 320 && v_count <= 350) ||
         (h_count >= 380 && h_count <= 390 && v_count >= 350 && v_count <= 380)) ||

        // !
        ((h_count >= 460 && h_count <= 480 && v_count >= 290 && v_count <= 360) ||
         (h_count >= 460 && h_count <= 480 && v_count >= 375 && v_count <= 395));

  

    wire you_lose_text;

    assign you_lose_text =
        // Y
        ((h_count >= 60  && h_count <= 80  && v_count >= 150 && v_count <= 190) ||
         (h_count >= 100 && h_count <= 120 && v_count >= 150 && v_count <= 190) ||
         (h_count >= 80  && h_count <= 100 && v_count >= 190 && v_count <= 250)) ||

        // O
        ((h_count >= 140 && h_count <= 200 && v_count >= 150 && v_count <= 170) ||
         (h_count >= 140 && h_count <= 200 && v_count >= 230 && v_count <= 250) ||
         (h_count >= 140 && h_count <= 160 && v_count >= 150 && v_count <= 250) ||
         (h_count >= 180 && h_count <= 200 && v_count >= 150 && v_count <= 250)) ||

        // U
        ((h_count >= 220 && h_count <= 240 && v_count >= 150 && v_count <= 250) ||
         (h_count >= 280 && h_count <= 300 && v_count >= 150 && v_count <= 250) ||
         (h_count >= 220 && h_count <= 300 && v_count >= 230 && v_count <= 250)) ||

        // L
        ((h_count >= 80  && h_count <= 100 && v_count >= 290 && v_count <= 390) ||
         (h_count >= 80  && h_count <= 180 && v_count >= 370 && v_count <= 390)) ||

        // O
        ((h_count >= 210 && h_count <= 270 && v_count >= 290 && v_count <= 310) ||
         (h_count >= 210 && h_count <= 270 && v_count >= 370 && v_count <= 390) ||
         (h_count >= 210 && h_count <= 230 && v_count >= 290 && v_count <= 390) ||
         (h_count >= 250 && h_count <= 270 && v_count >= 290 && v_count <= 390)) ||

        // S
        ((h_count >= 300 && h_count <= 380 && v_count >= 290 && v_count <= 310) ||
         (h_count >= 300 && h_count <= 320 && v_count >= 290 && v_count <= 340) ||
         (h_count >= 300 && h_count <= 380 && v_count >= 335 && v_count <= 355) ||
         (h_count >= 360 && h_count <= 380 && v_count >= 355 && v_count <= 390) ||
         (h_count >= 300 && h_count <= 380 && v_count >= 370 && v_count <= 390)) ||

        // E
        ((h_count >= 410 && h_count <= 430 && v_count >= 290 && v_count <= 390) ||
         (h_count >= 410 && h_count <= 510 && v_count >= 290 && v_count <= 310) ||
         (h_count >= 410 && h_count <= 490 && v_count >= 335 && v_count <= 355) ||
         (h_count >= 410 && h_count <= 510 && v_count >= 370 && v_count <= 390)) ||

        // !!!
        ((h_count >= 540 && h_count <= 555 && v_count >= 290 && v_count <= 360) ||
         (h_count >= 540 && h_count <= 555 && v_count >= 375 && v_count <= 390)) ||

        ((h_count >= 570 && h_count <= 585 && v_count >= 290 && v_count <= 360) ||
         (h_count >= 570 && h_count <= 585 && v_count >= 375 && v_count <= 390)) ||

        ((h_count >= 600 && h_count <= 615 && v_count >= 290 && v_count <= 360) ||
         (h_count >= 600 && h_count <= 615 && v_count >= 375 && v_count <= 390));

    

    reg [3:0] r;
    reg [3:0] g;
    reg [3:0] b;

    always @(*) begin
        // green play background
        r = 0;
        g = 15;
        b = 0;

        if (!visible) begin
            r = 0;
            g = 0;
            b = 0;
        end

        // red background (YOU LOSE!!!)
        else if ((game_state == 4'd4) || (game_state == 4'd5 && (lose || wrong_flash))) begin
            r = 15;
            g = 0;
            b = 0;

            if (you_lose_text) begin
                r = 15;
                g = 15;
                b = 15;
            end
        end

        // purple background YOU WIN!
        else if (game_state == 4'd5 && win) begin
            r = 8;
            g = 0;
            b = 12;

            if (you_win_text) begin
                r = 15;
                g = 15;
                b = 15;
            end
        end

     
        else begin
           
            if (dpad_area) begin
        r = 15;
           g = 15;
                b = 15;
            end

         
   if (arrow_up || arrow_down || arrow_left || arrow_right || center_button) begin
        r = 0;
                g = 0;
             b = 0;
            end

            if (game_state == 4'd2 && selected_arrow) begin
                r = 0;
                g = 0;
                b = 15;
            end
          
            if (pressed_arrow) begin
            r = 15;
                g = 0;
              b = 0;
     end
    end
    end

    assign vgaRed   = r;
    assign vgaGreen = g;
    assign vgaBlue  = b;

endmodule
