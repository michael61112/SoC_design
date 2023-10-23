module address_gen
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
	parameter S0 = 3'b000, // Idle
	parameter S1 = 3'b001, // TB write
	parameter S2 = 3'b010, // TB read
	parameter S3 = 3'b011, // FIR read
	parameter S4 = 3'b100, // R/W Done
	parameter S5 = 3'b101  // Send result
)
(
	// Global Signals 
	input   wire                     axis_clk,
	input   wire                     axis_rst_n,
	output  wire [2:0] 			 	 state_o,
	
	// Write Address Channel
	input  wire [2:0]				 state_data_ram ,
	input  wire                      fir_start,
	
    input wire                       mac_reset,
    input wire                       fir_request,
	input wire 					 	 result_ready,
	//output wire [9:0]				 counter,
	
	output wire [(pADDR_WIDTH-1):0]	 tap_addr_r,
	output wire [(pADDR_WIDTH-1):0]  fir_addr_r 
);
begin
	
	reg [1:0] state;
	reg [3:0]i;
	assign state_o = state;
	//reg [9:0]				 counter_temp;
	reg mac_reset_temp;
	reg fir_request_temp;
	reg result_ready_temp;
	reg [(pADDR_WIDTH-1):0]		 tap_addr_r_temp;
	reg [(pADDR_WIDTH-1):0] 		 fir_addr_r_temp; 
	
	always@(negedge axis_clk) begin
		if (!axis_rst_n) begin
			state <= S0;
		end else begin
			case(state)
				S0: begin
					if (state_data_ram == S1 && fir_start) begin
						state <= S1;
					end
					else begin
						state <= S0;
					end
				end
				S1: begin
					if (i == 1)
					state <= S2;
				end
				S2: begin
					state <= S1;
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
			S0: begin mac_reset_temp <= 1'b1; fir_request_temp <= 1'b0; result_ready_temp <= 1'b0; 
				tap_addr_r_temp <= 12'h00; 
				fir_addr_r_temp <= 12'h00;
				i = 4'h0;
				end
			S1: begin mac_reset_temp <= 1'b0; fir_request_temp <= 1'b1; result_ready_temp <= 1'b0; 
				tap_addr_r_temp <= (tap_addr_r_temp < 12'h028) ? (tap_addr_r_temp + 12'h4) : 12'h0;
				fir_addr_r_temp <= (fir_addr_r_temp < 12'h028) ? (fir_addr_r_temp + 12'h4) : 12'h0;
				i = i + 4'h1;
				end
			S2: begin mac_reset_temp <= 1'b0; fir_request_temp <= 1'b1; result_ready_temp <= 1'b0; end
			S3: begin mac_reset_temp <= 1'b0; fir_request_temp <= 1'b1; result_ready_temp <= 1'b1; end
				//counter = counter + 10'b1; end
		endcase
	end

	assign mac_reset = mac_reset_temp;
	assign fir_request = fir_request_temp;
	assign result_ready = result_ready_temp;
	
	assign tap_addr_r = tap_addr_r_temp;
	assign fir_addr_r = fir_addr_r_temp;
	
	//assign counter_o = counter_temp;
end
endmodule