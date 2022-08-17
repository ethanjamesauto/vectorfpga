//Original author: Trammell Hudson (https://trmm.net/)
//clk_pin = clk / 2
//TODO: make CS only high for one clock cycle, and maybe make the whole thing 2x as fast
module mcp4922(
	input clk,
	input reset,

	// physical interface
	output cs_pin,
	output reg clk_pin,
	output data_pin,

	// logical interface
	input [11:0] value,
	input axis,
	input strobe,
	output ready
);
	parameter GAIN = 1'b1; // Normal gain
	parameter BUFFERED = 1'b1; // buffered
	parameter SHUTDOWN = 1'b1; // not shutdown

	reg [15:0] cmd;
	reg [4:0] bits;
	assign ready = !reset && bits == 0;
	assign cs_pin = ready; // negative logic
	assign data_pin = cmd[15];

	always @(posedge clk)
	begin
		if (reset) begin
			bits <= 0;
			clk_pin <= 0;
		end else
		if (strobe) begin
			$display("channel: %d, value: %d", axis, value);
			cmd <= { axis, BUFFERED, GAIN, SHUTDOWN, value };
			bits <= 16;
			clk_pin <= 0;
		end else
		if (bits != 0) begin
			if (clk_pin) begin
				// change when it is currently high
				cmd <= { cmd[14:0], 1'b0 };
				clk_pin <= 0;
				bits <= bits - 1;
			end else begin
				// rising edge clocks the data
				clk_pin <= 1;
			end
		end else begin
			clk_pin <= 0;
		end
	end

endmodule

//Original author: Trammell Hudson (https://trmm.net/)
/**
 * Bresenham's Line Drawing algorithm.
 * Generate straight lines from the current point to the
 * destination.  x_in/y_in can be reset at any time with the strobe.
 */
module lineto(
	input clk,
	input reset,

	input strobe,
	input halt,
	input [BITS-1:0] x_in,
	input [BITS-1:0] y_in,

	output ready, // set when done
	output axis, // did the x or y value change
	output [BITS-1:0] x_out,
	output [BITS-1:0] y_out
);
	parameter BITS = 12;

	reg [BITS-1:0] err;

	reg [BITS-1:0] x_dst;
	reg [BITS-1:0] y_dst;

	reg [BITS-1:0] x_out;
	reg [BITS-1:0] y_out;

	// once the output reaches the dstination, it is ready
	// for a new point.
	assign ready = (x_dst == x_out) && (y_dst == y_out);

	reg axis;
	reg sx;
	reg sy;

	reg signed [BITS-1:0] dx;
	reg signed [BITS-1:0] dy;

	wire signed [BITS:0] err2 = err << 1;

	always @(posedge clk)
	begin
		//$monitor("%d %d %d %d %d", x_out, y_out, dx, dy, err);
		if (reset) begin
			// reset will latch the current inputs
			
		end else
		if (strobe) begin
			x_dst <= x_in;
			y_dst <= y_in;
			//axis <= 0;

			if (x_in > x_out) begin
				sx <= 1;
				dx <= x_in - x_out;
			end else begin
				sx <= 0;
				dx <= x_out - x_in;
			end

			if (y_in > y_out) begin
				sy <= 1;
				dy <= y_in - y_out;
			end else begin
				sy <= 0;
				dy <= y_out - y_in;
			end

			err <= ((x_in > x_out) ? (x_in - x_out) : (x_out - x_in))
				-
				((y_in > y_out) ? (y_in - y_out) : (y_out - y_in));

		end else
		if (!ready && !halt) begin
			// move towards the dstination point
			if (err2 > -dy)
			begin
				err <= err - dy;
				x_out <= x_out + (sx ? 1 : -1);
				axis <= 0;
			end else
			if (err2 < dx)
			begin
				err <= err + dx;
				y_out <= y_out + (sy ? 1 : -1);
				axis <= 1;
			end
		end
	end

	always@(posedge reset) begin
		x_dst <= x_in;
		y_dst <= y_in;
		x_out <= x_in;
		y_out <= y_in;
		err <= 0;
		axis <= 0;
	end
endmodule
