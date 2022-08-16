module vectorfpga(
	input clk,
	input reset
);
	reg strobe = 0;
	wire ready;
	reg [11:0] x = 5;
	reg [11:0] y = 10;
	draw_line line_draw(
		.clk(clk),
		.reset(reset),
		.strobe(strobe),
		.ready(ready),
		.x(x),
		.y(y)
	);

	always@(posedge clk) begin
		if (!reset && !strobe && ready) begin
			strobe <= 1;
			x <= x + 12'd4;
			y <= y + 12'd4;
		end else begin
			strobe <= 0;
		end
	end
endmodule