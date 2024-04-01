module rails(clk, reset, data, valid, result);

input        clk;
input        reset;
input  [3:0] data;
output       valid;
output       result; 
reg          valid;
reg          result;

reg    [9:0] station;
reg    [9:0] stack;
reg    [9:0] max;

reg    [9:0] data_temp;
reg    [3:0] train_total;
reg    [3:0] counter;

reg          Result;
/*
	Write Your Design Here ~
*/

// train_total
always @(posedge clk or posedge reset) begin
	if(reset) begin
		train_total <= 4'b0;
	end

	else if (train_total <= data) begin
		train_total <= data;
	end

	else if (train_total == counter) begin
		train_total <= 4'b0;
	end

	else begin
		train_total <= train_total;
	end
end

// counter
always @(posedge clk or posedge reset) begin
	if(reset) begin
		counter <= 4'b0;
	end

	else if (train_total == counter) begin
		counter <= 4'b0;
	end


	else if (counter != train_total) begin
		counter <= counter + 1'b1;
	end

	else begin
		counter <= counter;
	end
end

// data_temp
always @(posedge clk or posedge reset) begin
	if(reset) begin
		data_temp <= 10'b0;
	end

	else if (train_total > 4'b0) begin
		case(data)
			4'b0001: data_temp <= 10'b0000000001; //1
			4'b0010: data_temp <= 10'b0000000010; //2
			4'b0011: data_temp <= 10'b0000000100; //3
			4'b0100: data_temp <= 10'b0000001000; //4
			4'b0101: data_temp <= 10'b0000010000; //5
			4'b0110: data_temp <= 10'b0000100000; //6
			4'b0111: data_temp <= 10'b0001000000; //7
			4'b1000: data_temp <= 10'b0010000000; //8
			4'b1001: data_temp <= 10'b0100000000; //9
			4'b1010: data_temp <= 10'b1000000000; //10
			default: data_temp <= 10'b0000000000;
		endcase
	end

	else begin
		data_temp <= data_temp;
	end
end

// station
always @(posedge clk or posedge reset) begin
	if(reset) begin
		station <= 10'b0;
	end

	else if (train_total > 4'b0) begin
		case(data)
			4'b0001: station <= 10'b0000000001; //1
			4'b0010: station <= 10'b0000000011; //2
			4'b0011: station <= 10'b0000000111; //3
			4'b0100: station <= 10'b0000001111; //4
			4'b0101: station <= 10'b0000011111; //5
			4'b0110: station <= 10'b0000111111; //6
			4'b0111: station <= 10'b0001111111; //7
			4'b1000: station <= 10'b0011111111; //8
			4'b1001: station <= 10'b0111111111; //9
			4'b1010: station <= 10'b1111111111; //10
			default: station <= 10'b0000000000;
		endcase
	end
	else begin
		station <= station;
	end
end

// stack
always @(posedge clk or posedge reset) begin
	if(reset) begin
		stack <= 10'b0;
	end

	else if (counter == 4'b0) begin
		stack <= 10'b0;
	end

	else if (counter >= 4'b1) begin
		stack <= stack + data_temp;
	end

	else if (train_total == 4'b0) begin
		stack <= data_temp;
	end



	else begin
		stack <= stack;
	end
end

// max
always @(posedge clk or posedge reset) begin
	if (reset) begin
		max <= 10'b0;
	end

	else if (counter == train_total) begin
		max <= 10'b0;
	end

	else if (data_temp > max) begin
		max <= (station ^ data_temp ^ stack);
	end

	else if (max > station) begin
		max <= max;
	end	
	else if (max <= station) begin
		max <= max - data_temp;
	end

	else begin
		max <= max;
	end

end

//Results
always @(posedge clk or posedge reset) begin
	if (reset) begin
		Result <= 1'b0;
	end
	else if (max > station && !Result) begin
		Result <= 1'b1;
	end

	else if (data_temp == 10'b0) begin
		Result <= 1'b0;
	end
end

// valid
always @(*) begin
	if (train_total == counter && counter != 4'b0) begin
		valid = 1'b1;
	end

	else begin
		valid = 1'b0;
	end
end

//results
always @(posedge clk or posedge reset) begin
	if (reset) begin
		result <= 1'b0;
	end
	else if (max > station && !Result) begin
		result <= 1'b0;
	end

	else if (data_temp == 10'b0) begin
		result <= 1'b1;
	end
end

endmodule