

`ifndef CONNECT8_DEFS_VH
`define CONNECT8_DEFS_VH

`define BOARD_COLS       8
`define BOARD_ROWS       8
`define WIN_STREAK       4

`define CELL_EMPTY       2'b00
`define CELL_P1          2'b01
`define CELL_P2          2'b10

`define P1               1'b0
`define P2               1'b1

`define SYS_CLK_HZ       100_000_000

`define VGA_H_VISIBLE    640
`define VGA_H_FRONT      16
`define VGA_H_SYNC       96
`define VGA_H_BACK       48
`define VGA_H_TOTAL      800

`define VGA_V_VISIBLE    480
`define VGA_V_FRONT      10
`define VGA_V_SYNC       2
`define VGA_V_BACK       33
`define VGA_V_TOTAL      525

`define UART_BAUD        9600

`define STATE_PLAY_P1    3'd0
`define STATE_PLAY_P2    3'd1
`define STATE_CHECK      3'd2
`define STATE_WIN_P1     3'd3
`define STATE_WIN_P2     3'd4
`define STATE_DRAW       3'd5
`define STATE_COMMIT     3'd6

`endif
