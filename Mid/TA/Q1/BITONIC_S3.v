module BITONIC_S3(  number_in1, number_in2, number_in3, number_in4,
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

wire [7:0] number_tmp1_1;
wire [7:0] number_tmp1_2;
wire [7:0] number_tmp1_3;
wire [7:0] number_tmp1_4;
wire [7:0] number_tmp1_5;
wire [7:0] number_tmp1_6;
wire [7:0] number_tmp1_7;
wire [7:0] number_tmp1_8;

wire [7:0] number_tmp2_1;
wire [7:0] number_tmp2_2;
wire [7:0] number_tmp2_3;
wire [7:0] number_tmp2_4;
wire [7:0] number_tmp2_5;
wire [7:0] number_tmp2_6;
wire [7:0] number_tmp2_7;
wire [7:0] number_tmp2_8;

BITONIC_AS u_AS1_1(.number_in1(number_in1), .number_in2(number_in5), .number_out1(number_tmp1_1), .number_out2(number_tmp1_5));
BITONIC_AS u_AS1_2(.number_in1(number_in2), .number_in2(number_in6), .number_out1(number_tmp1_2), .number_out2(number_tmp1_6));
BITONIC_AS u_AS1_3(.number_in1(number_in3), .number_in2(number_in7), .number_out1(number_tmp1_3), .number_out2(number_tmp1_7));
BITONIC_AS u_AS1_4(.number_in1(number_in4), .number_in2(number_in8), .number_out1(number_tmp1_4), .number_out2(number_tmp1_8));

BITONIC_AS u_AS2_1(.number_in1(number_tmp1_1), .number_in2(number_tmp1_3), .number_out1(number_tmp2_1), .number_out2(number_tmp2_3));
BITONIC_AS u_AS2_2(.number_in1(number_tmp1_2), .number_in2(number_tmp1_4), .number_out1(number_tmp2_2), .number_out2(number_tmp2_4));
BITONIC_AS u_AS2_3(.number_in1(number_tmp1_5), .number_in2(number_tmp1_7), .number_out1(number_tmp2_5), .number_out2(number_tmp2_7));
BITONIC_AS u_AS2_4(.number_in1(number_tmp1_6), .number_in2(number_tmp1_8), .number_out1(number_tmp2_6), .number_out2(number_tmp2_8));

BITONIC_AS u_AS3_1(.number_in1(number_tmp2_1), .number_in2(number_tmp2_2), .number_out1(number_out1), .number_out2(number_out2));
BITONIC_AS u_AS3_2(.number_in1(number_tmp2_3), .number_in2(number_tmp2_4), .number_out1(number_out3), .number_out2(number_out4));
BITONIC_AS u_AS3_3(.number_in1(number_tmp2_5), .number_in2(number_tmp2_6), .number_out1(number_out5), .number_out2(number_out6));
BITONIC_AS u_AS3_4(.number_in1(number_tmp2_7), .number_in2(number_tmp2_8), .number_out1(number_out7), .number_out2(number_out8));

endmodule
