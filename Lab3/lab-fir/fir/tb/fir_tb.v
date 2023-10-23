`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/20/2023 10:38:55 AM
// Design Name: 
// Module Name: fir_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fir_tb
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11,
    parameter Data_Num    = 600
)();
	// Global Signals    
    reg                         axis_clk;
    reg                         axis_rst_n;
    wire  [1:0]					state_w;
	wire  [1:0]					state_r;
	wire  [1:0]					state_data_ram;
	wire  [1:0] 			 last_state_o;
	wire [(pADDR_WIDTH-1):0]       addr_r_o;
	wire [(pADDR_WIDTH-1):0]       addr_w_o;
	wire [(pADDR_WIDTH-1):0]       tb_A_o;
	
	wire  [(pADDR_WIDTH-1):0]   out_adress;
	wire  [(pDATA_WIDTH-1):0]   out_data;
	wire  [(pDATA_WIDTH-1):0]   rdata_in_debug;
    // Write Address Channel
    reg   [(pADDR_WIDTH-1): 0]  awaddr;
	reg                         awvalid;
	wire                        awready;
	
	
	// Write Data Channel
	reg                         wvalid;
	wire                        wready;
	reg signed [(pDATA_WIDTH-1) : 0] wdata;
	
    
	
	// Read Address Channel
    reg         [(pADDR_WIDTH-1): 0] araddr;
	reg                         arvalid;
    wire                        arready;
	
	
	// Read Data Channel
	wire                        rvalid; 
	reg                         rready;
	wire signed [(pDATA_WIDTH-1): 0] rdata;
        
	// Stream Slave
    reg signed [(pDATA_WIDTH-1) : 0] ss_tdata;
    wire                        ss_tready;
	reg                         ss_tvalid;
	reg                         ss_tlast;
	
	// Stream Master
	wire signed [(pDATA_WIDTH-1) : 0] sm_tdata;
    reg                         sm_tready;
    wire                        sm_tvalid;
    wire                        sm_tlast;

// ram for tap
    wire [3:0]               tap_WE;
    wire                     tap_EN;
    wire [(pDATA_WIDTH-1):0] tap_Di;
    wire [(pADDR_WIDTH-1):0] tap_A;
    wire [(pDATA_WIDTH-1):0] tap_Do;

// ram for data RAM
    wire [3:0]               data_WE;
    wire                     data_EN;
    wire [(pDATA_WIDTH-1):0] data_Di;
    wire [(pADDR_WIDTH-1):0] data_A;
    wire [(pDATA_WIDTH-1):0] data_Do;



    fir fir_DUT(
	
		.state_w(state_w),
		.state_r(state_r),
		.state_data_ram(state_data_ram),
		.last_state_o(last_state_o),
		.out_adress(out_adress),
		.out_data(out_data),
		.addr_r_o(addr_r_o),
		.addr_w_o(addr_w_o),
		.tb_A_o(tb_A_o),
		
		
        .awready(awready),
        .wready(wready),
        .awvalid(awvalid),
        .awaddr(awaddr),
        .wvalid(wvalid),
        .wdata(wdata),
        .arready(arready),
        .rready(rready),
        .arvalid(arvalid),
        .araddr(araddr),
        .rvalid(rvalid),
        .rdata(rdata),
        .ss_tvalid(ss_tvalid),
        .ss_tdata(ss_tdata),
        .ss_tlast(ss_tlast),
        .ss_tready(ss_tready),
        .sm_tready(sm_tready),
        .sm_tvalid(sm_tvalid),
        .sm_tdata(sm_tdata),
        .sm_tlast(sm_tlast),

        // ram for tap
        .tap_WE(tap_WE),
        .tap_EN(tap_EN),
        .tap_Di(tap_Di),
        .tap_A(tap_A),
        .tap_Do(tap_Do),

        // ram for data
        .data_WE(data_WE),
        .data_EN(data_EN),
        .data_Di(data_Di),
        .data_A(data_A),
        .data_Do(data_Do),
		
        .axis_clk(axis_clk),
        .axis_rst_n(axis_rst_n)
		
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

    reg signed [(pDATA_WIDTH-1):0] Din_list[0:(Data_Num-1)];
    reg signed [(pDATA_WIDTH-1):0] golden_list[0:(Data_Num-1)];

    initial begin
        $dumpfile("fir.vcd");
        $dumpvars();
    end

// Initial Clock
    initial begin
        axis_clk = 0;
        forever begin
            #5 axis_clk = (~axis_clk);
        end
    end




// Read Data in and Golden (Din_listï¿½î?Ÿolden_listï¿½î?œata_length)
    reg [31:0]  data_length;
    integer Din, golden, input_data, golden_data, m, i;
    initial begin
        data_length = 0;
        Din = $fopen("./samples_triangular_wave.dat","r");
        golden = $fopen("./out_gold.dat","r");
        for(m=0;m<Data_Num;m=m+1) begin
            input_data = $fscanf(Din,"%d", Din_list[m]);
            golden_data = $fscanf(golden,"%d", golden_list[m]);
            data_length = data_length + 1;
        end
    end

//  -------------------------------------------------------------------------------------------

//  Step 1: Check FIR is idle, if not, wait until FIR is idle
//  TB push Din_list to FIR by stream


    // Prevent hang
    integer timeout = (3000000); //1000000
    initial begin
        while(timeout > 0) begin
            @(posedge axis_clk);
            timeout = timeout - 1;
        end
        $display($time, "Simualtion Hang ....");
        $finish;
    end


    reg signed [31:0] coef[0:10]; // fill in coef 
    initial begin
        coef[0]  =  32'd0;
        coef[1]  = -32'd10;
        coef[2]  = -32'd9;
        coef[3]  =  32'd23;
        coef[4]  =  32'd56;
        coef[5]  =  32'd63;
        coef[6]  =  32'd56;
        coef[7]  =  32'd23;
        coef[8]  = -32'd9;
        coef[9]  = -32'd10;
        coef[10] =  32'd0;
    end

//  Step2: Program length, and tap parameters
//  Step3: Program ap_start -> 1
//  Write coefficient from TB to FIR by AXI-lite
//  Including: data_lengthï¿½î?›oef[] and ap_start
    reg error_coef;
    initial begin
        error_coef = 0;
		
		axis_rst_n = 1;
		@(posedge axis_clk); 
		axis_rst_n = 0;
        @(posedge axis_clk); @(posedge axis_clk);
        axis_rst_n = 1;
		
		$display("------------Start simulation-----------");
		while(error_coef) begin
			config_read_check(12'h00, 32'h00, 32'h0000_000f); // check idle = 0
		end
        $display("----Start the data_length¡Bcoefficient input(AXI-lite)----");
        config_write(12'h10, data_length);
		
        for(k=0; k< Tape_Num; k=k+1) begin
            config_write(12'h40+4*k, coef[k]);
        end

		$display(" Check Data Length ...");
		config_read_check(12'h10, data_length, 32'hffffffff);
		
        $display(" Check Coefficient ...");
        for(k=0; k < Tape_Num; k=k+1) begin
            config_read_check(12'h40+4*k, coef[k], 32'hffffffff);
        end
        $display("----End the coefficient input(AXI-lite)----");

		ss_tvalid = 0;
		ss_tlast = 0; 
		sm_tready = 0;
		$display("----Start initial Data BRAM default value(AXI-Stream)----");
        for(i=0;i< 11;i=i+1) begin //(data_length-1)
			ss(32'b0);
        end
		
        $display(" Start FIR");
        @(posedge axis_clk) config_write(12'h00, 32'h0000_0001);    // ap_start = 1
		
		///////////////////////////////////////////////////////////////////////////////////////////
/*
		
		for(i=0;i< 11;i=i+1) begin //(data_length-1)
			sm(32'b0, i);
        end

		axis_rst_n = 1;
		@(posedge axis_clk); 
		axis_rst_n = 0;
        @(posedge axis_clk); @(posedge axis_clk);
        axis_rst_n = 1;
*/		
		
		$display("----Start the data input(AXI-Stream)----");
        for(i=0;i< (data_length-1);i=i+1) begin //(data_length-1)
			ss(Din_list[i]);
			
			sm(golden_list[i],i);
        end
		/*
        ss_tlast = 1;
		ss(Din_list[(Data_Num-1)]);
		ss_tvalid = 0;
        $display("------End the data input(AXI-Stream)------");
        */
		/*
		for(i=0;i< 11;i=i+1) begin //(data_length-1)
			sm(i+1, i);
			//$display("read[%d]: %d", i, Din_list[i]);
        end
		*/
    end

// Step5: When ap_done is sampled, compare Yn with golden data
//  TB Receive golden_list from FIR by stream
    integer k;
    reg error;
    reg status_error;
/*    initial begin
        error = 0; status_error = 0;
        sm_tready = 1;
        wait (sm_tvalid);
        for(k=0;k < data_length;k=k+1) begin
            sm(golden_list[k],k);
        end
        config_read_check(12'h00, 32'h02, 32'h0000_0002); // check ap_done = 1 (0x00 [bit 1])
        config_read_check(12'h00, 32'h04, 32'h0000_0004); // check ap_idle = 1 (0x00 [bit 2])
        if (error == 0 & error_coef == 0) begin
            $display("---------------------------------------------");
            $display("-----------Congratulations! Pass-------------");
        end
        else begin
            $display("--------Simulation Failed---------");
        end
        $finish;
    end
*/
//  -------------------------------------------------------------------------------------------

//  Write config register by AXI-lite
    task config_write;
        input [11:0]    addr;
        input [31:0]    data;
        begin
            awvalid <= 0; wvalid <= 0;   //Non-blocking assignment //the updated values are only available on the next clock cycle
            @(posedge axis_clk);
            awvalid <= 1; awaddr <= addr;
			while (!awready) @(posedge axis_clk);
			awvalid <= 0;
			@(posedge axis_clk);
			@(posedge axis_clk);
            while (!wready) @(posedge axis_clk);  // Leave the loop when write ready 
			wvalid  <= 1; wdata <= data;
			@(posedge axis_clk);
			wvalid <= 0;
        end
    endtask

//  Read config register by AXI-lite
//  If not match the exp_data, set the error_coef to high

	reg signed [(pDATA_WIDTH-1): 0] rdata_in = 32'b0;
	always@(*) begin
		rdata_in = (rvalid & rready) ? rdata : rdata_in;
	end
    task config_read_check;
        input [11:0]        addr;
        input signed [31:0] exp_data;
        input [31:0]        mask;
        begin
            arvalid <= 0; rready <= 0;
            @(posedge axis_clk);
            arvalid <= 1; araddr <= addr;
			while (!arready) @(posedge axis_clk);
            arvalid <= 0;
            @(posedge axis_clk);
            @(posedge axis_clk);
			rready <= 1;
            while (!rvalid) @(posedge axis_clk);
			rdata_in <= rdata;
			rready <= 0;
			
            if( (rdata_in & mask) != (exp_data & mask)) begin
                $display("ERROR: exp = %d, rdata_in = %d", exp_data, rdata_in);
                error_coef <= 1;
            end else begin
                $display("OK: exp = %d, rdata_in = %d", exp_data, rdata_in);
            end
        end
    endtask


assign rdata_in_debug = rdata_in;
//  Send 32'b in1 value to slave by stream
//  Leave while loop when ss_tready is high
    task ss;
        input  signed [31:0] in1;
        begin
            ss_tvalid <= 1;
            ss_tdata  <= in1;
            @(posedge axis_clk);  //? if no clk, the for loop will finish immediately
            while (!ss_tready) @(posedge axis_clk);
			ss_tvalid <= 0;
        end
    endtask

//  Receive 32'b FIR data from slave by stream
//  If the result does not match golden, set error high

    task sm;
        input  signed [31:0] in2; // golden data
        input         [31:0] pcnt; // pattern count
        begin
			
            sm_tready <= 1;
			@(posedge axis_clk);  //? if no clk, the for loop will finish immediately
            while(!sm_tvalid) @(posedge axis_clk);
			sm_tready <= 0;
			
            if (sm_tdata != in2) begin
                $display("[ERROR] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
                error <= 1;
            end
            else begin
                $display("[PASS] [Pattern %d] Golden answer: %d, Your answer: %d", pcnt, in2, sm_tdata);
            end
        end
    endtask
endmodule

