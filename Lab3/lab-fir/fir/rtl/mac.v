module mac 
(
	input 			axis_clk,
	input			reset,
	input [31:0]	A,
	input [31:0]	B,
	output [31:0]  result
);
begin

	reg [31:0] accumulator;

	always @(posedge axis_clk or posedge reset) begin
		if (reset) begin
			accumulator <= 32'b0;
		end else begin
			
			accumulator <= accumulator + (A * B);
		end
	end

	assign result = accumulator;
end
endmodule


