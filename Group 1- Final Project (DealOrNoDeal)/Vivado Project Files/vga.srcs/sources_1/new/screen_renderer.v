`timescale 1ns / 1ps

module screen_renderer (

    input  wire        pix_clk,
    input  wire [11:0] hpos,
    input  wire [11:0] vpos,
    input  wire        active,
    input  wire [15:0] case_opened,
    input  wire [15:0] case_preview,
    input  wire        valid_selection,
    input  wire        invalid_selection,
    input  wire [31:0] banker_offer,
    input  wire        offer_valid,
    input  wire [31:0] opened_case_value,
    input  wire [31:0] remaining_total,
    input  wire [31:0] remaining_average,
    input  wire [3:0]  player_case,
    input  wire        player_case_locked,
    input  wire [3:0]  game_state,
    output reg  [3:0]  pixel_r,
    output reg  [3:0]  pixel_g,
    output reg  [3:0]  pixel_b
);
    
    // ?? Layout constants (1280x1024) ??????????????????????????????????????????
    localparam CASE_X0   = 80;
    localparam CASE_Y0   = 110;
    localparam CASE_W    = 150;
    localparam CASE_H    = 100;
    localparam CASE_GAP  = 30;

    localparam MONEY_X   = 900;
    localparam MONEY_Y0  = 140;
    localparam MONEY_W   = 300;
    localparam MONEY_H   = 40;
    localparam MONEY_GAP = 8;

    localparam TITLE_Y   = 20;
    localparam TITLE_H   = 70;
    localparam STATUS_Y  = 920;
    localparam STATUS_H  = 40;
    localparam OFFER_Y   = 968;
    localparam OFFER_H   = 40;

    // ?? Colours ???????????????????????????????????????????????????????????????
    localparam [11:0] COL_BLACK      = 12'h000;
    localparam [11:0] COL_WHITE      = 12'hFFF;
    localparam [11:0] COL_ROYAL_BLUE = 12'h246;
    localparam [11:0] COL_GOLD       = 12'hFA0;
    localparam [11:0] COL_GRAY       = 12'h888;
    localparam [11:0] COL_DARK_BLUE  = 12'h013;
    localparam [11:0] COL_DIM_GRAY   = 12'h555;
    localparam [11:0] COL_DARK_GREEN = 12'h050;
    localparam [11:0] COL_DARK_RED   = 12'h500;
    localparam [11:0] COL_BG         = 12'h111;
    localparam [11:0] COL_PLAYER_CASE = 12'hF0F;  // magenta
    // ?? Font scale - each font pixel is SCALE x SCALE screen pixels ???????????
    localparam SCALE = 4;
    localparam CHAR_W = 5 * SCALE;   // 20 pixels per character
    localparam CHAR_H = 7 * SCALE;   // 28 pixels per character
    
    // Only show preview highlight during OPEN_CASE state (4'd2)
    wire preview_active = (game_state == 4'd1 || game_state == 4'd2);

    

    // ?? Case box region ???????????????????????????????????????????????????????
    wire [11:0] case_rel_x = hpos - CASE_X0;
    wire [11:0] case_rel_y = vpos - CASE_Y0;

    wire [4:0] case_col = (hpos >= CASE_X0) ?
                          (case_rel_x / (CASE_W + CASE_GAP)) : 5'd16;
    wire [4:0] case_row = (vpos >= CASE_Y0) ?
                          (case_rel_y / (CASE_H + CASE_GAP)) : 5'd16;
    wire [4:0] case_idx = (case_col < 4 && case_row < 4) ?
                          (case_row * 4 + case_col) : 5'd16;

    wire in_case_x = (case_col < 4) &&
                     (case_rel_x % (CASE_W + CASE_GAP) < CASE_W);
    wire in_case_y = (case_row < 4) &&
                     (case_rel_y % (CASE_H + CASE_GAP) < CASE_H);
    wire in_case_box = in_case_x && in_case_y &&
                       (case_idx < 16) &&
                       (hpos >= CASE_X0) &&
                       (vpos >= CASE_Y0);

    wire in_case_border = in_case_box && (
        (case_rel_x % (CASE_W + CASE_GAP) < 2) ||
        (case_rel_x % (CASE_W + CASE_GAP) >= CASE_W - 2) ||
        (case_rel_y % (CASE_H + CASE_GAP) < 2) ||
        (case_rel_y % (CASE_H + CASE_GAP) >= CASE_H - 2)
    );

    // ?? Position within the current case box ?????????????????????????????????
    wire [11:0] box_x = case_rel_x % (CASE_W + CASE_GAP);
    wire [11:0] box_y = case_rel_y % (CASE_H + CASE_GAP);

    // ?? Case number text (two digits centered in box) ?????????????????????????
    // Text block is 2 chars + 1 gap = 2*CHAR_W + SCALE wide
    // Centered: start_x = (CASE_W - (2*CHAR_W + SCALE)) / 2
    localparam CASE_TXT_X = (CASE_W - (2 * CHAR_W + SCALE)) / 2;
    localparam CASE_TXT_Y = (CASE_H - CHAR_H) / 2;

    // Which character are we in (0=tens digit, 1=ones digit)
    wire in_case_text_x = (box_x >= CASE_TXT_X) &&
                          (box_x <  CASE_TXT_X + 2 * CHAR_W + SCALE);
    wire in_case_text_y = (box_y >= CASE_TXT_Y) &&
                          (box_y <  CASE_TXT_Y + CHAR_H);
    wire in_case_text   = in_case_box && in_case_text_x && in_case_text_y;

    wire [11:0] txt_rel_x = box_x - CASE_TXT_X;
    wire [11:0] txt_rel_y = box_y - CASE_TXT_Y;

    // Which character column (0 or 1), skipping the gap between them
    wire in_char0 = (txt_rel_x < CHAR_W);
    wire in_char1 = (txt_rel_x >= CHAR_W + SCALE) &&
                    (txt_rel_x <  CHAR_W + SCALE + CHAR_W);

    wire [11:0] char0_px = txt_rel_x;
    wire [11:0] char1_px = txt_rel_x - (CHAR_W + SCALE);

    // Font row and column within the character
    wire [2:0] font_row0  = txt_rel_y / SCALE;
    wire [2:0] font_col0  = (CHAR_W - 1 - char0_px) / SCALE;
    wire [2:0] font_row1  = txt_rel_y / SCALE;
    wire [2:0] font_col1  = (CHAR_W - 1 - char1_px) / SCALE;

    // Case number digits
    wire [3:0] case_tens = (case_idx < 16) ? (case_idx / 10) : 4'd0;
    wire [3:0] case_ones = (case_idx < 16) ? (case_idx % 10) : 4'd0;

    // Font ROM lookups for case number
    wire [4:0] bitmap_case_tens, bitmap_case_ones;

    font_rom fr_case_tens (
        .char_code (case_tens),
        .row       (font_row0),
        .bitmap    (bitmap_case_tens)
    );

    font_rom fr_case_ones (
        .char_code (case_ones),
        .row       (font_row1),
        .bitmap    (bitmap_case_ones)
    );

    wire case_pixel = in_case_text && (
        (in_char0 && bitmap_case_tens[font_col0]) ||
        (in_char1 && bitmap_case_ones[font_col1])
    );

    // ?? Money board region ????????????????????????????????????????????????????
    wire [11:0] money_rel_y = vpos - MONEY_Y0;
    wire [4:0]  money_row   = (vpos >= MONEY_Y0) ?
                              (money_rel_y / (MONEY_H + MONEY_GAP)) : 5'd16;
    wire in_money_x = (hpos >= MONEY_X) && (hpos < MONEY_X + MONEY_W);
    wire in_money_y = (money_row < 16) &&
                      (money_rel_y % (MONEY_H + MONEY_GAP) < MONEY_H);
    wire in_money   = in_money_x && in_money_y && (vpos >= MONEY_Y0);

    wire in_money_border = in_money && (
        (money_rel_y % (MONEY_H + MONEY_GAP) < 1) ||
        (money_rel_y % (MONEY_H + MONEY_GAP) >= MONEY_H - 1) ||
        (hpos == MONEY_X) ||
        (hpos == MONEY_X + MONEY_W - 1)
    );

    // ?? Money label text ??????????????????????????????????????????????????????
    // Prize table matching your C# and prize_logic.v
    reg [31:0] prize_table [0:15];
    initial begin
        prize_table[0]  = 32'd1;
        prize_table[1]  = 32'd5;
        prize_table[2]  = 32'd10;
        prize_table[3]  = 32'd25;
        prize_table[4]  = 32'd50;
        prize_table[5]  = 32'd75;
        prize_table[6]  = 32'd100;
        prize_table[7]  = 32'd200;
        prize_table[8]  = 32'd300;
        prize_table[9]  = 32'd400;
        prize_table[10] = 32'd500;
        prize_table[11] = 32'd750;
        prize_table[12] = 32'd1000;
        prize_table[13] = 32'd5000;
        prize_table[14] = 32'd10000;
        prize_table[15] = 32'd100000;
    end

    // Position within current money label
    wire [11:0] mon_box_x = hpos - MONEY_X;
    wire [11:0] mon_box_y = money_rel_y % (MONEY_H + MONEY_GAP);

    // Money label text starts with $ then up to 6 digits
    // Text area: starts at x=8, y=(MONEY_H-CHAR_H/2)/2 centered vertically
    localparam MON_TXT_X = 8;
    localparam MON_TXT_Y = (MONEY_H - CHAR_H / 2) / 2;
    localparam MON_SCALE = 2;   // smaller font for money labels
    localparam MON_CW    = 5 * MON_SCALE;
    localparam MON_CH    = 7 * MON_SCALE;

    wire [11:0] mon_txt_x = mon_box_x - MON_TXT_X;
    wire [11:0] mon_txt_y = mon_box_y - MON_TXT_Y;

    wire in_mon_text_area = in_money && !in_money_border &&
                            (mon_box_x >= MON_TXT_X) &&
                            (mon_box_y >= MON_TXT_Y) &&
                            (mon_box_y <  MON_TXT_Y + MON_CH);

    // Which character position (0=$ 1-6=digits)
    localparam MON_STRIDE = MON_CW + 2;  // 2 pixel gap between characters
    localparam MON_TEXT_W = 7 * MON_STRIDE;
    
    wire in_mon_text_area = in_money && !in_money_border &&
                            (mon_box_x >= MON_TXT_X) &&
                            (mon_box_x <  MON_TXT_X + MON_TEXT_W) &&  // ? hard right edge
                            (mon_box_y >= MON_TXT_Y) &&
                            (mon_box_y <  MON_TXT_Y + MON_CH);
    
    wire [3:0] mon_char_pos = (mon_txt_x < MON_TEXT_W) ?
                               mon_txt_x / MON_STRIDE : 4'd15;  // 15 = out of range
    
    wire [11:0] mon_char_px = mon_txt_x % MON_STRIDE;
    wire in_mon_char = (mon_char_px < MON_CW) &&
                       (mon_char_pos <= 6);

    wire [2:0] mon_font_row = mon_txt_y / MON_SCALE;
    wire [2:0] mon_font_col = (MON_CW - 1 - mon_char_px) / MON_SCALE;

    // Extract digits from the prize value for the current money row
    wire [31:0] mon_prize = (money_row < 16) ? prize_table[money_row] : 32'd0;

    // Decompose prize into up to 6 digits
    wire [3:0] mon_d5 = (mon_prize / 100000) % 10;
    wire [3:0] mon_d4 = (mon_prize / 10000)  % 10;
    wire [3:0] mon_d3 = (mon_prize / 1000)   % 10;
    wire [3:0] mon_d2 = (mon_prize / 100)    % 10;
    wire [3:0] mon_d1 = (mon_prize / 10)     % 10;
    wire [3:0] mon_d0 = (mon_prize)          % 10;

    // Leading zero suppression - find first nonzero digit
    wire show_d5 = (mon_prize >= 100000);
    wire show_d4 = (mon_prize >= 10000);
    wire show_d3 = (mon_prize >= 1000);
    wire show_d2 = (mon_prize >= 100);
    wire show_d1 = (mon_prize >= 10);

    // Map character position to digit code
    // pos 0 = $, pos 1..6 = digits with leading zero suppression
    reg [3:0] mon_char_code;
    reg       mon_char_blank;

    always @(*) begin
        mon_char_blank = 0;
        case (mon_char_pos)
            0: mon_char_code = 4'd10;  // $
            1: begin
                if (show_d5) mon_char_code = mon_d5;
                else         mon_char_blank = 1;
                mon_char_code = show_d5 ? mon_d5 : 4'd0;
            end
            2: begin
                mon_char_code  = show_d4 ? mon_d4 : 4'd0;
                mon_char_blank = !show_d4 && !show_d5;
            end
            3: begin
                mon_char_code  = show_d3 ? mon_d3 : 4'd0;
                mon_char_blank = !show_d3 && !show_d4 && !show_d5;
            end
            4: begin
                mon_char_code  = show_d2 ? mon_d2 : 4'd0;
                mon_char_blank = !show_d2 && !show_d3 && !show_d4 && !show_d5;
            end
            5: begin
                mon_char_code  = show_d1 ? mon_d1 : 4'd0;
                mon_char_blank = !show_d1 && !show_d2 && !show_d3 &&
                                 !show_d4 && !show_d5;
            end
            6: mon_char_code = mon_d0;
            default: begin
                mon_char_code  = 4'd0;
                mon_char_blank = 1;
            end
        endcase
    end

    wire [4:0] mon_bitmap;

    font_rom fr_money (
        .char_code (mon_char_code),
        .row       (mon_font_row),
        .bitmap    (mon_bitmap)
    );

    wire money_pixel = in_mon_text_area && in_mon_char &&
                       !mon_char_blank &&
                       (mon_char_pos <= 6) &&                    // ? add this guard
                       mon_bitmap[mon_font_col];

    // ?? Pixel colour selection ????????????????????????????????????????????????
    reg [11:0] colour;

    always @(*) begin
        if (!active) begin
            colour = COL_BLACK;

        end else if (vpos >= TITLE_Y && vpos < TITLE_Y + TITLE_H) begin
            colour = COL_DARK_BLUE;

        end else if (vpos >= STATUS_Y && vpos < STATUS_Y + STATUS_H) begin
            if (invalid_selection)  colour = COL_DARK_RED;
            else if (valid_selection) colour = COL_DARK_GREEN;
            else                    colour = COL_DARK_BLUE;

        end else if (vpos >= OFFER_Y && vpos < OFFER_Y + OFFER_H) begin
            colour = offer_valid ? COL_GOLD : COL_DARK_BLUE;

        end else if (in_case_box) begin
                if (in_case_border)
                    colour = COL_WHITE;
                else if (player_case_locked && (case_idx[3:0] == player_case))
                    // Player's own locked case - always shown distinctly
                    colour = case_pixel ? COL_WHITE : COL_PLAYER_CASE;
                else if (case_opened[case_idx[3:0]])
                    colour = case_pixel ? COL_WHITE : COL_GRAY;
                else if (case_preview[case_idx[3:0]])
                    colour = case_pixel ? COL_BLACK : COL_GOLD;
                else if (preview_active && case_preview[case_idx[3:0]])
                        colour = case_pixel ? COL_BLACK : COL_GOLD;
                else
                    colour = case_pixel ? COL_WHITE : COL_ROYAL_BLUE;

        end else if (in_money) begin
            if (in_money_border)
                colour = COL_WHITE;
            else if (case_opened[money_row[3:0]])
                colour = money_pixel ? COL_WHITE : COL_DIM_GRAY;
            else
                colour = money_pixel ? COL_WHITE : COL_DARK_BLUE;

        end else begin
            colour = COL_BG;
        end
    end

    // ?? Register output ???????????????????????????????????????????????????????
    always @(posedge pix_clk) begin
        pixel_r <= colour[11:8];
        pixel_g <= colour[7:4];
        pixel_b <= colour[3:0];
    end

endmodule