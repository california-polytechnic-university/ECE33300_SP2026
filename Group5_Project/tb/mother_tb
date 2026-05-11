`timescale 1ns/1ps

module mother_tb;

    reg clk;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    reg  [15:0] sw;
    reg         btnU, btnD, btnL, btnR, btnC;

    wire [15:0] led;
    wire [15:0] reaction_time;
    wire [3:0]  game_state;
    wire [2:0]  direction;
    wire        win;
    wire        lose;
    wire        log_start;
    wire [1:0]  mode;
    wire [3:0]  round_count;
    wire        wrong_flash;

    game_fsm u_game_fsm (
        .clk(clk),
        .sw(sw),

        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .btnC(btnC),

        .led(led),
        .reaction_time(reaction_time),
        .game_state(game_state),
        .direction(direction),
        .win(win),
        .lose(lose),
        .log_start(log_start),
        .mode(mode),
        .round_count(round_count),
        .wrong_flash(wrong_flash)
    );

    initial begin
        sw = 0;
        btnU = 0;
        btnD = 0;
        btnL = 0;
        btnR = 0;
        btnC = 0;
    end

    task press_correct_button;
        begin
            case (direction)
                3'd0: btnU = 1;
                3'd1: btnD = 1;
                3'd2: btnL = 1;
                3'd3: btnR = 1;
                3'd4: btnC = 1;
            endcase

            repeat (2) @(posedge clk);

            btnU = 0;
            btnD = 0;
            btnL = 0;
            btnR = 0;
            btnC = 0;
        end
    endtask

    initial begin

        sw[0] = 1;
        repeat (5) @(posedge clk);
        sw[0] = 0;

        repeat (10) @(posedge clk);

        repeat (5) begin

            wait (game_state == 4'd2);

            repeat (3) @(posedge clk);

            press_correct_button;

            repeat (20) @(posedge clk);

        end

        wait (game_state == 4'd2);
        btnL = 1; 
        repeat (2) @(posedge clk);
        btnL = 0;

        repeat (20) @(posedge clk);

        $finish;
    end

endmodule
