module MMS_4num(result, select, number0, number1, number2, number3);

input        select;
input  [7:0] number0;
input  [7:0] number1;
input  [7:0] number2;
input  [7:0] number3;
output [7:0] result; 

/*
	Write Your Design Here ~
*/
reg [7:0] result, temp1, temp2;
wire mux1 = number0 < number1;
wire mux2 = number2 < number3;
wire temp = temp1 < temp2;

always @(*) begin
    case({select, mux1})
        2'b00: temp1 = number0;
        2'b01: temp1 = number1;
        2'b10: temp1 = number1;
        2'b11: temp1 = number0;
    endcase
end

always @(*) begin
    case({select, mux2})
        2'b00: temp2 = number2;
        2'b01: temp2 = number3;
        2'b10: temp2 = number3;
        2'b11: temp2 = number2;
    endcase
end

always @(*) begin
    case({select, temp})
        2'b00: result = temp1;
        2'b01: result = temp2;
        2'b10: result = temp2;
        2'b11: result = temp1;
    endcase
end


endmodule