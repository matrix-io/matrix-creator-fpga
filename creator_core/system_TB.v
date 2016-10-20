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

  module system_TB;

       // Inputs
       reg clk;
       reg resetn;
       reg mosi;
       reg ss;
       reg sck;
       reg uart0_rx;
       reg uart1_rx;
       reg [7:0]pdm_data;
       
       // Outputs
       wire miso;
       wire led;
       wire [15:0] gpio_io;
       

       wire nfc_sck;
       reg nfc_miso;

  system uut(
       .clk_50(clk), .resetn(resetn), .mosi(mosi), .ss(ss), .sck(sck), 
       .miso(miso), .pdm_data(pdm_data), .gpio_io(gpio_io), .nfc_miso(nfc_miso), .nfc_sck(nfc_sck)
       
  );

  initial begin
    // Initialize Inputs
    resetn = 0; clk = 0; mosi = 0; ss = 1; sck = 1; uart0_rx = 0; nfc_miso = 0;
  end
  
//------------------------------------------
//          TRI-STATE GENERATION
//------------------------------------------
parameter PERIOD_INPUT = 8000;
parameter real DUTY_CYCLE_INPUT = 0.8;

reg [15:0] data;
reg [15:0] gpio_dir;

genvar k;
generate 
  for (k=0;k<16;k=k+1)  begin: gpio_tris
    assign gpio_io[k] = ~(gpio_dir[k]) ? data[k] : 1'bz;
  end
endgenerate

initial    // Clock process for clk
    begin
        #OFFSET;
        forever
        begin
            data = 16'h0000;
            #(PERIOD_INPUT-(PERIOD_INPUT*DUTY_CYCLE_INPUT)) data = 16'hFFFF;
            #(PERIOD_INPUT*DUTY_CYCLE_INPUT);
        end
    end


//------------------------------------------
//          RESET GENERATION
//------------------------------------------

event reset_trigger;
event reset_done_trigger;

initial begin 
  forever begin 
   @ (reset_trigger);
   @ (negedge clk);
   resetn = 1;
   @ (negedge clk);
   resetn = 0;
   -> reset_done_trigger;
  end
end


//------------------------------------------
//          CLOCK GENERATION
//------------------------------------------

    parameter TBIT   = 1;
    parameter PERIOD = 20;
    parameter real DUTY_CYCLE = 0.5;
    parameter OFFSET = 0;

//------------------------------------------
//          MEMORY MAP
//------------------------------------------
    
    parameter bram_addr = 0;
    parameter uart_addr = 14'h0800;
    parameter mica_addr = 14'h1000;
    parameter pxxx_addr = 14'h1800;
    parameter pyyy_addr = 14'h2000;

    parameter read      = 1;
    parameter write     = 0;
    parameter single    = 0;
    parameter burst     = 1;

    initial    // Clock process for clk
    begin
        #OFFSET;
        forever
        begin
            clk = 1'b0;
            #(PERIOD-(PERIOD*DUTY_CYCLE)) clk = 1'b1;
            #(PERIOD*DUTY_CYCLE);
        end
    end



//------------------------------------------
//          SPI SINGLE TRANSFER TASK
//------------------------------------------
  reg [4:0] i;
  reg [15:0] data_tx;

  task automatic spi_transfer;
    input [13:0] address;
    input [15:0] data;
    input autoinc;
    input RnW;
  begin
    data_tx = {address, autoinc, RnW};
    ss = 1;
    repeat(4*TBIT) begin
      @(negedge clk);
    end
    ss = 0; 
    repeat(2*TBIT) begin
      @(negedge clk);
    end
  ///////////////////
  // Send address 
  ///////////////////
    for(i=0; i<16; i=i+1) begin
      sck = 0;
      mosi <= data_tx[15-i];
      repeat(TBIT) begin
        @(negedge clk);
      end
      sck = 1;	
      repeat(TBIT) begin
        @(negedge clk);
      end
    end
  ///////////////////
  // Send data
  ///////////////////
    data_tx <= {data[7:0],data[15:8]};
    repeat(2*TBIT) begin
      @(negedge clk);
    end
    for(i=0; i<16; i=i+1) begin
      sck = 0;
      mosi <= data_tx[15-i];
      repeat(TBIT) begin
        @(negedge clk);
      end
      sck = 1;	
      repeat(TBIT) begin
        @(negedge clk);
      end
    end
    repeat(4*TBIT) begin
      @(negedge clk);
    end		
    ss = 1;
    repeat(4*TBIT) begin
      @(negedge clk);
    end
  end
  endtask

