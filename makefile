all:
	iverilog -o vectorfpga.vpp verilog/*.v
	vvp vectorfpga.vpp > out.txt

view: all
	gtkwave vectorfpga_tb.vcd