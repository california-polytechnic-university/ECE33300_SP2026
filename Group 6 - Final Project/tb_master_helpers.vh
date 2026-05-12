
//====================================================
// Common DUT signals, tasks, and checks for tb_master_pong
// Include THIS FILE INSIDE the tb_master_pong module.
//====================================================

reg         clk;
reg         reset_clk;
reg         reset;
reg  [1:0]  btn;
reg         btn_pause;
reg         uart_rx;

wire        uart_tx;
wire        hsync;
wire        vsync;
wire [6:0]  LED;
wire [11:0] rgb;
wire [7:0]  an;
wire [7:0]  seg;
wire        light;
wire        lights;
wire        LED16_R;
wire        LED16_G;
wire        LED16_B;
wire        LED17_R;
wire        LED17_G;
wire        LED17_B;

//====================================================
// Generic wait task
//====================================================
task automatic wait_clks;
    input integer num_clks;
    integer i;
    begin
        for (i = 0; i < num_clks; i = i + 1)
            @(posedge clk);
    end
endtask

//====================================================
// Initial startup reset task
//====================================================
task automatic apply_reset;
    begin
        reset     = 1'b1;
        reset_clk = 1'b1;
        btn       = 2'b00;
        btn_pause = 1'b0;
        uart_rx   = 1'b1;

        wait_clks(8);
        reset_clk = 1'b0;
        wait_clks(8);
        reset     = 1'b0;
        wait_clks(8);
    end
endtask

//====================================================
// Runtime pulse of global reset
//====================================================
task automatic pulse_global_reset;
    begin
        @(negedge clk);
        reset = 1'b1;
        wait_clks(6);
        @(negedge clk);
        reset = 1'b0;
        wait_clks(12);
    end
endtask

//====================================================
// Runtime pulse of clock-divider reset
//====================================================
task automatic pulse_reset_clk_only;
    begin
        @(negedge clk);
        reset_clk = 1'b1;
        wait_clks(6);
        @(negedge clk);
        reset_clk = 1'b0;
        wait_clks(12);
    end
endtask

//====================================================
// Pause button pulse
//====================================================
task automatic pulse_pause_button;
    begin
        @(negedge clk);
        btn_pause = 1'b1;
        wait_clks(4);
        @(negedge clk);
        btn_pause = 1'b0;
        wait_clks(40);   // allow synchronizer / edge detect to settle
    end
endtask

//====================================================
// Physical button stimuli
//====================================================
task automatic press_btn_left;
    input integer hold_clks;
    begin
        @(negedge clk);
        btn[0] = 1'b1;
        wait_clks(hold_clks);
        @(negedge clk);
        btn[0] = 1'b0;
        wait_clks(8);
    end
endtask

task automatic press_btn_right;
    input integer hold_clks;
    begin
        @(negedge clk);
        btn[1] = 1'b1;
        wait_clks(hold_clks);
        @(negedge clk);
        btn[1] = 1'b0;
        wait_clks(8);
    end
endtask

//====================================================
// UART byte sender (8N1)
//====================================================
task automatic send_uart_byte;
    input [7:0] data;
    integer bit_idx;
    begin
        uart_rx = 1'b1;
        wait_clks(`UART_DIV);

        // start bit
        uart_rx = 1'b0;
        wait_clks(`UART_DIV);

        // data bits LSB first
        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            uart_rx = data[bit_idx];
            wait_clks(`UART_DIV);
        end

        // stop bit
        uart_rx = 1'b1;
        wait_clks(`UART_DIV);

        // inter-byte gap
        wait_clks(`UART_DIV);
    end
endtask

task automatic send_left_cmd;
    begin
        send_uart_byte(`ASCII_A_UPPER);
    end
endtask

task automatic send_right_cmd;
    begin
        send_uart_byte(`ASCII_D_UPPER);
    end
endtask

task automatic send_stop_cmd;
    begin
        send_uart_byte(`ASCII_S_UPPER);
    end
endtask

//====================================================
// Score event injection tasks
//====================================================
task automatic inject_paddle_hit;
    begin
        force dut.paddle_hit_pulse = 1'b1;
        wait_clks(2);
        release dut.paddle_hit_pulse;
        wait_clks(4);
    end
endtask

task automatic inject_miss;
    begin
        force dut.miss_pulse = 1'b1;
        wait_clks(2);
        release dut.miss_pulse;
        wait_clks(4);
    end
endtask

//====================================================
// Checkers
//====================================================
task automatic expect_equal_1bit;
    input actual;
    input expected;
    input [255:0] msg;
    begin
        if (actual !== expected)
            $display("[FAIL] %0t %0s | actual=%b expected=%b", $time, msg, actual, expected);
        else
            $display("[PASS] %0t %0s | value=%b", $time, msg, actual);
    end
endtask

task automatic expect_equal_8bit;
    input [7:0] actual;
    input [7:0] expected;
    input [255:0] msg;
    begin
        if (actual !== expected)
            $display("[FAIL] %0t %0s | actual=0x%0h expected=0x%0h", $time, msg, actual, expected);
        else
            $display("[PASS] %0t %0s | value=0x%0h", $time, msg, actual);
    end
endtask

task automatic expect_equal_32bit;
    input [31:0] actual;
    input [31:0] expected;
    input [255:0] msg;
    begin
        if (actual !== expected)
            $display("[FAIL] %0t %0s | actual=0x%0h expected=0x%0h", $time, msg, actual, expected);
        else
            $display("[PASS] %0t %0s | value=0x%0h", $time, msg, actual);
    end
endtask

task automatic expect_fifo_empty_flag;
    input actual;
    input expected;
    input [255:0] msg;
    begin
        if (actual !== expected)
            $display("[FAIL] %0t %0s | fifo_empty actual=%b expected=%b", $time, msg, actual, expected);
        else
            $display("[PASS] %0t %0s | fifo_empty=%b", $time, msg, actual);
    end
endtask

task automatic expect_fifo_count_value;
    input [4:0] actual;
    input [4:0] expected;
    input [255:0] msg;
    begin
        if (actual !== expected)
            $display("[FAIL] %0t %0s | fifo_count actual=%0d expected=%0d", $time, msg, actual, expected);
        else
            $display("[PASS] %0t %0s | fifo_count=%0d", $time, msg, actual);
    end
endtask
