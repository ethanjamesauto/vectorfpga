module control(
    input clk,
    input reset,

    input [11:0] x,
    input [11:0] y,

    input jump,
    input draw,

    output ready,
    output reg beam,

    //DAC pins
	output cs_pin,
	output clk_pin,
	output data_pin
);
    //these state registers are used to track if the control module
    //is drawing, jumping, or dwelling before or after either.
    reg[1:0] draw_state;
    reg[1:0] jump_state;

    //each state register can have these possible states
    parameter OFF = 0;
    parameter PRE_DWELLING = 1;
    parameter WORKING = 2;
    parameter POST_DWELLING = 3;

    //counter used to track how many "steps" (outputs to the dac)
    //the control module should dwell. Setting to 0 will dwell for one
    //step. Disabling dwelling requires modification of the state machine
    //to skip the dwell state.
    reg[12:0] dwell; 

    //reset will make the line generator jump to the input x and y, so reset if jumping
    //or if the global reset is high
    wire line_reset = reset || jump_state == WORKING; 
    reg line_strobe; //starts the line drawing
    wire [11:0] x_out; //line generator output x
    wire [11:0] y_out; //line generator output y
    wire line_ready; //signals that the line generator is ready to draw another line
    wire line_axis; //the DAC axis to write to
    reg line_next; //set to high to output the next line drawing point

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
    
    wire dac_ready;
    wire dac_strobe = dac_ready; //always run the dac, and do so at max speed
    reg dac_axis;

    //tie the DAC input to the line generator's output
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
	
    //ready will be high for a clock cycle
    //the control module should be used at this time
    assign ready = jump_state == OFF && draw_state == OFF && dac_ready && line_ready;    

    always@(posedge clk) begin
        if (reset) begin //initialize registers
            dac_axis <= 0;
            line_strobe <= 0;
            line_next <= 0;
            dwell <= 0;
            
            jump_state <= 0;
            draw_state <= 0;
            beam <= 0;
        end else if (jump) begin 
            jump_state <= PRE_DWELLING;
            dwell <= 0; //pre-jump dwell
            beam <= 0;
        end else if (draw) begin
            draw_state <= PRE_DWELLING;
            line_strobe <= 1; //start the line generation
            dwell <= 0; //pre-draw dwell
            beam <= 1;
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
                dwell <= 0; //post-jump dwell
            end else if (jump_state == POST_DWELLING) begin
                if (dwell == 0) begin
                    jump_state <= OFF;
                end else begin
                    dwell <= dwell - 1;
                end
            end else if (draw_state == PRE_DWELLING) begin
                line_strobe <= 0;
                if (dwell == 0) begin
                    draw_state <= WORKING;
                    line_next <= 1;
                    dac_axis <= line_axis;
                end else begin
                    dwell <= dwell - 1;
                end
            end else if (draw_state == WORKING) begin
                line_next <= 1;
                dac_axis <= line_axis;
            end else if (draw_state == POST_DWELLING) begin
                if (dwell == 0) begin
                    draw_state <= OFF;
                end else begin
                    dwell <= dwell - 1;
                end
            end
        end else if (draw_state == WORKING && line_ready) begin

            //line_ready doesn't turn on until after line_next, so we need this to be
            //outside of the main state machine to ensure that we don't dwell
            //for an extra step
            draw_state <= POST_DWELLING;
            dwell <= 0; //post-draw dwell
        end else if (line_next) begin
            line_next <= 0; //line_next should only be on for a clock cycle
        end else if (line_strobe) begin
            line_strobe <= 0; //line_strobe should only be on for a clock cycle
        end
    end

endmodule