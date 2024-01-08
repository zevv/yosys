
`default_nettype none



module audio_clk_gen(input clk, output reg clk_pdm = 0, output reg stb_pcm = 0, output reg stb_left = 0, output reg stb_right = 0);

	reg [8:0] cnt = 0;
	reg [6:0] div = 0;

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
          10: begin
            clk_pdm <= 1;
          end
          18: begin
             stb_right <= 1;
          end
          19: begin
             div <= div + 1;
             cnt <= 0;
             if (div == 127) stb_pcm <= 1;
          end
    endcase

	end

endmodule


module integrator #(parameter W=16)
	(input clk, input en, input signed [W-1:0] din, output reg signed [W-1:0] dout = 0);

	always @(posedge clk)
	begin
      if (en)
         dout <= dout + din;
	end

endmodule


module comb #(parameter W=16)
	(input clk, input en, input signed [W-1:0] din, output reg signed [W-1:0] dout = 0);

	reg signed [W-1:0] din_prev = 0;

	always @(posedge clk)
	begin
      if (en) begin
         dout <= din - din_prev;
         din_prev <= din;
      end
	end
endmodule


module audio_filter #(parameter W=24)
	(input clk, input stb_sample, input stb_pcm, input din, output reg signed [15:0] out);

   // Four stage CIC filter to low pass filter and downsample PDM

	wire signed [W-1:0] d[8:0];

   assign d[0] = din ? +1 : -1;

	integrator #(.W(W)) int0 (clk, stb_sample, d[0], d[1]);
	integrator #(.W(W)) int1 (clk, stb_sample, d[1], d[2]);
	integrator #(.W(W)) int2 (clk, stb_sample, d[2], d[3]);
	integrator #(.W(W)) int3 (clk, stb_sample, d[3], d[4]);
	
	comb #(.W(W)) comb0 (clk, stb_pcm, d[4], d[5]);
	comb #(.W(W)) comb1 (clk, stb_pcm, d[5], d[6]);
	comb #(.W(W)) comb2 (clk, stb_pcm, d[6], d[7]);
	comb #(.W(W)) comb3 (clk, stb_pcm, d[7], d[8]);

   // DC rejection filter to remove wandering DC offset
   // y(n) = x(n) - x(n-1) + R * y(n-1)

   reg signed [W-1:0] y0 = 0;
   reg signed [W-1:0] y1 = 0;
   reg signed [W-1:0] x0 = 0;
   reg signed [W-1:0] x1 = 0;

	always @(posedge clk)
	begin

      if (stb_pcm) begin
         x0 <= d[8];
         x1 <= x0;
         y0 <= (x0 - x1) + (y1 >>> 1);
         y1 <= y0;
         out <= y0 >>> 5;
      end
	end

endmodule


// vi: ft=verilog ts=3 sw=3 et
