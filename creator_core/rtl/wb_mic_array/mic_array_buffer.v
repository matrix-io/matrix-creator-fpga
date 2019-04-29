/*
* Copyright 2016 <Admobilize>
* All rights reserved.
*/


module mic_array_buffer #(
  parameter ADDR_WIDTH = "mandatory",
  parameter DATA_WIDTH = 16
) (
  // write port a
  input                       clk_a,
  input                       we_a ,
  input      [ADDR_WIDTH-1:0] adr_a,
  input      [DATA_WIDTH-1:0] dat_a,
  // read port b
  input                       clk_b,
  input      [ADDR_WIDTH-1:0] adr_b,
  output reg [DATA_WIDTH-1:0] dat_b,
  input                       en_b
);

  localparam DEPTH = (2 ** ADDR_WIDTH);

  reg [DATA_WIDTH-1:0] ram[0:DEPTH-1];
//------------------------------------------------------------------
// write port A
//------------------------------------------------------------------
  always @(posedge clk_a)
    begin
      if (we_a)
        ram[adr_a] <= dat_a;
    end

//------------------------------------------------------------------
// read port B
//------------------------------------------------------------------
  always @(posedge clk_b) begin
    if(en_b)
      dat_b <= ram[adr_b];
    else
      dat_b <= 0;
  end
endmodule
