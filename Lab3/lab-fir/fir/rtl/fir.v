module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
	// Global Signals 
	input   wire                     axis_clk,
    input   wire                     axis_rst_n,
	output  wire  [1:0] state_o,
	// Write Address Channel
	input   wire [(pADDR_WIDTH-1):0] awaddr,
	input   wire                     awvalid,
    output  wire                     awready,
	
	// Write Data Channel
	input   wire [(pDATA_WIDTH-1):0] wdata,
	input   wire                     wvalid,
    output  wire                     wready,
    
    // Read Address Channel
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output  wire                     arready,
    input   wire                     arvalid,
	
	// Read Data Channel
	output  wire [(pDATA_WIDTH-1):0] rdata,    
	output  wire                     rvalid,
	input   wire                     rready,
    
	// Stream Slave
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tvalid, 
    output  wire                     ss_tready, 
    input   wire                     ss_tlast, 

	// Stream Master
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    output  wire                     sm_tvalid, 
    input   wire                     sm_tready, 
    output  wire                     sm_tlast, 
    
    // bram for tap RAM
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do
);
begin

	// [ap_start]
	// set by software/ testbench
	// reset by engine when start data transfer

	// [ap_done]
	// set when engine complete s last data processing and data is transferred
	// reset when reset signal is asserted
	// reset when it is read
	
	// [ap_idle]
	// set when reset
	// set when FIR engine processes the last data and last data is transferred
	// reset when ap_start is sampled
/*
WE = AW valid & wvalid
awready = @WE @clk
wready =  @WE @clk

// drew the timing path

x_buffer <= x
y_buffer <= y

back_pressure
*/
// TB wait 11T to look dead lock or not


//  config_write Feedback
	reg [(pADDR_WIDTH-1):0]  config_write_address;
	reg [(pDATA_WIDTH-1):0]  config_write_data;


    assign tap_A = ((config_write_address & 12'hf0) == 12'h40) ? { 6'b0 , config_write_address[5:0]} : 12'b0;

	
	reg [1:0] state;
	assign state_o = state;
	
// AXI4-Lite Write Transaction
	reg awready_temp = 0;
	reg wready_temp = 0;

	// Set state parameter
	parameter S0 = 2'b00;
	parameter S1 = 2'b01;
	parameter S2 = 2'b10;
	parameter S3 = 2'b11;
	
	always@(negedge axis_clk or negedge axis_rst_n) begin
		if (!axis_rst_n) begin
			state <= S0;
		end else begin
			case(state)
				S0: begin
					if (awvalid) begin
						config_write_address <= awaddr;
						state <= S1;
					end 
					else begin
						state <= S0;
					end
				end
				S1: begin
					if (!awvalid) begin
						state <= S2;
					end
					else begin
						state <= S1;
					end
				end
				S2: begin
					if (wvalid) begin
						config_write_data <= wdata;
						state <= S3;
					end
					else begin
						state <= S2;
					end
				end
				S3: begin
					if (!wvalid) begin
						state <= S0;
					end
					else begin
						state <= S3;
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
			S0: begin awready_temp <= 1'b0; wready_temp <= 1'b0; end
			S1: begin awready_temp <= 1'b1; wready_temp <= 1'b0; end
			S2: begin awready_temp <= 1'b0; wready_temp <= 1'b0; end
			S3: begin awready_temp <= 1'b0; wready_temp <= 1'b1; end
		endcase
	end

	assign awready = (awready_temp) ? 1'b1 : 1'b0;
	assign wready = (wready_temp) ? 1'b1 : 1'b0;	
	
	always @(negedge awvalid) begin
		awready_temp <= 1'b0;
	end
	
	always @(negedge wvalid) begin
		wready_temp <= 1'b0;
	end
////////////////////////////////////////////////////////////////////////////
	
// AXI4-Lite Read Transaction
	reg arready_temp = 0;
	reg rvalid_temp = 0;
	reg [(pDATA_WIDTH-1):0] rdata_temp;
	// config_read Feedback
	reg [(pADDR_WIDTH-1):0]  config_read_address;
	reg [(pDATA_WIDTH-1):0]  config_read_data = 12'hff;
/*
	// Set state parameter
	parameter S0 = 2'b00;
	parameter S1 = 2'b01;
	parameter S2 = 2'b10;
	parameter S3 = 2'b11;
	*/
	always@(negedge axis_clk or negedge axis_rst_n) begin
		if (!axis_rst_n) begin
			state <= S0;
		end else begin
			case(state)
				S0: begin
					if (arvalid) begin
						config_read_address <= araddr;
						state <= S1;
					end 
					else begin
						state <= S0;
					end
				end
				S1: begin
					if (!arvalid) begin
						state <= S2;
					end
					else begin
						state <= S1;
					end
				end
				S2: begin
					if (rready) begin
						rdata_temp = config_read_data;
						state <= S3;
					end
					else begin
						state <= S2;
					end
				end
				S3: begin
					if (!rready) begin
						state <= S0;
					end
					else begin
						state <= S3;
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
			S0: begin arready_temp <= 1'b0; rvalid_temp <= 1'b0; end
			S1: begin arready_temp <= 1'b1; rvalid_temp <= 1'b0; end
			S2: begin arready_temp <= 1'b0; rvalid_temp <= 1'b0; end
			S3: begin arready_temp <= 1'b0; rvalid_temp <= 1'b1; end
		endcase
	end

	assign arready = (arready_temp) ? 1'b1 : 1'b0;
	assign rvalid = (rvalid_temp) ? 1'b1 : 1'b0;	
	assign rdata = rdata_temp;
	
	always @(negedge arvalid) begin
		arready_temp <= 1'b0;
	end
	
	always @(negedge rready) begin
		rvalid_temp <= 1'b0;
	end
end
endmodule 