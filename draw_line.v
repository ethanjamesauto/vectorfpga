module draw_line(
    input clk,
    input reset,

    input [11:0] x,
    input [11:0] y,
    input draw, //draw the line to the point
	input jump,

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

	wire line_reset;
	assign line_reset = reset || doJump;

	reg queueJump = 0;
	reg doJump = 0;

	wire line_strobe;
	assign line_strobe = draw;

	wire line_ready;
	assign ready = line_ready;
	
	wire line_halt = !dac_ready;
	wire [11:0] x_out;
	wire [11:0] y_out;
    
	lineto line_gen(
		.clk(clk),
		.reset(line_reset),
		.strobe(line_strobe),
		.halt(line_halt),
		.x_in(x),
		.y_in(y),
		.x_out(x_out),
		.y_out(y_out),

		.ready(line_ready),
		.axis(dac_axis)
	);
	
	assign dac_value = dac_axis ? y_out : x_out;

	always @(posedge clk) begin
		if (reset) begin

		end else if (jump) begin
			queueJump <= 1;
		end

		//TODO: find a waay to do this in a single clock cycle???
		if (queueJump && dac_ready) begin
			queueJump <= 0;
			doJump <= 1;
		end else begin
			doJump <= 0;
		end
	end
endmodule