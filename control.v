module control(
    input clk,
    input reset,

    input [11:0] x,
    input [11:0] y,

    input jump,
    input draw,

    output ready
);
    reg control_ready;
    assign ready = control_ready && dac_ready && line_ready;

    //controls for the DAC
    wire [11:0] dac_value;
    assign dac_value = dac_axis ? y_out : x_out;

    reg dac_axis;

    reg dac_enable;
    wire dac_ready;
    wire dac_strobe = dac_ready && dac_enable;

    mcp4922 dac(
		.clk(clk),
		.reset(reset),
		.value(dac_value),
		.axis(dac_axis),
		.strobe(dac_strobe),
		.ready(dac_ready)
	);

    //controls for the line generator
    wire line_reset = reset || jump;
    reg line_strobe;
    reg line_halt;
    wire [11:0] x_out;
    wire [11:0] y_out;
    wire line_ready;
    wire line_axis;

    lineto line_gen(
		.clk(clk),
		.reset(line_reset),
		.strobe(line_strobe),
		.halt(line_halt),
		.x_in(x),
		.y_in(y),
		.x_out(x_out),
		.y_out(y_out),

		.ready(line_ready),
		.axis(line_axis)
	);

    //state controls
    reg jumping;
    reg drawing;

    always@(posedge clk) begin
        if (reset) begin
            dac_enable <= 0;
            dac_axis <= 0;
            control_ready <= 1;
            line_strobe <= 0;
            line_halt <= 0;

            jumping <= 0;
            drawing <= 0;
        end else if (jumping) begin
            if (dac_axis == 1 && dac_ready) begin
                dac_enable <= 0;
                control_ready <= 1;
                jumping <= 0;
            end else if (dac_enable == 1) begin
                dac_axis <= 1;
            end
        end
    end

    always@(posedge jumping) begin
        #2 dac_enable <= 1;
    end

    always@(posedge jump) begin
        if (!reset && ready) begin
            control_ready <= 0;
            jumping <= 1;
            dac_axis <= 0;
        end
    end

endmodule