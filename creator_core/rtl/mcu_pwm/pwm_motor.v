module pwm_motor(reset, clk, time_work, period, PWM_out); //,out
	
	input reset;
	input clk; 				
	input [23:0] time_work;	// time [us] of PWM_out = 1
	input [23:0] period;	// Period [us]
	
	output reg PWM_out = 1'b0;			//PWM signal out
	
	
	reg [23:0] counter = 24'b0;	//Counter: 0 ~ Period
	reg [23:0] timeWork_reg = 24'b0;
	reg [23:0] period_reg = 24'b0;
	reg enable = 1'b0; 	//Habilita el PWM
	reg avail = 1'b1;

// Registros y salidas de prueba PWM
//	output reg out;
//	reg [23:0] pruebaPeriod = 24'h3D0900;
//	reg [23:0] duty =24'h030D40;
	
	always @(posedge clk) begin
		if(avail)begin
			//period_reg	<= pruebaPeriod;
			period_reg	<= period;
			//if(duty <= pruebaPeriod)begin //
			if(time_work <= period)begin 
				//timeWork_reg <= duty; 
				timeWork_reg <= time_work; //time_work;
			end else begin
				//timeWork_reg <= pruebaPeriod; //
				timeWork_reg <= period;
			end
		end
	end

	always @(posedge clk) begin
		if((period_reg != 24'b0) && (timeWork_reg != 24'b0))begin
			enable <= 1'b1;
			//out <= 1'b1;
		end else begin
			enable <= 1'b0;
			//out <= 1'b0;
		end
	end
	
	always @(posedge clk)begin //Controla el contador
		if(period_reg != 24'b0)begin
			if(counter < period_reg - 24'b1)begin
				counter <= counter+1'b1;	//Aumenta uno con cada subida de flanco del clk
				avail <= 1'b0;
			end else begin
				counter <= 24'b0;
				avail <= 1'b1;		//Solo se habilita el cambio de work_time cuando el contador es cero
			end
		end
	end
	
	always @(posedge clk)begin //Controla la salida del PWM
		if(enable)begin
			if(counter == period_reg - 24'b1)begin
				PWM_out <= 1'b1;
			end else if(counter == (timeWork_reg - 24'b1)) begin
				PWM_out <= 1'b0;
			end			
		end else begin
			PWM_out <= 1'b0;
		end
	end
	
// Blinking LED
//  reg [24:0]  counter1;
//  always @(posedge clk) begin
//    if(~reset) 
//      counter1 <= 0;
//    else 
//      counter1 <= counter1 + 1;
//  end 
//  assign out = counter1[24];
  
			
endmodule
	
