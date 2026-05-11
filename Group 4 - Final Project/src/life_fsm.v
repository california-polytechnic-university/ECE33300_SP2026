module life_fsm(
    input wire clk,
    input wire rst,
    input wire move,              // connect this to frame_tick in top_vga
    input wire [9:0] ball_yloc,

    output reg [2:0] led,
    output wire respawn_ball,
    output reg game_over,
    output wire reset_blocks
);

    localparam DEAD        = 2'd0;
    localparam ONE_LIFE    = 2'd1;
    localparam TWO_LIVES   = 2'd2;
    localparam THREE_LIVES = 2'd3;

    // 100 MHz clock:
    // 100,000,000 cycles is about 1 second.
    localparam [27:0] DEAD_PAUSE_COUNT = 28'd100_000_000;

    // Hold reset long enough to be caught by pixpulse-based modules.
    localparam [21:0] RESET_HOLD_COUNT = 22'd2_000_000;

    reg [1:0] state;
    reg [27:0] dead_counter;
    reg [21:0] respawn_counter;
    reg [21:0] block_reset_counter;
    reg hit_locked;

    wire near_bottom;
    wire bottom_hit;

    assign near_bottom = (ball_yloc >= 10'd474);

    assign bottom_hit = move &&
                        near_bottom &&
                        !hit_locked &&
                        (state != DEAD) &&
                        (respawn_counter == 0);

    assign respawn_ball = (respawn_counter != 0);

    // This resets the blocks, which also resets the score.
    assign reset_blocks = (block_reset_counter != 0);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= THREE_LIVES;
            dead_counter <= 28'd0;
            respawn_counter <= 22'd0;
            block_reset_counter <= 22'd0;
            hit_locked <= 1'b0;
        end else begin

            // Count down reset pulses
            if (respawn_counter != 0)
                respawn_counter <= respawn_counter - 1'b1;

            if (block_reset_counter != 0)
                block_reset_counter <= block_reset_counter - 1'b1;

            // Unlock hit detection after ball resets
            if (ball_yloc < 10'd300)
                hit_locked <= 1'b0;

            // DEAD pause
            if (state == DEAD) begin
                if (dead_counter >= DEAD_PAUSE_COUNT) begin
                    dead_counter <= 28'd0;
                    state <= THREE_LIVES;

                    // Reset ball.
                    respawn_counter <= RESET_HOLD_COUNT;

                    // Reset blocks and therefore score.
                    block_reset_counter <= RESET_HOLD_COUNT;

                    hit_locked <= 1'b1;
                end else begin
                    dead_counter <= dead_counter + 1'b1;
                end
            end

            // Lose lives on bottom wall hit
            else if (bottom_hit) begin
                hit_locked <= 1'b1;

                case (state)

                    THREE_LIVES: begin
                        state <= TWO_LIVES;
                        respawn_counter <= RESET_HOLD_COUNT;
                    end

                    TWO_LIVES: begin
                        state <= ONE_LIFE;
                        respawn_counter <= RESET_HOLD_COUNT;
                    end

                    ONE_LIFE: begin
                        state <= DEAD;
                        dead_counter <= 28'd0;
                    end

                    default: begin
                        state <= THREE_LIVES;
                        respawn_counter <= RESET_HOLD_COUNT;
                        block_reset_counter <= RESET_HOLD_COUNT;
                    end

                endcase
            end
        end
    end

    always @(*) begin
        case (state)

            THREE_LIVES: begin
                led = 3'b111;
                game_over = 1'b0;
            end

            TWO_LIVES: begin
                led = 3'b011;
                game_over = 1'b0;
            end

            ONE_LIFE: begin
                led = 3'b001;
                game_over = 1'b0;
            end

            DEAD: begin
                led = 3'b000;
                game_over = 1'b1;
            end

            default: begin
                led = 3'b111;
                game_over = 1'b0;
            end

        endcase
    end

endmodule
