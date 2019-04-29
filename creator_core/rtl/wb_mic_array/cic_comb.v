/*
* Copyright 2016 <Admobilize>
* All rights reserved.
*/

module cic_comb#(
  parameter WIDTH  = "mandatory",
  parameter CHANNELS = "mandatory"
)(
  input  clk,
  input  resetn,
  input  read_en,
  input  wr_en,
  input  [$clog2(CHANNELS)-1:0] channel,
  input  signed [WIDTH-1:0] data_in,
  output reg signed [WIDTH-1:0] data_out
);

  reg signed [WIDTH-1:0] data_in_prev [0:CHANNELS-1];
  reg signed [WIDTH-1:0] data_out_prev[0:CHANNELS-1];

  localparam [2:0] S_IDLE  = 2'd0;
  localparam [2:0] S_READ  = 2'd1;
  localparam [2:0] S_STORE = 2'd2;

  reg  signed [WIDTH-1:0] prev;
  wire signed [WIDTH-1:0] diff;

  assign diff = data_in - prev;

  always @(posedge clk or posedge resetn) begin
    if (resetn) begin
      data_out <= 0;
      prev     <= 0;
    end
    else begin
      case({read_en,wr_en})
        2'b10 :
          begin
            data_out <= data_out_prev[channel];
            prev     <= data_in_prev[channel];
          end
        2'b01 :
          begin
            data_in_prev[channel]  <= data_in;
            data_out_prev[channel] <= diff;
          end
        default :
          data_out <= data_out;
      endcase
    end
  end

  integer i;
  initial begin
    for (i=0; i<CHANNELS; i=i+1) begin
      data_in_prev[i] = 0;
      data_out_prev[i] = 0;
    end
  end

endmodule
