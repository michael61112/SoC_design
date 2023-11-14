module hw_fir(

    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o
);
    reg write_en;
   reg wbs_ack_temp;
    // Create a 10-cycle delay for wbs_ack_o
    reg [9:0] ack_delay;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ack_delay <= 10'b0;
        end else if (wbs_cyc_i) begin
            ack_delay <= ack_delay + 1'b1;
        end

        if (ack_delay == 10'hb) begin
                wbs_ack_temp <= 1'b1;
                ack_delay <= 0;
        end
        else begin
                wbs_ack_temp <= 1'b0;
        end
    end

    assign wbs_ack_o = wbs_ack_temp;//(ack_delay == 10'd11) ? 1'b1 : 1'b0;
//    assign wbs_dat_o = 32'hffffffff;


always @(*) begin
        write_en = (wbs_stb_i && wbs_cyc_i && wbs_we_i) ? 1'b1 : 1'b0;
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


reg axilite_w_rst_n;
reg axilite_r_rst_n;
reg axirstream_w_rst_n;
reg axirstream_r_rst_n;

reg [3:0] state_rst;
always @(*) begin
	if (wbs_adr_i[31:24] == 'h30) begin //FIR
		if (wbs_adr_i[7:0] == 'h80) begin //stream  no range
		  if (wbs_we_i) begin
		    axilite_w_rst_n = 1'b0;
		    axilite_r_rst_n = 1'b0;
		    axirstream_w_rst_n = 1'b1;
		    axirstream_r_rst_n = 1'b0;
		    state_rst = 1;
		  end
		  else begin
		    axilite_w_rst_n = 1'b0;
		    axilite_r_rst_n = 1'b0;
		    axirstream_w_rst_n = 1'b0;
		    axirstream_r_rst_n = 1'b1;
		    state_rst = 2;
		  end
		end
		else begin // lite
		  if (wbs_we_i) begin
		    axilite_w_rst_n = 1'b1;
		    axilite_r_rst_n = 1'b0;
		    axirstream_w_rst_n = 1'b0;
		    axirstream_r_rst_n = 1'b0;
		    state_rst = 3;
		  end
		  else begin
		    axilite_w_rst_n = 1'b0;
		    axilite_r_rst_n = 1'b1;
		    axirstream_w_rst_n = 1'b0;
		    axirstream_r_rst_n = 1'b0;
		    state_rst = 4;
		  end
		end
	end
	else begin
		    axilite_w_rst_n = 1'b0;
		    axilite_r_rst_n = 1'b0;
		    axirstream_w_rst_n = 1'b0;
		    axirstream_r_rst_n = 1'b0;
		    state_rst = 0;
	end
end


wire [31:0] axilite_data_o;
wire [31:0] axistream_data_o;
assign wbs_dat_o = (wbs_adr_i[11:0] == 12'h084) ? axistream_data_o : axilite_data_o;


wire [11:0] awaddr;
wire [31:0] wdata;

wire [11:0] araddr;
wire [31:0] rdata;

wire [31:0] ss_data;
wire [31:0] sm_data;

axilite_write axilite_write
(
	.axis_clk(wb_clk_i),
	.axilite_w_rst_n(axilite_w_rst_n),
	//state_o,
	.awready(awready),
	.wready(wready),
    	.addr(wbs_adr_i[11:0]),   // input address
    	.data(wbs_dat_i),   // input data

	.awvalid(awvalid),
	.wvalid(wvalid),
	.awaddr(awaddr),
	.wdata(wdata)
);

axilite_read axilite_read
(
	.axis_clk(wb_clk_i),
	.axilite_r_rst_n(axilite_r_rst_n),
	//state_o,
	.arready(arready),
	.rvalid(rvalid),
    	.addr(wbs_adr_i[11:0]),
    	.rdata(rdata),   

	.arvalid(arvalid),
	.rready(rready),
	.araddr(araddr),
	.data(axilite_data_o)
);

axistream_write axistream_write
(
	.axis_clk(wb_clk_i),
	.axirstream_w_rst_n(axirstream_w_rst_n),
	//state_o,
	.ss_tready(ss_tready),
    	.data(wbs_dat_i),
	.ss_tvalid(ss_tvalid),
	.ss_data(ss_data)
);

axistream_read axistream_read
(
	.axis_clk(wb_clk_i),
	.axirstream_r_rst_n(axirstream_r_rst_n),
	//state_o,
	.sm_tvalid(sm_tvalid),
	.sm_data(sm_data),
	.sm_tready(sm_tready),
	.data(axistream_data_o)
);
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


fir fir(

	.axis_clk(wb_clk_i),
	.axis_rst_n(~wb_rst_i),
	//.state_w,
	//.state_r,
	//.state_data_ram,
	//.last_state_o,
	//.status_address_gen_o,
	//.out_adress,
	//.out_data,
	//.addr_r_o,
	//.addr_w_o,
	//.tb_A_o,
	//.fir_start_address_o,
	//.fir_start_o,
	//.mac_reset_o,
	//.result_ready_o,
	//.i_o,
	//.A_o,
	//.B_o,
	//.result_Y_o,
	//.sm_fdata_o,

	//.mac_EN_o,
	//.ap_start_o,
	//.ap_done_o,
	//.ap_idle_o,
	//.counter_o,

        // Write Address Channel
	.awaddr(awaddr),
	.awvalid(awvalid),
	.awready(awready),

        // Write Data Channel
	.wdata(wdata),
	.wvalid(wvalid),
	.wready(wready),

	// Read Address Channel
	.araddr(araddr),
	.arready(arready),
	.arvalid(arvalid),

        // Read Data Channel
	.rdata(rdata),
	.rvalid(rvalid),
	.rready(rready),
        // Stream Slave
	.ss_tdata(ss_tdata),
	.ss_tvalid(ss_tvalid),
	.ss_tready(ss_tready),
	.ss_tlast(ss_tlast),

        // Stream Master
	.sm_tdata(sm_tdata),
	.sm_tvalid(sm_tvalid),
	.sm_tready(sm_tready),
	.sm_tlast(sm_tlast),

    	// bram for tap RAM
	.tap_WE(tap_WE),
	.tap_EN(tap_EN),
	.tap_Di(tap_Di),
	.tap_A(tap_A),
	.tap_Do(tap_Do),

	// bram for data RAM
	.data_WE(data_WE),
	.data_EN(data_EN),
	.data_Di(data_Di),
	.data_A(data_A),
	.data_Do(data_Do)
);

    // RAM for tap
    bram11 tap_RAM (
        .CLK(axis_clk),
        .WE(tap_WE),
        .EN(tap_EN),
        .Di(tap_Di),
        .A(tap_A),
        .Do(tap_Do)
    );

    // RAM for data: choose bram11 or bram12
    bram11 data_RAM(
        .CLK(axis_clk),
        .WE(data_WE),
        .EN(data_EN),
        .Di(data_Di),
        .A(data_A),
        .Do(data_Do)
    );


endmodule
