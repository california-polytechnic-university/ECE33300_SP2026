`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: bank_logic
//
// Description: Calculates the amount offered to player
//
//////////////////////////////////////////////////////////////////////////////////

module bank_logic (
    input             clk,
    input             rst,
    input             generate_offer,
    input      [31:0] remaining_average,
    input      [3:0]  opened_case_count,

    output reg [31:0] banker_offer,

    output reg        offer_valid
);

    reg [7:0] risk_percent;

    always @(*) begin

        if (opened_case_count < 4)
            risk_percent = 8'd45;

        else if (opened_case_count < 8)
            risk_percent = 8'd65;

        else if (opened_case_count < 12)
            risk_percent = 8'd80;

        else
            risk_percent = 8'd95;

    end

    always @(posedge clk) begin
        if (rst) begin

            banker_offer <= 32'd0;
            offer_valid  <= 1'b0;

        end else begin

            offer_valid <= 1'b0;

            if (generate_offer) begin

                banker_offer <=
                    (remaining_average * risk_percent) / 100;

                offer_valid <= 1'b1;

            end
        end
    end

endmodule