//------------------------------------------
//          SPI BURST TRANSFER TASK
//------------------------------------------
  reg [4:0] ib;
  reg [4:0] jb;
  reg [15:0] data_txb[18:0];
  task automatic spi_burst_transfer;
    input [13:0] address_b;
    input [4:0] count;
    input autoinc_b;
    input RnW_b;
  begin

    data_txb[0] = {address_b, autoinc_b, RnW_b};
    data_txb[1] = 1;
    data_txb[2] = 2;
    data_txb[3] = 3;
    data_txb[4] = 4;
    data_txb[5] = 5;
    data_txb[6] = 6;
    data_txb[7] = 7;
    data_txb[8] = 8;
    data_txb[9] = 9;
    data_txb[10] = 10;
    data_txb[11] = 11;
    data_txb[12] = 12;
    data_txb[13] = 13;
    data_txb[14] = 14;
    data_txb[15] = 15;
    data_txb[16] = 16;
    data_txb[17] = 17;
    data_txb[18] = 18;

    ss = 1;
    repeat(20*TBIT) begin
      @(negedge clk);
    end
    ss = 0; 
    repeat(2*TBIT) begin
      @(negedge clk);
    end
    for(jb = 0; jb < count; jb = jb + 1) begin 
      repeat(2*TBIT) begin
        @(negedge clk);
      end
      for(ib = 0; ib < 16; ib = ib + 1) begin
        sck = 0;
        mosi <= data_txb[jb][15-ib];
        repeat(TBIT) begin
          @(negedge clk);
        end
        sck = 1;	
        repeat(TBIT) begin
          @(negedge clk);
        end
      end
    end
    ss = 1;
    repeat(4*TBIT) begin
      @(negedge clk);
    end
  end
  endtask


//------------------------------------------
//          SPI NFC TRANSFER TASK
//------------------------------------------
  reg [5:0] n;
  reg [15:0] data_nfc;

  task automatic nfc_spi;
    input [15:0] data;
  begin
    data_nfc = data;
    nfc_miso <= data_nfc[14] ;

  ///////////////////
  // Send data
  ///////////////////
    for(n=0; n<14; n=n+1) begin
      nfc_miso <= data_nfc[13-n];
      repeat(TBIT) begin
        @(negedge nfc_sck);
      end
    end
   nfc_miso <= 0;
    end
  endtask


//------------------------------------------
//             TEST SINGLE SPI TRANSFER
//------------------------------------------

  reg [4:0] j;
