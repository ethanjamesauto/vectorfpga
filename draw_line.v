module draw_line(
    input clk,
    input reset,

    input [11:0] x,
    input [11:0] y,
    input strobe, //draw the line to the point

    output ready //ready for the next point
);
    reg [11:0] value = 0;
	reg dac_axis = 0; //selects the dac channel (2 channels)
	reg dac_strobe = 0; //triggers the dac
	wire dac_ready;
	mcp4922 dac0(
		.clk(clk),
		.reset(reset),
		.value(value),
		.axis(dac_axis),
		.strobe(dac_strobe),

		.ready(dac_ready)
	);

	reg line_strobe = 0;
	reg [11:0] x_in = 0;
	reg [11:0] y_in = 0;

	wire line_ready;
	//wire line_axis;
	//wire [11:0] x_out;
	//wire [11:0] y_out;
    
	lineto line_gen(
		.clk(clk),
		.reset(reset),
		.strobe(line_strobe),
		.x_in(x_in),
		.y_in(y_in),

		.ready(line_ready)
	);

endmodule