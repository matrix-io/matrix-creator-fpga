/*
* Copyright 2018 <Admobilize>
* All rights reserved.
*/

module mic_fir #(
  parameter DATA_WIDTH     = "mandatory",
  parameter CHANNELS       = "mandatory",
  parameter CHANNELS_WIDTH = "mandatory",
  parameter FIR_TAP_WIDTH  = "mandatory",
  parameter FIR_TAP        = "mandatory",
  parameter FIR_TAP_ADDR   = "mandatory",
  parameter FIR_MEM_DATA_ADDR = $clog2(FIR_TAP*CHANNELS)
) (
  input                              clk           ,
  input                              resetn        ,
  input                              data_load     ,
  input         [CHANNELS_WIDTH-1:0] channel       ,
  input                              ce            ,
  input  signed [    DATA_WIDTH-1:0] data_in       ,
  output signed [    DATA_WIDTH-1:0] data_out      ,
  output                             write_data_mem,
  // FIR Coeff
  output        [  FIR_TAP_ADDR-1:0] coeff_addr    ,
  input  signed [ FIR_TAP_WIDTH-1:0] coeff_data
);

  reg [FIR_MEM_DATA_ADDR-1:0] wr_data_addr;

  wire end_write_data;
  assign end_write_data = (&channel) & data_load;

  always @(posedge clk or posedge resetn) begin
    if (resetn)
      wr_data_addr <= 0;
    else begin
      if (data_load)
        wr_data_addr <= wr_data_addr + 1;
    end
  end

  wire [FIR_MEM_DATA_ADDR-1:0] wr_addr_deinterlaced;
  assign wr_addr_deinterlaced = {wr_data_addr[CHANNELS_WIDTH-1:0],wr_data_addr[FIR_MEM_DATA_ADDR-1:CHANNELS_WIDTH]};

  wire [FIR_MEM_DATA_ADDR-1:0] data_memory_addr;
  wire [   CHANNELS_WIDTH-1:0] pipe_channel    ;
  wire                         load_data_memory;

  wire reset_tap   ;
  reg  reset_tap_p1,reset_tap_p2;

  wire write_data   ;
  reg  write_data_p1,write_data_p2;

  fir_pipe_fsm #(
    .CHANNELS      (CHANNELS      ),
    .FIR_TAP       (FIR_TAP       ),
    .CHANNELS_WIDTH(CHANNELS_WIDTH)
  ) fir_pipe0 (
    .clk             (clk             ),
    .resetn          (resetn          ),
    .end_write_data  (end_write_data  ),
    
    .tap_count       (coeff_addr      ),
    .channel_count   (pipe_channel    ),
    .load_data_memory(load_data_memory),
    .reset_tap       (reset_tap       ),
    .write_data      (write_data      )
  );

  // Pipe LIne Register
  wire signed [FIR_TAP_WIDTH-1:0] data_reg_a;

  wire signed [DATA_WIDTH-1:0] data_reg_b;
  assign data_reg_a = coeff_data;

  wire [(FIR_MEM_DATA_ADDR-CHANNELS_WIDTH-1):0] read_pointer;
  assign read_pointer = coeff_addr+wr_data_addr[FIR_MEM_DATA_ADDR-1:CHANNELS_WIDTH]-1;

  assign data_memory_addr = {pipe_channel,read_pointer};

  //Data Memory
  mic_array_buffer #(
    .ADDR_WIDTH(FIR_MEM_DATA_ADDR),
    .DATA_WIDTH(DATA_WIDTH       )
  ) mic_fir_data0 (
    // write port a
    .clk_a(clk                 ),
    .we_a (data_load           ),
    .adr_a(wr_addr_deinterlaced),
    .dat_a(data_in             ),
    
    // read port b
    .clk_b(clk                 ),
    .adr_b(data_memory_addr    ),
    .en_b (load_data_memory    ),
    .dat_b(data_reg_b          )
  );

  // Pipe line stage 1
  always @(posedge clk or posedge  resetn) begin
    if(resetn) begin
      reset_tap_p1  <= 0;
      write_data_p1 <= 0;
    end else begin
      reset_tap_p1  <= reset_tap;
      write_data_p1 <= write_data;
    end
  end

  wire signed [(FIR_TAP_WIDTH+DATA_WIDTH)-1:0] factor_wire;
  assign factor_wire = data_reg_a * data_reg_b;

  reg signed [DATA_WIDTH-1:0] data_reg_c;

  // Pipe line stage 2
  always @(posedge clk or posedge  resetn) begin
    if(resetn) begin
      data_reg_c    <= 0;
      reset_tap_p2  <= 0;
      write_data_p2 <= 0;
    end else begin
      write_data_p2 <= write_data_p1;
      data_reg_c    <= {factor_wire[(FIR_TAP_WIDTH+DATA_WIDTH)-1],factor_wire[(FIR_TAP_WIDTH+DATA_WIDTH)-3:FIR_TAP_WIDTH-1]};
      reset_tap_p2  <= reset_tap_p1;
    end
  end

  reg signed [DATA_WIDTH-1:0] data_reg_d;

  // Pipe line stage 3
  always @(posedge clk or posedge  resetn) begin
    if(resetn | reset_tap_p2) begin
      data_reg_d <= 0;
    end else begin
      data_reg_d <= (data_reg_d + data_reg_c);
    end
  end

  assign data_out       = data_reg_d;
  assign write_data_mem = write_data_p2;

endmodule