
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

	reg [7:0] next_byte;

	always @(posedge clk) begin
		if (state == TX_DATA)
			next_byte <= frame[ptr];
		else
			next_byte <= (ptr < 6) ? 'h55 : 'hD5;
	end
	
	reg [10:0] ptr = 0;

	always @(posedge clk) begin
		if (start || n == 14) begin
			case (state)
				IDLE: begin
					ptr <= 0;
				end
				PREAMBLE: begin
					if (ptr == 6)
						ptr <= 0;
					else
						ptr <= ptr + 1;
				end
				TX_DATA: begin
					if (ptr == 'h43)
						ptr <= 0;
					else
						ptr <= ptr + 1;
				end
			endcase
		end
	end


	wire byte;
	assign byte = (n == 0);
	
	reg [1:0] state = IDLE;

	always @(posedge clk) begin
		case (state)
			IDLE: begin
				if (start) begin
					state <= PREAMBLE;
				end
			end
			PREAMBLE: begin
				if (ptr == 6 && n == 14) begin
					state <= TX_DATA;
				end
			end
			TX_DATA: begin
				if (ptr == 'h43 && n == 14) begin
					state <= IDLE;
				end
			end
		endcase
	end

	reg [3:0] n = 0;

	always @(posedge clk) begin
		if (state == TX_DATA | state == PREAMBLE)
			n <= n + 1;
		else
			n <= 15;
	end

	reg [7:0] shift = 0;
	always @(posedge clk) begin
		if (n == 15) begin
			if (state == TX_DATA | state == PREAMBLE) begin
				shift = next_byte;
			end 
		end else begin
			if (n[0]) begin
				shift = {1'b0, shift[7:1]};
			end
		end
	end

	reg [31:0] crc = ~0;
	wire crcinput = (shift[0] ^ crc[31]);

	always @(posedge clk) begin
		if(n[0])
			if (state == TX_DATA && n == 15)
				crc <= ~0;
			else
				crc <= ({crc[30:0],1'b0} ^ ({32{crcinput}} & 32'h04C11DB7));
	end

	always @(posedge clk) begin
		if (state == IDLE) begin
			tx <= 0;
		end else begin
			tx <= shift[0] ^ ~n[0];
		end
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
