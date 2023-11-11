module axistream_write
#(
	parameter S0 = 2'b00,
	parameter S1 = 2'b01,
	parameter S2 = 2'b10,
	parameter S3 = 2'b11 
)
(
	// Global Signals 
	input   wire                     	axis_clk,
	input   wire                     	axis_rst_n,
	//output  wire [1:0] 			state_o,
	input	wire				wbs_cyc_i,

	input   wire				ss_tready,
    	input   wire [(pDATA_WIDTH-1):0] 	data,

	output	reg				ss_tvalid,
	output	reg  [(pDATA_WIDTH-1):0]	ss_data
);
begin // AXI4-Lite Write Transaction
	
	reg [1:0] state;
	//assign state_o = state;
	
	always@(negedge axis_clk) begin
		if (!axis_rst_n) begin
			state <= S0;
		end else begin
			case(state)
				S0: begin
					if (axis_rst_n) begin
						state <= S1;
					end
					else begin
						state <= S0;
					end
				end
				S1: begin
					if (!awready) begin
						state <= S1;
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
	
end
endmodule