initial begin: TEST_CASE 
  #250 -> reset_trigger;
  #0 pdm_data <= 7'hFF;
  @ (reset_done_trigger);
  #500
  
  //spi_burst_transfer(14'h1800, 5'h12, burst, read);
  gpio_dir <= 16'hFFF0;
  spi_transfer(14'h3003, 16'h0050 , single, write);
  spi_transfer(14'h3003, 0 , single, read);
  spi_transfer(14'h3000, 16'hAAAA , single, write);
  spi_transfer(14'h3001, 0 , single, read);
  nfc_spi(16'h2AAA);
  #1000
  spi_transfer(14'h3000, 0 , single, read);
//  spi_transfer(14'h3000, 16'h0000 , single, write);
  spi_transfer(14'h2800, 16'hFFF0 , single, write);
  spi_transfer(14'h2801, 16'h0000 , single, write);
  

  spi_transfer(14'h2803, {16'hFFFF} , single, write);
  
  spi_transfer(14'h2804, 16'h1111 , single, write);
  
  spi_transfer(14'h2805, 16'h0050 , single, write);
  spi_transfer(14'h2806, 16'h0010 , single, write);
  spi_transfer(14'h2807, 16'h0020 , single, write);
  spi_transfer(14'h2808, 16'h0030 , single, write);
  spi_transfer(14'h2809, 16'h0040 , single, write);
  
  spi_transfer(14'h280A, 16'h0030 , single, write);
  spi_transfer(14'h280B, 16'h0020 , single, write);
  spi_transfer(14'h280C, 16'h0020 , single, write);
  spi_transfer(14'h280D, 16'h0020 , single, write);
  spi_transfer(14'h280E, 16'h0020 , single, write);
  
  spi_transfer(14'h280F, 16'h0040 , single, write);
  spi_transfer(14'h2810, 16'h0020 , single, write);
  spi_transfer(14'h2811, 16'h0020 , single, write);
  spi_transfer(14'h2812, 16'h0020 , single, write);
  spi_transfer(14'h2813, 16'h0020 , single, write);
  
  spi_transfer(14'h2814, 16'h0050 , single, write);
  spi_transfer(14'h2815, 16'h0030 , single, write);
  spi_transfer(14'h2816, 16'h0030 , single, write);
  spi_transfer(14'h2817, 16'h0030 , single, write);
  spi_transfer(14'h2818, 16'h0030 , single, write);
  
  spi_transfer(14'h2819, 16'h0055 , single, write);
  spi_transfer(14'h281A, 0 , single, read);
  spi_transfer(14'h281B, 0 , single, read);
  spi_transfer(14'h281C, 0 , single, read);
  spi_transfer(14'h281D, 0 , single, read);
  
  spi_transfer(14'h2801, 0 , single, read);
  /*
  spi_transfer(14'h2803, 16'h0505 , single, write);
  spi_transfer(14'h2804, 16'h0505 , single, write);
  spi_transfer(14'h2805, 16'hFFFF , single, write);
  spi_transfer(14'h2806, 16'hAADD , single, write);
  spi_transfer(14'h2807, 16'hAADD , single, write);
  spi_transfer(14'h2808, 16'hAADD , single, write);
  
  spi_transfer(14'h2803, 16'h0505 , single, write);
  spi_transfer(14'h2804, 16'h0505 , single, write);
  spi_transfer(14'h2805, 16'hFFCC , single, write);
  spi_transfer(14'h2806, 16'hAADD , single, write);
  spi_transfer(14'h2807, 16'hAADD , single, write);
  spi_transfer(14'h2808, 16'hAADD , single, write);
  
  spi_transfer(14'h2803, 16'h0505 , single, write);
  spi_transfer(14'h2804, 16'h0505 , single, write);
  spi_transfer(14'h2805, 16'hFFCC , single, write);
  spi_transfer(14'h2806, 16'hAADD , single, write);
  spi_transfer(14'h2807, 16'hAADD , single, write);
  spi_transfer(14'h2808, 16'hAADD , single, write);
  */
  spi_transfer(14'h0005, 0 , single, read);
  spi_transfer(14'h0006, 0 , single, read);
  spi_transfer(14'h0007, 0 , single, read);
  spi_transfer(14'h0000, 0 , single, read);
  spi_transfer(14'h0000, 0 , single, read);
  spi_transfer(14'h0000, 0 , single, read);
  spi_transfer(14'h0000, 0 , single, read);
  spi_transfer(14'h0000, 0 , single, read);
  
  
  //spi_transfer(14'h0800, 4'h0003 , single, write);
  //spi_transfer(14'h1000, 4'h0003 , single, write);
  //spi_transfer(14'h1800, 4'h0003 , single, write);
  //spi_transfer(14'h2000, 4'h0003 , single, write);
  //spi_transfer(14'h2800, 4'h0003 , single, write);
  //spi_transfer(14'h3000, 4'h0003 , single, write);
  
  //pdm_data <= 8'hFE; 
  //spi_burst_transfer(14'h1000, 5'h12, burst, read);
  //spi_transfer(14'h080C, 4'h0083 , single, write);
  //spi_transfer(14'h0800, 4'h0003 , single, write);
  //spi_transfer(14'h0804, 4'h0000 , single, write);
  //spi_transfer(14'h080C, 4'h0003 , single, write);
  //spi_transfer(14'h0800, 4'h0003 , single, write);
  //spi_transfer(14'h0800, 4'h0083 , single, write);
  //spi_transfer(14'h0800, 4'h0083 , single, write);
  

  /*
  // --------------------------
  //Read and write test to bram
  // --------------------------  
   // read loop
  for(j=0; j<8; j=j+1)
    begin
   // spi_transfer(address, data, autoinc, RnW);
      spi_transfer(bram_addr + j, 0, single, read);
    end
    
  // write loop
  for(j=0; j<8; j=j+1)
    begin
   // spi_transfer(address, data, autoinc, RnW);
      spi_transfer(bram_addr + j, {j[4:0], 11'h001}, single, write);
    end
 
  // --------------------------
  //Write test to uart
  // --------------------------
  //spi_transfer(uart_addr, 16'hAAAA, single, write);
  // --------------------------
  //Write test to mic
  // --------------------------
  //spi_transfer(mica_addr, 16'h5555, single, write);

//------------------------------------------
//             TEST BURST SPI TRANSFER
//------------------------------------------
//  spi_burst_transfer(bram_addr, 5'h06, burst, write);
  spi_burst_transfer(bram_addr, 5'h12, burst, read);
 
  spi_burst_transfer(bram_addr, 5'h06, burst, write);
*/


end

   initial begin: TEST_DUMP
     $dumpfile("system_TB.vcd");
     $dumpvars(-1, uut,nfc_miso,n );
     #((PERIOD*DUTY_CYCLE)*15000) $finish;
   end

endmodule
