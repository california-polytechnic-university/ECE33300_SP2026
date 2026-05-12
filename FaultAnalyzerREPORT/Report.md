# FaultAnalyzer Project Report
### Team Members: Viren Kumar, Tirth Thakkar

Demo Video: [Fault Analyzer](https://www.youtube.com/watch?v=QVP0LqKe_Bc)

# System Description

This project was a student attempt to build an FPGA-based fault analyzer that could use `JTAG` to read an external device ID, compare it to an expected Gowin IDCODE, and show the result through several outputs on the Nexys A7 board. The final design is not perfect, especially in the `JTAG`, `UART`, and `VGA` sections, but it shows a working understanding of how different hardware modules can be connected together into one larger digital system.

# Project Details

The design was built from several smaller IP-style modules and then tied together through a top-level wrapper. The `JTAG` module attempts to generate TCK, drive the TAP controller, send the IDCODE instruction, read TDO, and create an event word. The `StatusReg` module stores the latest scan result, match status, fault flags, and system state. The `SevenSegDecoder` and `TimeMux` modules drive the seven-segment display. The `UartTx` and `UartRx` modules are based on Nandland UART examples, as noted in the code comments and project discussions. The `VGA` module also follows a common Nandland-style VGA timing and counter approach, according to the source comment in the file. These parts are connected in `TopModule`, which acts as the system wrapper and routes control, status, and display signals between the modules. 

## System Block Diagram

![Wiring](https://cdn.discordapp.com/attachments/939267407501996112/1503430144948441278/Screenshot_from_2026-05-11_09-14-23.png?ex=6a0351ee&is=6a02006e&hm=d4cb2e289abc10ccce4403aefebea658fb280c0ece80aa1230bd752a3a1c74fb&)


# Modeling Styles

The binary to bcd converter had the 4 binary to 1 decimal converted  written in gate style logic using the dabble dabble algorithm (Refactored from depreciated Alien counter module). The rest of the code like the UART IP and the JTAG scan with a `FSM` and `FIFO` followed behavioral and structural modeling styles as needed. Overall the scope of the project followed all required instructions. 

## Structural Example
'''verilog
 // Purpose: Control RX state machine 
  always @(posedge i_Clock)
    begin

      case (r_SM_Main)
        s_IDLE :
          begin
            r_Rx_DV       <= 1'b0;
            r_Clock_Count <= 0;
            r_Bit_Index   <= 0;

            if (r_Rx_Data == 1'b0)          // Start bit detected
              r_SM_Main <= s_RX_START_BIT;
            else
              r_SM_Main <= s_IDLE;
          end
'''
As shown in snippet, the structure of the block is outlined as highlighted by always @ to define code function, which in this case is to control a state of the RX state machine. 
lkdsfjkdl;asjfdkalsahdfsklahlfkd
## Dataflow Example
Look at Gate Level Example
## Gate Level Example
Uses assign so its dataflow too, since I am going to double dip examples
'''verilog
    // ge_five = bcd_in >= 5
    assign ge_five = bcd_in[3] | (bcd_in[2] & (bcd_in[1] | bcd_in[0]));

    // Add either 0000 or 0011.
    // Bit 0: bcd_in[0] + ge_five
    assign s0 = bcd_in[0] ^ ge_five;
    assign c1 = bcd_in[0] & ge_five;

    // Bit 1: bcd_in[1] + ge_five + c1
    assign s1 = bcd_in[1] ^ ge_five ^ c1;
    assign c2 = (bcd_in[1] & ge_five) |
                (bcd_in[1] & c1)       |
                (ge_five  & c1);

    // Bit 2: bcd_in[2] + c2
    assign s2 = bcd_in[2] ^ c2;
    assign c3 = bcd_in[2] & c2;

    // Bit 3: bcd_in[3] + c3
    assign s3 = bcd_in[3] ^ c3;
'''
# Goals and IO details

The main goal was to string these pieces together into a working system rather than to create a polished design. A scan starts from pressing switch one, then cycled through either sw 15 or BTNJ, with the bottom button for a reset, the JTAG logic attempts to capture the IDCODE, the result is stored in the status registers, and the outputs present the system state. The LED indicators show basic JTAG and UART states. And the LCD is used to display ID codes. Which are also shown via VGA to another display. 

## Status LEDs
- Indicated the following JTAG and FIFO states: 
    - `LED0`: JTAG scan done 
    - `LED1`: JTAG scan done and id match
    - `LED2`: JTAG scan done and id mismatch
    - `LED3`: FIFO Empty
    - `LED4`: FIFO Full
    - `LED5`: FIFO Overflow
    - `LED6`: FIFO Underflow
    - `LED7`: UART Busy
    - `LED[11:8]`: JTAG State
    - `LED12`: JTAG TCK
    - `LED13`: JTAG TMS
    - `LED14`: JTAG TDI
    - `LED15`: JTAG TDO

## Buttons 
- `BTNC`: cycles through ID codes via FIFO
- `BTJD`: clears id codes

## Switches
- `Switch 0` start Jtag scan, 
- `Switch 14`: cycles through ID codes via FIFO 

## UART
- `uart_txd_o`: transmits scan result after each JTAG event
- `uart_rxd_i`: UART receive input, 

## GPIO

- `jtag_tck_o`: JTAG clock output
- `jtag_tms_o`: JTAG mode-select output
- `jtag_tdi_o`: JTAG data output to target
- `jtag_tdo_i`: JTAG data input from target

## Seven Segment Display

- Shows Gowin ID OPCODE: 32'h0120_681B
- Shows boundary Scan 
- DP is disabled 

## VGA

- Outputs VGA status display
- Resolution timing: `640x480`-style VGA timing
- Pixel clock derived from 100 MHz clock by divide-by-4
  - Effective pixel clock: `25 MHz`
- Shows:
  - scan status header
  - captured IDCODE as large hex digits
  - FIFO empty/full/error status boxes
  - JTAG state bar

Color meaning:

- Blue header: scan busy
- Green header: scan pass
- Red header: scan fail/FULL
- Yellow ID digits: pending / not yet matched
- Green ID digits: matched IDCODE
- Red FIFO error box: FIFO underflow or overflow

# Required Features

a## Finite State Machine (FSM)
- Was utilized in the JTAG module to control the TAP state transitions and sequencing of the scan process. The FSM had states for idle, shifting in instructions, shifting out data, and handling results. It was also used in the UART receiver to manage the reception of bits and detection of start/stop bits. These IPs were determined from external sources ![JTAG](https://github.com/patsaoglou/JTAG-IEEE-1149.1) and Nandland UART examples, as noted in the code comments and project discussions. The modifications that were made to the JTAG FSM were mostly in the state transitions and output logic to fit the specific timing and control needs of our design and through adding bounndry register functions as recommended in Gowin BSDL to perform the scan operation on the hardware. 

## FIFO Explanation
- Used to hold the scans data and page through values to be displayed through 7-seg and VGA in the appropriate bit-widths. Using AMD VIVADO fifo IP of 16 width and 64 depth.

# Verification and Testing Methodology
In the textbench design we used the mother testbench model as described in the previous labs and assignments. However with one core distinction due to the nature of the external JTAG structure we had to use force and release statements to simulate the behavior of the JTAG signals as without the usage of force and release the JTAG signals would not be able to be driven by the testbench. Otherwise all normal features such as tasks were used to then have a main testbehcn that could be run to showcase all tested signals below. 

![TestBench](https://cdn.discordapp.com/attachments/939267407501996112/1503430506463625457/image.png?ex=6a035245&is=6a0200c5&hm=69c055a16cddead30546ca3a339a7f6e0473b18cf2dfcef7259698dffd33126d&)

# Reflections and Future Progress

There are still clear flaws. The JTAG logic is fragile and would need more testing against real TAP behavior and timing. The UART works more like a simple debug message sender than a complete communication interface. The VGA output is ambitious, but pixel-level display logic becomes difficult to maintain and even harder to debug the way it is set up now, especially when also managing JTAG state with an `FSM`, `FIFO` events, UART messages, and display formatting. While the effort and learning gained from this endevour there are clear holes where the design became frustrating and hard to factor.

A better future version could use a softcore processor such as MicroBlaze, PicoRV32, or another small embedded CPU to handle sequencing, messages, display updates, and higher-level control. That would let the FPGA fabric focus on the lower-level timing-sensitive hardware while software handles status formatting and user interaction. The project could also be improved by using SystemVerilog features such as functions, tasks, structs, enums, interfaces, and cleaner state-machine definitions. Those tools would reduce repeated logic and make the design easier to read, debug, and expand.

Overall, FaultAnalyzer is best understood as a successful rough draft. We have managed to have a jtag scan work, now is the next steps on refinement, building out robustness and better data collection, then finally branching out to multiple other sensors on the FPGA before starting to build the error correcting protocol that would ideally use this information. 

