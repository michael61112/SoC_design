module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11,
	parameter S0 = 3'b000, // Idle
	parameter S1 = 3'b001, // TB write
	parameter S2 = 3'b010, // TB read
	parameter S3 = 3'b011, // FIR read
	parameter S4 = 3'b100  // R/W Done
)
(
	// Global Signals 
	input   wire                     axis_clk,
    input   wire                     axis_rst_n,
	output  wire  [1:0] 			 state_w,
	output  wire  [1:0] 			 state_r,
	output  wire  [1:0] 			 state_data_ram,
	output  wire  [1:0] 			 last_state_o,
	output [(pADDR_WIDTH-1):0]       out_adress,
	output [(pDATA_WIDTH-1):0]   	 out_data,
	output [(pADDR_WIDTH-1):0]       addr_r,
	output [(pADDR_WIDTH-1):0]       addr_w,
	output [(pADDR_WIDTH-1):0]       tb_A,
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
    output  wire  [(pDATA_WIDTH-1):0] sm_tdata, 
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

//  AXI4 Lite Write Transaction
	wire [(pADDR_WIDTH-1):0]  config_write_address;
	wire [(pDATA_WIDTH-1):0]  config_write_data;

	axi4lite_write axi4lite_write_1(
		.axis_clk(axis_clk),
		.axis_rst_n(axis_rst_n),
		.state_o(state_w),
		.awaddr(awaddr),
		.awvalid(awvalid),
		.awready(awready),
		.wdata(wdata),
		.wvalid(wvalid),
		.wready(wready),
		.config_write_address(config_write_address),
		.config_write_data(config_write_data)
	);
    
	assign tap_WE = (wvalid & wready) ? 4'hf : 4'h0;
    assign tap_EN = config_write_address[6] | config_read_address[6];
    assign tap_Di = wdata;
    assign tap_A = (!tap_EN) ? 12'b0 :
					(tap_WE) ? {6'b0, config_write_address[5:0]} : {6'b0, config_read_address[5:0]};
    assign rdata = (config_read_address[6]) ? tap_Do :
					(config_read_address == 12'h10) ? data_length :
						(config_read_address == 12'h00) ? {29'b0, ap_idle, ap_done, ap_start} : 32'b0;
	//debug
	assign out_adress = config_read_address;
	assign out_data = rdata;
	
	
////////////////////////////////////////////////////////////////////////////
//  AXI4 Lite Read Transaction
	wire  [(pADDR_WIDTH-1):0]  config_read_address;
	//wire  [(pDATA_WIDTH-1):0]  config_read_data;

	axi4lite_read axi4lite_read_1(
		.axis_clk(axis_clk),
		.axis_rst_n(axis_rst_n),
		.state_o(state_r),
		.araddr(araddr),
		.arready(arready),
		.arvalid(arvalid),
		.rdata(rdata),    
		.rvalid(rvalid),
		.rready(rready),
		.config_read_address(config_read_address)//,
		//.config_read_data(tap_Do)
	);
///////////////////////////////////////////////////////////////////////////

reg ap_start = 1'b0;
reg ap_done = 1'b0;
reg ap_idle = 1'b0;
reg [31:0] data_length = 32'b0;

always@(*) begin
ap_start = !(config_write_address == 12'h00) ? ap_start :
				(config_write_data & 32'b1) ? 1'b1 : 1'b0;



data_length = ((config_write_address == 12'h10) & (wvalid & wready)) ? wdata : data_length;
end

///////////////////////////////////////////////////////////////////////////

/*

wire BRAM_avail_w = (ss_tvalid & data_EN);
wire BRAM_avail_r = ~BRAM_avail_w;

//  SS Bus Logic
assign ss_tready = (BRAM_avail_w) ? 1'b1 : 1'b0;



///////////////////////////////////////////////////////////////////////////
wire fir_or_bram_out = 1'b0;  //just connect to FIR, if debug can change to BRAM
//  SM Bus Logic
assign sm_tvalid = (BRAM_avail_r & !(&data_WE) & data_EN) ? 1'b1 : 1'b0; ////
*/

// Address Generater
reg [(pADDR_WIDTH-1):0] addr_w = 12'h0;
reg [(pADDR_WIDTH-1):0] addr_r = 12'h0;
reg [(pADDR_WIDTH-1):0] fir_addr_r = 12'h0;

reg [1:0] last_state;
always@(posedge axis_clk) begin
	if (state_data_ram != S0) begin
		last_state <= state_data_ram;
	end
end
assign last_state_o = last_state;


always@(posedge axis_clk) begin
	if (~axis_rst_n) begin
		addr_w <= 12'h0;
		addr_r <= 12'h0;
		fir_addr_r <= 12'h0;
		last_state <= S0;
	end
	else begin
		if ((state_data_ram == S4) && (last_state == S1)) begin
			addr_w <= (addr_w < 12'h028) ? (addr_w + 12'h4) : 12'h0;
		end
		
		else if ((state_data_ram == S4) && ((last_state == S2) || (last_state == S3))) begin
			addr_r <= (addr_r < 12'h028) ? (addr_r + 12'h4) : 12'h0;
		end
		else begin
			addr_w <= addr_w;
			addr_r <= addr_r;
		end
	end
	last_state <= state_data_ram;
end

wire [(pADDR_WIDTH-1):0] tb_A;
wire [(pADDR_WIDTH-1):0] fir_A = 12'h0;

assign tb_A = (state_data_ram == S1) ? addr_w : addr_r;
assign fir_A = fir_addr_r;
/*
///////////////////////////////////////////////////////////////////////////
//  RAM Control Logic	
assign data_WE = (ss_tready) ? 4'hf : 4'h0;
assign data_EN = 1'b1;

assign data_Di = ss_tdata;

assign data_A = (ss_tready) ? addr_w : 
					(sm_tvalid) ? addr_r : data_A;
					

assign sm_tdata = (fir_or_bram_out) ? 32'b0 : data_Do;  // Change to Y
*/
///////////////////////////////////////////////////////////////////////////


//wire ram_rw;

data_ram_axi4stream data_ram_axi4stream1(
	.axis_clk(axis_clk),
	.axis_rst_n(axis_rst_n),
	.ss_tvalid(ss_tvalid),
	.ss_tready(ss_tready),
	.ss_tdata(ss_tdata),
	.sm_tready(sm_tready),
	.sm_tvalid(sm_tvalid),
	.sm_tdata(sm_tdata),
	.tb_A(tb_A),
	.fir_request(fir_request),
	.fir_A(fir_A),
	.state_o(state_data_ram),
	.data_WE(data_WE),
	.data_EN(data_EN),
	.data_A(data_A),
	.data_Di(data_Di),
	.data_Do(data_Do)
);



//data_Do
///////////////////////////////////////////////////////////////////////////
/*
reg [31:0]			result;
reg [31:0]			result_temp;
wire [31:0]	A=32'h3;
wire [31:0] B=32'h2;
reg [2:0] i;

	mac mac1(
		.axis_clk(axis_clk),
		.reset(reset),
		.A(A),
		.B(B),
		.result(result)
	);

always@(*) begin
	tap_A = 12'h00;
	data_A = 12'h00;
	sm_tvalid = 1'b0;

	reset = 1'b1;
	@(posedge axis_clk);
	reset = 1'b0;
	
	for (i = 0; i < 11; i = i + 1) begin
		tap_A = tap_A + 4*i;
		data_A = data_A + 4*i;
		
		A = tap_Do;
		B = data_Do;
	end
	sm_tdata = result;
	sm_tvalid = 1'b1;
end
*/



end
endmodule 
