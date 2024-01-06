
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


module cic #(parameter W=32)
	(input clk, input en_sample, input en_pcm, input din, output signed [15:0] out);

	reg signed [W-1:0] d0 = 0;
	wire signed [W-1:0] d1;
	wire signed [W-1:0] d2;
	wire signed [W-1:0] d3;
	wire signed [W-1:0] d4;
	wire signed [W-1:0] c1;
	wire signed [W-1:0] c2;
	wire signed [W-1:0] c3;
	wire signed [W-1:0] c4;

	integrator #(.W(W)) int0 (clk, en_sample, d0, d1);
	integrator #(.W(W)) int1 (clk, en_sample, d1, d2);
	integrator #(.W(W)) int2 (clk, en_sample, d2, d3);
	integrator #(.W(W)) int3 (clk, en_sample, d3, d4);

	comb #(.W(W)) comb0 (clk, en_pcm, d4, c1);
	comb #(.W(W)) comb1 (clk, en_pcm, c1, c2);
	comb #(.W(W)) comb2 (clk, en_pcm, c2, c3);
	comb #(.W(W)) comb3 (clk, en_pcm, c3, c4);

	assign out = c4 >>> 6;

	always @(posedge clk)
	begin
      if (din == 0)
         d0 <= +1;
      else
         d0 <= -1;
	end

endmodule


// vi: ft=verilog ts=3 sw=3 et
