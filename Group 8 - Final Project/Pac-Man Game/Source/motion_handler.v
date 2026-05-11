`timescale 1ns / 1ps


module motion_handler(xpos, ypos, curdir, movdir, validdir, default_pos_x, default_pos_y, clk, rst);
    input  [3:0] movdir, validdir;
    input        clk, rst;
    output [9:0] xpos;
    output [8:0] ypos;
    output [3:0] curdir;
    input  [9:0] default_pos_x;
    input  [8:0] default_pos_y;

    reg [9:0] xpos;
    reg [8:0] ypos;
    reg [3:0] nextdir;
    reg [3:0] curdir;
    reg       phase;

    parameter def_pos_x = 10'd208;
    parameter def_pos_y = 9'd368;

    parameter LEFT  = 4'b0001;
    parameter RIGHT = 4'b0010;
    parameter UP    = 4'b0100;
    parameter DOWN  = 4'b1000;

    localparam [9:0] MAX_X = 10'd432; // col 27 * 16
    localparam [8:0] MAX_Y = 9'd480;  // row 30 * 16
    localparam [4:0] TUNNEL_ROW = 5'd14;

    wire at_tile_center = (xpos[3:0] == 4'b0000) && (ypos[3:0] == 4'b0000);
    wire curdir_valid   = ((curdir & validdir) != 4'b0000);
    wire nextdir_valid  = ((movdir & validdir) != 4'b0000);
    wire on_tunnel_row  = (ypos[8:4] == TUNNEL_ROW);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            xpos    <= def_pos_x;
            ypos    <= def_pos_y;
            nextdir <= 4'b0000;
            curdir  <= 4'b0000;
            phase   <= 1'b0;
        end else begin
            nextdir <= movdir;
            phase   <= ~phase;

            if (!phase) begin
                if ((curdir == LEFT  && movdir == RIGHT) ||
                    (curdir == RIGHT && movdir == LEFT ) ||
                    (curdir == UP    && movdir == DOWN ) ||
                    (curdir == DOWN  && movdir == UP   )) begin
                    curdir <= movdir;
                end else if (at_tile_center) begin
                    if (movdir == 4'b0000)
                        curdir <= 4'b0000;
                    else if (nextdir_valid)
                        curdir <= movdir;
                    else if (!curdir_valid)
                        curdir <= 4'b0000;
                end
            end else begin
                if (!(at_tile_center && !curdir_valid)) begin
                    case (curdir)
                        LEFT: begin
                            if (xpos == 10'd0 && on_tunnel_row)
                                xpos <= MAX_X;
                            else if (xpos != 10'd0)
                                xpos <= xpos - 10'd1;
                        end
                        RIGHT: begin
                            if (xpos == MAX_X && on_tunnel_row)
                                xpos <= 10'd0;
                            else if (xpos != MAX_X)
                                xpos <= xpos + 10'd1;
                        end
                        UP: begin
                            if (ypos != 9'd0)
                                ypos <= ypos - 9'd1;
                        end
                        DOWN: begin
                            if (ypos != MAX_Y)
                                ypos <= ypos + 9'd1;
                        end
                        default: begin
                            xpos <= xpos;
                            ypos <= ypos;
                        end
                    endcase
                end
            end
        end
    end
endmodule
