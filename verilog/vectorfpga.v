module vectorfpga(
	input clk,

	//UART input 
	input rx,
	output test,
	output drawing,
	
	//DAC outputs
	output cs,
	output dclk,
	output data
);
	reg reset = 0;
	reg [1:0] reset_ctr = 0;
	always@(posedge clk) begin
		if (reset_ctr < 3) begin
			reset_ctr = reset_ctr + 1;
			reset <= 1;
		end else begin
			reset <= 0;
		end
	end

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

	wire buf_ready;
	reg point_drawn = 1;
	wire [31:0] point;

	rx_buffer buffer(
		.clk(clk),
		.reset(reset),

		.rx(rx),
		.index(11'b0),
		.ready(buf_ready),
		.point(point),

		.test(test),
		.drawing(drawing)
	);

	always@(posedge clk) begin
		if (reset) begin
			draw <= 0;
			jump <= 0;
			x <= 0;
			y <= 0;
		end else if (buf_ready) begin
			point_drawn <= 0;
		end else if (ready && !point_drawn) begin
			y <= point[11:0];
			x <= point[23:12];
			jump <= 1;
			point_drawn <= 1;
		end

		if (jump) begin
			jump <= 0;
		end
		if (draw) begin
			draw <= 0;
		end
	end
		
endmodule