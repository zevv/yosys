
/* verilator lint_off DECLFILENAME */

module eth_tx(input clk, input start, output reg tx = 0);


	reg [6:0] rdaddress = 0;
	reg [7:0] pkt_data = 0;

	reg [7:0] frame [0:8'h43];
	initial begin
		$readmemh("frame.bin", frame);
	end

	always @(posedge clk)
		pkt_data <= frame[rdaddress];

	//////////////////////////////////////////////////////////////////////
	// and finally the 10BASE-T's magic
	reg [3:0] ShiftCount = 0;
	reg SendingPacket = 0;

	always @(posedge clk)
		if(start)
			SendingPacket<=1;
		else
			if(ShiftCount==14 && rdaddress==7'h48) SendingPacket<=0;

	always @(posedge clk)
		ShiftCount <= SendingPacket ? ShiftCount+1 : 15;

	wire readram = (ShiftCount==15);

	always @(posedge clk)
		if(ShiftCount==15)
			rdaddress <= SendingPacket ? rdaddress+1 : 0;

	reg [7:0] ShiftData = 0;
	always @(posedge clk)
		if(ShiftCount[0])
			ShiftData <= readram ? pkt_data : {1'b0, ShiftData[7:1]};

		// generate the CRC32
	reg [31:0] CRC = 0;
	reg CRCflush = 0;

	always @(posedge clk)
		if(CRCflush)
			CRCflush <= SendingPacket;
		else
			if(readram)
				CRCflush <= (rdaddress==7'h44);

	reg CRCinit = 0;
	always @(posedge clk)
		if(readram)
			CRCinit <= (rdaddress==7);
		wire CRCinput = CRCflush ? 0 : (ShiftData[0] ^ CRC[31]);

	always @(posedge clk)
		if(ShiftCount[0])
			CRC <= CRCinit ? ~0 : ({CRC[30:0],1'b0} ^ ({32{CRCinput}} & 32'h04C11DB7));

	// generate the NLP
	reg [17:0] LinkPulseCount = 0;
	always @(posedge clk)
		LinkPulseCount <= SendingPacket ? 0 : LinkPulseCount+1;
	reg LinkPulse = 0;

	always @(posedge clk)
		LinkPulse <= &LinkPulseCount[17:1];

	// TP_IDL, shift-register and manchester encoder
	reg SendingPacketData = 0;

	always @(posedge clk)
		SendingPacketData <= SendingPacket;

	reg [2:0] idlecount = 0;
	always @(posedge clk)
		if(SendingPacketData)
			idlecount<=0;
		else
			if(~&idlecount)
				idlecount<=idlecount+1;
	wire dataout = CRCflush ? ~CRC[31] : ShiftData[0];

	reg qo = 0;
	always @(posedge clk)
		qo <= SendingPacketData ? ~dataout^ShiftCount[0] : 1;

	reg qoe = 0;
	always @(posedge clk)
		qoe <= SendingPacketData | LinkPulse | (idlecount<6);

	always @(posedge clk)
		tx <= (qoe ? qo : 1'b0);

endmodule



module eth_tx2(input clk, input start, output reg tx = 0);

	localparam
		LINK = 0,
		TX_PREAMBLE = 1,
		TX_SFD = 2,
		TX_DATA = 3,
		TX_CRC = 4,
		IDLE = 5,
		IPG = 6;

	reg [7:0] frame [0:'d60];
	initial begin
		$readmemh("frame2.bin", frame);
	end

	reg [10:0] len = 'd60;
	reg [2:0] state = LINK;
	reg [18:0] n = 0;
	reg [10:0] ptr = 0;
	reg [7:0] next_byte = 0;
	reg [7:0] shift = 0;
	reg [31:0] crc = 0;
		
	always @(posedge clk) begin
		
		n <= n + 1;
		
		case (state)
			LINK: if (start) ptr <= 0;
			TX_SFD: if(n == 15) ptr <= 1;
			TX_PREAMBLE, TX_SFD, TX_DATA: if (n == 15) ptr <= ptr + 1;
		endcase

		case (state)
			LINK: tx <= (n == 0);
			TX_PREAMBLE: tx <= shift[0] ^ ~n[0];
			TX_SFD: tx <= shift[0] ^ ~n[0];
			TX_DATA: tx <= shift[0] ^ ~n[0];
			TX_CRC: tx <= crc[31] ^ n[0];
			IDLE: tx <= 1;
			IPG: tx <= 0;
		endcase

		case (state)
			LINK:
				if (start) n <= 0;
			TX_PREAMBLE, TX_SFD, TX_DATA:
				if (n == 15) n <= 0;
			TX_CRC:
				if (n == 63) n <= 0;
		endcase

		case (state)
			LINK: shift <= 8'h55;
			TX_PREAMBLE, TX_SFD, TX_DATA: begin
				if (n[0])
					shift <= { 1'b0, shift[7:1] };
				if (n == 15) begin
					shift <= next_byte;
				end
			end
		endcase
		
		case (state)
			TX_SFD: crc <= 32'hFFFFFFFF;
			TX_DATA: if (!n[0]) crc <= ({crc[30:0],1'b0} ^ ({32{shift[0] ^ crc[31]}} & 32'h04C11DB7));
			TX_CRC: if (n[0]) crc <= crc << 1;
		endcase

		case (state)
			LINK: next_byte <= 8'h55;
			TX_PREAMBLE: if( ptr == 6) next_byte <= 8'hD5;
			TX_SFD: next_byte <= frame[0];
			TX_DATA: next_byte <= frame[ptr];
		endcase

		case (state)
			LINK: if (start) state <= TX_PREAMBLE;
			TX_PREAMBLE: if (ptr == 6 && n == 15) state <= TX_SFD;
			TX_SFD: if(n == 15) state <= TX_DATA;
			TX_DATA: if (ptr == len && n == 15) state <= TX_CRC;
			TX_CRC: if (n == 63) state <= IDLE;
			IDLE: if (n == 5) state <= IPG;
			IPG: if (n == 192) state <= LINK;
		endcase

	end

endmodule


// vi: ft=verilog ts=3 sw=3
