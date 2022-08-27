module vectorfpga(
	input clk,

	//UART input 
	input rx,
	output rx_avail,
	output reg test,
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
		.o_Rx_DV(rx_avail),
		.o_Rx_Byte(rx_data)
	);

	reg [7:0] byte = 0;
	reg state = 0;
	parameter WAITING = 0;
	parameter DRAWING = 1;

	reg [31:0] point_read = 0;
	reg [1:0] point_offset = 0;

	reg [31:0] point = 0;
	reg point_drawn = 0;

	always@(posedge rx_avail) begin
		if (state == WAITING) begin	
			test <= 0;
			if (rx_data != 0) begin
				state = DRAWING;
			end
		end
		if (state == DRAWING) begin
			test <= 1;
			point_read[7:0] <= rx_data;
			point_read <= point_read << 8;
			//if (rx_data == 8'b1) begin
			//	state = WAITING;
			//end 
			if (point_offset == 3) begin //we received an entire point
				//do shit with the point
				if (point_read == 32'h01010101) begin //we recieved the "done" command
					state = WAITING;
				end else begin
					point <= point_read;
				end
				point_drawn <= 0;
				point_offset <= 0;
			end else begin
				point_offset <= point_offset + 1;
			end//*/
		end
	end

	always@(posedge clk) begin
		if (reset) begin
			draw <= 0;
			jump <= 0;
			x <= 0;
			y <= 0;
		end else if (ready) begin
			
		end
		if (jump) begin
			jump <= 0;
		end
		if (draw) begin
			draw <= 0;
		end
	end
		
endmodule