module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
	// Global Signals 
	input   wire                     axis_clk,
    input   wire                     axis_rst_n
	
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
    input   wire [(pDATA_WIDTH-1):0] data_Do,
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


end