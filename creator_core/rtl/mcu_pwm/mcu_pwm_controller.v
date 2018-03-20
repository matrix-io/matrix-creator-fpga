`timescale 1ns / 1ps

module mcu_pwm_controller #(
	parameter adr_width = 8,
	parameter data_width = 8
) (
  input reset,
  //MCU SAM
  input  pwm_clk,
  input  pwm_nwe,
  input  pwm_ncs,
  input  pwm_nrd,
  input  [7:0] pwm_addr, 
  input  [7:0]  pwm_sram_data,
  output pwmout1,
  output pwmout2,
  output pwmout3,
  output pwmout4
  //output prueba
  
  );

/* synchronize signals */
reg    pwm_sncs;
reg    pwm_snwe;
reg    [7:0] pwm_buffer_addr;
reg    [7:0]  pwm_buffer_data;  

/* bram interfaz signals */
reg    pwm_we;
reg    pwm_w_st;

reg    [7:0] pwm_wdBus;
wire   [7:0] pwm_rdBus;



/* synchronize assignment */
always  @(negedge pwm_clk)
begin
  pwm_sncs   <= pwm_ncs;
  pwm_snwe   <= pwm_nwe;
  pwm_buffer_data <= pwm_sram_data;
  pwm_buffer_addr <= pwm_addr;
end

/* write access cpu to bram */
always @(posedge pwm_clk)
begin
 pwm_wdBus <= pwm_buffer_data;
 case (pwm_w_st)
   0: begin
        pwm_we <= 0;
        if (pwm_sncs | pwm_snwe) 
          pwm_w_st <= 1;
      end
   1: begin
        if (~(pwm_sncs | pwm_snwe)) begin
          pwm_we    <= 1;
          pwm_w_st  <= 0;
        end	
          else pwm_we <= 0;
      end
  endcase
end

//Pwm signals and registers
reg [23:0]period;

reg [23:0]duty1;
reg [23:0]duty2;
reg [23:0]duty3;
reg [23:0]duty4;
//wire prueba;

//Redireccionamiento de datos a registros según dirección

always @(negedge pwm_clk)begin
 if(pwm_we) begin
	case (pwm_buffer_addr[4:0]) 
	//PERIOD
        0 : begin
        period[23:16]   <= pwm_wdBus; 
        period[15:0 ]   <= period[15:0 ];
        
       /* if (period[23:16]== 8'h3D ) begin
        	prueba <= 1;        
        end
        else prueba <=0;*/
        duty1  [23:0]   <= duty1  [23:0];
        duty2  [23:0]   <= duty2  [23:0];
        duty3  [23:0]   <= duty3  [23:0]; 
        duty4  [23:0]   <= duty4  [23:0];  
        end
        1 : begin
        period[15:8 ]   <= pwm_wdBus;
        period[23:16]   <= period[23:16];
        period[ 7:0 ]   <= period[ 7:0 ];
        
        duty1  [23:0]   <= duty1  [23:0];
        duty2  [23:0]   <= duty2  [23:0];
        duty3  [23:0]   <= duty3  [23:0];
        duty4  [23:0]   <= duty4  [23:0];  
        end
        2 : begin
        period[ 7:0]    <= pwm_wdBus;
        period[23:8]    <= period[23:8];
        
        duty1  [23:0]   <= duty1  [23:0];
        duty2  [23:0]   <= duty2  [23:0];
        duty3  [23:0]   <= duty3  [23:0]; 
        duty4  [23:0]   <= duty4  [23:0];  
        end
        
        //DUTY 1
        3 : begin
        duty1  [23:16]  <= pwm_wdBus; 
        duty1  [15:0]   <= duty1 [15:0];
        
        period [23:0]   <= period [23:0];
        duty2  [23:0]   <= duty2  [23:0];
        duty3  [23:0]   <= duty3  [23:0]; 
        duty4  [23:0]   <= duty4  [23:0];  
        end
        4 : begin
        duty1  [15:8]   <= pwm_wdBus; 
        duty1  [23:16]  <= duty1  [23:16];
        duty1  [7:0 ]   <= duty1  [7:0 ];
        
        period [23:0]   <= period [23:0];
        duty2  [23:0]   <= duty2  [23:0];
        duty3  [23:0]   <= duty3  [23:0]; 
        duty4  [23:0]   <= duty4  [23:0];  
        end
        5: begin
        duty1  [7:0 ]   <= pwm_wdBus;
        duty1  [23:8]   <= duty1  [23:8];
        
        period [23:0]   <= period [23:0];
        duty2  [23:0]   <= duty2  [23:0];
        duty3  [23:0]   <= duty3  [23:0]; 
        duty4  [23:0]   <= duty4  [23:0];  
        end
        //DUTY 2
        6: begin
        duty2  [23:16]  <= pwm_wdBus; 
        duty2  [15:0]   <= duty2 [15:0];
        
        period [23:0]   <= period [23:0];
        duty1  [23:0]   <= duty1  [23:0];
        duty3  [23:0]   <= duty3  [23:0];
        duty4  [23:0]   <= duty4  [23:0];  
        end
        7: begin
        duty2  [15:8]   <= pwm_wdBus; 
        duty2  [23:16]  <= duty2  [23:16];
        duty2  [7:0 ]   <= duty2  [7:0 ];
        
        period [23:0]   <= period [23:0];
        duty1  [23:0]   <= duty1  [23:0];
        duty3  [23:0]   <= duty3  [23:0]; 
        duty4  [23:0]   <= duty4  [23:0];  
        end
        8: begin
        duty2  [7:0 ]   <= pwm_wdBus;
        duty2  [23:8]   <= duty2  [23:8];
        
        period [23:0]   <= period [23:0];
        duty1  [23:0]   <= duty1  [23:0];
        duty3  [23:0]   <= duty3  [23:0];
        duty4  [23:0]   <= duty4  [23:0];  
        end
        
        //DUTY 3
        9 : begin
        duty3  [23:16]  <= pwm_wdBus; 
        duty3  [15:0]   <= duty3 [15:0];
        
        period [23:0]   <= period [23:0];
        duty1  [23:0]   <= duty1  [23:0];
        duty2  [23:0]   <= duty2  [23:0]; 
        duty4  [23:0]   <= duty4  [23:0];  
        end
        10 : begin
        duty3  [15:8]   <= pwm_wdBus; 
        duty3  [23:16]  <= duty3  [23:16];
        duty3  [7:0 ]   <= duty3  [7:0 ];
        
        period [23:0]   <= period [23:0];
        duty1  [23:0]   <= duty1  [23:0];
        duty2  [23:0]   <= duty2  [23:0]; 
        duty4  [23:0]   <= duty4  [23:0];   
        end
        11: begin
        duty3  [7:0 ]   <= pwm_wdBus;
        duty3  [23:8]   <= duty3  [23:8];
        
        period [23:0]   <= period [23:0];
        duty1  [23:0]   <= duty1  [23:0];
        duty2  [23:0]   <= duty2  [23:0]; 
        duty4  [23:0]   <= duty4  [23:0];   
        end
        
        //DUTY 4
        12: begin
        duty4  [23:16]  <= pwm_wdBus; 
        duty4  [15:0]   <= duty4 [15:0];
        
        period [23:0]   <= period [23:0];
        duty1  [23:0]   <= duty1  [23:0];
        duty2  [23:0]   <= duty2  [23:0]; 
        duty3  [23:0]   <= duty3  [23:0];   
        end
        13: begin
        duty4  [15:8]   <= pwm_wdBus; 
        duty4  [23:16]  <= duty4  [23:16];
        duty4  [7:0 ]   <= duty4  [7:0 ];
        
        period [23:0]   <= period [23:0];
        duty1  [23:0]   <= duty1  [23:0]; 
        duty2  [23:0]   <= duty2  [23:0]; 
        duty3  [23:0]   <= duty3  [23:0];    
        end
        14: begin
        duty4  [7:0 ]   <= pwm_wdBus;
        duty4  [23:8]   <= duty4  [23:8];
        
        period [23:0]   <= period [23:0];
        duty1  [23:0]   <= duty1  [23:0]; 
        duty2  [23:0]   <= duty2  [23:0]; 
        duty3  [23:0]   <= duty3  [23:0];    
        end
        
	default : begin
		period [23:0]   <= period [23:0]; 
		duty1  [23:0]   <= duty1  [23:0];
		duty2  [23:0]   <= duty2  [23:0];
        duty3  [23:0]   <= duty3  [23:0]; 
        duty4  [23:0]   <= duty4  [23:0];  
	end
	 endcase
	 end
end

  pwm_motor pwm1 (
  	.reset(reset),
  	.clk  (pwm_clk),
  	.time_work(duty1), //1s 32'h3333333
  	.period(period),   //2s
  	.PWM_out(pwmout1)
  	//.out(prueba)
  	);
  pwm_motor pwm2 (
  	.reset(reset),
  	.clk  (pwm_clk),
  	.time_work(duty2), //1s 32'h3333333
  	.period(period),   //2s
  	.PWM_out(pwmout2)
  	//.out(prueba1)
  	);
 pwm_motor pwm3 (
  	.reset(reset),
  	.clk  (pwm_clk),
  	.time_work(duty3), //1s 32'h3333333
  	.period(period),   //2s
  	.PWM_out(pwmout3)
  	//.out(prueba2)
  	);
  pwm_motor pwm4 (
  	.reset(reset),
  	.clk  (pwm_clk),
  	.time_work(duty4), //1s 32'h3333333
  	.period(period),   //2s
  	.PWM_out(pwmout4)
  	//.out(prueba3)
  	
  	);
// ciclo - periodo
//time_work(32'h80000000),  
//FFFFFFFF Periodo completo 20s

// Blinking LED
/*  reg [24:0]  counter;
  always @(posedge pwm_clk) begin
    if(~reset) 
      counter <= 0;
    else 
      counter <= counter + 1;
  end 
  assign pwm1Output = counter[24];*/
  
endmodule
