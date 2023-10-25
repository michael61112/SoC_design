module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11,
	parameter S0 = 3'b000, // Idle
	parameter S1 = 3'b001, // TB write
	parameter S2 = 3'b010, // TB read
	parameter S3 = 3'b011, // FIR read
	parameter S4 = 3'b100, // R/W Done
	parameter S5 = 3'b101, // Send result
	parameter S6 = 3'b110  // Reset
)
(
	// Global Signals 
	input   wire                     axis_clk,
    input   wire                     axis_rst_n,
	output  wire  [1:0] 			 state_w,
	output  wire  [1:0] 			 state_r,
	output  wire  [2:0] 			 state_data_ram,
	output  wire  [2:0] 			 last_state_o,
	output  wire  [2:0] 			 status_address_gen_o,
	output [(pADDR_WIDTH-1):0]       out_adress,
	output [(pDATA_WIDTH-1):0]   	 out_data,
	output [(pADDR_WIDTH-1):0]       addr_r_o,
	output [(pADDR_WIDTH-1):0]       addr_w_o,
	output [(pADDR_WIDTH-1):0]       tb_A_o,
	output [(pADDR_WIDTH-1):0] fir_start_address_o,
	output  wire  					 fir_start_o,
	output  wire  					 mac_reset_o,
	output  wire  					 result_ready_o,
	output  wire [3:0]				 i_o,
	output  [(pDATA_WIDTH-1):0]				 A_o,
	output  [(pDATA_WIDTH-1):0]				 B_o,
	output  [(pDATA_WIDTH-1):0]				 result_Y_o,
	output  [(pDATA_WIDTH-1):0]				 sm_fdata_o,
	
	output wire						mac_EN_o,
	output wire						ap_start_o,
	output wire						ap_done_o,
	output wire						ap_idle_o,
	output wire	[9:0]					counter_o,
	
	
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

assign ap_start_o = ap_start;
assign ap_done_o = ap_done;
assign ap_idle_o = ap_idle;
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
		//.rdata(rdata),    
		.rvalid(rvalid),
		.rready(rready),
		.config_read_address(config_read_address)//,
		//.config_read_data(tap_Do)
	);
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
	.sm_fready(sm_fready),
	.sm_fvalid(sm_fvalid),
	.sm_fdata(sm_fdata),
	.tb_A(tb_A),
	.fir_A(fir_A),
	.state_o(state_data_ram),
	.data_WE(data_WE),
	.data_EN(data_EN),
	.data_A(data_A),
	.data_Di(data_Di),
	.data_Do(data_Do),
	.ap_idle(ap_idle),
	.result_ready(result_ready),
	.result_Y(result_Y)
);


reg ap_start = 1'b0;
reg ap_done = 1'b0;
reg ap_idle = 1'b0;
reg [31:0] data_length = 32'b0;

