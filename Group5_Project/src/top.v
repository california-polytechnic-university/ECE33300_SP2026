`include "project_defs.v"

module top(
    input CLK100MHZ,
    input [15:0] SW,

    input BTNU,
    input BTND,
    input BTNL,
    input BTNR,
    input BTNC,

    output [15:0] LED,

    output [6:0] SEG,
    output DP,
    output [7:0] AN,

    output UART_TX,

    output Hsync,
    output Vsync,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue
);

    wire [4:0] btn_noisy;
    wire [4:0] btn_clean;

    assign btn_noisy = {BTNC, BTNR, BTNL, BTND, BTNU};

    genvar i;
    generate
        for (i = 0; i < 5; i = i + 1) begin : DEBOUNCE_GEN
            debounce db_inst(
                .clk(CLK100MHZ),
                .noisy(btn_noisy[i]),
                .clean(btn_clean[i])
            );
        end
    endgenerate

    wire btnU;
    wire btnD;
    wire btnL;
    wire btnR;
    wire btnC;

    assign btnU = btn_clean[`BTN_U_IDX];
    assign btnD = btn_clean[`BTN_D_IDX];
    assign btnL = btn_clean[`BTN_L_IDX];
    assign btnR = btn_clean[`BTN_R_IDX];
    assign btnC = btn_clean[`BTN_C_IDX];

    wire [15:0] reaction_time;
    wire [3:0] game_state;
    wire [2:0] direction;
    wire win;
    wire lose;
    wire log_start;
    wire [1:0] mode;
    wire [3:0] round_count;
    wire wrong_flash;

    game_fsm game(
        .clk(CLK100MHZ),
        .sw(SW),

        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .btnC(btnC),

        .led(LED),
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

    wire [19:0] fifo_data_in;
    wire [19:0] fifo_data_out;
    wire fifo_full;
    wire fifo_empty;

    assign fifo_data_in = {win, lose, mode, reaction_time};

    simple_fifo #(
        .DATA_WIDTH(20),
        .DEPTH(8)
    ) result_fifo (
        .clk(CLK100MHZ),
        .reset(SW[0]),
        .wr_en(log_start),
        .rd_en(1'b0),
        .din(fifo_data_in),
        .dout(fifo_data_out),
        .full(fifo_full),
        .empty(fifo_empty)
    );

    sevenseg_driver display(
        .clk(CLK100MHZ),
        .number(reaction_time),
        .SEG(SEG),
        .AN(AN),
        .DP(DP)
    );

    uart_logger logger(
        .clk(CLK100MHZ),
        .start(log_start),
        .win(win),
        .lose(lose),
        .mode(mode),
        .reaction_time(reaction_time),
        .tx(UART_TX)
    );

    vga_simple vga(
        .clk(CLK100MHZ),
        .game_state(game_state),
        .direction(direction),

        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .btnC(btnC),

        .win(win),
        .lose(lose),
        .wrong_flash(wrong_flash),

        .Hsync(Hsync),
        .Vsync(Vsync),
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue)
    );

endmodule