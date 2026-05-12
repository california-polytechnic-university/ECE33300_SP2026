    `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2026 11:15:19 PM
// Design Name: 
// Module Name: game_fsm
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

module game_fsm (
input clk,
input rst,

input            valid_selection,
input            invalid_selection,
input      [3:0] current_selected_case,

input            deal_pulse,
input            no_deal_pulse,
input            confirm_pulse,

output reg [3:0] player_case,
output reg [3:0] opened_case_count,
output reg       player_case_locked,
output reg       game_over,
output reg       deal_taken,
output reg      case_confirmed,
output reg       generate_offer,

output reg [3:0] state
);

localparam START              = 4'd0;
localparam CHOOSE_PLAYER_CASE = 4'd1;
localparam OPEN_CASE          = 4'd2;
localparam BANKER_OFFER       = 4'd3;
localparam DEAL_OR_NO_DEAL    = 4'd4;
localparam FINAL_REVEAL       = 4'd5;
localparam GAME_OVER          = 4'd6;
localparam INVALID_CASE       = 4'd7;

localparam [3:0] MAX_OPENED_CASES = 4'd15;
localparam [3:0] OFFER_INTERVAL   = 4'd3;

always @(posedge clk) begin
    if (rst) begin
        state              <= START;
        player_case        <= 4'd0;
        opened_case_count  <= 4'd0;
        player_case_locked <= 1'b0;
        game_over          <= 1'b0;
        deal_taken         <= 1'b0;
        generate_offer     <= 1'b0;
        case_confirmed <= 1'b0;
    end else begin

        generate_offer <= 1'b0;

        case (state)

            START: begin
                player_case        <= 4'd0;
                opened_case_count  <= 4'd0;
                player_case_locked <= 1'b0;
                game_over          <= 1'b0;
                deal_taken         <= 1'b0;
                case_confirmed <= 1'b0;
                state              <= CHOOSE_PLAYER_CASE;
            end

            CHOOSE_PLAYER_CASE: begin
                if (invalid_selection) begin
                    state <= INVALID_CASE;
                end else if (valid_selection) begin
                    player_case        <= current_selected_case;
                    player_case_locked <= 1'b1;
                    state              <= OPEN_CASE;
                end
            end

            OPEN_CASE: begin
                if (invalid_selection) begin
                    state <= INVALID_CASE;
                end else if (valid_selection && case_confirmed) begin
                    opened_case_count <= opened_case_count + 1'b1;
                    if ((opened_case_count + 1'b1) >= MAX_OPENED_CASES) begin
                        state <= FINAL_REVEAL;
                    end else if (((opened_case_count + 1'b1) % OFFER_INTERVAL) == 0) begin
                        state <= BANKER_OFFER;
                    end else begin
                        state <= OPEN_CASE;
                    end
                end
            end

            BANKER_OFFER: begin
                generate_offer <= 1'b1;
                case_confirmed <= 1'b0;
                state          <= DEAL_OR_NO_DEAL;
            end

            DEAL_OR_NO_DEAL: begin
                if (deal_pulse) begin
                    deal_taken <= 1'b1;
                    game_over  <= 1'b1;
                    state      <= GAME_OVER;
                end else if (no_deal_pulse) begin
                    deal_taken <= 1'b0;
                    state <= OPEN_CASE;
                end else if (confirm_pulse) begin
                    case_confirmed <= 1'b1;
                    state <= OPEN_CASE;
                    end
            end

            FINAL_REVEAL: begin
                game_over <= 1'b1;
                state     <= GAME_OVER;
            end

            GAME_OVER: begin
                game_over <= 1'b1;
                state     <= GAME_OVER;
            end

            INVALID_CASE: begin
                if (!player_case_locked)
                    state <= CHOOSE_PLAYER_CASE;
                else
                    state <= OPEN_CASE;
            end

            default: begin
                state <= START;
            end

        endcase
    end
end

endmodule
