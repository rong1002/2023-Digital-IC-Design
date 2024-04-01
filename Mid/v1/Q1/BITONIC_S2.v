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

output reg [7:0] number_out1;
output reg [7:0] number_out2;
output reg [7:0] number_out3;
output reg [7:0] number_out4;
output reg [7:0] number_out5;
output reg [7:0] number_out6;
output reg [7:0] number_out7;
output reg [7:0] number_out8;

/*
    Write your design here!
*/
wire [7:0] tmp1;
wire [7:0] tmp2;
wire [7:0] tmp3;
wire [7:0] tmp4;
wire [7:0] tmp1_1;
wire [7:0] tmp1_2;
wire [7:0] tmp1_3;
wire [7:0] tmp1_4;
wire [7:0] tmp5;
wire [7:0] tmp6;
wire [7:0] tmp7;
wire [7:0] tmp8;
wire [7:0] tmp2_1;
wire [7:0] tmp2_2;
wire [7:0] tmp2_3;
wire [7:0] tmp2_4;

BITONIC_DS BITONIC_DS0(.number_in1(number_in1), .number_in2(number_in3), .number_out1(tmp1), .number_out2(tmp3));
BITONIC_DS BITONIC_DS1(.number_in1(number_in2), .number_in2(number_in4), .number_out1(tmp2), .number_out2(tmp4));
BITONIC_DS BITONIC_DS2(.number_in1(tmp1), .number_in2(tmp2), .number_out1(tmp1_1), .number_out2(tmp1_2));
BITONIC_DS BITONIC_DS3(.number_in1(tmp3), .number_in2(tmp4), .number_out1(tmp1_3), .number_out2(tmp1_4));

BITONIC_AS BITONIC_AS0(.number_in1(number_in5), .number_in2(number_in7), .number_out1(tmp5), .number_out2(tmp7));
BITONIC_AS BITONIC_AS1(.number_in1(number_in6), .number_in2(number_in8), .number_out1(tmp6), .number_out2(tmp8));
BITONIC_AS BITONIC_AS2(.number_in1(tmp5), .number_in2(tmp6), .number_out1(tmp2_1), .number_out2(tmp2_2));
BITONIC_AS BITONIC_AS3(.number_in1(tmp7), .number_in2(tmp8), .number_out1(tmp2_3), .number_out2(tmp2_4));


always @(*) begin
    if (tmp1 < tmp2) begin
        number_out1 = tmp2;
        number_out2 = tmp1;

    end
    else begin
        number_out1 = tmp1;
        number_out2 = tmp2;

    end
end
always @(*) begin
    if (tmp3 < tmp4) begin
        number_out3 = tmp4;
        number_out4 = tmp3;
    end
    else begin
        number_out3 = tmp3;
        number_out4 = tmp4;
    end
end
always @(*) begin
    if (tmp5 > tmp6) begin
        number_out5 = tmp6;
        number_out6 = tmp5;
    end
    else begin
        number_out5 = tmp5;
        number_out6 = tmp6;
    end
end



always @(*) begin
    if (tmp7 > tmp8) begin
        number_out7 = tmp8;
        number_out8 = tmp7;
    end
    else begin
        number_out7 = tmp7;
        number_out8 = tmp8;
    end
end




endmodule