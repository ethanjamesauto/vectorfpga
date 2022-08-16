all:
	iverilog -o vectorfpga.vpp vectorfpga_tb.v vectorfpga.v util.v
	vvp vectorfpga.vpp

view: all
	gtkwave vectorfpga_tb.vcd