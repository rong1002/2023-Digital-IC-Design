module BITONIC_DS(number_in1, number_in2, number_out1, number_out2);
input  [7:0] number_in1;
input  [7:0] number_in2;
output [7:0] number_out1;
output [7:0] number_out2;

assign number_out1 = (number_in1 > number_in2)? number_in1 : number_in2;
assign number_out2 = (number_in1 < number_in2)? number_in1 : number_in2;

endmodule