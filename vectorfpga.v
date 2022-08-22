module vectorfpga(
	input clk,
	input reset,

	// physical interface
	output cs,
	output dclk,
	output data
);
	reg draw;
	reg jump;
	wire ready;
	reg [11:0] x;
	reg [11:0] y;

	control line_draw(
		.clk(clk),
		.reset(reset),
		.x(x),
		.y(y),
		.draw(draw),
		.jump(jump),
		.ready(ready),

		.cs_pin(cs),
		.clk_pin(dclk),
		.data_pin(data)
	);

	parameter size = 4095;

	reg [1:0] state = 0;
	always@(posedge clk) begin
		if (reset) begin
			draw <= 0;
			jump <= 0;
			x <= 0;
			y <= 0;
		end else if (!reset && ready) begin
			if (state == 0) begin
				x <= size;
				y <= 400;
				jump <= 1;
			end else if (state == 1) begin
				x <= 0;
				y <= size - 400;
				draw <= 1;
			end else if (state == 2) begin
				x <= size;
				y <= size;
				draw <= 1;
			end else begin
				x <= 0;
				y <= 0;
				draw <= 1;
			end
			state <= state + 1;
		end
		if (jump) begin
			jump <= 0;
		end
		if (draw) begin
			draw <= 0;
		end
	end
		
endmodule