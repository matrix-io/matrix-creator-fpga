module OBUFT (
	input T,
	input I,
	output O
);
	assign O = ~T ? I : 1'bz;

endmodule
