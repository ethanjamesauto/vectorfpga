module vectorfpga(
	input clk,

	//UART input 
	input rx,
	output test,
	output reg state,
	
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

	wire rx_avail;
	wire [7:0] rx_data;

	uart_rx uart(
		.i_Clock(clk),
		.i_Rx_Serial(rx),
		.o_Rx_DV(rx_avail),
		.o_Rx_Byte(rx_data),
		.test(test)
	);

	reg [7:0] byte = 0;
	parameter WAITING = 0;
	parameter DRAWING = 1;

	reg [31:0] point_read = 0;
	reg [1:0] point_offset = 0;

	reg [31:0] point = 0;
	reg point_drawn = 0;

	always@(posedge clk) begin
		if(rx_avail && !reset) begin
			if (state == WAITING) begin	
				if (rx_data != 0) begin
					state = DRAWING;
				end
			end
			if (state == DRAWING) begin
				point_read = (point_read << 8) + rx_data;
				if (point_offset == 3) begin //we received an entire point
					point <= point_read;
					if (point_read == 32'h01010101) begin //we recieved the "done" command
						state = WAITING;
					end
					point_drawn <= 0;
					point_offset <= 0;
				end else begin
					point_offset <= point_offset + 1;
				end
			end
		end

		if (reset) begin
			draw <= 0;
			jump <= 0;
			x <= 0;
			y <= 0;
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