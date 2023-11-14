module axilite_read
#(	parameter pADDR_WIDTH = 12,
    	parameter pDATA_WIDTH = 32,
	parameter S0 = 2'b00,
	parameter S1 = 2'b01,
	parameter S2 = 2'b10,
	parameter S3 = 2'b11 
)
(
	// Global Signals 
	input   wire                     	axis_clk,
	input   wire                     	axilite_r_rst_n,
	//output  wire [1:0] 			state_o,
	
	input   wire				arready,
	input   wire				rvalid,
    	input   wire [(pADDR_WIDTH-1):0] 	addr,
    	input   wire [(pDATA_WIDTH-1):0] 	rdata,

	output	reg				arvalid,
	output	reg				rready,
	output	reg  [(pADDR_WIDTH-1):0]	araddr,
	output	reg  [(pDATA_WIDTH-1):0]	data
);
// AXI4-Lite Write Transaction
	
	reg [1:0] state;
	//assign state_o = state;
	
	always@(negedge axis_clk) begin
		if (!axilite_r_rst_n) begin
			state <= S0;
		end else begin
			case(state)
				S0: begin
					if (axilite_r_rst_n) begin
						state <= S1;
					end
					else begin
						state <= S0;
					end
				end
				S1: begin
					if (!arready) begin
						state <= S1;
					end
					else begin
						state <= S2;
					end
				end
				S2: begin
					if (!rvalid) begin
						state <= S2;
					end
					else begin
						state <= S3;
					end
				end
				S3: begin
						state <= S0;
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
			S0: begin arvalid <= 1'b0; rready <= 1'b0; end
			S1: begin arvalid <= 1'b1; rready <= 1'b0; araddr <= addr; end
			S2: begin arvalid <= 1'b0; rready <= 1'b1; end
			S3: begin arvalid <= 1'b0; rready <= 1'b0; data <= rdata; end
		endcase
	end

endmodule
