module control(
    input clk,
    input reset,

    input [11:0] x,
    input [11:0] y,

    input jump,
    input draw,

    output ready
);
    reg jumping;
    reg drawing;

    //controls for the DAC
    wire [11:0] dac_value;
    reg dac_axis;
    reg dac_enable;
    wire dac_ready;
    wire dac_strobe = dac_ready && dac_enable;


    //controls for the line generator
    wire line_reset = reset || jump;
    reg line_strobe;
    wire [11:0] x_out;
    wire [11:0] y_out;
    wire line_ready;
    wire line_axis;
    reg line_next;
    
    assign ready = !jumping && dac_ready && line_ready;    
    assign dac_value = dac_axis ? y_out : x_out;

    mcp4922 dac(
		.clk(clk),
		.reset(reset),
		.value(dac_value),
		.axis(dac_axis),
		.strobe(dac_strobe),
		.ready(dac_ready)
	);

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

    always@(posedge clk) begin
        if (reset) begin
            dac_enable <= 1;
            dac_axis <= 0;
            line_strobe <= 0;
            line_next <= 0;
            jumping <= 0;
            drawing <= 0;
        end 

        //handle drawing
        if (!reset && draw) begin
            line_strobe <= 1;
            drawing <= 1;
        end
        if (!reset && drawing) begin
            dac_axis <= line_axis;
            if (dac_ready && !ready) begin
                line_next <= 1;
                if (line_ready) begin //TODO: make this happen ASAP
                    drawing <= 0;
                end
            end
            if (line_next) begin
                line_next <= 0;
            end
        end
        if (line_strobe) begin
            line_strobe <= 0;
            line_next <= 1;
        end

        //handle jumping
        if (!reset && jump) begin
            jumping <= 1;
            drawing <= 0; //make sure this is the case
            dac_axis <= 0;
        end else if (!reset && jumping && dac_ready) begin
            dac_axis <= 1;
            jumping <= 0;
        end
    end

endmodule