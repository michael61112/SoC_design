module prefetch (
    input clk,
    input rst,
    // Wishbone
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [31:0] wbs_adr_i,
    input wbs_ack_o,
    output [31:0] wbs_dat_o,
    // SD controller
    output ctrl_in_valid,
    input ctrl_out_valid,
    input ctrl_busy,
    output [22:0] ctrl_addr,
    input [31:0] sd_data_out
);
  wire valid;

  reg ctrl_in_valid_q;
  wire [31:0] sd_data_out;

  assign valid = wbs_stb_i && wbs_cyc_i;
  assign ctrl_in_valid = wbs_we_i ? valid : ~ctrl_in_valid_q && valid;
  assign wbs_ack_o = (wbs_we_i) ? ~ctrl_busy && valid : ctrl_out_valid;
  assign ctrl_addr = wbs_adr_i[22:0];

  assign wbs_dat_o = sd_data_out;

  always @(posedge clk) begin
    if (rst) begin
      ctrl_in_valid_q <= 1'b0;
    end else begin
      if (~wbs_we_i && valid && ~ctrl_busy && ctrl_in_valid_q == 1'b0)
        ctrl_in_valid_q <= 1'b1;
      else if (ctrl_out_valid)
        ctrl_in_valid_q <= 1'b0;
    end
  end

endmodule
