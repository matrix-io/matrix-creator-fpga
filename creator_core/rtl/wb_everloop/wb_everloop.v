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

module wb_everloop #(
  parameter MEM_FILE_NAME = "none" ,
  parameter SYS_FREQ_HZ = "mandatory",
  parameter DATA_WIDTH = "mandatory",
  parameter ADDR_WIDTH = "mandatory"
) (
  input                       clk         ,
  input                       resetn      ,
  input                       led_fb      ,
  input                       wb_stb_i    ,
  input                       wb_cyc_i    ,
  input                       wb_we_i     ,
  input      [           1:0] wb_sel_i    ,
  input      [ADDR_WIDTH-1:0] wb_adr_i    ,
  input      [DATA_WIDTH-1:0] wb_dat_i    ,
  output     [DATA_WIDTH-1:0] wb_dat_o    ,
  output reg                  wb_ack_o    ,
  //Everloop
  output                      everloop_ctl
);

  localparam MEM_ADDR_WIDTH = 8;
  localparam MEM_DATA_WIDTH = DATA_WIDTH/2;

  wire wb_rd = wb_stb_i & wb_cyc_i & ~wb_we_i & ~wb_ack_o;
  wire wb_wr = wb_stb_i & wb_cyc_i & wb_we_i & ~wb_ack_o ;

  reg [2:0] swr;

  always @(posedge clk)  swr <= {swr[1:0],wb_wr};

  reg  [MEM_ADDR_WIDTH-1:0] adr_a ;
  reg  [MEM_ADDR_WIDTH-1:0] adr_b ;
  wire [MEM_DATA_WIDTH-1:0] data_b;

  reg [DATA_WIDTH-1:0] data_a;

  wire en_b,ack_b;
  reg  reset_everloop;

  everloop #(.SYS_FREQ_HZ(SYS_FREQ_HZ)) everloop0 (
    .clk           (clk           ),
    .rst           (resetn        ),
    .everloop_d    (everloop_ctl  ),
    
    .ack           (ack_b         ),
    .en_rd         (en_b          ),
    .data_RGB      (data_b        ),
    .reset_everloop(reset_everloop)
  );

  everloop_ram #(
    .ADDR_WIDTH   (MEM_ADDR_WIDTH),
    .DATA_WIDTH   (MEM_DATA_WIDTH),
    .MEM_FILE_NAME(MEM_FILE_NAME )
  ) everloopram0 (
    // write port a
    .clk_a(clk                       ),
    .en_a (swr[1] | swr[2]           ),
    .adr_a(adr_a                     ),
    .dat_a(data_a[MEM_ADDR_WIDTH-1:0]),
    .we_a (swr[1] | swr[2]           ),
    // read port b
    .clk_b(clk                       ),
    .en_b (en_b                      ),
    .adr_b(adr_b                     ),
    .ack_b(ack_b                     ),
    .dat_b(data_b                    )
  );

  reg [3:0] clk_cnt;

  always @(posedge clk or posedge resetn) begin
    if(resetn) begin
      adr_b          <= 0;
      reset_everloop <= 1;
      clk_cnt        <= 0;
    end else begin
      if(en_b)
        if(adr_b == 140) begin
          clk_cnt <= clk_cnt +1;
          if(clk_cnt < 4'd10) begin
            reset_everloop <= 1;
          end else adr_b <= 0;
        end else begin
        adr_b          <= adr_b+1;
        reset_everloop <= 0;
        clk_cnt        <= 0;
      end
    end
  end

  always @(posedge clk or posedge resetn) begin
    if(resetn) begin
      adr_a    <= 0;
      data_a   <= 0;
      wb_ack_o <= 0;
    end
    else begin
      wb_ack_o <= 0;
      case({wb_wr,swr[1]})
        2'b10 : begin
          data_a   <= wb_dat_i;
          wb_ack_o <= 1;
          adr_a    <= {wb_adr_i[MEM_ADDR_WIDTH-2:0],1'b0};
        end
        2'b01 : begin
          data_a <= data_a >> 8;
          adr_a  <= {adr_a[MEM_ADDR_WIDTH-1:1],1'b1};
        end

        default : begin
          data_a <= data_a;
          adr_a  <= adr_a;
        end
      endcase
    end
  end

endmodule
