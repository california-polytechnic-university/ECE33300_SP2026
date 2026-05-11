

module top(
    input CLK100MHZ,
    input [11:0] SW,

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

    wire btnU;
    wire btnD;
    wire btnL;
    wire btnR;
    wire btnC;

    debounce db_u(.clk(CLK100MHZ), .noisy(BTNU), .clean(btnU));
    debounce db_d(.clk(CLK100MHZ), .noisy(BTND), .clean(btnD));
    debounce db_l(.clk(CLK100MHZ), .noisy(BTNL), .clean(btnL));
    debounce db_r(.clk(CLK100MHZ), .noisy(BTNR), .clean(btnR));
    debounce db_c(.clk(CLK100MHZ), .noisy(BTNC), .clean(btnC));

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