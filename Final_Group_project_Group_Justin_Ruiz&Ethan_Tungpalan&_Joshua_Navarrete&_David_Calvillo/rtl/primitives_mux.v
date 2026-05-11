

module primitives_mux (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       sel,
    output wire [3:0] y
);

    wire sel_n;
    wire [3:0] a_gated;
    wire [3:0] b_gated;

    not u_inv  (sel_n, sel);

    and u_a0   (a_gated[0], a[0], sel_n);
    and u_a1   (a_gated[1], a[1], sel_n);
    and u_a2   (a_gated[2], a[2], sel_n);
    and u_a3   (a_gated[3], a[3], sel_n);

    and u_b0   (b_gated[0], b[0], sel);
    and u_b1   (b_gated[1], b[1], sel);
    and u_b2   (b_gated[2], b[2], sel);
    and u_b3   (b_gated[3], b[3], sel);

    or  u_y0   (y[0], a_gated[0], b_gated[0]);
    or  u_y1   (y[1], a_gated[1], b_gated[1]);
    or  u_y2   (y[2], a_gated[2], b_gated[2]);
    or  u_y3   (y[3], a_gated[3], b_gated[3]);

endmodule
