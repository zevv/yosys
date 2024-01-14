
`default_nettype none

`include "sender.v"



module top(
   output IOB_8A, output IOB_23B,
   output IOB_9B,
   output RGB2,
   output IOT_37A,
   output IOT_41A,
   input IOT_50B,
);
   
   assign RGB2 = ~eth_tx_busy;
   assign IOB_8A = tx_p;
   assign IOB_9B = tx_n;
   assign IOB_23B = tx_p;
   assign IOT_37A = debug;
   assign IOT_41A = au_pdm_clk;
   assign au_pdm_data = IOT_50B;

   wire clk_48mhz;
   wire clk;
   
   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1),
      .CLKHFPU(1),
      .CLKHF(clk_48mhz)
   );


   wire locked;
   SB_PLL40_CORE #(
      .FEEDBACK_PATH("SIMPLE"),
      .DIVR(4'b0010),
      .DIVF(7'b0100111),
      .DIVQ(3'b100), 
      .FILTER_RANGE(3'b001)
   ) uut (
      .LOCK(locked),
      .RESETB(1'b1),
      .BYPASS(1'b0),
      .REFERENCECLK(clk_48mhz),
      .PLLOUTCORE(clk)
   );


   reg clk_eth = 0;
   always @(posedge clk) begin
      clk_eth <= ~clk_eth;
   end


   wire debug;
   
   wire eth_tx;
   wire eth_tx_busy;
   wire au_pdm_clk;
   wire [15:0] au_pdm_data = { 15'b0, IOT_50B };
   sender sender (clk,
                  clk_eth, eth_tx, eth_tx_busy,
                  au_pdm_clk, au_pdm_data,
                  debug
               );

   wire tx_p;
   wire tx_n;

   assign tx_p = eth_tx;
   assign tx_n = ~tx_p;
   

endmodule


// vi: ft=verilog ts=3 sw=3 et
