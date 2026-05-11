

module input_ctrl (
    input  wire        clk,
    input  wire        slow_tick,

    input  wire        btnc_raw,
    input  wire        btnu_raw,
    input  wire        btnd_raw,
    input  wire        btnl_raw,
    input  wire        btnr_raw,
    input  wire [15:0] sw_raw,

    output wire        rst,
    output wire        dump_pulse,
    output wire        auto_tx_toggle_pulse,
    output wire        undo_pulse,
    output wire        redo_pulse,

    output wire        p1_drop_req,
    output wire [2:0]  p1_drop_col,
    output wire        p2_drop_req,
    output wire [2:0]  p2_drop_col,

    output wire [15:0] sw_lvl
);

    wire btnc_lvl;
    wire btnu_rise, btnd_rise, btnl_rise, btnr_rise;

    debouncer u_db_btnc (
        .clk(clk), .rst(1'b0), .slow_tick(slow_tick),
        .in(btnc_raw), .out_db(btnc_lvl), .rise(), .fall()
    );
    debouncer u_db_btnu (
        .clk(clk), .rst(1'b0), .slow_tick(slow_tick),
        .in(btnu_raw), .out_db(), .rise(btnu_rise), .fall()
    );
    debouncer u_db_btnd (
        .clk(clk), .rst(1'b0), .slow_tick(slow_tick),
        .in(btnd_raw), .out_db(), .rise(btnd_rise), .fall()
    );
    debouncer u_db_btnl (
        .clk(clk), .rst(1'b0), .slow_tick(slow_tick),
        .in(btnl_raw), .out_db(), .rise(btnl_rise), .fall()
    );
    debouncer u_db_btnr (
        .clk(clk), .rst(1'b0), .slow_tick(slow_tick),
        .in(btnr_raw), .out_db(), .rise(btnr_rise), .fall()
    );

    assign rst                  = btnc_lvl;
    assign dump_pulse           = btnu_rise;
    assign auto_tx_toggle_pulse = btnd_rise;
    assign undo_pulse           = btnl_rise;
    assign redo_pulse           = btnr_rise;

    wire [15:0] sw_fall;

    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : G_SW
            debouncer u_sw (
                .clk        (clk),
                .rst        (1'b0),
                .slow_tick  (slow_tick),
                .in         (sw_raw[gi]),
                .out_db     (sw_lvl[gi]),
                .rise       (),
                .fall       (sw_fall[gi])
            );
        end
    endgenerate

    reg [2:0] p1_col_r;
    always @* begin
        if      (sw_fall[0]) p1_col_r = 3'd0;
        else if (sw_fall[1]) p1_col_r = 3'd1;
        else if (sw_fall[2]) p1_col_r = 3'd2;
        else if (sw_fall[3]) p1_col_r = 3'd3;
        else if (sw_fall[4]) p1_col_r = 3'd4;
        else if (sw_fall[5]) p1_col_r = 3'd5;
        else if (sw_fall[6]) p1_col_r = 3'd6;
        else                 p1_col_r = 3'd7;
    end
    assign p1_drop_req = |sw_fall[7:0];
    assign p1_drop_col = p1_col_r;

    reg [2:0] p2_col_r;
    always @* begin
        if      (sw_fall[8])  p2_col_r = 3'd0;
        else if (sw_fall[9])  p2_col_r = 3'd1;
        else if (sw_fall[10]) p2_col_r = 3'd2;
        else if (sw_fall[11]) p2_col_r = 3'd3;
        else if (sw_fall[12]) p2_col_r = 3'd4;
        else if (sw_fall[13]) p2_col_r = 3'd5;
        else if (sw_fall[14]) p2_col_r = 3'd6;
        else                  p2_col_r = 3'd7;
    end
    assign p2_drop_req = |sw_fall[15:8];
    assign p2_drop_col = p2_col_r;

endmodule
