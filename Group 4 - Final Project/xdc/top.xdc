## score_to_7seg_cumulative_uart_nexys_a7.xdc
## Constraints for the cumulative-score UART top_vga module on a Digilent Nexys A7 / Nexys 4 DDR board.
##
## Top-level ports expected by top_vga.v:
##   clk, rst, move_dir[3:0], score_select, uart_rx
##   vgaRed[3:0], vgaGreen[3:0], vgaBlue[3:0], hsync, vsync
##   led[2:0]
##   seg[6:0], an[7:0], dp
##
## Notes:
## - rst is mapped to BTNC and is active-high, matching the Verilog reset input.
## - move_dir is one-hot in paddle.v: {up, right, down, left}.
##   Therefore:
##      move_dir[0] = BTNL = left
##      move_dir[1] = BTND = down
##      move_dir[2] = BTNR = right
##      move_dir[3] = BTNU = up
## - score_select is mapped to SW0:
##      SW0 = 0 shows the current cycle score
##      SW0 = 1 shows the cumulative score
## - led[2:0] shows remaining lives: 111, 011, 001, then 000 during game over.
## - uart_rx is mapped to the board USB-UART receive path from the laptop.
##   In Digilent's master XDC this pin is commonly named UART_TXD_IN because
##   it is the USB bridge TXD signal entering the FPGA.
## - sevenseg_score.v uses active-low segment/anode outputs.
## - seg[6:0] is encoded as {g, f, e, d, c, b, a}, so seg[0] drives CA.

## Clock: 100 MHz board clock
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports { clk }]

## Reset and movement buttons
set_property -dict { PACKAGE_PIN N17 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { rst }]
set_property -dict { PACKAGE_PIN P17 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { move_dir[0] }]
set_property -dict { PACKAGE_PIN P18 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { move_dir[1] }]
set_property -dict { PACKAGE_PIN M17 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { move_dir[2] }]
set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports { move_dir[3] }]

## Score display select switch: SW0
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports { score_select }]


## Life LEDs: LD0-LD2
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports { led[2] }]

## USB-UART receive from laptop/TeraTerm
## TeraTerm settings: 115200 baud, 8 data bits, no parity, 1 stop bit, no flow control.
set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 PULLUP true } [get_ports { uart_rx }]

## VGA connector
set_property -dict { PACKAGE_PIN A3 IOSTANDARD LVCMOS33 } [get_ports { vgaRed[0] }]
set_property -dict { PACKAGE_PIN B4 IOSTANDARD LVCMOS33 } [get_ports { vgaRed[1] }]
set_property -dict { PACKAGE_PIN C5 IOSTANDARD LVCMOS33 } [get_ports { vgaRed[2] }]
set_property -dict { PACKAGE_PIN A4 IOSTANDARD LVCMOS33 } [get_ports { vgaRed[3] }]

set_property -dict { PACKAGE_PIN C6 IOSTANDARD LVCMOS33 } [get_ports { vgaGreen[0] }]
set_property -dict { PACKAGE_PIN A5 IOSTANDARD LVCMOS33 } [get_ports { vgaGreen[1] }]
set_property -dict { PACKAGE_PIN B6 IOSTANDARD LVCMOS33 } [get_ports { vgaGreen[2] }]
set_property -dict { PACKAGE_PIN A6 IOSTANDARD LVCMOS33 } [get_ports { vgaGreen[3] }]

set_property -dict { PACKAGE_PIN B7 IOSTANDARD LVCMOS33 } [get_ports { vgaBlue[0] }]
set_property -dict { PACKAGE_PIN C7 IOSTANDARD LVCMOS33 } [get_ports { vgaBlue[1] }]
set_property -dict { PACKAGE_PIN D7 IOSTANDARD LVCMOS33 } [get_ports { vgaBlue[2] }]
set_property -dict { PACKAGE_PIN D8 IOSTANDARD LVCMOS33 } [get_ports { vgaBlue[3] }]

set_property -dict { PACKAGE_PIN B11 IOSTANDARD LVCMOS33 } [get_ports { hsync }]
set_property -dict { PACKAGE_PIN B12 IOSTANDARD LVCMOS33 } [get_ports { vsync }]

## 7-segment display segments
## top_vga/sevenseg_score port order: seg[6:0] = {g, f, e, d, c, b, a}
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { seg[0] }]
set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports { seg[1] }]
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports { seg[2] }]
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports { seg[3] }]
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports { seg[4] }]
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports { seg[5] }]
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports { seg[6] }]
set_property -dict { PACKAGE_PIN H15 IOSTANDARD LVCMOS33 } [get_ports { dp }]

## 7-segment display digit enables / anodes
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports { an[0] }]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports { an[1] }]
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports { an[2] }]
set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports { an[3] }]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports { an[4] }]
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports { an[5] }]
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports { an[6] }]
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports { an[7] }]
