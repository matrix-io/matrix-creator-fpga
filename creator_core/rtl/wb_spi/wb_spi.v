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

module wb_spi(
	input               clk,
	input               reset,
	// Wishbone bus
	input      [15:0]   wb_adr_i,
	input      [15:0]   wb_dat_i,
	output reg [15:0]   wb_dat_o,
	input      [ 3:0]   wb_sel_i,
	input               wb_cyc_i,
	input               wb_stb_i,
	input               wb_we_i,
	// SPI 
	output              spi_sck,
	output              spi_mosi,
	input               spi_miso,
	output reg          spi_cs,
	output reg          spi_rst
);


wire [15:0] rx_register;
reg start;
reg [15:0] divisor;
wire busy;


spi spi0(
  .clk(clk),
  .rst(reset),
	// SPI 
  .spi_sck(spi_sck),
  .spi_mosi(spi_mosi),
  .spi_miso(spi_miso),
  .busy(busy),
	//Config Register
 .start(start),
 .divisor(divisor),
 .rx_register({rx_register[7:0],rx_register[15:8]}),
 .tx_register({wb_dat_i[7:0],wb_dat_i[15:8]})
);

	wire wb_rd = wb_stb_i & wb_cyc_i  & ~wb_we_i;
	wire wb_wr = wb_stb_i & wb_cyc_i  & wb_we_i;

	always @(posedge clk or posedge reset) begin
		if (reset == 1'b1) begin
			start   <= 1'b0;
			spi_cs  <= 1'b0; 
			spi_rst <= 1'b0;
		end else begin
		start <= 1'b0;
			if (wb_rd) begin
			     // read cycle
				case (wb_adr_i[3:0])
					4'h0:
				    wb_dat_o <= rx_register;
				    
				  4'h1:
				    wb_dat_o <= {15'h0000,busy};
				  
				  4'h3:
							wb_dat_o <= divisor;
							
					default:
				    wb_dat_o <= 0;
				endcase
			end			
			if (wb_wr) begin // write cycle
				case (wb_adr_i[3:0])
					4'h0: begin //Load TX buffer into SPI
							start <= 1'b1;
					  end
					4'h2:
							spi_cs  <=  wb_dat_i[0];
					4'h3:
							divisor <=  wb_dat_i;
				  4'h4:
				      spi_rst <= wb_dat_i[0];
					default: begin
					    start <= 1'b0;
					    spi_cs  <=   spi_cs;
					    divisor <=   divisor;
					    spi_rst <= spi_rst;
				    end					    
				endcase
			end
		end
	end


endmodule
