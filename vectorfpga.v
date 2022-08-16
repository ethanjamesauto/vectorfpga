module vectorfpga(
	input clk,
	input reset
);
	reg [11:0] value = 0;
	reg axis = 0; //selects the dac channel (2 channels)
	reg strobe = 0; //triggers the dac
	wire ready;

	mcp4922 dac0(
		.clk(clk),
		.reset(reset),
		.value(value),
		.axis(axis),
		.strobe(strobe),

		.ready(ready)
	);

	always@(posedge clk) begin
		//see if the dac is ready and hasn't already been triggered
		if(ready && !strobe) begin 
			value <= value + 1'd1;
			strobe <= 1;
		end else begin //otherwise, make sure the dac can't be trigged again
			strobe <= 0;
		end
	end

endmodule