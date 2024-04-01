module rails(clk, reset, data, valid, result);

input        clk;
input        reset;
input  [3:0] data;
output       valid;
output   reg     result; 

reg [9:0]total, station;
reg [3:0]count;

reg [9:0]decode_data, onehot_data;

reg [2:0] state, nextstate;
reg [4:0] f_o;
wire l_S_rst, l_S_input, l_S_cmp, l_S_vld;
parameter S_rst = 2'd0,
		S_input = 2'd1,
		S_cmp = 2'd2,
		S_vld = 2'd3;

////////////////////////FSM/////////////////////////

always @(*) begin
	case (state)
		// S_rst: nextstate = S_input;
		// S_input: nextstate = S_cmp;
		S_rst: nextstate = S_cmp;
		S_cmp: nextstate = (count == 1) ? S_vld : S_cmp;
		S_vld: nextstate = S_rst;
		default: 
			nextstate = S_rst;
	endcase
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		state <= S_rst;
	end
	else begin
		state <= nextstate;
	end
end
always @(*) begin
	case (state)
		S_rst: 
			f_o = 4'b1000;
		S_input: 
			f_o = 4'b0100;
		S_cmp: 
			f_o = 4'b0010;
		S_vld: 
			f_o = 4'b0001;
		default: f_o = 4'b0000;
	endcase
end
assign {l_S_rst, l_S_input, l_S_cmp, l_S_vld} = f_o;


//////////////////////datapath//////////////////////
always @(posedge clk or posedge reset) begin
	if (reset) begin
		count <= 4'b1111; 
	end
	else if(l_S_rst) begin
		count <= data;
	end
	else if (l_S_cmp) begin
		count <= count - 1;
	end
	else begin
		count <= 4'b1111; 
	end
end

assign valid = (count == 0)? 1 : 0 ;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		total <= 10'd0;
		station <= 10'd0;
		result <= 1;
	end
	else begin
		if (l_S_cmp) begin
			if (decode_data > total) begin
				total <= decode_data | total;
				station <= station | ((total ^ decode_data) ^ onehot_data);
			end
			else if (decode_data >= station) begin
				station <= station ^ onehot_data;
			end
			else if (decode_data < station && result) begin
				result <= 0;
			end
		end
		else begin
			result <= 1;
			total <= 10'd0;
			station <= 10'd0;
		end
	end
end

always @(*) begin
	case (data)
		4'd1:	decode_data = 10'b0000000001;
		4'd2: 	decode_data = 10'b0000000011;
		4'd3:  	decode_data = 10'b0000000111;
		4'd4:  	decode_data = 10'b0000001111;
		4'd5:  	decode_data = 10'b0000011111;
		4'd6:  	decode_data = 10'b0000111111;
		4'd7:  	decode_data = 10'b0001111111;
		4'd8:  	decode_data = 10'b0011111111;
		4'd9:  	decode_data = 10'b0111111111;
		4'd10: 	decode_data = 10'b1111111111;
		default: 
			   	decode_data = 10'b0000000000;
	endcase
end

always @(*) begin
	case (data)
		4'd1:	onehot_data = 10'b0000000001;
		4'd2: 	onehot_data = 10'b0000000010;
		4'd3:  	onehot_data = 10'b0000000100;
		4'd4:  	onehot_data = 10'b0000001000;
		4'd5:  	onehot_data = 10'b0000010000;
		4'd6:  	onehot_data = 10'b0000100000;
		4'd7:  	onehot_data = 10'b0001000000;
		4'd8:  	onehot_data = 10'b0010000000;
		4'd9:  	onehot_data = 10'b0100000000;
		4'd10: 	onehot_data = 10'b1000000000;
		default: 
			   	onehot_data = 10'b0000000000;
	endcase
end
endmodule