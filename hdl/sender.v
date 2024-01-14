
`default_nettype none

`include "bram.v"
`include "audio.v"
`include "ethernet.v"

module sender(input clk, 
   input eth_clk_stb, output eth_tx, output eth_tx_busy,
   output au_pdm_clk, input au_pdm_data,
   output debug
);
   
  // Audio clock genenerator

   wire au_stb_pcm;
   wire au_stb_left;
   wire au_stb_right;
   audio_clk_gen ag(clk, au_pdm_clk,
                    au_stb_pcm, au_stb_left, au_stb_right);

   // Audio CIC filter first halves (integrators)
   
   wire [23:0] au_cic[31:0];

   genvar i;
   generate
      for (i = 0; i < 4; i = i + 1) begin : ci
         cic_integrator ci_l(clk, au_stb_left,  au_pdm_data, au_cic[i*2 + 0]);
         cic_integrator ci_r(clk, au_stb_right, au_pdm_data, au_cic[i*2 + 1]);
      end
   endgenerate
   
   // Audio CIC filter second half (differentiators)

   wire [23:0] bram_af_wr_data;
   wire [23:0] bram_af_rd_data;
   wire [9:0] bram_af_rd_addr;
   wire [9:0] bram_af_wr_addr;
   wire bram_af_rd_en;
   wire bram_af_wr_en;

   bram24 bram_af0(clk,
      bram_af_rd_en, bram_af_rd_addr, bram_af_rd_data,
      bram_af_wr_en, bram_af_wr_addr, bram_af_wr_data);

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

   // Ethernet transmitter + BRAM

   reg [7:0] bram_eth_wr_data = 0;
   wire [7:0] bram_eth_rd_data;
   wire [9:0] bram_eth_rd_addr;
   reg [9:0] bram_eth_wr_addr = 14;
   wire bram_eth_rd_en;
   reg bram_eth_wr_en = 0;

   bram bram_eth0(clk,
      bram_eth_rd_en, bram_eth_rd_addr, bram_eth_rd_data,
      bram_eth_wr_en, bram_eth_wr_addr, bram_eth_wr_data);
     
   reg eth_start = 0;

   eth_tx2 et(clk, eth_clk_stb,
              eth_start, eth_tx, eth_tx_busy, 
              bram_eth_rd_en, bram_eth_rd_addr, bram_eth_rd_data);


   // Main state machine

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

         // For each channel, run second CIC filter second half
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

         // For each channel, write PCM to BRAM
         5: begin
            bram_eth_wr_data <= cic2_out[7:0];
            bram_eth_wr_en <= 1;
            state <= 6;
         end
         6: begin
            bram_eth_wr_addr <= bram_eth_wr_addr + 1;
            bram_eth_wr_data <= cic2_out[15:8];
            bram_eth_wr_en <= 1;
            state <= 7;
         end
         7: begin
            bram_eth_wr_en <= 0;
            bram_eth_wr_addr <= bram_eth_wr_addr + 1;
            chan <= chan + 1;
            cic2_addr <= cic2_addr + 8;
            if (chan == 7)
               state <= 10;
            else 
               state <= 1;
         end
        
         // If packet full, start ethernet transmit
         10: begin
            if (bram_eth_wr_addr == 14 + 32 * 16) begin
               eth_start <= 1;
               state <= 11;
            end else begin
               state <= 0;
            end
         end
         11: begin
            bram_eth_wr_addr <= 14;
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
