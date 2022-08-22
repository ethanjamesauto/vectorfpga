`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:38:26 08/22/2022
// Design Name:   vectorfpga
// Module Name:   /home/ise/vectorfpga/xilinx/vectorfpga/testbench.v
// Project Name:  vectorfpga
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: vectorfpga
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module testbench;

	// Inputs
	reg clk;
	reg reset;

	// Outputs
	wire cs;
	wire dclk;
	wire data;

	// Instantiate the Unit Under Test (UUT)
	vectorfpga uut (
		.clk(clk), 
		.reset(reset), 
		.cs(cs), 
		.dclk(dclk), 
		.data(data)
	);

	initial begin
		reset = 0;
		// Wait 100 ns for global reset to finish
		#100;
		
		reset = 1;
		#10
		reset = 0;
	end
	
	initial begin
		clk = 0;
		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		repeat(4096 * 1) begin
			#1 clk = !clk;
		end
	end
      
endmodule

