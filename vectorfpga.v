module vectorfpga(
	input clk,
	input reset
);
	reg draw = 0;
	reg jump = 0;
	wire ready;
	reg [11:0] x = 0;
	reg [11:0] y = 0;

	control line_draw(
		.clk(clk),
		.reset(reset),
		.x(x),
		.y(y),
		.draw(draw),
		.jump(jump),
		.ready(ready)
	);

	parameter size = 50;

	reg [1:0] state = 0;
	always@(posedge clk) begin
		if (!reset && ready) begin
			x <= x + 5;
			y <= y + 10;
			jump <= 1;
		end else begin
			jump <= 0;
		end
	end
endmodule