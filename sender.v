
module sender(input clk, input clk_en, output tx, output tx_led);

   reg [20:0] tick = 0;
   reg start = 0;
   reg eth_w_en = 0;
   reg [7:0] eth_w_addr = 0;
   reg [7:0] eth_w_data = 0;
   reg [31:0] flop = 0;

   eth_tx2 et(clk, clk_en, eth_w_addr, eth_w_data, eth_w_en, start, tx, tx_led);

   always @(posedge clk) begin
      if (clk_en) begin
         tick <= tick + 1;
         case (tick)
            0: flop <= flop + 1;
            1: eth_w_addr <= 8'h3b;
            2: eth_w_data <= flop[7:0];
            3: eth_w_en <= 1;
            4: eth_w_en <= 0;
            5: eth_w_addr <= 8'h3a;
            6: eth_w_data <= flop[15:8];
            7: eth_w_en <= 1;
            8: eth_w_en <= 0;
            9: eth_w_addr <= 8'h39;
            10: eth_w_data <= flop[23:16];
            11: eth_w_en <= 1;
            12: eth_w_en <= 0;
            13: eth_w_addr <= 8'h38;
            14: eth_w_data <= flop[31:24];
            15: eth_w_en <= 1;
            16: eth_w_en <= 0;
            17: start <= 1;
            18: start <= 0;
         endcase
      end

   end

endmodule


// vi: ft=verilog ts=3 sw=3 et
