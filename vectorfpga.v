module vectorfpga(
	input clk,
	input reset
);
	reg draw = 0;
	reg jump = 0;
	wire ready;
	reg [11:0] x = 0;
	reg [11:0] y = 0;
	draw_line line_draw(
		.clk(clk),
		.reset(reset),
		.draw(draw),
		.jump(jump),
		.ready(ready),
		.x(x),
		.y(y)
	);

	parameter size = 50;

	reg [1:0] state = 0;
	always@(posedge clk) begin
		if (!reset && !draw && ready) begin
			draw <= 1;
			if(state == 0) begin
				x <= 0;
				y <= 0;
			end else if (state == 1) begin
				x <= size;
				y <= 0;
			end else if (state == 2) begin
				x <= size;
				y <= size;
			end else begin
				jump <= 1;
				x <= 0;
				y <= size;
			end
			state <= state + 1;
		end else begin
			draw <= 0;
			jump <= 0;
		end
	end
endmodule