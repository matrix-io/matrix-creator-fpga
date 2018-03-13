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


module everloop_ram #(
	parameter MEM_FILE_NAME = "none",
	parameter ADDR_WIDTH = "mandatory",
	parameter DATA_WIDTH = "mandatory"
) (
	// write port a
	input                       clk_a    ,
	input                       en_a     ,
	input                       en_b     ,
	input      [ADDR_WIDTH-1:0] adr_a    ,
	input      [DATA_WIDTH-1:0] dat_a    ,
	// read port b
	input                       clk_b    ,
	input      [ADDR_WIDTH-1:0] adr_b    ,
	output reg [DATA_WIDTH-1:0] dat_b    ,
	output reg                  ack_b    ,
	output reg [DATA_WIDTH-1:0] dat_a_out,
	input                       we_a
);

	localparam DEPTH = (1 << ADDR_WIDTH);
	reg [DATA_WIDTH-1:0] ram[0:DEPTH-1];
//------------------------------------------------------------------
// read port B
//------------------------------------------------------------------
	always @(posedge clk_b)
		begin
			ack_b <= 0;
			if (en_b)
				ack_b <= 1'b1;
			dat_b <= ram[adr_b];
		end

//------------------------------------------------------------------
// write port A
//------------------------------------------------------------------
	always @(posedge clk_a)
		begin
			if (en_a) begin
				if (we_a) begin
					ram[adr_a] <= dat_a;
				end
			end
		end

endmodule
