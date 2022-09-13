all:
	iverilog -o vectorfpga.vpp verilog/vectorfpga_tb.v verilog/vectorfpga_tb1.v verilog/util.v verilog/control.v
	vvp vectorfpga.vpp > out.txt

view: all
	gtkwave vectorfpga_tb.vcd