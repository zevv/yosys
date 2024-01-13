
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
   reg [9:0] bram_wr_addr = 13;
   wire bram_rd_en;
   reg bram_wr_en = 0;

   bram bram0(clk,
      bram_rd_en, bram_rd_addr, bram_rd_data,
      bram_wr_en, bram_wr_addr, bram_wr_data);
     

   eth_tx2 et(clk, eth_clk_en,
              eth_start, eth_tx, eth_tx_busy, 
              bram_rd_en, bram_rd_addr, bram_rd_data);


   wire au_stb_pcm;
   wire au_stb_left;
   wire au_stb_right;
   audio_clk_gen ag(clk, au_pdm_clk,
                    au_stb_pcm, au_stb_left, au_stb_right);

   wire signed [15:0] au_pcm[16];

   audio_filter af00l (clk, au_stb_left,  au_stb_pcm, au_pdm_data, au_pcm[ 0]);
   audio_filter af00r (clk, au_stb_right, au_stb_pcm, au_pdm_data, au_pcm[ 1]);
//   audio_filter af01l (clk, au_stb_left,  au_stb_pcm, au_pdm_data, au_pcm[ 2]);
//   audio_filter af01r (clk, au_stb_right, au_stb_pcm, au_pdm_data, au_pcm[ 3]);
//   audio_filter af02l (clk, au_stb_left,  au_stb_pcm, au_pdm_data, au_pcm[ 4]);
//   audio_filter af02r (clk, au_stb_right, au_stb_pcm, au_pdm_data, au_pcm[ 5]);
//   audio_filter af03l (clk, au_stb_left,  au_stb_pcm, au_pdm_data, au_pcm[ 6]);
//   audio_filter af03r (clk, au_stb_right, au_stb_pcm, au_pdm_data, au_pcm[ 7]);
//   audio_filter af04l (clk, au_stb_left,  au_stb_pcm, au_pdm_data, au_pcm[ 7]);
//   audio_filter af04r (clk, au_stb_right, au_stb_pcm, au_pdm_data, au_pcm[ 9]);
//   audio_filter af05l (clk, au_stb_left,  au_stb_pcm, au_pdm_data, au_pcm[10]);
//   audio_filter af05r (clk, au_stb_right, au_stb_pcm, au_pdm_data, au_pcm[11]);

   assign debug = au_stb_pcm;


   reg [4:0] state = 0;
   reg [3:0] chan = 0;
   always @(posedge clk) begin

      case (state)
         0: begin
            if(au_stb_pcm) begin
               state <= 1;
               chan <= 0;
            end
         end

         1: begin
            bram_wr_addr <= bram_wr_addr + 1;
            bram_wr_data <= au_pcm[chan][7:0];
            bram_wr_en <= 1;
            state <= 2;
         end
         2: begin
            bram_wr_addr <= bram_wr_addr + 1;
            bram_wr_data <= au_pcm[chan][15:8];
            chan <= chan + 1;
            if (chan == 7)
               state <= 10;
            else
               state <= 1;
         end
         
         10: begin
            bram_wr_en <= 0;
            if (bram_wr_addr == 14 + 32 * 16 - 1) begin
               eth_start <= 1;
               state <= 11;
            end else begin
               state <= 0;
            end
         end
         11: begin
            bram_wr_addr <= 13;
            state <= 12;
         end
         12: begin
            eth_start <= 0;
            state <= 0;
         end
      endcase

   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
