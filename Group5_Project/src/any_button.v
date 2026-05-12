`timescale 1ns/1ps

module any_button(
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    input btnC,
    output any_button
);

wire w1, w2, w3;

or g1(w1, btnU, btnD);
or g2(w2, btnL, btnR);
or g3(w3, w1, w2);
or g4(any_button, w3, btnC);

endmodule
