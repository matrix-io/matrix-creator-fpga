//---------------------------------------------------------------------------
// Wishbone UART
//
// Register Description:
//
//    0x00 UCR      [ 0 | 0 | 0 | tx_busy | 0 | 0 | rx_error | rx_avail ]
//    0x04 DATA
//
//---------------------------------------------------------------------------

module wb_uart #(
	parameter ADDR_WIDTH = "mandatory",
	parameter DATA_WIDTH = "mandatory",
	parameter SYS_FREQ_HZ = "mandatory",
	parameter FIFO_ADDR_SIZE = 8     ,
	parameter BAUD_RATE      = 115200,
	parameter PULSE_WIDTH    = 13
) (
	input                   clk     ,
	input                   resetn  ,
	// Wishbone interface
	input                   wb_stb_i,
	input                   wb_cyc_i,
	input                   wb_we_i ,
	input  [           3:0] wb_sel_i,
	input  [ADDR_WIDTH-1:0] wb_adr_i,
	input  [DATA_WIDTH-1:0] wb_dat_i,
	output [DATA_WIDTH-1:0] wb_dat_o,
	output                  wb_ack_o,
	// Serial Wires
	input                   uart_rxd,
	output                  uart_txd,
	output                  uart_irq
);

//---------------------------------------------------------------------------
// UART engine
//---------------------------------------------------------------------------
	wire [7:0] rx_data ;
	wire       rx_avail;
	wire       rx_error;
	wire       rx_ack  ;
	wire [7:0] tx_data ;
	reg        tx_wr   ;
	wire       tx_busy ;

	uart #(
		.SYS_FREQ_HZ(SYS_FREQ_HZ),
		.BAUD_RATE  (BAUD_RATE  )
	) uart0 (
		.clk     (clk     ),
		.resetn  (resetn  ),
		//
		.uart_rxd(uart_rxd),
		.uart_txd(uart_txd),
		//
		.rx_data (rx_data ),
		.rx_avail(rx_avail),
		.rx_error(rx_error),
		.rx_ack  (rx_ack  ),
		.tx_data (tx_data ),
		.tx_wr   (tx_wr   ),
		.tx_busy (tx_busy )
	);

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------


	wire wb_rd = wb_stb_i & wb_cyc_i & ~wb_we_i & ~wb_ack_o;
	wire wb_wr = wb_cyc_i & wb_stb_i & wb_we_i & ~wb_ack_o ;

	wire read_rx_wishbone = (wb_adr_i[FIFO_ADDR_SIZE:0]==0) & wb_rd ;

	reg [DATA_WIDTH-1:0] wb_dat;
	assign wb_dat_o = (wb_adr_i[FIFO_ADDR_SIZE:0]==0) ? {ucr[7:0],read_data} : wb_dat ;

	reg wb_ack;
	assign wb_ack_o = (wb_adr_i[FIFO_ADDR_SIZE:0]==0) ?  read_ack : wb_ack ;

	reg write_enable;

	reg [PULSE_WIDTH-1:0] pulse_width;

	always @(posedge clk or posedge resetn) begin
		if(resetn) begin
			pulse_width <= 0;
		end else begin
			if(~fifo_empty)
				pulse_width <= pulse_width + 1;
			else
				pulse_width <= 0;
		end
	end

	assign uart_irq = pulse_width[PULSE_WIDTH-1];

	wire [7:0] read_data  ;
	wire [7:0] fifo_status;
	reg        fifo_flush ;
	wire       read_ack   ;

	wire [7:0] read_pointer ;
	wire [7:0] write_pointer;

	uart_fifo #(
		.ADDRESS_WIDTH(FIFO_ADDR_SIZE),
		.DATA_WIDTH   (8             )
	) uart_fifo0 (
		.clk          (clk             ),
		.resetn       (resetn          ),
		.write_enable (write_enable    ),
		.write_ack    (rx_ack          ),
		.data_a       (rx_data         ),
		.read_enable  (read_rx_wishbone),
		.read_ack     (read_ack        ),
		.data_b       (read_data       ),
		.fifo_flush   (fifo_flush      ),
		.empty        (fifo_empty      ),
		.full         (fifo_full       ),
		.read_pointer (read_pointer    ),
		.write_pointer(write_pointer   )
	);

	wire [DATA_WIDTH-1:0] ucr;
	assign ucr[7:0]             = {7'b0,fifo_empty};
	assign ucr[DATA_WIDTH-1-:8] = {3'b0,tx_busy,rx_error,rx_avail,fifo_empty,fifo_full};

	reg [1:0] state_write;

	localparam [1:0] S_IDLE       = 2'd0;
	localparam [1:0] S_WRITE_FIFO = 2'd1;
	localparam [1:0] S_WAIT       = 2'd2;

	always @(state_write) begin
		case(state_write)
			S_IDLE :
				write_enable = 1'b0;
			S_WRITE_FIFO :
				write_enable = 1'b1;
			S_WAIT :
				write_enable = 1'b0;
			default :
				write_enable = 1'b0;
		endcase
	end

	always @(posedge clk or posedge resetn) begin
		if(resetn)
			state_write <= S_IDLE;
		else begin
			case(state_write)
				S_IDLE :
					if(rx_avail)
						state_write <= S_WRITE_FIFO;
				else
					state_write <= S_IDLE;
				S_WRITE_FIFO :
					state_write <= S_WAIT;
				S_WAIT :
					if( ~rx_avail )
						state_write <= S_IDLE;
				else
					state_write <= S_WAIT;
				default :
					state_write <= S_IDLE;
			endcase
		end
	end

	assign tx_data = wb_dat_i[7:0];

	always @(posedge clk or posedge resetn)
		begin
			if (resetn) begin
				wb_ack                 <= 0;
				wb_dat[DATA_WIDTH-1:8] <= {DATA_WIDTH{1'b0}};
				tx_wr                  <= 0;
				fifo_flush             <= 0;
			end else begin
				wb_ack                 <= 0;
				wb_dat[DATA_WIDTH-1:0] <= 16'b0;
				tx_wr                  <= 0;
				if (wb_rd & wb_adr_i[FIFO_ADDR_SIZE]) begin
					wb_ack <= 1;
					case (wb_adr_i[1:0])
						2'b00 : begin
							wb_dat[DATA_WIDTH-1:0] <= ucr;
						end
						2'b11 : begin
							wb_dat[DATA_WIDTH-1:0] <= {write_pointer,read_pointer};
						end
						default : begin
							wb_dat[DATA_WIDTH-1:0] <= 8'b0;
						end
					endcase
				end else if (wb_wr & wb_adr_i[FIFO_ADDR_SIZE]) begin
					wb_ack <= 1;
					case (wb_adr_i[1:0])
						2'b01 : begin
							tx_wr <= 1;
						end
						2'b10 : begin
							fifo_flush <= wb_dat_i[0];
						end
						default : begin
							tx_wr      <= 0;
							fifo_flush <= 0;
						end
					endcase
				end
			end
		end
endmodule
