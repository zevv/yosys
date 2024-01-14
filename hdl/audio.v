
`default_nettype none



module audio_clk_gen(input clk, output reg clk_pdm = 0, output reg stb_pcm = 0, output reg stb_left = 0, output reg stb_right = 0);

	reg [8:0] cnt = 0;
	reg [7:0] div = 0;

	always @(posedge clk)
	begin

		stb_left <= 0;
		stb_right <= 0;
		stb_pcm <= 0;

      cnt <= cnt + 1;

      case (cnt)
          0: begin
             clk_pdm <= 0;
          end
          7: begin
             stb_left <= 1;
          end
          8: begin
            clk_pdm <= 1;
          end
          15: begin
             stb_right <= 1;
             cnt <= 0;
             div <= div + 1;
             if (div == 124) begin
                stb_pcm <= 1;
                div <= 0;
             end
          end
    endcase

	end

endmodule


// Four stage CIC filter integrators

module cic_integrator(
   input clk,
   input stb_sample,
   input din,
   output signed [23:0] out
);
   reg signed [23:0] e[0:3];
   assign out = e[3];

   initial begin
      e[0] = 0;
      e[1] = 0;
      e[2] = 0;
      e[3] = 0;
   end

   always @(posedge clk)
   begin
      if(stb_sample) begin
         e[0] <= e[0] + (din ? 24'd1 : -24'd1);
         e[1] <= e[1] + e[0];
         e[2] <= e[2] + e[1];
         e[3] <= e[3] + e[2];
      end
   end

endmodule


module audio_filter #(parameter W=24) (
   input clk, 
   input stb_start,
   output reg busy,
   input [9:0] addr_start,
   input [23:0] din, 
   output reg signed [15:0] out,
   output reg rd_en, output reg [9:0] rd_addr, input [23:0] rd_data,
   output reg wr_en, output reg [9:0] wr_addr, output reg [23:0] wr_data
);

   // four stage comb filter and down converter

   reg signed [W-1:0] ra, rb, rc;
   reg [3:0] state = 0;
   reg [9:0] addr = 0;
   reg [1:0] stage = 0;

   initial begin
      busy = 0;
      rd_en = 0;
      wr_en = 0;
      out = 0;
      ra = 0;
      rb = 0;
      rc = 0;
   end

   always @(posedge clk)
   begin

      state <= state + 1;
      case (state)

         // Wait for start
         0: begin
            if (stb_start) begin
               rb <= din;
               addr <= addr_start;
               stage <= 0;
               state <= 1;
               busy <= 1;
            end else begin
               state <= 0;
            end
         end

         // Differentiator for each stage
         1: begin
            rd_addr <= addr;
            rd_en <= 1;
         end
         2: begin
            // wait for rd_data valid
         end
         3: begin
            ra <= rd_data;
            rd_en <= 0;
            wr_addr <= addr;
            wr_data <= rb;
            wr_en <= 1;
         end
         4: begin
            wr_en <= 0;
            rb <= ra - rb;
            addr <= addr + 1;
            stage <= stage + 1;
            if (stage == 3)
               state <= 5;
            else
               state <= 1;
         end

         // DC bias removal
         5: begin
            rd_addr <= addr;
            rd_en <= 1;
         end
         6: begin
            // wait for rd_data valid
         end
         7: begin
            ra <= rd_data;
            rd_en <= 0;
         end
         8: begin
            rb <= (rb >>> 8);
         end
         9: begin
            rb <= rb + ra;
         end
         10: begin
            rc <= rb[15] ? -4 : +4;
         end
         11: begin
            ra <= ra - rc;
         end
         12: begin
            wr_addr <= addr;
            wr_data <= ra;
            wr_en <= 1;
         end
         13: begin
            wr_en <= 0;
         end

         14: begin
            out <= rb[15:0];
            state <= 0;
            busy <= 0;
         end
      endcase
   end
   
endmodule


// vi: ft=verilog ts=3 sw=3 et
