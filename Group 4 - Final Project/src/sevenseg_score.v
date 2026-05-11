// 7-segment score display driver for an active-low, common-anode display
//
// Segment bit order is seg[6:0] = {g, f, e, d, c, b, a}.
// an[0] is the right-most digit. A 0 enables a digit/segment.
//
// This version accepts a 27-bit score and displays up to 8 decimal digits.
// Scores above 99,999,999 are clamped to 99,999,999 because the board has eight 7-segment digits.

module sevenseg_score(
    input  wire        clk,
    input  wire        rst,
    input  wire [26:0] score,
    output reg  [6:0]  seg,
    output reg  [7:0]  an,
    output wire        dp
    );

    localparam [26:0] DISPLAY_MAX = 27'd99999999;

    wire [26:0] score_limited;
    reg  [26:0] score_sampled;
    reg  [26:0] displayed_score;
    reg  [31:0] score_bcd;
    reg  [31:0] bcd_work;
    reg  [31:0] bcd_add3;
    reg  [26:0] binary_shift;
    wire [58:0] shifted_combo;
    reg  [5:0]  convert_count;
    reg         converting;

    reg  [15:0] refresh_count;
    reg  [2:0]  digit_select;
    reg  [3:0]  bcd_digit;
    reg         blank_digit;

    assign score_limited = (score > DISPLAY_MAX) ? DISPLAY_MAX : score;
    assign shifted_combo = {bcd_add3, binary_shift} << 1;

    // Decimal point off. This is active-low on Nexys
    assign dp = 1'b1;

    // One step of the double-dabble add-3 operation. This is kept separate
    // from the shifter so the full binary-to-BCD conversion is spread across
    // 27 clock cycles instead of being one long combinational path.
    always @(*) begin
        bcd_add3 = bcd_work;

        if (bcd_add3[3:0] >= 4'd5)
            bcd_add3[3:0] = bcd_add3[3:0] + 4'd3;
        if (bcd_add3[7:4] >= 4'd5)
            bcd_add3[7:4] = bcd_add3[7:4] + 4'd3;
        if (bcd_add3[11:8] >= 4'd5)
            bcd_add3[11:8] = bcd_add3[11:8] + 4'd3;
        if (bcd_add3[15:12] >= 4'd5)
            bcd_add3[15:12] = bcd_add3[15:12] + 4'd3;
        if (bcd_add3[19:16] >= 4'd5)
            bcd_add3[19:16] = bcd_add3[19:16] + 4'd3;
        if (bcd_add3[23:20] >= 4'd5)
            bcd_add3[23:20] = bcd_add3[23:20] + 4'd3;
        if (bcd_add3[27:24] >= 4'd5)
            bcd_add3[27:24] = bcd_add3[27:24] + 4'd3;
        if (bcd_add3[31:28] >= 4'd5)
            bcd_add3[31:28] = bcd_add3[31:28] + 4'd3;
    end

    // Sequential binary-to-BCD conversion. 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            score_sampled  <= 27'd0;
            displayed_score <= 27'd0;
            score_bcd      <= 32'd0;
            bcd_work       <= 32'd0;
            binary_shift   <= 27'd0;
            convert_count  <= 6'd0;
            converting     <= 1'b0;
        end else begin
            if (!converting) begin
                if (score_limited != score_sampled) begin
                    score_sampled <= score_limited;
                    bcd_work      <= 32'd0;
                    binary_shift  <= score_limited;
                    convert_count <= 6'd0;
                    converting    <= 1'b1;
                end
            end else begin
                {bcd_work, binary_shift} <= shifted_combo;

                if (convert_count == 6'd26) begin
                    score_bcd       <= shifted_combo[58:27];
                    displayed_score <= score_sampled;
                    converting      <= 1'b0;
                end else begin
                    convert_count <= convert_count + 1'b1;
                end
            end
        end
    end

    // Display multiplexing.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            refresh_count <= 16'd0;
            digit_select  <= 3'd0;
        end else begin
            refresh_count <= refresh_count + 1'b1;

            if (refresh_count == 16'hffff)
                digit_select <= digit_select + 1'b1;
        end
    end

    // Drive all eight digits. Leading zeros are blanked, but the ones digit
    // is always shown so that a score of 0 displays as "0".
    always @(*) begin
        an = ~(8'b00000001 << digit_select);
        bcd_digit = 4'd0;
        blank_digit = 1'b0;

        case (digit_select)
            3'd0: begin
                bcd_digit = score_bcd[3:0];
                blank_digit = 1'b0;
            end
            3'd1: begin
                bcd_digit = score_bcd[7:4];
                blank_digit = (displayed_score < 27'd10);
            end
            3'd2: begin
                bcd_digit = score_bcd[11:8];
                blank_digit = (displayed_score < 27'd100);
            end
            3'd3: begin
                bcd_digit = score_bcd[15:12];
                blank_digit = (displayed_score < 27'd1000);
            end
            3'd4: begin
                bcd_digit = score_bcd[19:16];
                blank_digit = (displayed_score < 27'd10000);
            end
            3'd5: begin
                bcd_digit = score_bcd[23:20];
                blank_digit = (displayed_score < 27'd100000);
            end
            3'd6: begin
                bcd_digit = score_bcd[27:24];
                blank_digit = (displayed_score < 27'd1000000);
            end
            3'd7: begin
                bcd_digit = score_bcd[31:28];
                blank_digit = (displayed_score < 27'd10000000);
            end
            default: begin
                bcd_digit = 4'd0;
                blank_digit = 1'b1;
            end
        endcase
    end

    // Active-low segment patterns for seg[6:0] = {g,f,e,d,c,b,a}.
    always @(*) begin
        if (blank_digit) begin
            seg = 7'b1111111;
        end else begin
            case (bcd_digit)
                4'd0: seg = 7'b1000000;
                4'd1: seg = 7'b1111001;
                4'd2: seg = 7'b0100100;
                4'd3: seg = 7'b0110000;
                4'd4: seg = 7'b0011001;
                4'd5: seg = 7'b0010010;
                4'd6: seg = 7'b0000010;
                4'd7: seg = 7'b1111000;
                4'd8: seg = 7'b0000000;
                4'd9: seg = 7'b0010000;
                default: seg = 7'b1111111;
            endcase
        end
    end

endmodule
