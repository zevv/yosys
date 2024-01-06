
`default_nettype none



module audio_clk_gen(input clk, output reg clk_pdm = 0, output reg en_pcm = 0, output reg en_left = 0, output reg en_right = 0);

	reg [8:0] cnt = 0;
	reg [6:0] div = 0;

	always @(posedge clk)
	begin

		en_left <= 0;
		en_right <= 0;
		en_pcm <= 0;

      cnt <= cnt + 1;

      case (cnt)
          0: begin
             clk_pdm <= 0;
          end
          7: begin
             en_left <= 1;
          end
          10: begin
            clk_pdm <= 1;
          end
          18: begin
             en_right <= 1;
          end
          19: begin
             div <= div + 1;
             cnt <= 0;
             if (div == 127) en_pcm <= 1;
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
	(input clk, input en_sample, input en_pcm, input din, output reg signed [15:0] out);

   // Four stage CIC filter to low pass filter and downsample PDM

	reg signed [W-1:0] d0 = 0;
	wire signed [W-1:0] d1;
	wire signed [W-1:0] d2;
	wire signed [W-1:0] d3;
	wire signed [W-1:0] d4;

	integrator #(.W(W)) int0 (clk, en_sample, d0, d1);
	integrator #(.W(W)) int1 (clk, en_sample, d1, d2);
	integrator #(.W(W)) int2 (clk, en_sample, d2, d3);
	integrator #(.W(W)) int3 (clk, en_sample, d3, d4);
	
   wire signed [W-1:0] d5;
	wire signed [W-1:0] d6;
	wire signed [W-1:0] d7;
	wire signed [W-1:0] d8;

	comb #(.W(W)) comb0 (clk, en_pcm, d4, d5);
	comb #(.W(W)) comb1 (clk, en_pcm, d5, d6);
	comb #(.W(W)) comb2 (clk, en_pcm, d6, d7);
	comb #(.W(W)) comb3 (clk, en_pcm, d7, d8);

   // DC rejection filter to remove wandering DC offset
   // y(n) = x(n) - x(n-1) + R * y(n-1)

   reg signed [W-1:0] y0 = 0;
   reg signed [W-1:0] y1 = 0;
   reg signed [W-1:0] x0 = 0;
   reg signed [W-1:0] x1 = 0;

	always @(posedge clk)
	begin
      if (din == 0)
         d0 <= +1;
      else
         d0 <= -1;

      if (en_pcm) begin
         x0 <= d8;
         x1 <= x0;
         y0 <= (x0 - x1) + (y1 >>> 1);
         y1 <= y0;
         out <= y0 >>> 5;
      end
	end

endmodule


// vi: ft=verilog ts=3 sw=3 et
