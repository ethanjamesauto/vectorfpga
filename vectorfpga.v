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

	
	reg line_strobe = 0;
	reg [11:0] x = 0;
	reg [11:0] y = 0;

	wire line_ready;
	//wire line_axis;
	//wire [11:0] x_out;
	//wire [11:0] y_out;

	lineto line_gen(
		.clk(clk),
		.reset(reset),
		.strobe(line_strobe),
		.x_in(x),
		.y_in(y),

		.ready(line_ready)
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

	always@(posedge clk) begin
		if(line_ready && !line_strobe) begin
			line_strobe <= 1;
			x <= 12'd15;
			y <= 12'd10;
		end else begin
			line_strobe <= 0;
		end
	end

endmodule