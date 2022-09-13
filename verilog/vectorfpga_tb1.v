module vectorfpga_tb1(
	input clk,

	//UART input 
	input rx,
	output test,
	output [7:0] rx_data,
	
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

	uart_rx uart(
		.i_Clock(clk),
		.i_Rx_Serial(rx),
		.o_Rx_DV(test),
		.o_Rx_Byte(rx_data)
	);

	parameter size = 30;

	reg [1:0] state = 0;
	always@(posedge clk) begin
		if (reset) begin
			draw <= 0;
			jump <= 0;
			x <= 0;
			y <= 0;
		end else if (ready) begin
			if (state == 0) begin
				x <= size;
				y <= size / 10;
				jump <= 1;
			end else if (state == 1) begin
				x <= 0;
				y <= size - size / 10;
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