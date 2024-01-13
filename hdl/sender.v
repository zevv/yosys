
`default_nettype none

`include "bram.v"
`include "audio.v"
`include "ethernet.v"

module sender(input clk, 
   input eth_clk_stb, output eth_tx, output eth_tx_busy,
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
     

   eth_tx2 et(clk, eth_clk_stb,
              eth_start, eth_tx, eth_tx_busy, 
              bram_rd_en, bram_rd_addr, bram_rd_data);


   wire au_stb_pcm;
   wire au_stb_left;
   wire au_stb_right;
   audio_clk_gen ag(clk, au_pdm_clk,
                    au_stb_pcm, au_stb_left, au_stb_right);

   wire [23:0] bram_af_wr_data;
   wire [23:0] bram_af_rd_data;
   wire [9:0] bram_af_rd_addr;
   wire [9:0] bram_af_wr_addr;
   wire bram_af_rd_en;
   wire bram_af_wr_en;

   bram24 bram_af0(clk,
      bram_af_rd_en, bram_af_rd_addr, bram_af_rd_data,
      bram_af_wr_en, bram_af_wr_addr, bram_af_wr_data);

   wire [23:0] au_cic[15:0];
   cic_integrator ci00l(clk, au_stb_left,  au_pdm_data, au_cic[ 0]);
   cic_integrator ci00r(clk, au_stb_right, au_pdm_data, au_cic[ 1]);
   cic_integrator ci01l(clk, au_stb_left,  au_pdm_data, au_cic[ 2]);
   cic_integrator ci01r(clk, au_stb_right, au_pdm_data, au_cic[ 3]);
   cic_integrator ci02l(clk, au_stb_left,  au_pdm_data, au_cic[ 4]);
   cic_integrator ci02r(clk, au_stb_right, au_pdm_data, au_cic[ 5]);
   cic_integrator ci03l(clk, au_stb_left,  au_pdm_data, au_cic[ 6]);
   cic_integrator ci03r(clk, au_stb_right, au_pdm_data, au_cic[ 7]);
   cic_integrator ci04l(clk, au_stb_left,  au_pdm_data, au_cic[ 8]);
   cic_integrator ci04r(clk, au_stb_right, au_pdm_data, au_cic[ 9]);
   cic_integrator ci05l(clk, au_stb_left,  au_pdm_data, au_cic[10]);
   cic_integrator ci05r(clk, au_stb_right, au_pdm_data, au_cic[11]);
   cic_integrator ci06l(clk, au_stb_left,  au_pdm_data, au_cic[12]);
   cic_integrator ci06r(clk, au_stb_right, au_pdm_data, au_cic[13]);
   cic_integrator ci07l(clk, au_stb_left,  au_pdm_data, au_cic[14]);
   cic_integrator ci07r(clk, au_stb_right, au_pdm_data, au_cic[15]);

   reg cic2_stb = 0;
   wire cic2_busy;
   reg [9:0] cic2_addr = 0;
   reg [23:0] cic2_in = 0;
   wire [15:0] cic2_out;

   audio_filter af00l (clk,
      cic2_stb,
      cic2_busy,
      cic2_addr, cic2_in, cic2_out,
      bram_af_rd_en, bram_af_rd_addr, bram_af_rd_data,
      bram_af_wr_en, bram_af_wr_addr, bram_af_wr_data);

   assign debug = au_stb_pcm;


   reg [4:0] state = 0;
   reg [3:0] chan = 0;
   always @(posedge clk) begin

      case (state)
         // Wait for PCM strobe
         0: begin
            if(au_stb_pcm) begin
               state <= 1;
               chan <= 0;
               cic2_addr <= 0;
            end
         end

         // Run second CIC filter second half
         1: begin
            cic2_in <= au_cic[chan];
            cic2_stb <= 1;
            state <= 2;
         end
         2: begin
            cic2_stb <= 0;
            state <= 3;
         end
         3: begin
            if (!cic2_busy) begin
               state <= 5;
            end
         end

         // Write PCM to BRAM
         5: begin
            bram_wr_addr <= bram_wr_addr + 1;
            bram_wr_data <= cic2_out[7:0];
            bram_wr_en <= 1;
            state <= 6;
         end
         6: begin
            bram_wr_addr <= bram_wr_addr + 1;
            bram_wr_data <= cic2_out[15:8];
            bram_wr_en <= 1;
            state <= 7;
         end
         7: begin
            bram_wr_en <= 0;
            chan <= chan + 1;
            cic2_addr <= cic2_addr + 8;
            if (chan == 15)
               state <= 10;
            else 
               state <= 1;
         end
        
         // If packet full, start ethernet transmit
         10: begin
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
