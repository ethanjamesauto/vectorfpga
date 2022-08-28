module rx_buffer
#(parameter buffer_size = 2000)
(
    input clk,
    input reset,

    input rx,
    input[10:0] index,

    output reg ready,
    //output[11:0] x,
    //output[11:0] y,
    //output intensity
    output reg [31:0] point,
    output test,
    output drawing
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

	reg state = 0;
	assign drawing = state;

	parameter WAITING = 0;
	parameter DRAWING = 1;

	reg [31:0] point_read = 0;
	reg [1:0] point_offset = 0;
	
	reg [2:0] zero_ctr = 0;
	
	parameter max_pts = 20000; //number of points to get before giving up
	reg [14:0] counter;

    always@(posedge clk) begin
        if (reset) begin
            ready <= 0;
        end
        if(rx_avail && !reset) begin
			if (state == WAITING) begin
				if (rx_data == 0) begin
					if (zero_ctr == 7) begin
						state <= DRAWING;
						counter <= 0;
						zero_ctr <= 0;
					end else begin
						zero_ctr <= zero_ctr + 1;
					end
				end else begin
					zero_ctr <= 0;
				end
			end
			if (state == DRAWING) begin
				point_read = (point_read << 8) + rx_data;
				if (point_offset == 3) begin //we received an entire point
					if (point_read == 32'h01010101 || counter >= max_pts) begin //we recieved the "done" command or we give up
						state <= WAITING;
                    end else begin
                    	counter <= counter + 1;
					    point <= point_read;
                        ready <= 1;
                    end
					point_offset <= 0;
				end else begin
                    ready <= 0;
					point_offset <= point_offset + 1;
				end
			end
		end
    end
endmodule
