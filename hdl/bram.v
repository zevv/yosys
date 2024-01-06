
`default_nettype none


module bram(
   input wire clk,
   input wire rd_en, input wire [9:0] rd_addr, output reg [7:0] rd_data,
   input wire wr_en, input wire [9:0] wr_addr, input wire [7:0] wr_data
);

   localparam SIZE = 1024;

   reg [7:0] memory [0:SIZE-1];
   integer i;

   initial begin
      memory[0] = 8'h00;
      memory[1] = 8'h01;
      memory[2] = 8'h02;
      memory[3] = 8'h02;
      memory[4] = 8'h03;
      memory[5] = 8'h04;

      memory[6] = 8'h05;
      memory[7] = 8'h06;
      memory[8] = 8'h07;
      memory[9] = 8'h08;
      memory[10] = 8'h09;
      memory[11] = 8'h0a;

      memory[12] = 8'h42;
      memory[13] = 8'h42;
      // rd_data = 0; //should not exist if we want bram to be inferred
   end

   always @(posedge clk)
   begin

      if(wr_en) begin
         memory[wr_addr] <= wr_data;
      end
      if (rd_en) begin
         rd_data <= memory[rd_addr];
      end
   end
endmodule



// vi: ft=verilog ts=3 sw=3 et
