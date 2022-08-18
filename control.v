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
    wire [11:0] x_out;
    wire [11:0] y_out;
    wire line_ready;
    wire line_axis;

    reg line_next = 0;

    lineto line_gen(
		.clk(clk),
		.reset(line_reset),
		.strobe(line_strobe),
		.next(line_next),
		.x_in(x),
		.y_in(y),
		.x_out(x_out),
		.y_out(y_out),

		.ready(line_ready),
		.axis(line_axis)
	);

    //state controls
    always@(posedge reset) begin
        dac_enable <= 1;
        dac_axis <= 0;
        control_ready <= 1;
        line_strobe <= 0;

        jumping <= 0;
        drawing <= 0;
    end

    reg jumping;
    reg drawing;

    always@(posedge clk && !reset) begin            
        if (jumping && dac_ready) begin
            if (dac_axis == 0) begin
                dac_axis <= 1;
                control_ready <= 1;
                jumping <= 0;
            end
        end
    end

    always@(posedge jump) begin
        if (!reset) begin
            control_ready <= 0;
            jumping <= 1;
            dac_axis <= 0;
        end
    end

    always@(posedge clk && !reset) begin     
        if (drawing) begin
            line_strobe <= 0;
            dac_axis <= line_axis;
            if (dac_ready && !ready) begin
                line_next <= 1;
                if (line_ready) begin
                    drawing <= 0;
                end
            end
            if (line_next) begin
                line_next <= 0;
            end
        end       
    end

    always@(posedge draw) begin
        if (!reset) begin
            line_strobe <= 1;
            drawing <= 1;
        end
    end

    always@(negedge line_strobe) begin
        if (drawing) begin
            line_next <= 1;
        end
    end
    

endmodule