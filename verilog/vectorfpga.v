module vectorfpga(
	input clk,

	//UART input 
	input rx,
	output test,
	output drawing,
	
	//DAC outputs
	output cs,
	output dclk,
	output data,
	
	//Single beam on/off output
	output reg beam
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
	reg [3:0] shift;

	control line_draw(
		.clk(clk),
		.reset(reset),
		.x(x),
		.y(y),
		.draw(draw),
		.jump(jump),
		.ready(ready),
		//.beam(beam),
		.shift(shift),

		.cs_pin(cs),
		.clk_pin(dclk),
		.data_pin(data)
	);

	wire [24:0] point;
	wire [10:0] num_pts;
	reg done_drawing = 0;
	reg[10:0] draw_ctr = 0;

	rx_buffer buffer(
		.clk(clk),
		.reset(reset),
		
		.rx(rx),
		.read_address(draw_ctr),
		.point(point),
		.num_points(num_pts),
		.done_drawing(done_drawing),

		.test(test),
		.drawing(drawing)
	);
	always@(posedge clk) begin
		if (reset) begin
			draw <= 0;
			jump <= 1; //TODO: find out why having this as 0 breaks the whole thing
			x <= 0;
			y <= 0;
			shift <= 0;
			beam <= 0;
		end else if (ready && drawing) begin
			if (draw_ctr >= num_pts) begin
				draw_ctr <= 0;
				done_drawing <= 1;
				beam <= 0;
			end else begin
				x <= point[23:12];
				y <= point[11:0];
				if (point[24]) begin
					draw <= 1;
					beam <= 1;
					shift <= 1;
				end else begin
					draw <= 1;
					beam <= 0;
					shift <= 2;
				end
				draw_ctr <= draw_ctr + 1;
			end
		end else if (done_drawing) begin
			done_drawing <= 0;
		end

		if (jump) begin
			jump <= 0;
		end
		if (draw) begin
			draw <= 0;
		end
	end
		
endmodule