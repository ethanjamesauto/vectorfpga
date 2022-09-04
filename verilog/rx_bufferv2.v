module rx_buffer
#(parameter buffer_size = 2000)
(
	input clk,
	input reset,

	input done_drawing,
	input rx,
	input[10:0] index,

	//output[11:0] x,
	//output[11:0] y,
	//output intensity
	output [24:0] point,
	output reg [10:0] num_pts,
	output test,
	output drawing
);
	wire rx_avail;
	wire [7:0] rx_data;
	
	reg [1:0] uart_state = 0;

	uart_rx uart(
		.i_Clock(clk),
		.i_Rx_Serial(rx),
		.o_Rx_DV(rx_avail),
		.o_Rx_Byte(rx_data),
		.test(test)
	);


	parameter UART_WAITING = 0;
	parameter UART_READING = 1;
	parameter UART_DONE = 2;
	
	reg [31:0] point_read = 0;
	reg [1:0] point_offset = 0;
	
	reg [10:0] addr = 0;
	reg write = 0;
	reg next = 0;
	
	wire [24:0] point_in;
	assign point_in [24] = point_read[29:24] > 0;
	assign point_in [23:0] = point_read;

	reg buffer = 0; //used to select which buffer is used for drawing, and which for reading

	ram ram1(
		.clka(clk),
		.addra(buffer == 0 ? addr : index),
		.dina(point_in),
		.wea(buffer == 0 ? write : 0),
		.douta(point)
	);

	ram ram2(
		.clka(clk),
		.addra(buffer == 1 ? addr : index),
		.dina(point_in),
		.wea(buffer == 1 ? write : 0),
		.douta(point)
	);
	
	reg [2:0] zero_ctr = 0;
	
	parameter max_pts = buffer_size; //number of points to get before giving up

	always@(posedge clk) begin
		if (reset) begin
		end 
		if (state == DRAWING && done_drawing) begin
			state <= WAITING;
		end 
		if (next) begin
			write <= 0;
			addr <= addr + 1;
			next <= 0;
		end
		
		if(rx_avail && !reset) begin
			if (state == WAITING) begin
				if (rx_data == 0) begin
					if (zero_ctr == 7) begin
						state <= READING;
						addr <= 0;
						num_pts <= 0;
						zero_ctr <= 0;
					end else begin
						zero_ctr <= zero_ctr + 1;
					end
				end else begin
					zero_ctr <= 0;
				end
			end
			if (state == READING) begin
				point_read = (point_read << 8) + rx_data;
				if (point_offset == 3) begin //we received an entire point
					if (point_read == 32'h01010101 || num_pts >= max_pts) begin //we recieved the "done" command or we give up
						state <= DRAWING;
					end else begin
						num_pts <= num_pts + 1;
						write <= 1;
						next <= 1;
					end
					point_offset <= 0;
				end else begin
					point_offset <= point_offset + 1;
				end
			end
		end
	end
endmodule
