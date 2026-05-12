`timescale 1ns / 1ps ////////////////////////////////////////////////////////////////////////////////// // Module Name: display // Description: // Overall 8-digit multiplexed 7-segment display file for the Nexys A7. // // Shows two things: // // AN[7:6] = current selected case after FIFO/case_selector // AN[1:0] = preview case from SW[3:0], not pushed into FIFO yet // // Example: // current_selected_case = 4'd3 // preview_case = 4'd12 // // Display looks like: // // 03 12 // // Digit positions: // AN[7] = leftmost digit // AN[6] = second-left digit // AN[1] = second-right digit // AN[0] = rightmost digit // // Nexys A7 7-segment display is active-low: // an = 0 enables a digit // seg = 0 turns on a segment //////////////////////////////////////////////////////////////////////////////////
module display ( input clk, input rst,
input      [3:0] current_selected_case,  // already pushed through FIFO
input      [3:0] preview_case,           // currently on switches

output reg [6:0] seg,
output reg [7:0] an,
output           dp
 
);
assign dp = 1'b1;   // decimal point off

/* ================= DECIMAL CONVERSION ================= */

wire [3:0] selected_tens;
wire [3:0] selected_ones;

wire [3:0] preview_tens;
wire [3:0] preview_ones;

assign selected_tens = current_selected_case / 10;
assign selected_ones = current_selected_case % 10;

assign preview_tens = preview_case / 10;
assign preview_ones = preview_case % 10;

/* ================= REFRESH COUNTER ================= */

reg [19:0] refresh_cnt;

always @(posedge clk) begin
    if (rst)
        refresh_cnt <= 20'd0;
    else
        refresh_cnt <= refresh_cnt + 1'b1;
end

wire [2:0] sel;
assign sel = refresh_cnt[19:17];

/* ================= CURRENT DIGIT ================= */

reg [3:0] cur_digit;
reg       blank_digit;

always @(*) begin
    blank_digit = 1'b0;

    case (sel)
        3'd7: cur_digit = selected_tens; // leftmost selected tens
        3'd6: cur_digit = selected_ones; // left selected ones

        3'd1: cur_digit = preview_tens;  // right preview tens
        3'd0: cur_digit = preview_ones;  // rightmost preview ones

        default: begin
            cur_digit   = 4'd0;
            blank_digit = 1'b1;
        end
    endcase
end

/* ================= ANODE CONTROL ================= */

always @(*) begin
    case (sel)
        3'd0: an = 8'b11111110; // AN[0], rightmost
        3'd1: an = 8'b11111101; // AN[1]
        3'd2: an = 8'b11111011;
        3'd3: an = 8'b11110111;
        3'd4: an = 8'b11101111;
        3'd5: an = 8'b11011111;
        3'd6: an = 8'b10111111; // AN[6]
        3'd7: an = 8'b01111111; // AN[7], leftmost
        default: an = 8'b11111111;
    endcase
end

/* ================= 7-SEGMENT DECODER ================= */

reg [6:0] seg_digit;

always @(*) begin
    case (cur_digit)
        4'd0: seg_digit = 7'b1000000;
        4'd1: seg_digit = 7'b1111001;
        4'd2: seg_digit = 7'b0100100;
        4'd3: seg_digit = 7'b0110000;
        4'd4: seg_digit = 7'b0011001;
        4'd5: seg_digit = 7'b0010010;
        4'd6: seg_digit = 7'b0000010;
        4'd7: seg_digit = 7'b1111000;
        4'd8: seg_digit = 7'b0000000;
        4'd9: seg_digit = 7'b0010000;
        default: seg_digit = 7'b1111111;
    endcase
end

/* ================= OUTPUT SEGMENTS ================= */

always @(*) begin
    if (blank_digit)
        seg = 7'b1111111;
    else
        seg = seg_digit;
end
 
endmodule
