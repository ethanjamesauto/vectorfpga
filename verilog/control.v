module control(
    input clk,
    input reset,

    input [11:0] x,
    input [11:0] y,

    input jump,
    input draw,

    output ready,

    // physical interface
	output cs_pin,
	output clk_pin,
	output data_pin
);

    parameter OFF = 0;
    parameter PRE_DWELLING = 1;
    parameter WORKING = 2;
    parameter POST_DWELLING = 3;
    reg[1:0] draw_state;
    reg[1:0] jump_state;

    reg jump_ctr;
    reg[5:0] dwell;

    //controls for the line generator
    wire line_reset = reset || jump_state == WORKING;
    reg line_strobe;
    wire [11:0] x_out;
    wire [11:0] y_out;
    wire line_ready;
    wire line_axis;
    reg line_next;

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
    
    assign ready = jump_state == OFF && draw_state == OFF && dac_ready && line_ready;    

    //controls for the DAC
    wire dac_ready;
    wire dac_strobe = dac_ready; //always run the dac, and do so at max speed
    reg dac_axis;
    wire [11:0] dac_in = dac_axis ? y_out : x_out;

    mcp4922 dac(
		.clk(clk),
		.reset(reset),
		.value(dac_in),
		.axis(dac_axis),
		.strobe(dac_strobe),
		.ready(dac_ready),

        .cs_pin(cs_pin),
        .clk_pin(clk_pin),
        .data_pin(data_pin)
	);

    always@(posedge clk) begin
        if (reset) begin
            dac_axis <= 0;
            line_strobe <= 0;
            line_next <= 0;
            dwell <= 0;
            
            jump_state <= 0;
            draw_state <= 0;
            jump_ctr <= 0;
        end else if (jump) begin
            jump_state <= PRE_DWELLING;
            dwell <= 2;
        end else if (draw) begin
            draw_state <= PRE_DWELLING;
            dwell <= 3;
        end else if (dac_ready) begin
            if (jump_state == PRE_DWELLING) begin
                if (dwell == 0) begin
                    jump_state <= WORKING;
                end else begin
                    dwell <= dwell - 1;
                end
            end else if (jump_state == WORKING) begin
                dac_axis <= 1;
                jump_state <= POST_DWELLING;
            end else if (jump_state == POST_DWELLING) begin
                if (dwell == 0) begin
                    jump_state <= OFF;
                end else begin
                    dwell <= dwell - 1;
                end
            end else if (draw_state == PRE_DWELLING) begin

            end else if (draw_state == WORKING) begin

            end else if (draw_state == POST_DWELLING) begin

            end
        end
    end

endmodule