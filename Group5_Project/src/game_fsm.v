module game_fsm(
    input clk,
    input [15:0] sw,
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    input btnC,

    output reg [15:0] led,
    output reg [15:0] reaction_time,
    output reg [3:0] game_state,
    output reg [2:0] direction,
    output reg win,
    output reg lose,
    output reg log_start,
    output reg [1:0] mode,
    output reg [3:0] round_count,
    output reg wrong_flash
);

    localparam IDLE       = 4'd0;
    localparam WAIT_STATE = 4'd1;
    localparam GO_STATE   = 4'd2;
    localparam ROUND_WIN  = 4'd3;
    localparam LOSE_STATE = 4'd4;
    localparam RESULT     = 4'd5;
    localparam NEXT_ROUND = 4'd6;

    reg [31:0] ms_counter = 0;
    reg ms_tick = 0;

    reg [31:0] wait_counter = 0;
    reg [31:0] wait_limit = 0;
    reg [15:0] time_limit = 0;
    reg [15:0] result_counter = 0;

    reg [15:0] lfsr = 16'hACE1;

    // =====================================================
    // RESET SIGNAL
    // =====================================================

    wire reset_game;
    assign reset_game = sw[0];

    // =====================================================
    // GATE-LEVEL ANY BUTTON LOGIC
    // =====================================================

    wire any_button;

    wire or1_out;
    wire or2_out;
    wire or3_out;

    or g1(or1_out, btnU, btnD);
    or g2(or2_out, btnL, btnR);
    or g3(or3_out, or1_out, or2_out);
    or g4(any_button, or3_out, btnC);

    // =====================================================
    // CORRECT BUTTON LOGIC
    // =====================================================

    wire correct_button;

    assign correct_button =
        (direction == 3'd0 && btnU) ||
        (direction == 3'd1 && btnD) ||
        (direction == 3'd2 && btnL) ||
        (direction == 3'd3 && btnR) ||
        (direction == 3'd4 && btnC);

    // =====================================================
    // WRONG BUTTON LOGIC
    // =====================================================

    wire wrong_button;
    assign wrong_button = any_button && !correct_button;

    // =====================================================
    // RANDOM DIRECTION
    // =====================================================

    wire [2:0] random_direction;

    assign random_direction =
        (lfsr[2:0] > 3'd4) ?
        (lfsr[2:0] - 3'd3) :
        lfsr[2:0];

    // =====================================================
    // CLOCK + LFSR
    // =====================================================

    always @(posedge clk) begin

        lfsr <= {
            lfsr[14:0],
            lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]
        };

        if (ms_counter == 100000 - 1) begin
            ms_counter <= 0;
            ms_tick <= 1;
        end
        else begin
            ms_counter <= ms_counter + 1;
            ms_tick <= 0;
        end
    end

    // =====================================================
    // MODE SELECT
    // =====================================================

    always @(*) begin

        mode = 2'd1;
        time_limit = 16'd1500;

        // HARD MODE
        if (sw[1]) begin
            mode = 2'd2;
            time_limit = 16'd500;
        end
        else if (sw[2]) begin
            mode = 2'd2;
            time_limit = 16'd700;
        end
        else if (sw[3]) begin
            mode = 2'd2;
            time_limit = 16'd900;
        end
        else if (sw[4]) begin
            mode = 2'd2;
            time_limit = 16'd1100;
        end
        else if (sw[5]) begin
            mode = 2'd2;
            time_limit = 16'd1300;
        end

        // NORMAL MODE
        else if (sw[6]) begin
            mode = 2'd1;
            time_limit = 16'd1500;
        end
        else if (sw[7]) begin
            mode = 2'd1;
            time_limit = 16'd1700;
        end
        else if (sw[8]) begin
            mode = 2'd1;
            time_limit = 16'd1900;
        end
        else if (sw[9]) begin
            mode = 2'd1;
            time_limit = 16'd2100;
        end
        else if (sw[10]) begin
            mode = 2'd1;
            time_limit = 16'd2300;
        end

        // EASY MODE
        else if (sw[11]) begin
            mode = 2'd0;
            time_limit = 16'd2500;
        end
        else if (sw[12]) begin
            mode = 2'd0;
            time_limit = 16'd2700;
        end else if (sw[13]) begin
            mode = 2'd0;
            time_limit = 16'd2900;
        end else if (sw[14]) begin
            mode = 2'd0;
            time_limit = 16'd3100;
        end else if (sw[15]) begin
            mode = 2'd0;
            time_limit = 16'd3300;
        end
    end

    // =====================================================
    // INITIAL VALUES
    // =====================================================

    initial begin
        game_state = IDLE;
        led = 16'h0000;
        reaction_time = 0;
        direction = 0;
        win = 0;
        lose = 0;
        log_start = 0;
        round_count = 0;
        wrong_flash = 0;
    end

    // =====================================================
    // MAIN FSM
    // =====================================================

    always @(posedge clk) begin

        log_start <= 0;

        if (reset_game) begin

            game_state <= IDLE;
            led <= 16'h0000;
            reaction_time <= 0;
            direction <= 0;
            win <= 0;
            lose <= 0;
            log_start <= 0;
            round_count <= 0;
            wrong_flash <= 0;
            wait_counter <= 0;
            result_counter <= 0;

        end
        else begin

            case (game_state)

                // =================================================
                // IDLE
                // =================================================

                IDLE: begin

                    led <= 16'h0000;
                    reaction_time <= 0;
                    win <= 0;
                    lose <= 0;
                    wrong_flash <= 0;
                    wait_counter <= 0;
                    result_counter <= 0;
                    round_count <= 0;

                    direction <= random_direction;
                    wait_limit <= 16'd800 + lfsr[9:0];

                    game_state <= WAIT_STATE;
                end

                // =================================================
                // WAIT STATE
                // =================================================

                WAIT_STATE: begin

                    led <= 16'h0000;
                    win <= 0;
                    lose <= 0;
                    wrong_flash <= 0;

                    if (any_button) begin

                        win <= 0;
                        lose <= 1;
                        wrong_flash <= 1;

                        game_state <= LOSE_STATE;
                    end

                    else if (ms_tick) begin

                        if (wait_counter >= wait_limit) begin

                            reaction_time <= 0;
                            game_state <= GO_STATE;

                        end
                        else begin
                            wait_counter <= wait_counter + 1;
                        end
                    end
                end

                // =================================================
                // GO STATE
                // =================================================

                GO_STATE: begin

                    if (ms_tick) begin
                        reaction_time <= reaction_time + 1;
                    end

                    if (correct_button) begin

                        round_count <= round_count + 1;

                        if (round_count == 4'd9) begin
                            win <= 1;
                            lose <= 0;
                        end
                        else begin
                            win <= 0;
                            lose <= 0;
                        end

                        wrong_flash <= 0;

                        game_state <= ROUND_WIN;
                    end

                    else if (wrong_button) begin

                        win <= 0;
                        lose <= 1;
                        wrong_flash <= 1;

                        game_state <= LOSE_STATE;
                    end

                    else if (reaction_time >= time_limit) begin

                        win <= 0;
                        lose <= 1;
                        wrong_flash <= 1;

                        game_state <= LOSE_STATE;
                    end
                end

                // =================================================
                // ROUND WIN
                // =================================================

                ROUND_WIN: begin

                    led <= 16'hFFFF;
                    log_start <= 1;

                    if (round_count >= 4'd10) begin

                        win <= 1;
                        lose <= 0;
                        wrong_flash <= 0;

                        game_state <= RESULT;
                    end

                    else begin

                        result_counter <= 0;
                        game_state <= NEXT_ROUND;
                    end
                end

                // =================================================
                // NEXT ROUND
                // =================================================

                NEXT_ROUND: begin

                    led <= 16'hFFFF;

                    if (ms_tick) begin

                        if (result_counter >= 16'd500) begin

                            led <= 16'h0000;
                            reaction_time <= 0;
                            wait_counter <= 0;
                            result_counter <= 0;

                            win <= 0;
                            lose <= 0;
                            wrong_flash <= 0;

                            direction <= random_direction;
                            wait_limit <= 16'd800 + lfsr[9:0];

                            game_state <= WAIT_STATE;
                        end

                        else begin
                            result_counter <= result_counter + 1;
                        end
                    end
                end

                // =================================================
                // LOSE STATE
                // =================================================

                LOSE_STATE: begin

                    led <= 16'h0000;

                    win <= 0;
                    lose <= 1;
                    wrong_flash <= 1;

                    log_start <= 1;

                    game_state <= RESULT;
                end

                // =================================================
                // RESULT
                // =================================================

                RESULT: begin

                    if (win) begin

                        led <= 16'hFFFF;
                        wrong_flash <= 0;

                    end
                    else begin

                        led <= 16'h0000;
                        wrong_flash <= 1;
                    end
                end

                // =================================================
                // DEFAULT
                // =================================================

                default: begin
                    game_state <= IDLE;
                end

            endcase
        end
    end

endmodule