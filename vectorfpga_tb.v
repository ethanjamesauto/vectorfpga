//Test bench for VectorFPGA
module vectorfpga_tb;
	reg clk = 0;
	initial begin
		repeat(4096*4) begin
			#1 clk = !clk;
		end
	end
	
	reg reset = 0;
	initial begin
		#1 reset = 1;
		#4 reset = 0;
	end

	initial begin
		$dumpfile("vectorfpga_tb.vcd");
		$dumpvars;
	end

	vectorfpga test(clk, reset);
	
endmodule