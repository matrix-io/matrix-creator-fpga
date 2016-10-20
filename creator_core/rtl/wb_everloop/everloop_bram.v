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
  parameter mem_file_name = "none",
	parameter adr_width = 7,
	parameter dat_width = 7
) (
	// write port a 
	input                       clk_a,
	input                       en_a,
	input                       en_b,
	input      [9:0]           adr_a,
	input 	   [7:0]  dat_a,
	// read port b
	input                       clk_b,
	input      [9:0]  adr_b,
	output reg [7:0]  dat_b,
	output reg         ack_b,
	output reg [7:0]  dat_a_out,
	input  we_a
);

parameter depth = (1 << adr_width);
// actual ram cells
reg [dat_width-1:0] ram [0:depth-1];
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


initial 
begin
	if (mem_file_name != "none")
	begin
		$readmemh(mem_file_name, ram);
	end
end


endmodule