always@(posedge axis_clk) begin

	if (~axis_rst_n) begin
		ap_start <= 1'b0;
		ap_done <= 1'b0;
		ap_idle <= 1'b1;
		
		fir_start =  1'b0;
	end
	else begin
		if (config_write_address == 12'h00) begin
			if (config_write_data & 32'b1) begin
				ap_start <= 1'b1;
				ap_idle <= 1'b0;
				fir_start <= 1'b1;
			end
			else begin
				ap_start <= 1'b0;
			end
		end
		else if (fir_start) begin
			ap_start <= 1'b0;
		end
		else begin
			ap_start <= ap_start;
		end


		data_length = ((config_write_address == 12'h10) & (wvalid & wready)) ? wdata : data_length;

		if ((counter == data_length) && sm_tvalid) begin
			ap_done <= 1'b1;
			ap_idle <= 1'b1;
			fir_start <= 1'b0;
		end
	end
end
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
///////////////////////////////////////////////////////////////////////////
	assign tap_WE = (wvalid & wready & awaddr[6]) ? 4'hf : 4'h0;
    assign tap_EN = config_write_address[6] | config_read_address[6];
    assign tap_Di = wdata;
	
	/*
    assign tap_A = (!tap_EN) ? 12'b0 :
					(tap_WE) ? {6'b0, config_write_address[5:0]} : {6'b0, config_read_address[5:0]};
				*/	
	assign tap_A = (!tap_EN) ? 12'b0 :
					(&tap_WE) ? {6'b0, config_write_address[5:0]} : 
					(fir_start) ? tap_addr_r : {6'b0, config_read_address[5:0]};				//fir_addr_r

					
					
    assign rdata = (config_read_address[6]) ? tap_Do :
					(config_read_address == 12'h10) ? data_length :
						(config_read_address == 12'h00) ? {29'b0, ap_idle, ap_done, ap_start} : 32'b0;
	//debug
	assign out_adress = config_read_address;
	assign out_data = rdata;
///////////////////////////////////////////////////////////////////////////

// Address Generater
reg [(pADDR_WIDTH-1):0] addr_w;
reg [(pADDR_WIDTH-1):0] addr_r;
reg [(pADDR_WIDTH-1):0] last_addr_w;
wire [(pADDR_WIDTH-1):0]		tap_addr_r;
wire [(pADDR_WIDTH-1):0] fir_addr_r;

reg [2:0] last_state;
always@(negedge axis_clk) begin
	if (~axis_rst_n) begin
		last_state <= S0;
	end
	else begin
		if (state_data_ram != S0) begin
			last_state <= state_data_ram;
		end
	end
end
assign last_state_o = last_state;


always@(posedge axis_clk) begin
	if (~axis_rst_n) begin
		addr_w <= 12'h0;
		addr_r <= 12'h0;
		last_addr_w <= 12'h0;
		//fir_addr_r <= 12'h0;
		
		//tap_A_temp <= 12'b0;
	end
	else begin
		// Data address assignment
		if (state_data_ram == S1) begin //(state_data_ram == S0) && (last_state == S1)
			addr_w <= (addr_w < 12'h028) ? (addr_w + 12'h4) : 12'h0;
			last_addr_w <= addr_w;
		end
		
		else if ((state_data_ram == S0) && (last_state == S2)) begin
			addr_r <= (addr_r < 12'h028) ? (addr_r + 12'h4) : 12'h0;
		end
		else begin
			addr_w <= addr_w;
			addr_r <= addr_r;
		end
		/*
		// Tap address assignment
		if (tap_EN) begin
			if (tap_WE) begin
				tap_A_temp = {6'b0, config_write_address[5:0]};
			end
			else begin
				if (fir_start) begin
					tap_A_temp = tap_addr_r;
				end
				else begin
					tap_A_temp = {6'b0, config_read_address[5:0]};
				end
			end
		end
		else begin
			tap_A_temp = 12'b0;
		end
	*/
	end
end

wire [(pADDR_WIDTH-1):0] tb_A;
wire [(pADDR_WIDTH-1):0] fir_A;
reg [11:0]			tap_A_temp;

assign tb_A = (state_data_ram == S1) ? addr_w : addr_r;
assign fir_A = fir_addr_r;
//assign tap_A = tap_A_temp;

assign addr_w_o = addr_w;
assign addr_r_o = addr_r;
assign tb_A_o = tb_A;

///////////////////////////////////////////////////////////////////////////

wire [31:0]			result_Y;
reg 				fir_start;

wire					mac_reset;
wire					result_ready;


wire [9:0]			counter;
reg [31:0]	A;
reg [31:0] B;

wire mac_EN;

wire 							sm_fready;
wire 							sm_fvalid;
wire 	[(pDATA_WIDTH-1):0]		sm_fdata;
assign A_o = tap_Do;
assign B_o = sm_fdata;
assign result_Y_o = result_Y;

assign result_ready_o = result_ready;
assign fir_start_o = fir_start;
assign mac_reset_o = mac_reset;
assign mac_EN_o = mac_EN;
assign sm_fdata_o = sm_fdata;
mac mac1(
	.axis_clk(axis_clk),
	.reset(mac_reset),
	.mac_EN(mac_EN),
	.A(tap_Do),
	.B(sm_fdata),
	.result(result_Y)
);
assign counter_o = counter;
assign fir_start_address_o = last_addr_w;
address_gen address_gen1(
	.axis_clk(axis_clk),
	.axis_rst_n(axis_rst_n),
	.state_o(status_address_gen_o),
	.state_data_ram(state_data_ram),
	.last_state(last_state),
	.fir_start(fir_start),
	
	
	
	.sm_fready(sm_fready),
	.sm_fvalid(sm_fvalid),
	
    .mac_reset(mac_reset),
	.result_ready(result_ready),
	.mac_EN(mac_EN),
	.i_o(i_o),
	.counter(counter),
	.fir_start_address(fir_start_address_o),
	
	.tap_addr_r(tap_addr_r),
	.fir_addr_r(fir_addr_r) 
);

end
endmodule 
