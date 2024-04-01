module MMS_8num(result, select, number0, number1, number2, number3, number4, number5, number6, number7);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
input  [7:0] number4;
input  [7:0] number5;
input  [7:0] number6;
input  [7:0] number7;
output [7:0] result; 
reg    [7:0] result;
wire   [7:0] result1, result2;
reg    [7:0] max, min;
/*
	Write Your Design Here ~
*/

MMS_4num MMS1(.result(result1), .select(select), .number0(number0), .number1(number1), .number2(number2), .number3(number3));
MMS_4num MMS2(.result(result2), .select(select), .number0(number4), .number1(number5), .number2(number6), .number3(number7));

always @(*) begin
    if (result2 < result1) begin
		min = result2;
	end

	else begin
		min = result1;
	end
end

always @(*) begin
    if (result2 > result1) begin
		max = result2;
	end

	else begin
		max = result1;
	end
end


always @(*) begin
	if (select == 1) begin
		result = min;
	end
	else begin
		result = max;
	end
end
endmodule