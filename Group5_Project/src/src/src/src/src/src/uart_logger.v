

module uart_logger(
    input clk,
    input start,
    input win,
    input lose,
    input [1:0] mode,
    input [15:0] reaction_time,
    output tx
);

    reg tx_start = 0;
    reg [7:0] tx_data = 0;
    wire busy;

    uart_tx TX(
        .clk(clk),
        .start(tx_start),
        .data(tx_data),
        .tx(tx),
        .busy(busy)
    );

    reg [7:0] msg [0:63];
    reg [6:0] index = 0;
    reg sending = 0;
    reg old_start = 0;
    reg wait_busy_high = 0;

    wire start_pulse;
    assign start_pulse = start & ~old_start;

    always @(posedge clk) begin
        old_start <= start;
        tx_start <= 0;

        if (start_pulse && !sending) begin

            msg[0]  <= "M";
            msg[1]  <= "O";
            msg[2]  <= "D";
            msg[3]  <= "E";
            msg[4]  <= ":";

            // MODE STRING
            if (mode == 2'd0) begin
                msg[5] <= "E"; msg[6] <= "A"; msg[7] <= "S"; msg[8] <= "Y";
            end else if (mode == 2'd1) begin
                msg[5] <= "N"; msg[6] <= "O"; msg[7] <= "R"; msg[8] <= "M";
            end else begin
                msg[5] <= "H"; msg[6] <= "A"; msg[7] <= "R"; msg[8] <= "D";
            end

            msg[9]  <= " ";
            msg[10] <= "T";
            msg[11] <= "I";
            msg[12] <= "M";
            msg[13] <= "E";
            msg[14] <= ":";

            // reaction time digits (ASCII FIXED)
            msg[15] <= "0" + ((reaction_time / 1000) % 10);
            msg[16] <= "0" + ((reaction_time / 100) % 10);
            msg[17] <= "0" + ((reaction_time / 10) % 10);
            msg[18] <= "0" + (reaction_time % 10);

            msg[19] <= "m";
            msg[20] <= "s";
            msg[21] <= " ";

            msg[22] <= "R";
            msg[23] <= "E";
            msg[24] <= "S";
            msg[25] <= ":";

            if (win) begin
                msg[26] <= "W";
                msg[27] <= "I";
                msg[28] <= "N";
                msg[29] <= "!";
                msg[30] <= 8'h0D;
                msg[31] <= 8'h0A;
                msg[32] <= 8'h00;
            end

            else if (lose) begin
                msg[26] <= "L";
                msg[27] <= "O";
                msg[28] <= "S";
                msg[29] <= "E";
                msg[30] <= 8'h0D;
                msg[31] <= 8'h0A;
                msg[32] <= 8'h00;
            end

            else begin
                msg[26] <= "P";
                msg[27] <= "A";
                msg[28] <= "S";
                msg[29] <= "S";
                msg[30] <= 8'h0D;
                msg[31] <= 8'h0A;
                msg[32] <= 8'h00;
            end

            index <= 0;
            sending <= 1;
            wait_busy_high <= 0;
        end

        else if (sending) begin

            if (!busy && !wait_busy_high) begin

                if (msg[index] != 8'h00) begin
                    tx_data <= msg[index];
                    tx_start <= 1;
                    wait_busy_high <= 1;
                end
                else begin
                    sending <= 0;
                end

            end

            else if (busy && wait_busy_high) begin
                wait_busy_high <= 0;
                index <= index + 1;
            end

        end
    end

endmodule
