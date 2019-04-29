/*
* Copyright 2016 <Admobilize>
* All rights reserved.
*/

module cic_op_fsm#(
  parameter WIDTH  = "mandatory",
  parameter CHANNELS = "mandatory"
)(
  input  clk,
  input  resetn,
  input  enable,
  output reg read_en,
  output reg wr_en,
  output reg [$clog2(CHANNELS)-1:0] channel
);

  wire channel_en;

  always @(posedge clk or posedge resetn) begin
    if (resetn|~enable)
      channel <= 0;
    else
      if (wr_en)
        channel <= channel + 1'b1;
  end

  localparam [2:0] S_IDLE  = 3'd0;
  localparam [2:0] S_READ  = 3'd1;
  localparam [2:0] S_STORE = 3'd2;

  reg [2:0] state;

  always @(state) begin
    case(state)
      S_IDLE :
        {read_en,wr_en} = 3'b00;
      S_READ :
        {read_en,wr_en} = 2'b10;
      S_STORE :
        {read_en,wr_en} = 2'b01;
      default :
        {read_en,wr_en} = 2'b00;
    endcase
  end

  always @(posedge clk or posedge resetn) begin
    if(resetn)
      state <= S_IDLE;
    else begin
      case(state)
        S_IDLE :
          if(enable)
            state <= S_READ;
        S_READ :
          state <= S_STORE;
        S_STORE :
          if(enable)
            state <= S_READ;
        else
          state <= S_IDLE;

        default :
          state <= S_IDLE;
      endcase
    end
  end

endmodule