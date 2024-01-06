
`default_nettype none

`include "ethernet.v"
`include "sender.v"
`include "ethernet-stolen.v"


module test();
   
   reg clk = 0;
   always #1 clk <= !clk;

   initial begin
      $dumpfile("test.vcd");
      $dumpvars(0, test);
      #100000 $finish;
   end

   reg [11:0] cnt = 0;
   reg start1 = 0;
   reg start2 = 0;
   always @(posedge clk_eth) begin
      cnt <= cnt + 1;
      start1 <= (cnt == 30);
      start2 <= (cnt == 32);
   end

   reg clk_eth = 0;


   wire error = tx_eth != tx_eth2;
   
   wire tx_eth;
   wire tx_eth2;
   wire tx_led;
   eth_tx et1(clk_eth, start1, tx_eth);
   sender sender (clk, clk_eth, tx_eth2, tx_led);


   always @(posedge clk) begin
      clk_eth <= ~clk_eth;
   end
   

endmodule

// vi: ft=verilog ts=3 sw=3 et
