
`default_nettype none

`include "sender.v"
`include "ethernet-stolen.v"


module test();
   
   reg clk = 0;
   always #1 clk <= !clk;

   initial begin
      $dumpfile("test.vcd");
      $dumpvars(0, test);
      $dumpvars(0, test.sender.af00l.c[0]);
      $dumpvars(0, test.sender.af00l.c[1]);
      $dumpvars(0, test.sender.af00l.c[2]);
      $dumpvars(0, test.sender.af00l.c[3]);
      $dumpvars(0, test.sender.af00l.c[4]);

		# 3
		`include "din.v"
      # 120000
		# 1 $finish();
	end

   reg [7:0] din = 0;

   reg [11:0] cnt = 0;
   reg start1 = 0;
   reg start2 = 0;
   always @(posedge eth_clk_en) begin
      cnt <= cnt + 1;
      start1 <= (cnt == 30);
      start2 <= (cnt == 32);
   end

   reg eth_clk_en = 0;


   wire error = tx_eth != tx_eth2;
   
   wire tx_eth;
   wire tx_eth2;
   wire tx_led;
   eth_tx et1(eth_clk_en, start1, tx_eth);
   wire au_pdm_clk;
   wire au_pdm_data;
   wire debug;

   assign au_pdm_data = din[0];

   sender sender (clk, eth_clk_en,
                  tx_eth2, tx_led,
                  au_pdm_clk, au_pdm_data, debug);


   always @(posedge clk) begin
      eth_clk_en <= ~eth_clk_en;
   end
   

endmodule

// vi: ft=verilog ts=3 sw=3 et
