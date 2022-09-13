//Test bench for VectorFPGA
module vectorfpga_tb;
	reg clk = 0;
	initial begin
		repeat(4096 * 5) begin
			#1 clk = !clk;
		end
	end
	
	initial begin
		$dumpfile("vectorfpga_tb.vcd");
		$dumpvars;
	end

	vectorfpga_tb1 test(
		.clk(clk)
	);
	
endmodule