/*
 * based in:
 * https://github.com/lgeek/orpsoc/blob/master/boards/xilinx/atlys/rtl/verilog/gpio/gpio.v
 *
 * Simple 24-bit wide GPIO module
 * 
 * Can be made wider as needed, but must be done manually.
 * 
 * First lot of bytes are the GPIO I/O regs
 * Second lot are the direction registers
 * 
 * Set direction bit to '1' to output corresponding data bit.
 *
 * Register mapping:
 *  
 * For 8 GPIOs we would have
 * adr 0: gpio data 7:0
 * adr 1: gpio data 15:8
 * adr 2: gpio data 23:16
 * adr 3: gpio dir 7:0
 * adr 4: gpio dir 15:8
 * adr 5: gpio dir 23:16
 * 
 * Backend pinout file needs to be updated for any GPIO width changes.
 * 
 */ 

module wb_gpio(
  clk,
  rst,
  
  wb_adr_i,
  wb_dat_i,
  wb_we_i,
  wb_cyc_i,
  wb_stb_i,
  
  wb_ack_o,
  wb_dat_o,
  gpio_io);


   parameter gpio_io_width = 8;

   parameter gpio_dir_reset_val = 0;
   parameter gpio_o_reset_val = 0;
   
   
   parameter wb_dat_width = 16;
   parameter wb_adr_width = 14; // 2^14 bytes addressable
   
   input clk;
   input rst;
   //WishBone Interface
   input [wb_adr_width-1:0] wb_adr_i;
   input [wb_dat_width-1:0] wb_dat_i;
   input     wb_we_i;
   input     wb_cyc_i;
   input     wb_stb_i;
   
   output reg [wb_dat_width-1:0] wb_dat_o; // constantly sampling gpio in bus
   output  wb_ack_o;
  
   //I/O PORT
   inout [gpio_io_width-1:0] gpio_io;
   //Interupt


   // Internal registers
   reg [gpio_io_width-1:0]   gpio_dir;

   reg [gpio_io_width-1:0]   gpio_o;

   wire [gpio_io_width-1:0]  gpio_i; 
   
   //Wisbone logical Interface

   wire wb_rd = wb_stb_i & wb_cyc_i & ~wb_we_i;
   wire wb_wr = wb_stb_i & wb_cyc_i &  wb_we_i;

   reg  ack;
   assign wb_ack_o = wb_stb_i & wb_cyc_i & ack;
    
    
   // Tristate logic for IO
   genvar    i;
   generate 
  for (i=0;i<gpio_io_width;i=i+1)  begin: gpio_tris
   assign gpio_io[i] = (gpio_dir[i]) ? gpio_o[i] : 1'bz;
   assign gpio_i[i] = gpio_io[i]; //(gpio_dir[i]) ? gpio_o[i] : ;
   end
   endgenerate
  //Interupt Mask
/*
  assign interrupt_mask = ~gpio_dir & wb_dat_o;
  
  rising_edge_detect r0(.clk(clk),.signal(interrupt_mask[0]),.pulse(vec_interrupt[0]));
  rising_edge_detect r1(.clk(clk),.signal(interrupt_mask[1]),.pulse(vec_interrupt[1]));
  rising_edge_detect r2(.clk(clk),.signal(interrupt_mask[2]),.pulse(vec_interrupt[2]));
  rising_edge_detect r3(.clk(clk),.signal(interrupt_mask[3]),.pulse(vec_interrupt[3]));
  rising_edge_detect r4(.clk(clk),.signal(interrupt_mask[4]),.pulse(vec_interrupt[4]));
  rising_edge_detect r5(.clk(clk),.signal(interrupt_mask[5]),.pulse(vec_interrupt[5]));
  rising_edge_detect r6(.clk(clk),.signal(interrupt_mask[6]),.pulse(vec_interrupt[6]));
  rising_edge_detect r7(.clk(clk),.signal(interrupt_mask[7]),.pulse(vec_interrupt[7]));
  
  assign irq=|vec_interrupt;
 */ 
   // GPIO data out register
   always @(posedge clk)begin
     if (rst)begin
    gpio_o <= 0; // All set to in at reset
    gpio_dir <= 0;
    ack <= 0;
     end
     else begin 
    ack<=0;
    if (wb_rd & ~ack) begin     //Read cycle
     ack<=1;
     case(wb_adr_i[1:0])
      2'b00:begin  
    wb_dat_o[wb_dat_width-1:8]<=0;
    wb_dat_o[7:0] <= gpio_i;
      end
      default: wb_dat_o <= 0; 
     endcase
    end

    else if (wb_wr & ~ack ) begin  
    ack <= 1;          //Write cycle
    case(wb_adr_i[1:0])
     2'b01: gpio_o   <= wb_dat_i[7:0];
     2'b10: gpio_dir <= wb_dat_i[7:0];
    endcase
    end
     end    
   end   
  
endmodule 
  
