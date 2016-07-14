module IOBUF (
	input T,
	input I,
	output O,
	inout IO
);
	assign IO = ~T ? I : 1'bz;
	assign O =  T ? IO : 1'bz;

endmodule
