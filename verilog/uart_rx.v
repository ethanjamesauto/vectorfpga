//`define IVERILOG
`ifdef IVERILOG
module uart_rx 
(
  input        i_Clock,
  input        i_Rx_Serial,
  output reg      o_Rx_DV,
  output reg [7:0] o_Rx_Byte,

  output reg test
);

reg [7:0] k[39:0];
integer i;

initial begin
  k[0] = 0;
  k[1] = 0;
  k[2] = 0;
  k[3] = 0;
  k[4] = 0;
  k[5] = 0;
  k[6] = 0;
  k[7] = 0;
  k[8] = 1;
  k[9] = 2;
  k[10] = 3;
  k[11] = 4;
  k[12] = 2;
  k[13] = 4;
  k[14] = 6;
  k[15] = 8;
  k[16] = 1;
  k[17] = 1;
  k[18] = 1;
  k[19] = 1;
  
  k[20] = 0;
  k[21] = 0;
  k[22] = 0;
  k[23] = 0;
  k[24] = 0;
  k[25] = 0;
  k[26] = 0;
  k[27] = 0;
  k[28] = 1;
  k[29] = 2;
  k[30] = 3;
  k[31] = 4;
  k[32] = 5;
  k[33] = 6;
  k[34] = 7;
  k[35] = 8;
  k[36] = 1;
  k[37] = 1;
  k[38] = 1;
  k[39] = 1;
  for (i = 0; i < 40; i=i+1) begin
    if (i == 20) begin
      #300;
    end
    #49;
    o_Rx_Byte = k[i];
    o_Rx_DV = 1;
    #2;
    o_Rx_DV = 0;
    o_Rx_Byte = 0;
  end
end

endmodule
`else
//////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
//////////////////////////////////////////////////////////////////////
// This file contains the UART Receiver.  This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When receive is complete o_rx_dv will be
// driven high for one clock cycle.
// 
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87
  
module uart_rx 
  #(parameter CLKS_PER_BIT = 23)
  (
   input        i_Clock,
	input        i_Rx_Serial,
   output       o_Rx_DV,
   output [7:0] o_Rx_Byte,
   output reg test
   );
    
  parameter s_IDLE         = 3'b000;
  parameter s_RX_START_BIT = 3'b001;
  parameter s_RX_DATA_BITS = 3'b010;
  parameter s_RX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;
   
  reg           r_Rx_Data_R = 1'b1;
  reg           r_Rx_Data   = 1'b1;
   
  reg [7:0]     r_Clock_Count = 0;
  reg [2:0]     r_Bit_Index   = 0; //8 bits total
  reg [7:0]     r_Rx_Byte     = 0;
  reg           r_Rx_DV       = 0;
  reg [2:0]     r_SM_Main     = 0;
   
  // Purpose: Double-register the incoming data.
  // This allows it to be used in the UART RX Clock Domain.
	// (It removes problems caused by metastability)
  always @(posedge i_Clock)
    begin
      r_Rx_Data_R <= i_Rx_Serial;
      r_Rx_Data   <= r_Rx_Data_R;
    end
   
   
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
         
        // Check middle of start bit to make sure it's still low
        s_RX_START_BIT :
          begin
            if (r_Clock_Count == (CLKS_PER_BIT-1)/2)
              begin
                if (r_Rx_Data == 1'b0)
                  begin
                    r_Clock_Count <= 0;  // reset counter, found the middle
                    r_SM_Main     <= s_RX_DATA_BITS;
                  end
                else
                  r_SM_Main <= s_IDLE;
              end
            else
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_RX_START_BIT;
              end
          end // case: s_RX_START_BIT
         
         
        // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
        s_RX_DATA_BITS :
          begin
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                test <= 0;
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_RX_DATA_BITS;
              end
            else
              begin
                test <= 1;
                r_Clock_Count          <= 0;
                r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
                 
                // Check if we have received all bits
                if (r_Bit_Index < 7)
                  begin
                    r_Bit_Index <= r_Bit_Index + 1;
                    r_SM_Main   <= s_RX_DATA_BITS;
                  end
                else
                  begin
                    r_Bit_Index <= 0;
                    r_SM_Main   <= s_RX_STOP_BIT;
                  end
              end
          end // case: s_RX_DATA_BITS
     
     
        // Receive Stop bit.  Stop bit = 1
        s_RX_STOP_BIT :
          begin
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_RX_STOP_BIT;
              end
            else
              begin
                r_Rx_DV       <= 1'b1;
                r_Clock_Count <= 0;
                r_SM_Main     <= s_CLEANUP;
              end
          end // case: s_RX_STOP_BIT
     
         
        // Stay here 1 clock
        s_CLEANUP :
          begin
            r_SM_Main <= s_IDLE;
            r_Rx_DV   <= 1'b0;
          end
         
         
        default :
          r_SM_Main <= s_IDLE;
         
      endcase
    end   
   
  assign o_Rx_DV   = r_Rx_DV;
  assign o_Rx_Byte = r_Rx_Byte;
   
endmodule // uart_rx
`endif