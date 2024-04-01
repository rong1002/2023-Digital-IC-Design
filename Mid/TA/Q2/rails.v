module rails(clk, reset, number, data1, data2, valid, result1, result2);

input        clk;
input        reset;
input  [3:0] number;
input  [3:0] data1;
input  [3:0] data2;
output  reg     valid;
output  reg     result1; 
output  reg     result2;

localparam NUMBER_IN = 4'd0;
localparam DATA_IN = 4'd1;
localparam STATION_POP = 4'd2;
localparam STATION_PUSH = 4'd3;
localparam OUT = 4'd4;
localparam WAIT = 4'd5;
localparam STATION_POP2 = 4'd6;
localparam STATION_PUSH2 = 4'd7;
localparam OUT2 = 4'd8;
localparam WAIT2 = 4'd9;


reg [3:0] state, nextState;
reg [3:0] num;
reg [3:0] index, station_index, sequence_index;
reg [3:0] station [0:9];//station stack
reg [3:0] order [0:9];//input order
reg [3:0] order2 [0:9];

wire [3:0] station_index_minus_one = station_index - 4'd1;

integer i;

always @(*) begin
    case(state)
        NUMBER_IN:begin
            nextState = DATA_IN;
        end
        DATA_IN:begin
            if(index == num - 1) nextState = STATION_POP;
            else nextState = DATA_IN;
        end
        STATION_POP:begin
            if((station_index > 4'd0) && (station[station_index_minus_one] == order[index])) nextState = STATION_POP;
            else nextState = STATION_PUSH;
        end
        STATION_PUSH:begin
            if((sequence_index == num + 1) || (station_index == 4'd6)) nextState = OUT;
            else nextState = STATION_POP;
        end
        OUT:begin
            nextState = WAIT;
        end
        WAIT:begin
            nextState = STATION_POP2;
        end
        STATION_POP2:begin
            if((station_index > 4'd0) && (station[station_index_minus_one] == order2[index])) nextState = STATION_POP2;
            else nextState = STATION_PUSH2;
        end
        STATION_PUSH2:begin
            if((sequence_index == num) || (station_index == 4'd4)) nextState = OUT2;
            else nextState = STATION_POP2;
        end
        OUT2:begin
            nextState = WAIT2;
        end
        default:begin
            nextState = NUMBER_IN;
        end
    endcase
end

always @(posedge clk) begin
    if(reset) state <= NUMBER_IN;
    else state <= nextState;
end

always @(posedge clk or posedge reset) begin
    if(reset)begin
        for(i = 0; i < 10; i = i + 1) station[i] <= 4'b1111;
        valid <= 1'b0;
        result1 <= 1'b0;
        result2 <= 1'b0;
        num <= 4'd0;
        index <= 4'd0;
        station_index <= 4'd0;
        sequence_index <= 4'd1;
    end
    else begin
        case(state)
            NUMBER_IN:begin//read number
                num <= number;
            end
            DATA_IN:begin//read data
                order[index] <= data1;
                order2[index] <= data2;
                if(index == num - 1) index <= 4'd0;
                else index <= index + 1;
            end
            STATION_POP:begin//compare top with order
                if((station_index > 4'd0) && (station[station_index_minus_one] == order[index]))begin
                    index <= index + 1;
                    station_index <= station_index - 1;
                end
            end
            STATION_PUSH:begin//push data into stack
                station[station_index] <= sequence_index;
                station_index <= station_index + 1;
                sequence_index <= sequence_index + 1;
            end
            OUT:begin//output result
                if(index == num) result1 <= 1;
            end
            WAIT:begin//reset register
                for(i = 0; i < 10; i = i + 1) station[i] <= 4'b1111;
                index <= 0;
                station_index <= 4'd0;
                sequence_index <= 4'd0;
            end
            STATION_POP2:begin//compare top with order
                if((station_index > 4'd0) && (station[station_index_minus_one] == order2[index]))begin
                    index <= index + 1;
                    station_index <= station_index - 1;
                end
            end
            STATION_PUSH2:begin//push data into stack
                station[station_index] <= order[sequence_index];
                station_index <= station_index + 1;
                sequence_index <= sequence_index + 1;
            end
            OUT2:begin//output result
                valid <= 1;
                if(index == num && result1) result2 <= 1;
            end
            WAIT2:begin//reset register
                for(i = 0; i < 10; i = i + 1) station[i] <= 4'b1111;
                valid <= 0;
                result1 <= 0;
                result2 <= 0;
                index <= 0;
                station_index <= 4'd0;
                sequence_index <= 4'd1;
            end
        endcase
    end
end

endmodule