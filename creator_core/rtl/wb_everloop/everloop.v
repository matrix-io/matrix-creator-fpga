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

module everloop (
  input clk,rst,
  output reg everloop_d,
  
  input [7:0] data_RGB,
  output en_rd,
  input ack,
  input reset_everloop
//  input everloop_select
);

reg [7:0]clk_cnt;
reg [2:0]data_cnt;
reg [7:0]data_register;
reg sh_e,rd_e,rd_ant;
wire s_data;


initial begin
clk_cnt = 0;
data_cnt = 0;
data_register = 0;
sh_e = 0;
rd_e = 0;
rd_ant = 0;
everloop_d=0;

end

assign s_data = data_register[7];

always @(posedge clk)
begin 
  if (rst | sh_e) begin 
    clk_cnt <= 0;
  end else begin
    clk_cnt <= clk_cnt+1;
  end
end

always @(posedge clk) begin
  if(rst | ack) begin
  sh_e <= 0;
  data_cnt <= 0;
  end else begin 
    if (clk_cnt == 8'd240) begin
      sh_e <= 1'b1;
      data_cnt <= data_cnt + 1;  
    end else begin
      sh_e <= 1'b0;
      data_cnt <= data_cnt;
    end  
  end
end

always @(posedge clk) begin
  if(rst) begin
  rd_e <= 0;
  rd_ant <= 0;
  end else begin 
    rd_ant <= rd_e;
    if (data_cnt == 3'd0 ) begin
      rd_e <= 1'b1;  
    end else begin
      rd_e <= 1'b0;
    end  
  end
end


always @(posedge clk) begin

  if(rst) begin
    data_register <= 0;
  end else begin
    if(ack) begin
      data_register <= data_RGB;
    end else begin    
      if(sh_e) begin
        data_register <= data_register << 1; 
      end else begin
        data_register <= data_register;
      end
    end
  end
  
end

assign en_rd = rd_e & ~ rd_ant;



always @(posedge clk) begin

  if(rst | reset_everloop ) begin
      everloop_d <= 0;
  end else begin
    
    case({1'b1, s_data})
      
      2'b00: begin
          if(clk_cnt < 8'd80) begin
            everloop_d <= 1;
          end else begin
            everloop_d <= 0;
          end
        end
      2'b10: begin
          if(clk_cnt < 8'd60) begin
            everloop_d <= 1;
          end else begin
            everloop_d <= 0;
          end
        end
      2'b01: begin
          if(clk_cnt < 8'd160) begin
            everloop_d <= 1;
          end else begin
            everloop_d <= 0;
          end
        end
      2'b11: begin
          if(clk_cnt < 8'd120) begin
            everloop_d <= 1;
          end else begin
            everloop_d <= 0;
          end
        end
    
    endcase
  
  end


end


endmodule



