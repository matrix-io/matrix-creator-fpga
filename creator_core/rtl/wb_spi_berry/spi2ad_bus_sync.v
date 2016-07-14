/*
 * Copyright 2016 <Admobilize>
 * MATRIX Labs  [http://creator.matrix.one]
 * This file is part of MATRIX Creator HDL for Spartan 6
 *
 * MATRIX Creator HDL is like free software: you can redistribute 
 * it and/or modify it under the terms of the GNU General Public License 
 * as published by the Free Software Foundation, either version 3 of the 
 * License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU 
 * General Public License for more details.

 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

`timescale 1ns / 1ps
module spi2ad_bus #(
       parameter ADDR_WIDTH = 16,
       parameter DATA_WIDTH = 16
) (
  input  clk,
  input  resetn,

  // SPI interface
  input  mosi,
  input  ss,
  input  sck,
  output miso,

  output [DATA_WIDTH-1:0] data_bus_out,
  input  [DATA_WIDTH-1:0] data_bus_in,
  output [ADDR_WIDTH-1:0] addr_bus,
  output wr,
  output rd,
  output strobe,
  output cycle
);


reg  [4:0] bit_count;
reg  [DATA_WIDTH-1:0] data_in_sr, data_out_sr;
reg  [ADDR_WIDTH-1:0] addr_bus_latched;
reg  [DATA_WIDTH-1:0] data_in_latched;
reg  auto_inc, rd_wrn, data_confn; 


// Sync signals
//
// Sync SCK to the FPGA clock using a 3-bits shift register
reg [2:0] SCKr;  always @(negedge clk)   SCKr <= {SCKr[1:0], sck};

// Sync ss to the FPGA clock using a 3-bits shift register
reg [2:0] SSELr;  always @(negedge clk) SSELr <= {SSELr[1:0], ss};

// and for MOSI
reg [1:0] MOSIr;  always @(posedge clk) MOSIr <= {MOSIr[0], mosi};


//This component generates the addr/data bus from spi commands
// communication is made in 16 bit per word in mode 0 at max speed 50Mhz (for now)
// The first written word is interprated as follow:
// [15 : 2] 14 bit bus address
// [1] : on for auto increment address, zero otherwise
// [0] : one if read, zero if write
wire SCK_risingedge = (SCKr[2:1]==2'b01);  // now we can detect SCK rising edges
wire SCK_fallingedge = (SCKr[2:1]==2'b10);  // and falling edges

wire SSEL_active = ~SSELr[1];  // SSEL is active low
wire SSEL_startmessage = (SSELr[2:1]==2'b10);  // message starts at falling edge
wire SSEL_endmessage = (SSELr[2:1]==2'b01);  // message stops at rising edge
wire MOSI_data = MOSIr[1];


always @(posedge clk)
begin
  if (~SSEL_active) begin
    bit_count  <=  4'h0;
  end else if (SCK_risingedge) begin
    data_in_sr[DATA_WIDTH-1:0] <= {data_in_sr[DATA_WIDTH-2:0], MOSI_data};
    bit_count <= bit_count + 1;
  end

end

wire en_data_out_sr;
assign en_data_out_sr = rd_wrn & ( (bit_count == 5'h10) | ( (bit_count[3:0] == 0) & auto_inc ) );


always @(posedge clk)
begin
  if (~SSEL_active) begin
    data_out_sr <=  {DATA_WIDTH{1'b0}};
  end else begin
    
    if(en_data_out_sr)begin 
      data_out_sr <= data_bus_in;
    end else begin
      data_out_sr <= data_out_sr;    
    end
  
  end
end

reg [DATA_WIDTH-1:0] miso_sr;

always @(posedge clk)
begin
  if (en_data_out_sr & SCK_fallingedge ) begin
    miso_sr <= data_out_sr;
  end else begin
    
    if(SCK_fallingedge)begin 
      miso_sr <= { miso_sr[DATA_WIDTH-2:0] , 1'b0 };
    end else begin
      miso_sr <= miso_sr;    
    end
  
  end
end

assign miso = miso_sr[DATA_WIDTH-1]; 
always @(posedge clk)
begin
  if (~SSEL_active) begin
    data_confn <= 1'b0;
    auto_inc   <= 1'b0;
    rd_wrn     <= 1'b0;
  end else begin
    if ( (data_confn == 1'b0) && (bit_count == 5'h10) )  begin   //Read address first 16 bits
      addr_bus_latched <= {2'b00, data_in_sr[DATA_WIDTH-1:2]};
      auto_inc           <= data_in_sr[1];                // 
      rd_wrn             <= data_in_sr[0];                // 
      data_confn         <= 1'b1;                         // enable read the second 16 bits (data)
    end
  end
end


assign data_bus_out  = data_in_latched;
assign addr_bus = addr_bus_latched;

wire en_data_in_latched ;

assign en_data_in_latched = (data_confn & ~SCK_risingedge & ~rd_wrn) & ( (bit_count == 5'h00)  | ( bit_count[3:0] == 0) & auto_inc ) ;

always @(posedge clk) begin
  if(~SSEL_active) begin
    data_in_latched <= {DATA_WIDTH{1'b0}};
  end else begin
    if(en_data_in_latched) begin
      data_in_latched <= data_in_sr[15:0];
    end else begin
      data_in_latched <= data_in_latched;
    end
  end
end

wire en_wr, en_rd;
assign wr = (data_confn == 1'b1) & ~rd_wrn & ( (bit_count == 5'h00) | ( (bit_count[3:0] == 0) & auto_inc ) );
assign rd = (data_confn == 1'b1) & rd_wrn & ( (bit_count == 5'h10) | ( (bit_count[3:0] == 0) & auto_inc ) );

assign strobe = wr | rd;
assign cycle = strobe;


initial begin
  bit_count = 0;
  data_in_sr = 0;
  data_out_sr = 0; 
  addr_bus_latched = 0;
  data_in_latched = 0;
  auto_inc = 0;
  rd_wrn = 0;
  data_confn= 0; 
  miso_sr = 0;  
end

endmodule


