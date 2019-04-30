DESIGN          = system
UCF		= creator
PINS            = $(UCF).ucf
DEVICE          = xc6slx4-2tqg144
BGFLAGS         = -g TdoPin:PULLNONE -g DonePin:PULLUP \
                  -g CRC:enable -g StartUpClk:CCLK
ISE_SIM_ROOT		= /opt/Xilinx/14.7/ISE_DS/ISE/verilog/src
XILINXCADROOT   = /opt/Xilinx/14.7/ISE_DS/ISE/bin/lin/ise
SIMGEN_OPTIONS  = -p $(FPGA_ARCH) -lang $(LANGUAGE)
IVERILOG        = iverilog


MIC_SRC         = rtl/wb_mic_array/cic_comb.v \
                  rtl/wb_mic_array/cic_sync.v \
                  rtl/wb_mic_array/cic_int.v \
                  rtl/wb_mic_array/cic.v \
                  rtl/wb_mic_array/mic_array.v \
                  rtl/wb_mic_array/mic_array_buffer.v \
                  rtl/wb_mic_array/cic_op_fsm.v \
                  rtl/wb_mic_array/fir.v \
                  rtl/wb_mic_array/fir_pipe_fsm.v \
                  rtl/wb_mic_array/wb_mic_array.v  

MCU_SRC         = rtl/wb_mcu_bram/wb_mcu_bram.v

UART_SRC        = rtl/wb_uart/uart.v \
                  rtl/wb_uart/wb_uart.v \
                  rtl/wb_uart/uart_fifo.v

EVERLOOP_SRC    = rtl/wb_everloop/everloop_bram.v \
                  rtl/wb_everloop/everloop.v \
                  rtl/wb_everloop/everloop_fsm.v \
                  rtl/wb_everloop/wb_everloop.v

SPI_SRC         = rtl/wb_spi_slave/wb_spi_slave.v \
                  rtl/wb_spi_slave/spi_slave.v \

GPIO_SRC        = rtl/wb_gpio/wb_gpio.v \
                  rtl/wb_gpio/pwm.v \
                  rtl/wb_gpio/core_clk.v \
                  rtl/wb_gpio/timer.v \
                  rtl/wb_gpio/timer_core.v \
                  rtl/wb_gpio/mux_io.v \
                  rtl/wb_gpio/single_mux.v

ZWAVE_GPIO 			=	rtl/wb_zwave_gpio/wb_zwave_gpio.v

SRC             = $(DESIGN).v \
                  creator_dcm.v \
                  rtl/wb_bram/bram.v \
                  rtl/wb_conbus/conbus_arb.v \
                  rtl/wb_conbus/conbus.v \
                  $(MCU_SRC) \
                  $(SPI_SRC) \
                  $(MIC_SRC) \
                  $(UART_SRC) \
                  $(GPIO_SRC) \
                  $(ZWAVE_GPIO) \
                  $(EVERLOOP_SRC)

SIM_SRC = $(DESIGN)_TB.v          \
          ../thrid_party/unisims/DCM_SP.v     \
          ../thrid_party/unisims/BUFG.v   \
          ../thrid_party/unisims/IBUFG.v


all:            bits

remake:         clean-build all

clean:
	rm -f *~ */*~ a.out *.log *.key *.edf *.ps trace.dat
	rm -f *.bit
	rm -rf build

cleanall: clean
	rm -rf build simulation/work simulation/transcript  simulation/vsim.wlf simulation/$(DESIGN)_TB.vvp simulation/*

bits:           $(DESIGN).bit

#
# Synthesis
#
build/project.src:
	@[ -d build ] || mkdir build
	@[ -d simulation ] || mkdir simulation
	@rm -f $@
	for i in $(SRC); do echo verilog work ../$$i >> $@; done
	for i in $(SRC_HDL); do echo VHDL work ../$$i >> $@; done

build/project.xst: build/project.src
	echo "run" > $@
	echo "-top $(DESIGN) " >> $@
	echo "-p $(DEVICE)" >> $@
	echo "-opt_mode Area" >> $@
	echo "-opt_level 2" >> $@
	echo "-ifn project.src" >> $@
	echo "-ifmt mixed" >> $@
	echo "-ofn project.ngc" >> $@
	echo "-ofmt NGC" >> $@
	echo "-rtlview yes" >> $@
	echo "-register_balancing yes" >> $@

build/project.ngc: build/project.xst $(SRC)
	cd build && xst -ifn project.xst -ofn project.log

build/project.ngd: build/project.ngc $(PINS)
	cd build && ngdbuild -p $(DEVICE) project.ngc -uc ../$(PINS)

build/project.ncd: build/project.ngd
	cd build && map -pr b -p $(DEVICE) project

build/project_r.ncd: build/project.ncd
	cd build && par -w project project_r.ncd

build/project_r.twr: build/project_r.ncd
	cd build && trce -v 25 project_r.ncd project.pcf

$(DESIGN).bit:  build/project_r.ncd build/project_r.twr
	cd build && bitgen project_r.ncd -l -w $(BGFLAGS)
	@mv -f build/project_r.bit $@

build/project_r.v: build/project_r.ncd
	cd build &&  ngd2ver project.ngd  -w project.v

postsim: build/project.ngc
	cd build &&  netgen -sim -ofmt verilog project.ngc
	cd build && iverilog -Wall \
	-y $(XILINXCADROOT)/verilog/src/unisims \
	-y $(XILINXCADROOT)/verilog/src/XilinxCoreLib \
	project.v ../$(DESIGN)_TB.v -o $(DESIGN).bin
	cd build && vvp $(DESIGN).bin
	gtkwave build/$(DESIGN)_TB.vcd&

iversim: build/project.src
	$(IVERILOG) -g2012 -gno-io-range-error -o simulation/$(DESIGN)_TB.vvp $(VINCDIR) $(SRC) $(SIM_SRC) -s $(DESIGN)_TB -y $(ISE_SIM_ROOT) -y $(ISE_SIM_ROOT)/unisims -y $(ISE_SIM_ROOT)/unimacro -y $(ISE_SIM_ROOT)/simprims
	vvp simulation/$(DESIGN)_TB.vvp; mv $(DESIGN)_TB.vcd simulation/
	gtkwave simulation/$(DESIGN)_TB.vcd&

upload:
	xc3sprog -c imx283 -v -p1 $(DESIGN).bit
