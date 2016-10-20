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


module spi(
	input               clk,
	input               rst,
	// SPI 
	output              spi_sck,
	output              spi_mosi,
	input               spi_miso,
	//Config Register
	input               start,
	input      [15:0]    divisor,
	
	output             busy,
	output reg  [15:0]    rx_register,
	input       [15:0]    tx_register
);


reg sck;
reg [4:0] bitcount;

reg load;
reg active;

assign busy = active;
//prescaler registers for sclk
reg [15:0] prescaler;

//data shift register
reg [15:0] sreg;

assign spi_sck = sck;
assign spi_mosi = sreg[15];

always @(posedge clk or posedge rst) begin
  if (rst ) begin
    sck <= 0;
    bitcount <= 0;
    prescaler <= 0;
    sreg <= 0;
    rx_register <= 0;
  end else begin
    prescaler <= prescaler + 1;
    if(~active) begin
       sck <= 0;
       bitcount <= 0;
       prescaler <= 0;
       sreg <= 0;
       rx_register <= rx_register;
    end else if(load) begin
      sreg <= tx_register;
    end else if (prescaler == divisor) begin
      prescaler <= 8'h00;
      sck <= ~sck;
      if(sck == 1'b1) begin
        bitcount <= bitcount + 1;
        sreg <= sreg << 1;
      end else begin
        rx_register[15:0] <= {rx_register [14:0] ,spi_miso};
      end
    end
  end
end

parameter [1:0]IDLE       = 2'd0;
parameter [1:0]ACTIVE     = 2'd1;
parameter [1:0]LOAD       = 2'd2;

reg [1:0]state;

always @(state) begin
  case(state)
    IDLE: begin
      active = 0;
      load = 0;
    end
    LOAD: begin
      active = 1;
      load = 1;
    end         
    ACTIVE: begin
      active = 1;
      load = 0; 
    end
    default: begin
      active = 0;
      load = 0;    
    end
  endcase
end


always @(negedge clk or posedge rst) begin
  if(rst)
    state <= IDLE;
  else begin
    case(state) 
      IDLE:
        if(start)
          state <= LOAD;
        else
          state <= IDLE; 
      
      LOAD: state <= ACTIVE;
      
      ACTIVE:
        if(bitcount == 5'h10)
          state <= IDLE;
        else
          state <= ACTIVE;
      
      default: state <= IDLE ; 
          
    endcase 
  end 
end 



endmodule
