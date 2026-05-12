`timescale 1ns / 1ps

module top (
    input clk,
    input rst,

    input  [15:0] sw,
    input         case_confirm,

    input         deal_button,
    input         no_deal_button,
    

    output [15:0] LED,
    output [6:0]  seg,
    output [7:0]  an,
    output        dp,

    output        uart_tx_pin,
    output wire        vga_hsync,
    output wire        vga_vsync,
        output wire [3:0]  vga_r,
        output wire [3:0]  vga_g,
        output wire [3:0]  vga_b
);

/* ================= ONE-PULSE BUTTON LOGIC ================= */

reg case_confirm_seen;
reg deal_seen;
reg no_deal_seen;

always @(posedge clk) begin
    if (rst) begin
        case_confirm_seen <= 0;
        deal_seen         <= 0;
        no_deal_seen      <= 0;
    end else begin
        case_confirm_seen <= case_confirm;
        deal_seen         <= deal_button;
        no_deal_seen      <= no_deal_button;
    end
end

wire case_confirm_once = case_confirm && !case_confirm_seen;
wire deal_pulse        = deal_button && !deal_seen;
wire no_deal_pulse     = no_deal_button && !no_deal_seen;

/* ================= FIFO ================= */

wire [15:0] fifo_din;
wire [15:0] fifo_dout;
wire fifo_full, fifo_empty;
wire fifo_wr_en, fifo_rd_en;

assign fifo_din   = {12'd0, sw[3:0]};
assign fifo_wr_en = case_confirm_once && !fifo_full;

fifo_generator_0 u_fifo (
    .clk(clk),
    .srst(rst),
    .din(fifo_din),
    .wr_en(fifo_wr_en),
    .rd_en(fifo_rd_en),
    .dout(fifo_dout),
    .full(fifo_full),
    .empty(fifo_empty)
);

reg [3:0] prev_preview_case;

wire preview_changed;
assign preview_changed = (sw[3:0] != prev_preview_case);

always @(posedge clk) begin
    if (rst)
        prev_preview_case <= 4'd0;
    else
        prev_preview_case <= sw[3:0];
end

/* ================= CASE SELECTOR ================= */

wire [3:0]  current_selected_case;
wire [15:0] available_cases;
wire        valid_selection;
wire        invalid_selection;

wire selector_enable;

case_selector u_case_selector (
    .clk(clk),
    .rst(rst),

    .selector_enable(selector_enable),

    .fifo_dout(fifo_dout),
    .fifo_empty(fifo_empty),
    .fifo_rd_en(fifo_rd_en),

    .current_selected_case(current_selected_case),
    .available_cases(available_cases),

    .valid_selection(valid_selection),
    .invalid_selection(invalid_selection)
);

/* ================= GAME FSM ================= */

wire [3:0] player_case;
wire [3:0] opened_case_count;
wire       player_case_locked;
wire       game_over;
wire       deal_taken;
wire       generate_offer;
wire [3:0] game_state;
wire case_confirmed;
game_fsm u_game_fsm (
    .clk(clk),
    .rst(rst),

    .valid_selection(valid_selection),
    .invalid_selection(invalid_selection),
    .current_selected_case(current_selected_case),
    
    .deal_pulse(deal_pulse),
    .no_deal_pulse(no_deal_pulse),
    .confirm_pulse(case_confirm_once),
    .player_case(player_case),
    .opened_case_count(opened_case_count),
    .player_case_locked(player_case_locked),
    .case_confirmed(case_confirmed),
    .game_over(game_over),
    .deal_taken(deal_taken),
    .generate_offer(generate_offer),

    .state(game_state)
);

/* ================= FSM CONTROL ================= */

assign selector_enable =
    (game_state == 4'd1) || // CHOOSE_PLAYER_CASE
    (game_state == 4'd2);   // OPEN_CASE

/* ================= DISPLAY ================= */

display u_display (
    .clk(clk),
    .rst(rst),
    .current_selected_case(current_selected_case),
    .preview_case(sw[3:0]),
    .seg(seg),
    .an(an),
    .dp(dp)
);

assign LED = available_cases;

/* ================= PRIZE LOGIC ================= */

wire [31:0] opened_case_value;
wire [15:0] remaining_prizes;
wire [31:0] remaining_total;
wire [31:0] remaining_average;

prize_logic u_prize_logic (
    .clk(clk),
    .rst(rst),
    .valid_selection(valid_selection),
    .selected_case(current_selected_case),
    .opened_case_value(opened_case_value),
    .remaining_prizes(remaining_prizes),
    .remaining_total(remaining_total),
    .remaining_average(remaining_average)
);

/* ================= BANK LOGIC ================= */

wire [31:0] banker_offer;
wire offer_valid;

bank_logic u_bank_logic (
    .clk(clk),
    .rst(rst),
    .generate_offer(generate_offer),
    .remaining_average(remaining_average),
    .opened_case_count(opened_case_count),
    .banker_offer(banker_offer),
    .offer_valid(offer_valid)
);
/* ================= UART MESSAGE GENERATOR ================= */

reg [7:0] uart_data_in;
reg       uart_send;
wire      uart_busy;

uart_tx #(
    .CLK_FREQ  (100_000_000),
    .BAUD_RATE (3_000_000)
) u_uart_tx (
    .clk     (clk),
    .rst     (rst),
    .data_in (uart_data_in),
    .send    (uart_send),
    .tx      (uart_tx_pin),
    .busy    (uart_busy)
);

/*
    Message format:
    P06\n = preview case 06
    C06\n = confirmed case 06
    I06\n = invalid case 06
*/


reg [3:0] uart_state;
reg [7:0] msg_cmd;
reg [3:0] msg_case;
reg [3:0] return_state;

wire [3:0] msg_tens;
wire [3:0] msg_ones;
reg [3:0] prev_game_state = 0;
wire game_state_changed = (game_state != prev_game_state);

always @(posedge clk) begin
    if (rst)
        prev_game_state <= 0;
    else
        prev_game_state <= game_state;
end
assign msg_tens = msg_case / 10;
assign msg_ones = msg_case % 10;
localparam UART_IDLE    = 4'd0;
localparam UART_CMD     = 4'd1;
localparam UART_TENS    = 4'd2;
localparam UART_ONES    = 4'd3;
localparam UART_NL      = 4'd4;
localparam UART_WAIT    = 4'd5;
localparam UART_DEAL    = 4'd6;
localparam UART_NODEAL  = 4'd7;
localparam UART_CONFIRM = 4'd8;

// Needs to be 3 bits - already covers 0-7 so no change needed
reg [3:0] confirmed_case;


always @(posedge clk) begin
    if (rst) begin
        uart_state   <= UART_IDLE;
        uart_data_in <= 8'd0;
        uart_send    <= 1'b0;
        msg_cmd      <= 8'd0;
        msg_case     <= 4'd0;
        confirmed_case <= 4'b0;
        
        return_state <= UART_IDLE;
    end else begin
        uart_send <= 1'b0;
        if (valid_selection) begin
            confirmed_case <= current_selected_case;  // ? correct
        end
        case (uart_state)

            UART_IDLE: begin
            if (case_confirm_once) begin
                    msg_cmd <= "C";
                    msg_case   <= confirmed_case;
                    uart_state <= UART_CONFIRM;
            end else if (invalid_selection) begin
                msg_cmd    <= "I";
                msg_case   <= current_selected_case;
                uart_state <= UART_CMD;
            end else if (preview_changed &&
                        (game_state == 4'd1 ||
                         game_state == 4'd2)) begin
                msg_cmd    <= "P";
                msg_case   <= sw[3:0];
                uart_state <= UART_CMD;
            end else if (game_state_changed) begin
                msg_cmd    <= "S";
                msg_case   <= game_state;
                uart_state <= UART_CMD;
            end else if (deal_pulse) begin
                uart_state <= UART_DEAL;
            end else if (no_deal_pulse) begin
                uart_state <= UART_NODEAL;
            end
        end

        UART_CONFIRM: begin
            if (!uart_busy) begin
                uart_data_in <= msg_cmd;
                uart_send    <= 1'b1;
                uart_state   <= UART_WAIT;
                return_state <= UART_TENS;
            end
        end

        UART_CMD: begin
            if (!uart_busy) begin
                uart_data_in <= msg_cmd;
                uart_send    <= 1'b1;
                uart_state   <= UART_WAIT;
                return_state <= UART_TENS;
            end
        end

        UART_TENS: begin
            if (!uart_busy) begin
                uart_data_in <= "0" + msg_tens;
                uart_send    <= 1'b1;
                uart_state   <= UART_WAIT;
                return_state <= UART_ONES;
            end
        end

        UART_ONES: begin
            if (!uart_busy) begin
                uart_data_in <= "0" + msg_ones;
                uart_send    <= 1'b1;
                uart_state   <= UART_WAIT;
                return_state <= UART_NL;
            end
        end

        UART_NL: begin
            if (!uart_busy) begin
                uart_data_in <= 8'h0A;
                uart_send    <= 1'b1;
                uart_state   <= UART_WAIT;
                return_state <= UART_IDLE;
            end
        end

        UART_WAIT: begin
            if (!uart_busy)
                uart_state <= return_state;
        end

        UART_DEAL: begin
            if (!uart_busy) begin
                uart_data_in <= "D";
                uart_send    <= 1'b1;
                uart_state   <= UART_WAIT;
                return_state <= UART_NL;
            end
        end

        UART_NODEAL: begin
            if (!uart_busy) begin
                uart_data_in <= "N";
                uart_send    <= 1'b1;
                uart_state   <= UART_WAIT;
                return_state <= UART_NL;
            end
        end

        default: uart_state <= UART_IDLE;

    endcase
end
end

vga_top #(
    .TEST_PATTERN (0)
) u_vga_top (
    .clk                   (clk),
    .rst                   (rst),
    .available_cases       (available_cases),
    .current_selected_case (current_selected_case),
    .preview_case          (sw[3:0]),
    .valid_selection       (valid_selection),
    .invalid_selection     (invalid_selection),
    .banker_offer          (banker_offer),
    .offer_valid           (offer_valid),
    .opened_case_value     (opened_case_value),
    .remaining_total       (remaining_total),
    .remaining_average     (remaining_average),
    .player_case           (player_case),        
    .player_case_locked    (player_case_locked), 
    .game_state            (game_state),         
    .vga_hsync             (vga_hsync),
    .vga_vsync             (vga_vsync),
    .vga_r                 (vga_r),
    .vga_g                 (vga_g),
    .vga_b                 (vga_b)
);
endmodule