
/* verilator lint_off DECLFILENAME */

module eth_tx2(input clk, input clk_en, input [7:0] w_addr, input [7:0] w_data, input w_en, input start, output reg tx = 0, output tx_led);
   
   reg [10:0] len = 'd200;
   reg [7:0] frame [0:'hff];
   integer k;
   initial begin
      //$readmemh("zeros.bin", frame);
      for (k=0; k<200; k=k+1) frame[k] = 0;
   end

   localparam LINK = 0, PREAMBLE = 1, SFD = 2, DATA = 3, CRC = 4, IDLE = 5, IPG = 6;
   localparam CRC_INIT = 32'hFFFFFFFF, CRC_POLY = 32'h04C11DB7;

   reg [19:0] link_timer = 0;
   reg [2:0] state = LINK;
   reg [18:0] n = 0;
   reg [10:0] ptr = 0;
   reg [7:0] data_next = 0;
   reg [7:0] data_out = 0;
   reg [31:0] crc = 0;
   reg [31:0] crc2 = 0;

   wire empty = (n == 15);
   assign tx_led = (state == LINK);

   always @(posedge clk) begin

      if (w_en) begin
         frame[w_addr] <= w_data;
      end

      if(clk_en) begin

         link_timer <= link_timer + 1;
         if (link_timer == 320000) begin
            link_timer <= 0;
         end

         n <= n + 1;
         case (state)
            LINK: if (start) n <= 0;
            PREAMBLE, SFD, DATA: if (empty) n <= 0;
            CRC: if (n == 63) n <= 0;
         endcase

         case (state)
            LINK: ptr <= 0;
            SFD: if (empty) ptr <= 1;
            PREAMBLE, SFD, DATA: if (empty) ptr <= ptr + 1;
         endcase

         case (state)
            LINK: tx <= (link_timer == 0);
            PREAMBLE: tx <= data_out[0] ^ !n[0];
            SFD: tx <= data_out[0] ^ !n[0];
            DATA: tx <= data_out[0] ^ !n[0];
            CRC: tx <= crc[31] ^ n[0];
            IDLE: tx <= 1;
            IPG: tx <= 0;
         endcase

         case (state)
            LINK: data_out <= 8'h55;
            PREAMBLE, SFD, DATA: begin
               if (n[0]) data_out <= data_out >> 1;
               if (empty) data_out <= data_next;
            end
         endcase

         case (state)
            PREAMBLE: crc <= CRC_INIT;
            DATA: if (!n[0]) crc <= (crc << 1) ^ ( {32{data_out[0] ^ crc[31]}} & CRC_POLY );
            CRC: if (n[0]) crc <= crc << 1;
         endcase

         case (state)
            LINK: data_next <= 8'h55;
            PREAMBLE: if(ptr == 6) data_next <= 8'hD5;
            SFD: data_next <= frame[0];
            DATA: data_next <= frame[ptr];
         endcase

         case (state)
            LINK: if (start) state <= PREAMBLE;
            PREAMBLE: if (ptr == 6 && empty) state <= SFD;
            SFD: if(empty) state <= DATA;
            DATA: if (ptr == len && empty) state <= CRC;
            CRC: if (n == 63) state <= IDLE;
            IDLE: if (n == 5) state <= IPG;
            IPG: if (n == 192) state <= LINK;
         endcase
         
      end
   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
