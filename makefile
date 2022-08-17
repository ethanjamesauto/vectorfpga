all:
	iverilog -o vectorfpga.vpp *.v
	vvp vectorfpga.vpp > out.txt

view: all
	gtkwave vectorfpga_tb.vcd