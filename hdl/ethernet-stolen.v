
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

   // TP_IDL, data_out-register and manchester encoder
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


// vi: ft=verilog ts=3 sw=3 et
