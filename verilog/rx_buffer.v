module rx_buffer
#(
	parameter buffer_size = 2000,
	parameter index_bits = 11, //can index a buffer up to size 2048
	parameter ram_width = 25 //25 bits (24 for xy, 1 for brightness)
)
(
	input clk,
	input reset,

	input done_drawing,
	input rx,
	input[index_bits - 1:0] read_address,

	output [24:0] point,
	output [index_bits - 1: 0] num_points,
	output test,
	output reg drawing
);
	//states used to track the serial input
	parameter UART_WAITING = 0;
	parameter UART_READING = 1;
	parameter UART_DONE = 2;
	reg [1:0] uart_state;

	wire rx_avail; //1 if UART is ready to read. Only readable for 1 clock cycle
	wire [7:0] rx_data; //byte from the UART module

	reg [31:0] point_read; //a whole point read from uart
	reg [1:0] point_offset; //used for reading each 4-byte point

	uart_rx uart(
		.i_Clock(clk),
		.i_Rx_Serial(rx),
		.o_Rx_DV(rx_avail),
		.o_Rx_Byte(rx_data),
		.test(test) //testing data from the UART module
	);

	reg [2:0] zero_ctr; //used to count the 0s at the beginning of each frame

	//take the 4 bytes of the point retrieved by serial
	wire [ram_width - 1:0] point_in;
	assign point_in [24] = point_read[29:24] > 0; //The brightness is composed of 6 bits, but we only need on/off
	assign point_in [23:0] = point_read; //the 24 bits for x and y




	reg buffer; //controls which buffer is read from, and which is written to
	reg [index_bits - 1:0] write_address; //the address to write to //TODO: just use the point counters for this
	reg write; //the ram will be written to if this is set

	//ram module 0 - written to when buffer = 0, read from when buffer = 1
	reg [index_bits - 1:0] point_counter0;
	wire [ram_width - 1:0] ram_output0;

	ram ram0(
		.clka(clk),
		.addra(buffer == 0 ? write_address : read_address),
		.dina(point_in),
		.wea(buffer == 0 ? write : 0),
		.douta(ram_output0)
	);

	//ram module 1 - written to when buffer = 1, read from when buffer = 0
	reg [index_bits - 1:0] point_counter1;
	wire [ram_width - 1:0] ram_output1;

	ram ram1(
		.clka(clk),
		.addra(buffer == 1 ? write_address : read_address),
		.dina(point_in),
		.wea(buffer == 1 ? write : 0),
		.douta(ram_output1)
	);

	//set this module's output to the correct buffer for reading from
	assign point = buffer == 0 ? ram_output1 : ram_output0;
	assign num_points = buffer == 0 ? point_counter1 : point_counter0;

	always@(posedge clk) begin
		if (reset) begin //set initial states for registers
			uart_state <= UART_WAITING;
			zero_ctr <= 0;

			buffer <= 0;
			write_address <= 0;
			write <= 0;
			
			point_counter0 <= 0;
			point_counter1 <= 0;
			point_offset <= 0;
			point_read = 0;

			drawing <= 0;
		end else begin
			if (rx_avail) begin //there's a new byte to read
				//If waiting, wait for 8 0-bytes indicating the start of a frame
				if (uart_state == UART_WAITING) begin
					if (rx_data == 0) begin
						if (zero_ctr == 7) begin //we've recieved 8 zeros in a row - time to start writing to the buffer
							uart_state <= UART_READING; //we're reading now
							write_address <= 0;
							zero_ctr <= 0;
							if (buffer == 0) begin //reset the number of points in a buffer
								point_counter0 <= 0;
							end else begin
								point_counter1 <= 0;
							end
						end else begin
							zero_ctr <= zero_ctr + 1;
						end
					end else begin
						zero_ctr <= 0; //if we get a byte that's not a zero, reset the counter. We need 8 in a row
					end

				end else if (uart_state == UART_READING) begin
					point_read = (point_read << 8) + rx_data; //shift in the next byte into the 4-byte word
					if (point_offset == 3) begin //we received an entire point
						if (point_read == 32'h01010101 || write_address >= buffer_size) begin //we received the "done" command or we give up
							uart_state <= UART_DONE; 
						end else begin
							write <= 1; //write the 4-byte word to ram
						end
						point_offset <= 0;
					end else begin
						point_offset <= point_offset + 1;
					end

				end else begin //the state is UART_DONE

				end
			end
			if (uart_state == UART_DONE) begin
				if (!drawing) begin
					buffer <= !buffer; //swap buffers
					uart_state <= UART_WAITING; //go back to waiting for a new frame
					drawing <= 1; //start drawing
				end
			end
			if (done_drawing) begin
				if (uart_state == UART_DONE) begin
					drawing <= 0; //set the drawing signal low if drawing is complete - this will lead to a buffer swap
				end
				//otherwise, do nothing - the current frame will be redrawn
			end
			if (write) begin
				write <= 0; //done with the write
				write_address <= write_address + 1;
				if (buffer == 0) begin
					point_counter0 <= point_counter0 + 1;
				end else begin
					point_counter1 <= point_counter1 + 1;
				end
			end
		end
	end

endmodule