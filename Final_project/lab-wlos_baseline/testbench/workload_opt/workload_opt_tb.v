// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype wire

`timescale 1 ns / 1 ps

module workload_opt_tb;
	reg clock;
    reg RSTB;
	reg CSB;

	reg power1, power2;

	wire gpio;
	wire [37:0] mprj_io;
	wire [15:0] checkbits;
	wire uart_tx;
	wire uart_rx;
	reg tx_start;
	reg [7:0] tx_data;
	wire tx_busy;
	wire tx_clear_req;
	integer delay;
	reg isr_complete;

	assign checkbits  = mprj_io[31:16];
	assign uart_tx = mprj_io[6];
	assign mprj_io[5] = uart_rx;

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	`ifdef ENABLE_SDF
		initial begin
			$sdf_annotate("../../../sdf/user_proj_example.sdf", uut.mprj) ;
			$sdf_annotate("../../../sdf/user_project_wrapper.sdf", uut.mprj.mprj) ;
			$sdf_annotate("../../../mgmt_core_wrapper/sdf/DFFRAM.sdf", uut.soc.DFFRAM_0) ;
			$sdf_annotate("../../../mgmt_core_wrapper/sdf/mgmt_core.sdf", uut.soc.core) ;
			$sdf_annotate("../../../caravel/sdf/housekeeping.sdf", uut.housekeeping) ;
			$sdf_annotate("../../../caravel/sdf/chip_io.sdf", uut.padframe) ;
			$sdf_annotate("../../../caravel/sdf/mprj_logic_high.sdf", uut.mgmt_buffers.mprj_logic_high_inst) ;
			$sdf_annotate("../../../caravel/sdf/mprj2_logic_high.sdf", uut.mgmt_buffers.mprj2_logic_high_inst) ;
			$sdf_annotate("../../../caravel/sdf/mgmt_protect_hv.sdf", uut.mgmt_buffers.powergood_check) ;
			$sdf_annotate("../../../caravel/sdf/mgmt_protect.sdf", uut.mgmt_buffers) ;
			$sdf_annotate("../../../caravel/sdf/caravel_clocking.sdf", uut.clocking) ;
			$sdf_annotate("../../../caravel/sdf/digital_pll.sdf", uut.pll) ;
			$sdf_annotate("../../../caravel/sdf/xres_buf.sdf", uut.rstb_level) ;
			$sdf_annotate("../../../caravel/sdf/user_id_programming.sdf", uut.user_id_value) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_bidir_1[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_bidir_1[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_bidir_2[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_bidir_2[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_bidir_2[2] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[2] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[3] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[4] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[5] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[6] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[7] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[8] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[9] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1[10] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1a[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1a[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1a[2] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1a[3] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1a[4] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_1a[5] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[2] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[3] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[4] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[5] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[6] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[7] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[8] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[9] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[10] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[11] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[12] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[13] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[14] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_control_block.sdf", uut.\gpio_control_in_2[15] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.\gpio_defaults_block_0[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.\gpio_defaults_block_0[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.\gpio_defaults_block_2[0] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.\gpio_defaults_block_2[1] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.\gpio_defaults_block_2[2] ) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_5) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_6) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_7) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_8) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_9) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_10) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_11) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_12) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_13) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_14) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_15) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_16) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_17) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_18) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_19) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_20) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_21) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_22) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_23) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_24) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_25) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_26) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_27) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_28) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_29) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_30) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_31) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_32) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_33) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_34) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_35) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_36) ;
			$sdf_annotate("../../../caravel/sdf/gpio_defaults_block.sdf", uut.gpio_defaults_block_37) ;
		end
	`endif 

	initial begin
		$dumpfile("workload_opt.vcd");
		$dumpvars(0, workload_opt_tb);

		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (200) begin
			repeat (3000) @(posedge clock);
			// $display("+1000 cycles");
		end
		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, Test LA (GL) Failed");
		`else
			$display ("Monitor: Timeout, Test LA (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	reg [31:0] start_time_fir, start_time_mm, start_time_qs;
	reg [31:0] end_time_fir, end_time_mm, end_time_qs;
	reg [31:0] wait_time_fir, wait_time_mm, wait_time_qs;
	reg [31:0] counter_fir, counter_mm, counter_qs, counter;
	reg counter_en_fir, counter_en_mm, counter_en_qs, counter_en;

	initial begin
		counter_en_fir = 0;
		counter_en_mm = 0;
		counter_en_qs = 0;
		counter_fir = 0;
		counter_mm = 0;
		counter_qs = 0;
		wait(checkbits == 16'hAB40);
		counter_en_fir = 1'b1;
		start_time_fir = $time;
		fork
			begin
				// FIR Test
				$display("\033[0;33mFIR Test started\033[0;37m");

				wait(checkbits == 16'h0); // 0
				$display("Call function fir() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'hfff6); // -10
				$display("Call function fir() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'hffe3); // -29
				$display("Call function fir() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'hffe7); // -25
				$display("Call function fir() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'h23); // 35
				$display("Call function fir() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'h9e); // 158
				$display("Call function fir() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'h151); // 337
				$display("Call function fir() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'h21b); // 539
				$display("Call function fir() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'h2dc); // 732
				$display("Call function fir() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'h393); // 915
				$display("Call function fir() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'h44a); // 1098
				$display("Call function fir() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);

				wait(checkbits == 16'hAB41);
				counter_en_fir = 1'b0;
				end_time_fir = $time;
				$display("\033[0;33mFIR Test passed\033[0;37m");

				// Matmul Test
				wait(checkbits == 16'hAB50);
				counter_en_mm = 1'b1;
				start_time_mm = $time;
				$display("\033[0;36mMatmul Test started\033[0;37m");

				wait(checkbits == 16'h003E);
				$display("\033[0;36mCall function matmul() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x\033[0;37m", checkbits);
				wait(checkbits == 16'h0044);
				$display("\033[0;36mCall function matmul() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x\033[0;37m", checkbits);
				wait(checkbits == 16'h004A);
				$display("\033[0;36mCall function matmul() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x\033[0;37m", checkbits);
				wait(checkbits == 16'h0050);
				$display("\033[0;36mCall function matmul() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x\033[0;37m", checkbits);

				wait(checkbits == 16'hAB51);
				counter_en_mm = 1'b0;
				end_time_mm = $time;
				$display("\033[0;36mMatmul Test passed");

				// Quick Sort Test
				wait(checkbits == 16'hAB60);
				counter_en_qs = 1'b1;
				start_time_qs = $time;
				$display("\033[0;35mQuick Sort Test started\033[0;37m");

				wait(checkbits == 16'd40);
				$display("Call function qsort() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'd893);
				$display("Call function qsort() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'd2541);
				$display("Call function qsort() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);
				wait(checkbits == 16'd2669);
				$display("Call function qsort() in User Project BRAM (mprjram, 0x38000000) return value passed, 0x%x", checkbits);

				wait(checkbits == 16'hAB61);
				counter_en_qs = 1'b0;
				end_time_qs = $time;
				$display("\033[0;35mQuick Sort Test passed\033[0;37m");

				wait_time_fir = end_time_fir - start_time_fir;
				wait_time_mm = end_time_mm - start_time_mm;
				wait_time_qs = end_time_qs - start_time_qs;

				$display("[FIR]Wait time: %0d time units", wait_time_fir);
				$display("[FIR]Wait #clk: %0d units", counter_fir);
				$display("[MM]Wait time: %0d time units", wait_time_mm);
				$display("[MM]Wait #clk: %0d units", counter_mm);
				$display("[QS]Wait time: %0d time units", wait_time_qs);
				$display("[QS]Wait #clk: %0d units", counter_qs);
				#10000;
				$finish;

/*
				if (isr_complete === 1) begin
					#1000;
					$finish();
				end
*/
			end
			begin
				isr_complete = 0;
				delay = $random % 1000000;
				// delay = 1000000;
				#delay;
				$display("UART Test started");
				send_data_2;
				wait(checkbits == 16'hAB31);
				$display("ISR completed");
				isr_complete = 1;
			end
		join		
	end

	always@(posedge clock) begin
		if(counter_en_fir) begin
			counter_fir <= counter_fir + 1;
		end
		else begin
			counter_fir <= counter_fir;
		end
		if(counter_en_mm) begin
			counter_mm <= counter_mm + 1;
		end
		else begin
			counter_mm <= counter_mm;
		end
		if(counter_en_qs) begin
			counter_qs <= counter_qs + 1;
		end
		else begin
			counter_qs <= counter_qs;
		end
	end

	task send_data_1;begin
		@(posedge clock);
		tx_start = 1;
		tx_data = 15;
		
		#50;
		wait(!tx_busy);
		tx_start = 0;
		$display("tx complete 1");
                if(counter_en) begin
                        counter <= counter + 1;
                end
                else begin
                        counter <= counter;
                end
		
	end endtask

	task send_data_2;begin
		@(posedge clock);
		tx_start = 1;
		tx_data = 61;
		
		#50;
		wait(!tx_busy);
		tx_start = 0;
		$display("tx complete 2");
		
	end endtask

	initial begin
		RSTB <= 1'b0;
		CSB  <= 1'b1;		// Force CSB high
		#2000;
		RSTB <= 1'b1;	    	// Release reset
		#170000;
		CSB = 1'b0;		// CSB can be released		
	end 

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		#200;
		power1 <= 1'b1;
		#200;
		power2 <= 1'b1;
	end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD1V8;
	wire VDD3V3;
	wire VSS;

	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	assign mprj_io[3] = 1;  // Force CSB high.
	assign mprj_io[0] = 0;  // Disable debug mode

	caravel uut (
/*
		.vddio	  (VDD3V3),
		.vddio_2  (VDD3V3),
		.vssio	  (VSS),
		.vssio_2  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (VDD3V3),
		.vdda1_2  (VDD3V3),
		.vdda2    (VDD3V3),
		.vssa1	  (VSS),
		.vssa1_2  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (VDD1V8),
		.vccd2	  (VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
*/
		.clock    (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("uart.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

	// Testbench UART
	tbuart tbuart (
		.ser_rx(uart_tx),
		.tx_start(tx_start),
		.ser_tx(uart_rx),
		.tx_data(tx_data),
		.tx_busy(tx_busy),
		.tx_clear_req(tx_clear_req)
	);

endmodule
`default_nettype wire


