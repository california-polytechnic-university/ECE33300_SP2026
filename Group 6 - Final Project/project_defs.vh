`ifndef PROJECT_DEFS_VH
`define PROJECT_DEFS_VH

//====================================================
// Global project macros
//====================================================
`define UART_DIV        434
`define UART_BAUD       115200

// UART command bytes stored in FIFO / transmitted back
`define CMD_LEFT        8'h4C   // 'L'
`define CMD_RIGHT       8'h52   // 'R'
`define CMD_STOP        8'h53   // 'S'

// ASCII bytes received from terminal
`define ASCII_A_UPPER   8'h41   // 'A'
`define ASCII_A_LOWER   8'h61   // 'a'
`define ASCII_D_UPPER   8'h44   // 'D'
`define ASCII_D_LOWER   8'h64   // 'd'
`define ASCII_S_UPPER   8'h53   // 'S'
`define ASCII_S_LOWER   8'h73   // 's'
`define ASCII_SPACE     8'h20   // ' '

// Score increment
`define SCORE_INC       4'd5

// Colors (12-bit RGB)
`define COLOR_WALL      12'hFD0
`define COLOR_BAR       12'hFD0
`define COLOR_BALL      12'h0F0
`define COLOR_BG        12'h0A0
`define COLOR_SCORE     12'hFD0
`define COLOR_BLANK     12'h000

// FIFO defaults
`define FIFO_WIDTH      8
`define FIFO_DEPTH      16
`define FIFO_ADDR_W     4

`endif