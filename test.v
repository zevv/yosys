
`include "ethernet.v"






module eth_tx2(input clk, input start, output reg tx = 0);

	localparam
		IDLE = 0,
		PREAMBLE = 1,
		TX_DATA = 2;

	reg [7:0] frame [0:'h43];
	initial begin
		$readmemh("frame2.bin", frame);
	end

	reg [2:0] state = IDLE;
	reg [3:0] bit = 0;

	always @(posedge clk) begin
		case (state)
			IDLE: begin
				if (start) begin
					state <= PREAMBLE;
					bit <= 0;
				end
			end
			PREAMBLE: begin
				bit <= bit + 1
			end
		endcase
	end




endmodule


module test();
	
   reg clk = 0;
	always #1 clk <= !clk;

	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0, test);
		#100000 $finish;
	end

	reg [20:0] cnt = 0;
	reg start1 = 0;
	reg start2 = 0;
	always @(posedge clk_eth) begin
		cnt <= cnt + 1;
		start1 <= (cnt == 31);
		start2 <= (cnt == 32);
	end

	reg clk_eth = 0;

	always @(posedge clk) begin
		clk_eth = ~clk_eth;
	end
	
	wire tx_eth;
	wire tx_eth2;
	eth_tx et1(clk_eth, start1, tx_eth);
	eth_tx2 et2(clk_eth, start2, tx_eth2);



endmodule

// vi: ft=verilog ts=3 sw=3
