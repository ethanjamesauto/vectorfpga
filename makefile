all:
	iverilog -o vectorfpga.vpp *.v
	vvp vectorfpga.vpp

view: all
	gtkwave vectorfpga_tb.vcd