//Test bench for VectorFPGA
module vectorfpga_tb;
	reg clk = 0;
	initial begin
		repeat(512) begin
			#1 clk = !clk;
		end
	end
	
	reg reset = 0;
	initial begin
		#1 reset = 1;
		#3 reset = 0;
	end

	initial begin
		$dumpfile("vectorfpga_tb.vcd");
		$dumpvars;
	end

	vectorfpga test(clk, reset);
	
endmodule