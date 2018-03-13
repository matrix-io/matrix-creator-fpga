/*
* Copyright 2016 <Admobilize>
* All rights reserved.
*/

module uart_fifo #(
  parameter ADDRESS_WIDTH = "mandatory",
  parameter DATA_WIDTH    = "mandatory"
) (
  input                       clk         ,
  input                       resetn       ,
  // write port a
  input                       write_enable,
  output reg                  write_ack   ,
  input      [DATA_WIDTH-1:0] data_a      ,
  // read port b
  input                       read_enable ,
  output reg                  read_ack    ,
  output reg [DATA_WIDTH-1:0] data_b      ,
  //status
  input                       fifo_flush,
  output                      empty,
  output                      full,

  output reg [ADDRESS_WIDTH-1:0] read_pointer,
  output reg [ADDRESS_WIDTH-1:0] write_pointer
);

  initial begin
    write_ack = 0;
  end

  localparam DEPTH = (2 ** ADDRESS_WIDTH);

  reg [DATA_WIDTH-1:0] ram[0:DEPTH-1];

  assign empty = (write_pointer == read_pointer);

  always @(posedge clk or posedge resetn) begin
    if(resetn | fifo_flush) begin
      read_pointer <= 0;
    end else if(read_ack) begin
      read_pointer <= read_pointer + 1;
    end
  end


  always @(posedge clk or posedge resetn) begin
    if(resetn | fifo_flush) begin
      write_pointer <= 0;
    end else if(write_ack ) begin
      write_pointer <= write_pointer + 1;
    end
  end

//------------------------------------------------------------------
// write port A
//------------------------------------------------------------------
  always @(posedge clk) begin
    write_ack <= 0;
    if (write_enable) begin
      ram[write_pointer] <= data_a;
      write_ack          <= 1;
    end
  end

//------------------------------------------------------------------
// read port B
//------------------------------------------------------------------
  always @(posedge clk) begin
    read_ack <= 0;
    if(read_enable & (~empty)) begin
      data_b   <= ram[read_pointer];
      read_ack <= 1;
    end else
      data_b <= data_b;
  end

endmodule // uart_fifo