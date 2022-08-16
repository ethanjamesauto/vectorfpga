module draw_line(
    input clk,
    input reset,

    input [11:0] x,
    input [11:0] y,
    input strobe, //draw the line to the point

    output ready //ready for the next point
);
	reg dac_enable = 1;
    wire [11:0] dac_value;
	wire dac_axis; //selects the dac channel (2 channels)
	wire dac_ready;
	wire dac_strobe = dac_ready && dac_enable;
	mcp4922 dac0(
		.clk(clk),
		.reset(reset),
		.value(dac_value),
		.axis(dac_axis),
		.strobe(dac_strobe),

		.ready(dac_ready)
	);

	reg line_strobe = 0;
	reg [11:0] x_in = 0;
	reg [11:0] y_in = 0;

	wire line_ready;
	wire line_halt = !dac_ready;
	//wire line_axis;
	wire [11:0] x_out;
	wire [11:0] y_out;
    
	lineto line_gen(
		.clk(clk),
		.reset(reset),
		.strobe(line_strobe),
		.halt(line_halt),
		.x_in(x_in),
		.y_in(y_in),
		.x_out(x_out),
		.y_out(y_out),

		.ready(line_ready),
		.axis(dac_axis)
	);
	
	assign dac_value = dac_axis ? y_out : x_out;

	always @(posedge clk) begin
		if (reset) begin

		end else if (line_ready && !line_strobe && !reset) begin
			line_strobe <= 1;
			x_in <= x_in + 12'd4;
			y_in <= y_in + 12'd4;
		end else begin
			line_strobe <= 0;
		end
	end
endmodule