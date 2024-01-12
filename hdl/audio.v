
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
             if (div == 0) stb_pcm <= 1;
          end
    endcase

	end

endmodule


module audio_filter #(parameter W=21)
	(input clk, input stb_sample, input stb_pcm, input din, output signed [15:0] out);

   // Four stage CIC filter to low pass filter and downsample PDM

	wire signed [W-1:0] d[8:0];
   reg signed [W-1:0] e[0:3];

   initial begin
      e[0] <= 0;
      e[1] <= 0;
      e[2] <= 0;
      e[3] <= 0;
   end

   always @(posedge clk)
   begin
      if(stb_sample) begin
         e[0] <= e[0] + (din ? +1 : -1);
         e[1] <= e[1] + e[0];
         e[2] <= e[2] + e[1];
         e[3] <= e[3] + e[2];
      end
   end
         
   // four stage comb filter and down converter

   reg signed [W-1:0] c[0:9];
   wire signed [W-1:0] fin;
   assign fin = e[3];

   always @(posedge clk)
   begin
      if(stb_pcm) begin
         c[0] <= fin;
         c[1] <= c[0] - fin;
         c[2] <= c[1];
         c[3] <= c[2] - c[1];
         c[4] <= c[3];
         c[5] <= c[4] - c[3];
         c[6] <= c[5];
         c[7] <= c[6] - c[5];
         // One more differenatiaon for DC removal. Why?
         c[8] <= c[7];
         c[9] <= c[8] - c[7];

      end
   end

   assign out = c[9] >>> 5;

endmodule


// vi: ft=verilog ts=3 sw=3 et
