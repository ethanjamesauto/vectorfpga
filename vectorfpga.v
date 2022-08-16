module vectorfpga(
	input clk,
	input reset
);
	reg strobe = 0;
	draw_line line_draw(
		.clk(clk),
		.reset(reset),
		.strobe(strobe),
		.x(12'b0),
		.y(12'b0)
	);

	always@(posedge clk) begin

	end
endmodule