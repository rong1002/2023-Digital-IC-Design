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
wire [7:0] tmp1_5;
wire [7:0] tmp1_6;
wire [7:0] tmp1_7;
wire [7:0] tmp1_8;
wire [7:0] tmp5;
wire [7:0] tmp6;
wire [7:0] tmp7;
wire [7:0] tmp8;
wire [7:0] out1;
wire [7:0] out2;
wire [7:0] out3;
wire [7:0] out4;


BITONIC_DS BITONIC_DS0(.number_in1(number_in1), .number_in2(number_in5), .number_out1(tmp1), .number_out2(tmp5));
BITONIC_DS BITONIC_DS1(.number_in1(number_in2), .number_in2(number_in6), .number_out1(tmp2), .number_out2(tmp6));
BITONIC_DS BITONIC_DS2(.number_in1(number_in3), .number_in2(number_in7), .number_out1(tmp3), .number_out2(tmp7));
BITONIC_DS BITONIC_DS3(.number_in1(number_in4), .number_in2(number_in8), .number_out1(tmp4), .number_out2(tmp8));

BITONIC_DS BITONIC_DS4(.number_in1(tmp1), .number_in2(tmp3), .number_out1(tmp1_1), .number_out2(tmp1_3));
BITONIC_DS BITONIC_DS5(.number_in1(tmp2), .number_in2(tmp4), .number_out1(tmp1_2), .number_out2(tmp1_4));

BITONIC_DS BITONIC_DS6(.number_in1(tmp5), .number_in2(tmp7), .number_out1(tmp1_5), .number_out2(tmp1_7));
BITONIC_DS BITONIC_DS7(.number_in1(tmp6), .number_in2(tmp8), .number_out1(tmp1_6), .number_out2(tmp1_8));

BITONIC_DS BITONIC_DS8(.number_in1(tmp1_1), .number_in2(tmp1_2), .number_out1(out1), .number_out2(out2));

BITONIC_DS BITONIC_DS9(.number_in1(tmp1_3), .number_in2(tmp1_4), .number_out1(out3), .number_out2(out4));

BITONIC_DS BITONIC_DSa(.number_in1(tmp1_5), .number_in2(tmp1_6), .number_out1(out5), .number_out2(out6));

BITONIC_DS BITONIC_DSb(.number_in1(tmp1_7), .number_in2(tmp1_8), .number_out1(out7), .number_out2(out8));

always @(*) begin
    if (tmp1_1 < tmp1_2) begin
        number_out1 = tmp1_2;
        number_out2 = tmp1_1;

    end
    else begin
        number_out1 = tmp1_1;
        number_out2 = tmp1_2;

    end
end

always @(*) begin
    if (tmp1_3 < tmp1_4) begin
        number_out3 = tmp1_4;
        number_out4 = tmp1_3;

    end
    else begin
        number_out3 = tmp1_3;
        number_out4 = tmp1_4;

    end
end

always @(*) begin
    if (tmp1_5 < tmp1_6) begin
        number_out6 = tmp1_5;
        number_out5 = tmp1_6;

    end
    else begin
        number_out6 = tmp1_6;
        number_out5 = tmp1_5;

    end
end

always @(*) begin
    if (tmp1_7 < tmp1_8) begin
        number_out8 = tmp1_7;
        number_out7 = tmp1_8;

    end
    else begin
        number_out8 = tmp1_8;
        number_out7 = tmp1_7;

    end
end

endmodule
