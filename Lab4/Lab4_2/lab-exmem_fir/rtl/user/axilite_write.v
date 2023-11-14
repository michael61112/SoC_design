module axilite_write
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
	input   wire                     	axilite_w_rst_n,
	//output  wire [1:0] 			state_o,
	
	input   wire				awready,
	input   wire				wready,
    	input   wire [(pADDR_WIDTH-1):0] 	addr,
    	input   wire [(pDATA_WIDTH-1):0] 	data,

	output	reg				awvalid,
	output	reg				wvalid,
	output	reg  [(pADDR_WIDTH-1):0]	awaddr,
	output	reg  [(pDATA_WIDTH-1):0]	wdata
);
// AXI4-Lite Write Transaction
	
	reg [1:0] state;
	//assign state_o = state;
	
	always@(negedge axis_clk) begin
		if (!axilite_w_rst_n) begin
			state <= S0;
		end else begin
			case(state)
				S0: begin
					if (axilite_w_rst_n) begin
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
					else begin
						state <= S2;
					end
				end
				S2: begin
					if (!wready) begin
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
			S0: begin awvalid <= 1'b0; wvalid <= 1'b0; end
			S1: begin awvalid <= 1'b1; wvalid <= 1'b0; awaddr <= addr; end
			S2: begin awvalid <= 1'b0; wvalid <= 1'b0; end
			S3: begin awvalid <= 1'b0; wvalid <= 1'b1; wdata <= data; end
		endcase
	end

endmodule
