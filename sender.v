
`default_nettype none

`include "bram.v"
`include "audio.v"
`include "ethernet.v"

module sender(input clk, 
   input eth_clk_en, output eth_tx, output eth_tx_busy,
   output au_pdm_clk, input au_pdm_data,
   output debug
);

   reg [20:0] tick = 0;
   reg eth_start = 0;
   reg [31:0] flop = 0;

   reg [7:0] bram_wr_data = 0;
   wire [7:0] bram_rd_data;
   wire [9:0] bram_rd_addr;
   reg [9:0] bram_wr_addr = 16;
   wire bram_rd_en;
   reg bram_wr_en = 0;

   bram bram0(clk,
      bram_rd_en, bram_rd_addr, bram_rd_data,
      bram_wr_en, bram_wr_addr, bram_wr_data);
     

   eth_tx2 et(clk, eth_clk_en,
              eth_start, eth_tx, eth_tx_busy, 
              bram_rd_en, bram_rd_addr, bram_rd_data);


   wire au_en_pcm;
   wire au_en_left;
   wire au_en_right;
   audio_clk_gen ag(clk, au_pdm_clk,
                    au_en_pcm, au_en_left, au_en_right);

   wire signed [15:0] au_pcm;
   audio_filter af (clk, au_en_left, au_en_pcm, au_pdm_data, au_pcm);


   assign debug = au_en_pcm;


   reg [4:0] state = 0;
   always @(posedge clk) begin

      case (state)

         0: begin
            if(au_en_pcm) begin
               bram_wr_data <= au_pcm[7:0];
               bram_wr_en <= 1;
               state <= 1;
            end
         end
         1: begin
            bram_wr_addr <= bram_wr_addr + 1;
            bram_wr_data <= au_pcm[15:8];
            bram_wr_en <= 1;
            state <= 2;
         end
         2: begin
            bram_wr_en <= 0;
            bram_wr_addr <= bram_wr_addr + 1;
            if (bram_wr_addr >= 510) begin
               bram_wr_addr <= 14;
               eth_start <= 1;
               state <= 3;
            end else begin
               state <= 0;
            end
         end
         3: begin
            eth_start <= 0;
            state <= 0;
         end
      endcase

   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
