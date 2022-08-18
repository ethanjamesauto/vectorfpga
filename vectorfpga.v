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
	always@(negedge ready) begin
		if (!reset) begin
			if (state == 0) begin
				x <= size;
				y <= 0;
				jump <= 1;
			end else if (state == 1) begin
				x <= 0;
				y <= size - 10;
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
	end

	always@(posedge clk) begin
		draw <= 0;
		jump <= 0;
	end
		
endmodule