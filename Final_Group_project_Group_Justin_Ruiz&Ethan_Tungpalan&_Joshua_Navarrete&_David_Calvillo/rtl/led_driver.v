

`include "connect8_defs.vh"

module led_driver (
    input  wire        clk,
    input  wire        rst,
    input  wire        blink_tick,
    input  wire [2:0]  game_state,
    input  wire [15:0] sw_lvl,

    output wire [15:0] led,

    output reg         led16_r,
    output reg         led16_g,
    output reg         led16_b,
    output reg         led17_r,
    output reg         led17_g,
    output reg         led17_b
);

    wire terminal = (game_state == `STATE_WIN_P1) ||
                    (game_state == `STATE_WIN_P2) ||
                    (game_state == `STATE_DRAW);

    reg [15:0] chase_reg;
    always @(posedge clk) begin
        if (rst) begin
            chase_reg <= 16'h0001;
        end else if (blink_tick && terminal) begin
            chase_reg <= {chase_reg[14:0], chase_reg[15]};
        end
    end

    primitives_mux u_mux_lo (
        .a   (sw_lvl[3:0]),
        .b   (chase_reg[3:0]),
        .sel (terminal),
        .y   (led[3:0])
    );
    primitives_mux u_mux_ml (
        .a   (sw_lvl[7:4]),
        .b   (chase_reg[7:4]),
        .sel (terminal),
        .y   (led[7:4])
    );
    primitives_mux u_mux_mh (
        .a   (sw_lvl[11:8]),
        .b   (chase_reg[11:8]),
        .sel (terminal),
        .y   (led[11:8])
    );
    primitives_mux u_mux_hi (
        .a   (sw_lvl[15:12]),
        .b   (chase_reg[15:12]),
        .sel (terminal),
        .y   (led[15:12])
    );

    always @* begin
        led16_r = 1'b0; led16_g = 1'b0; led16_b = 1'b0;
        led17_r = 1'b0; led17_g = 1'b0; led17_b = 1'b0;

        case (game_state)
            `STATE_PLAY_P1: begin
                led16_r = 1'b1;
            end
            `STATE_PLAY_P2: begin
                led17_b = 1'b1;
            end
            `STATE_CHECK: begin

            end
            `STATE_WIN_P1: begin
                led16_r = 1'b1;
            end
            `STATE_WIN_P2: begin
                led17_b = 1'b1;
            end
            `STATE_DRAW: begin
                led16_r = 1'b1; led16_g = 1'b1; led16_b = 1'b1;
                led17_r = 1'b1; led17_g = 1'b1; led17_b = 1'b1;
            end
            default: ;
        endcase
    end

endmodule
