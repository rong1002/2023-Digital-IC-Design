module MMS_4num(result, select, number0, number1, number2, number3);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
output [7:0] result; 
reg    [7:0] result;
reg    [7:0] max1 = 8'd0, max2 = 8'd0, min1 = 8'd0, min2 = 8'd0;
reg    [7:0] max = 8'd0, min = 8'd0;
/*
	Write Your Design Here ~
*/

always @(*) begin
    if (number1 > number0) begin
		max1 = number1;
	end

	else begin
		max1 = number0;
	end
end

always @(*) begin
	if (number3 > number2) begin
		max2 = number3;
	end

	else begin
		max2 = number2;
	end
end

always @(*) begin
	if (max2 > max1) begin
		max = max2;
	end

	else begin
		max = max1;
	end
end

always @(*) begin
    if (number1 < number0) begin
		min1 = number1;
	end

	else begin
		min1 = number0;
	end
end

always @(*) begin
	if (number3 < number2) begin
		min2 = number3;
	end

	else begin
		min2 = number2;
	end
end

always @(*) begin
	if (min2 < min1) begin
		min = min2;
	end

	else begin
		min = min1;
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