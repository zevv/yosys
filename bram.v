
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
      for(i = 0; i < SIZE; i=i+1) begin
         memory[i] = i;
      end
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
