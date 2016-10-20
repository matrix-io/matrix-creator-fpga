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

module wb_everloop#(
  parameter mem_file_name = "none"  
)(
  input clk,
  input nrst,
  
  // LED interface
  output everloop_ctl,
  input  led_fb,
    
  // Wishbone interface
  input              wb_stb_i,
  input              wb_cyc_i,
  input              wb_we_i,
  input       [13:0] wb_adr_i,
  input        [1:0] wb_sel_i,
  input       [15:0] wb_dat_i,
  output      [15:0] wb_dat_o   
);


/* CR = XXXX|everloop_select*/
reg [15:0] CR;
wire wb_rd = wb_stb_i & wb_cyc_i & ~wb_we_i;
wire wb_wr = wb_stb_i & wb_cyc_i & wb_we_i;

wire en_b,ack_b;
wire [7:0] data_b;
reg  [10:0] adr_b;
reg  [15:0] data_a;
reg reset_everloop;
reg [2:0] swr;

always @(negedge clk)  swr <= {swr[1:0],wb_wr};

wire wr_fallingedge = (swr[2:1]==2'b10);

reg add_adr_a;

initial begin
CR=0;
adr_b=0;
reset_everloop = 0;
end

everloop everloop0(
  .clk(clk),
  .rst(nrst),
  .everloop_d(everloop_ctl),
  
  .ack(ack_b),
  .en_rd(en_b),
  .data_RGB(data_b),
  .reset_everloop(reset_everloop)
); 


everloop_ram #(
  .adr_width(11), 
  .dat_width(8), 
  .mem_file_name(mem_file_name)
) everloopram0(
	// write port a 
	.clk_a(clk),
	.en_a(wb_wr | add_adr_a),
	.adr_a({wb_adr_i[9:0],add_adr_a}),
	.dat_a(data_a[7:0]),
	.we_a(wb_wr | add_adr_a),
	// read port b
	.clk_b(clk),
	.en_b(en_b),
	.adr_b(adr_b),
  .ack_b(ack_b),
	.dat_b(data_b)
	
);

reg[3:0] clk_cnt;

always @(posedge clk)
begin
if(nrst) begin
adr_b <= 0;
reset_everloop <= 1;
clk_cnt <= 0 ;
end else begin
if(en_b) 
  if(adr_b == 140) begin
  clk_cnt <= clk_cnt +1;
    if(clk_cnt < 4'd10) begin 
      
      reset_everloop <= 1;
    end else adr_b <= 0;
  end else begin
    adr_b <= adr_b+1;
    reset_everloop <= 0;
    clk_cnt<=0;
  end
end

end

always @(posedge clk)
begin

case({wb_wr,wr_fallingedge})
  2'b10: begin
    data_a <= wb_dat_i;
    add_adr_a <= 0;
  end
  2'b01:begin
    data_a <= data_a >>8;
    add_adr_a <= 1;
  end
  
  default: begin
    data_a <= data_a;
    add_adr_a <= 0;
  end



endcase
end






always @(posedge clk)
begin
	if (nrst) begin
	  CR <= 0;
	end else begin
    if (wb_wr) begin
      if(wb_adr_i[0]==1) begin
        CR <= wb_dat_i;
      end
		end
	end
end


endmodule
