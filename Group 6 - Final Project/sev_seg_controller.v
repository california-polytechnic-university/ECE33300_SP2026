`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2026 12:34:57 PM
// Design Name: 
// Module Name: sev_seg_controller
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


module seven_seg_controller(
    input clk,              
    input reset,
    input [31:0] bcd_count,     
    output  [7:0] an,    
    output  [7:0] seg        
);
reg [7:0]  an_tmp;
reg [7:0]  seg_tmp;

   
    reg [16:0] refresh_cnt;

    always @(posedge clk or posedge reset) begin
        if (reset)
            refresh_cnt <= 16'd0;
        else
            refresh_cnt <= refresh_cnt + 1;
    end

    // Top 3 bits pick which of the 8 digits to show right now
   wire [2:0] digit_sel = refresh_cnt[16:14];
    reg [3:0] digit_val; // the BCD value of the selected digit

    // Anode and digit mux
    always @(digit_sel or bcd_count) begin
        case (digit_sel)
            3'd0: begin an_tmp = 8'b11111110; digit_val = bcd_count[3:0];   end // ones
            3'd1: begin an_tmp = 8'b11111101; digit_val = bcd_count[7:4];   end // tens
            3'd2: begin an_tmp = 8'b11111011; digit_val = bcd_count[11:8];  end // hundreds
            3'd3: begin an_tmp = 8'b11110111; digit_val = bcd_count[15:12]; end // thousands
            3'd4: begin an_tmp = 8'b11101111; digit_val = bcd_count[19:16]; end // ten-thousands
            3'd5: begin an_tmp = 8'b11011111; digit_val = bcd_count[23:20]; end // hundred-thousands
            3'd6: begin an_tmp = 8'b10111111; digit_val = bcd_count[27:24]; end // millions
            3'd7: begin an_tmp = 8'b01111111; digit_val = bcd_count[31:28]; end // ten-millions
            default: begin an_tmp = 8'b11111111; digit_val = 4'h0; end
        endcase
    end
 assign an = an_tmp;
  
    
            
 
 always @(digit_val) begin
        case (digit_val)
            4'h0: seg_tmp = 8'b11000000;
            4'h1: seg_tmp = 8'b11111001;
            4'h2: seg_tmp = 8'b10100100;
            4'h3: seg_tmp = 8'b10110000;
            4'h4: seg_tmp = 8'b10011001;
            4'h5: seg_tmp = 8'b10010010;
            4'h6: seg_tmp = 8'b10000010;
            4'h7: seg_tmp= 8'b11111000;
            4'h8: seg_tmp = 8'b10000000;
            4'h9: seg_tmp = 8'b10010000;
            default: seg_tmp = 8'b11111111;
        endcase
    end
            assign seg = seg_tmp;

endmodule