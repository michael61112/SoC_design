module axistream_write
#(  	parameter pADDR_WIDTH = 12,
    	parameter pDATA_WIDTH = 32,
	parameter S0 = 2'b00,
	parameter S1 = 2'b01,
	parameter S2 = 2'b10,
	parameter S3 = 2'b11 
)
(
	// Global Signals 
	input   wire                     	axis_clk,
	input   wire                     	axirstream_w_rst_n,
	//output  wire [1:0] 			state_o,

	input   wire				ss_tready,
    	input   wire [(pDATA_WIDTH-1):0] 	data,

	output	reg				ss_tvalid,
	output	reg  [(pDATA_WIDTH-1):0]	ss_data
);
// AXI4-Stream Write Transaction
	
	reg [1:0] state;
	//assign state_o = state;
	
	always@(negedge axis_clk) begin
		if (!axirstream_w_rst_n) begin
			state <= S0;
		end else begin
			case(state)
				S0: begin
					if (axirstream_w_rst_n) begin
						state <= S1;
					end
					else begin
						state <= S0;
					end
				end
				S1: begin
					if (!ss_tready) begin
						state <= S1;
					end
					else begin
						state <= S0;
					end
				end
				default: begin 
					state <= S0;
				end
			endcase
		end
	end
	
	// Set output value
	always @(posedge axis_clk) begin
		case(state)
			S0: begin ss_tvalid <= 1'b0; end
			S1: begin ss_tvalid <= 1'b1; ss_data <= data; end
		endcase
	end

endmodule
