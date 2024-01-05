
`include "ethernet.v"



module top(
   output IOB_8A, output IOB_23B,
   output IOB_9B,
   output RGB2
);

   wire clk_48mhz;
   wire clk;
   
   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1),
      .CLKHFPU(1),
      .CLKHF(clk_48mhz)
   );


   SB_PLL40_CORE #(
      .FEEDBACK_PATH("SIMPLE"),
      .DIVR(4'b0010),      // DIVR =  2
      .DIVF(7'b0100111),   // DIVF = 39
      .DIVQ(3'b100),    // DIVQ =  4
      .FILTER_RANGE(3'b001)   // FILTER_RANGE = 1
   ) uut (
      .LOCK(locked),
      .RESETB(1'b1),
      .BYPASS(1'b0),
      .REFERENCECLK(clk_48mhz),
      .PLLOUTCORE(clk)
   );

   reg [21:0] tick = 0;
   wire start = (tick == 1000);
   always @(posedge clk) begin
      if (clk_eth)
         tick <= tick + 1;
   end

   wire tx_link;

   reg clk_eth = 0;

   always @(posedge clk) begin
      clk_eth <= ~clk_eth;
   end
   
   wire tx_eth;
   eth_tx2 et(clk, clk_eth, start, tx_eth, RGB2);

   wire tx_p;
   wire tx_n;

   assign tx_p = tx_eth;
   assign tx_n = ~tx_p;
   
   assign IOB_8A  = tx_p;
   assign IOB_9B  = tx_n;
   assign IOB_23B = tx_p;

endmodule

// vi: ft=verilog ts=3 sw=3 et
