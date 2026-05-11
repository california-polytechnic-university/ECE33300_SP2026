# Group 8 - Final Project

## Project Title
Pacman VGA Game on FPGA

## Project Overview
This project is a Pacman-style game designed for the ECE 3300 final project. The game is implemented using Verilog and displayed through VGA output. The player controls Pacman on the screen while collecting dots and moving through the game map.

## Features
- VGA display output
- Pacman character movement
- Game map/maze display
- Dots that can be collected
- Score tracking
- FPGA hardware implementation

## Files Included
- `Final Project Report.pdf` 
- `block_diagram-pacman.png` - Block diagram of the project
-  source files, constraints, testbench 
## Hardware Used
- Nexys A7 FPGA board
- VGA display/monitor
- Switches or buttons for player control

## How It Works
The FPGA runs the Verilog design that controls the game logic, movement, VGA timing, and graphics. The VGA module displays the maze and Pacman on the monitor. Inputs from the board are used to move Pacman around the screen.

## How to Play
1. Connect the Nexys A7 board to a VGA monitor.
2. Program the FPGA board with the Pacman project bitstream.
3. Use `BTNL`, `BTNR`, `BTNU`, and `BTND` to move Pacman around the maze:
   - `BTNL` moves Pacman left
   - `BTNR` moves Pacman right
   - `BTNU` moves Pacman up
   - `BTND` moves Pacman down
4. Use switches `SW0` to `SW3` to control the speed of Pacman.
5. Move Pacman over the dots to collect them.
6. The score increases as Pacman collects dots.
7. Try to collect as many dots as possible.

## Group Members
Group 8
Karen Heredia 
Marcos Reyes 
