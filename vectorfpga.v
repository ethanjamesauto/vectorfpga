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
		if (!reset && jump) begin
			jump <= 0;
		end
	end

	/*always@(negedge ready) begin
		if (!reset) begin
			x <= x + 1;
			y <= y + 2;
			jump <= 1;
		end;
	end*/

	reg choice = 0;
	always@(negedge ready) begin
		if (!reset) begin
			x <= x + 10;
			y <= y + 15;
			//done <= 1;
			if (choice) begin
				jump <= 1;
			end else begin
				draw <= 1;
			end
			choice += 1;
		end;
	end

	always@(posedge clk) begin
		draw <= 0;
		jump <= 0;
	end
		
endmodule