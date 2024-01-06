
`default_nettype none

`include "bram.v"

module sender(input clk, input clk_en, output tx_p, output tx_busy);

   reg [20:0] tick = 0;
   reg start = 0;
   reg [31:0] flop = 0;

   reg [7:0] bram_wr_data = 0;
   wire [7:0] bram_rd_data;
   wire [9:0] bram_rd_addr;
   reg [9:0] bram_wr_addr;
   wire bram_rd_en;
   reg bram_wr_en = 0;


   bram bram0(clk,
      bram_rd_en, bram_rd_addr, bram_rd_data,
      bram_wr_en, bram_wr_addr, bram_wr_data);
  // bram bram0(clk, bram_rd_en, bram_rd_addr, bram_rd_data, bram_wr_en, bram_wr_addr, bram_wr_data);
     

   eth_tx2 et(clk, clk_en,
              start,
              tx_p, tx_busy, 
              bram_rd_en, bram_rd_addr, bram_rd_data);

   always @(posedge clk) begin
      if (clk_en) begin
         tick <= tick + 1;
         case (tick)
            0: flop <= flop + 1;
            1: bram_wr_addr <= 8'h3b;
            2: bram_wr_data <= flop[7:0];
            3: bram_wr_en <= 1;
            4: bram_wr_en <= 0;
            5: bram_wr_addr <= 8'h3a;
            6: bram_wr_data <= flop[15:8];
            7: bram_wr_en <= 1;
            8: bram_wr_en <= 0;
            9: bram_wr_addr <= 8'h39;
            10: bram_wr_data <= flop[23:16];
            11: bram_wr_en <= 1;
            12: bram_wr_en <= 0;
            13: bram_wr_addr <= 8'h38;
            14: bram_wr_data <= flop[31:24];
            15: bram_wr_en <= 1;
            16: bram_wr_en <= 0;
            17: start <= 1;
            18: start <= 0;
         endcase
      end

   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
