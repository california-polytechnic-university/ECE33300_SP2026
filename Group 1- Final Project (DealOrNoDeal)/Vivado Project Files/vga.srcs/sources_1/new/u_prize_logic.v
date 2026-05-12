`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: prize_logic
//
// Description: assigns money value to cases
//
//////////////////////////////////////////////////////////////////////////////////

module prize_logic (
    input              clk,
    input              rst,
    input              valid_selection,
    input      [3:0]   selected_case,

    output reg [31:0]  opened_case_value,
    output reg [15:0]  remaining_prizes,
    output reg [31:0]  remaining_total,
    output reg [31:0]  remaining_average
);

    reg [31:0] prize_table [0:15];

    initial begin
        prize_table[0]  = 1;
        prize_table[1]  = 5;
        prize_table[2]  = 10;
        prize_table[3]  = 25;
        prize_table[4]  = 50;
        prize_table[5]  = 75;
        prize_table[6]  = 100;
        prize_table[7]  = 200;
        prize_table[8]  = 300;
        prize_table[9]  = 400;
        prize_table[10] = 500;
        prize_table[11] = 750;
        prize_table[12] = 1000;
        prize_table[13] = 5000;
        prize_table[14] = 10000;
        prize_table[15] = 100000;
    end

    integer i;

    reg [31:0] temp_total;
    reg [4:0]  temp_count;

    always @(posedge clk) begin
        if (rst) begin

            opened_case_value <= 32'd0;

            remaining_prizes <= 16'hFFFF;
            remaining_total <= 32'd117416;
            remaining_average <= 32'd7338;

        end else begin

            if (valid_selection) begin

                opened_case_value <= prize_table[selected_case];

                remaining_prizes[selected_case] <= 1'b0;

                temp_total = 0;
                temp_count = 0;

                for (i = 0; i < 16; i = i + 1) begin

                    if ((remaining_prizes[i] && (i != selected_case))) begin
                        temp_total = temp_total + prize_table[i];
                        temp_count = temp_count + 1'b1;
                    end

                end

                remaining_total <= temp_total;

                if (temp_count != 0)
                    remaining_average <= temp_total / temp_count;
                else
                    remaining_average <= 32'd0;

            end
        end
    end

endmodule
