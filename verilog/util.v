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
	input next,
	input [11:0] x_in, //TODO: get the macro working again
	input [11:0] y_in,
	input [3:0] shift,

	output ready, // set when done
	output reg axis, // did the x or y value change
	output reg [11:0] x_out,
	output reg [11:0] y_out
);
	reg [3:0] curr_shift;
	parameter BITS = 15;

	reg [BITS-1:0] err;

	reg [11:0] x_step;
	reg [11:0] y_step;
	reg [BITS-1:0] x_dst;
	reg [BITS-1:0] y_dst;

	// once the output reaches the dstination, it is ready
	// for a new point.
	assign ready = (x_dst == x_step) && (y_dst == y_step);

	reg sx;
	reg sy;

	reg signed [BITS-1:0] dx;
	reg signed [BITS-1:0] dy;
	
	wire signed [BITS:0] err2 = err << 1;

	reg assign_vars;

	always @(posedge clk)
	begin
		//$monitor("%d %d %d %d %d", x_step, y_step, dx, dy, err);
		if (reset) begin
			// reset will latch the current inputs
			x_step <= x_in;
			y_step <= y_in;
			x_out <= x_in;
			y_out <= y_in;
			err <= 0;
			axis <= 0;
			curr_shift <= 0;
			x_dst <= x_in;
			y_dst <= y_in;
			assign_vars <= 0;
		end else if (strobe) begin
			if (shift < curr_shift) begin
				x_step <= x_step << (curr_shift - shift);
				y_step <= y_step << (curr_shift - shift);
			end else begin
				x_step <= x_step >> (shift - curr_shift);
				y_step <= y_step >> (shift - curr_shift);
			end
			
			curr_shift <= shift;

			x_dst <= x_in >> shift;
			y_dst <= y_in >> shift;
			//axis <= 0;
			assign_vars <= 1;
		end else if (assign_vars) begin
			if (x_dst > x_step) begin
				sx <= 1;
				dx <= x_dst - x_step;
			end else begin
				sx <= 0;
				dx <= x_step - x_dst;
			end

			if (y_dst > y_step) begin
				sy <= 1;
				dy <= y_dst - y_step;
			end else begin
				sy <= 0;
				dy <= y_step - y_dst;
			end
			err <= ((x_dst > x_step) ? (x_dst - x_step) : (x_step - x_dst))
				-
				((y_dst > y_step) ? (y_dst - y_step) : (y_step - y_dst));
			
			assign_vars <= 0;
		end else if (!ready && next) begin
			// move towards the dstination point
			if (err2 > -dy)
			begin
				err <= err - dy;
				x_step <= x_step + (sx ? 1 : -1);
				x_out <= x_step << curr_shift;
				axis <= 0;
			end else
			if (err2 < dx)
			begin
				err <= err + dx;
				y_step <= y_step + (sy ? 1 : -1);
				y_out <= y_step << curr_shift;
				axis <= 1;
			end
		end
	end
endmodule