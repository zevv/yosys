
`include "ethernet.v"


module gen_link(input clk, output reg link);
	
	reg [20:0] link_cnt;
	
	always @(posedge clk) begin
		if(link_cnt == 21'd0) begin
			link <= 1;
		end
		if(link_cnt == 21'd4) begin
			link <= 0;
		end
		if(link_cnt == 21'd640000) begin
			link_cnt <= 21'd0;
		end
		link_cnt <= link_cnt + 21'd1;
	end

endmodule


module top(
	output IOB_8A, output IOB_23B,
	output IOB_9B
);

	wire clk_48mhz;
	wire clk;
   
   SB_HFOSC SB_HFOSC_inst(
      .CLKHFEN(1),
      .CLKHFPU(1),
      .CLKHF(clk_48mhz)
   );


	SB_PLL40_CORE #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'b0010),		// DIVR =  2
		.DIVF(7'b0100111),	// DIVF = 39
		.DIVQ(3'b100),		// DIVQ =  4
		.FILTER_RANGE(3'b001)	// FILTER_RANGE = 1
	) uut (
		.LOCK(locked),
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.REFERENCECLK(clk_48mhz),
		.PLLOUTCORE(clk)
	);


	wire tx_link;

	gen_link i(clk, tx_link);

	reg clk_eth = 0;

	always @(posedge clk) begin
		clk_eth = ~clk_eth;
	end
	
	wire tx_eth;
	eth_tx et(clk_eth, tx_eth);

	wire tx_p;
	wire tx_n;

	assign tx_p = tx_eth;
	assign tx_n = ~tx_p;
	
	assign IOB_8A  = tx_n;
	assign IOB_9B  = tx_p;
	assign IOB_23B = tx_p;

endmodule

// vi: ft=verilog ts=3 sw=3
