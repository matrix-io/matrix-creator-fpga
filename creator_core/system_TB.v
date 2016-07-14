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
       wire uart0_tx;
       wire uart1_tx;
       

  system uut(
       .clk_50(clk), .resetn(resetn), .mosi(mosi), .ss(ss), .sck(sck), 
       .miso(miso), .uart0_tx(uart0_tx), .uart0_rx(uart0_rx), .pdm_data(pdm_data),
       .uart1_tx(uart1_tx), .uart1_rx(uart1_rx)
  );

  initial begin
    // Initialize Inputs
    resetn = 0; clk = 0; mosi = 0; ss = 1; sck = 1; uart0_rx = 0;
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
    data_tx <= data;
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
//             TEST SINGLE SPI TRANSFER
//------------------------------------------

  reg [4:0] j;
initial begin: TEST_CASE 
  #150 -> reset_trigger;
  #0 pdm_data <= 7'hFF;
  @ (reset_done_trigger);
  #1250000
  
  spi_burst_transfer(14'h1800, 5'h12, burst, read);
  spi_transfer(14'h1801, 0 , single, read);
  spi_transfer(14'h1802, 0 , single, read);
  spi_transfer(14'h1803, 0 , single, read);
  spi_transfer(14'h1804, 0 , single, read);
  spi_transfer(14'h1805, 0 , single, read);
  spi_transfer(14'h1806, 0 , single, read);
  spi_transfer(14'h1807, 0 , single, read);
  spi_transfer(14'h1800, 0 , single, read);
  spi_transfer(14'h1800, 0 , single, read);
  spi_transfer(14'h1800, 0 , single, read);
  spi_transfer(14'h1800, 0 , single, read);
  spi_transfer(14'h1800, 0 , single, read);
  
  
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
     $dumpvars(-1, uut);
     #((PERIOD*DUTY_CYCLE)*150000) $finish;
   end

endmodule
