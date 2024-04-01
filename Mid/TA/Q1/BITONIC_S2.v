module BITONIC_S2(  number_in1, number_in2, number_in3, number_in4,
                    number_in5, number_in6, number_in7, number_in8,
                    number_out1, number_out2, number_out3, number_out4,
                    number_out5, number_out6, number_out7, number_out8);

input  [7:0] number_in1;
input  [7:0] number_in2;
input  [7:0] number_in3;
input  [7:0] number_in4;
input  [7:0] number_in5;
input  [7:0] number_in6;
input  [7:0] number_in7;
input  [7:0] number_in8;

output  [7:0] number_out1;
output  [7:0] number_out2;
output  [7:0] number_out3;
output  [7:0] number_out4;
output  [7:0] number_out5;
output  [7:0] number_out6;
output  [7:0] number_out7;
output  [7:0] number_out8;

wire [7:0] number_tmp1;
wire [7:0] number_tmp2;
wire [7:0] number_tmp3;
wire [7:0] number_tmp4;
wire [7:0] number_tmp5;
wire [7:0] number_tmp6;
wire [7:0] number_tmp7;
wire [7:0] number_tmp8;

BITONIC_AS u_AS1_1(.number_in1(number_in1), .number_in2(number_in3), .number_out1(number_tmp1), .number_out2(number_tmp3));
BITONIC_AS u_AS1_2(.number_in1(number_in2), .number_in2(number_in4), .number_out1(number_tmp2), .number_out2(number_tmp4));
BITONIC_DS u_DS1_1(.number_in1(number_in5), .number_in2(number_in7), .number_out1(number_tmp5), .number_out2(number_tmp7));
BITONIC_DS u_DS1_2(.number_in1(number_in6), .number_in2(number_in8), .number_out1(number_tmp6), .number_out2(number_tmp8));

BITONIC_AS u_AS2_1(.number_in1(number_tmp1), .number_in2(number_tmp2), .number_out1(number_out1), .number_out2(number_out2));
BITONIC_AS u_AS2_2(.number_in1(number_tmp3), .number_in2(number_tmp4), .number_out1(number_out3), .number_out2(number_out4));
BITONIC_DS u_DS2_1(.number_in1(number_tmp5), .number_in2(number_tmp6), .number_out1(number_out5), .number_out2(number_out6));
BITONIC_DS u_DS2_2(.number_in1(number_tmp7), .number_in2(number_tmp8), .number_out1(number_out7), .number_out2(number_out8));

endmodule