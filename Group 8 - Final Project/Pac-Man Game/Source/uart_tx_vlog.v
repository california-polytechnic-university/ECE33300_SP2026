`timescale 1ns / 1ps

module uart_tx_vlog
  #(parameter CLKS_PER_BIT = 10416)
   (
    input       i_Clock,
    input       i_Tx_DV,
    input [7:0] i_Tx_Byte,

    output reg  o_Tx_Serial,
    output      o_Tx_Done,
    output      o_Tx_Ready
    );

   localparam s_IDLE         = 3'b000;
   localparam s_TX_START_BIT = 3'b001;
   localparam s_TX_DATA_BITS = 3'b010;
   localparam s_TX_STOP_BIT  = 3'b011;
   localparam s_CLEANUP      = 3'b100;

   reg [2:0]  r_SM_Main     = s_IDLE;
   reg [13:0] r_Clock_Count = 14'd0;
   reg [2:0]  r_Bit_Index   = 3'd0;
   reg [7:0]  r_Tx_Data     = 8'd0;
   reg        r_Tx_Done     = 1'b0;
   reg        r_Tx_Active   = 1'b0;

   always @(posedge i_Clock) begin

      case (r_SM_Main)

        //--------------------------------------------------------
        // Idle state:
        //--------------------------------------------------------
        s_IDLE: begin
           o_Tx_Serial   <= 1'b1;
           r_Tx_Done     <= 1'b0;
           r_Clock_Count <= 14'd0;
           r_Bit_Index   <= 3'd0;
           r_Tx_Active   <= 1'b0;

           if (i_Tx_DV == 1'b1) begin
              r_Tx_Active <= 1'b1;
              r_Tx_Data   <= i_Tx_Byte;
              r_SM_Main   <= s_TX_START_BIT;
           end else begin
              r_SM_Main   <= s_IDLE;
           end
        end

 
        s_TX_START_BIT: begin
           o_Tx_Serial <= 1'b0;

           if (r_Clock_Count < CLKS_PER_BIT-1) begin
              r_Clock_Count <= r_Clock_Count + 14'd1;
              r_SM_Main     <= s_TX_START_BIT;
           end else begin
              r_Clock_Count <= 14'd0;
              r_SM_Main     <= s_TX_DATA_BITS;
           end
        end


        s_TX_DATA_BITS: begin
           o_Tx_Serial <= r_Tx_Data[r_Bit_Index];

           if (r_Clock_Count < CLKS_PER_BIT-1) begin
              r_Clock_Count <= r_Clock_Count + 14'd1;
              r_SM_Main     <= s_TX_DATA_BITS;
           end else begin
              r_Clock_Count <= 14'd0;

              if (r_Bit_Index < 3'd7) begin
                 r_Bit_Index <= r_Bit_Index + 3'd1;
                 r_SM_Main   <= s_TX_DATA_BITS;
              end else begin
                 r_Bit_Index <= 3'd0;
                 r_SM_Main   <= s_TX_STOP_BIT;
              end
           end
        end


        s_TX_STOP_BIT: begin
           o_Tx_Serial <= 1'b1;

           if (r_Clock_Count < CLKS_PER_BIT-1) begin
              r_Clock_Count <= r_Clock_Count + 14'd1;
              r_SM_Main     <= s_TX_STOP_BIT;
           end else begin
              r_Tx_Done     <= 1'b1;
              r_Clock_Count <= 14'd0;
              r_Tx_Active   <= 1'b0;
              r_SM_Main     <= s_CLEANUP;
           end
        end


        s_CLEANUP: begin
           r_Tx_Done <= 1'b0;
           r_SM_Main <= s_IDLE;
        end

        default: begin
           r_SM_Main <= s_IDLE;
        end

      endcase
   end

   assign o_Tx_Done  = r_Tx_Done;
   assign o_Tx_Ready = ~r_Tx_Active;

endmodule
