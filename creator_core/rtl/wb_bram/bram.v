/*
 * Milkymist SoC
 * Copyright (C) 2007, 2008, 2009 Sebastien Bourdeauducq
 * Copyright (C) 2011 CERN
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

//-----------------------------------------------------------------
// Wishbone BlockRAM
//-----------------------------------------------------------------

module wb_bram #(
  parameter mem_file_name = "none",
  parameter adr_width = 10
) (
  input             clk_i, 
  //
  input             wb_stb_i,
  input             wb_cyc_i,
  input             wb_we_i,
  input      [13:0] wb_adr_i,
  output reg [15:0] wb_dat_o,
  input      [15:0] wb_dat_i,
  input      [ 1:0] wb_sel_i
);

//-----------------------------------------------------------------
//
//-----------------------------------------------------------------
parameter word_depth = (1 << adr_width);

//-----------------------------------------------------------------
// 
//-----------------------------------------------------------------


wire ram0we;
reg  [15:0] ram [0:word_depth-1];    // actual RAM

assign ram0we = wb_cyc_i & wb_stb_i & wb_we_i;

always @(posedge clk_i)
begin
      if (ram0we) begin
        ram[ wb_adr_i ] <= wb_dat_i;
      end
      wb_dat_o <= ram[ wb_adr_i ];
end

initial 
begin
  if (mem_file_name != "none")
  begin
  $readmemh(mem_file_name, ram);
  end
end

endmodule

