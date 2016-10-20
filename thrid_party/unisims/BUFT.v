module BUFT (
	input I,
	output O,
	input T
);
	assign O =  ~T ? I: 1'bz;

endmodule
