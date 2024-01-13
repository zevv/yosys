
`default_nettype none

`include "sender.v"
`include "ethernet-stolen.v"


module test();
   
   reg clk = 0;
   always #1 clk <= !clk;

   initial begin
      $dumpfile("test.vcd");
      $dumpvars(0, test);

		# 3
		`include "din.v"
      # 440000
		# 1 $finish();
	end

   reg [0:0] din = 0;
   reg eth_clk_stb = 0;

   
   wire tx_eth2;
   wire au_pdm_clk;
   wire au_pdm_data;
   wire debug;

   assign au_pdm_data = din[0];

   sender sender (clk, eth_clk_stb,
                  tx_eth2, tx_led,
                  au_pdm_clk, au_pdm_data, debug);


   always @(posedge clk) begin
      eth_clk_stb <= ~eth_clk_stb;
   end
   

endmodule

// vi: ft=verilog ts=3 sw=3 et
