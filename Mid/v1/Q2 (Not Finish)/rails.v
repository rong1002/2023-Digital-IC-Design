module rails(clk, reset, number, data1, data2, valid, result1, result2);

input        clk;
input        reset;
input  [3:0] number;
input  [3:0] data1;
input  [3:0] data2;
output  reg     valid;
output  reg     result1; 
output  reg     result2;

/*
    Write your design here!
*/
localparam NUMBER_IN   = 3'd0;
localparam DATA_IN     = 3'd1;
localparam STATION_POP = 3'd2;
localparam STATION_IN  = 3'd3;
localparam DONE        = 3'd4;
localparam RESET       = 3'd5;

reg [2:0] currState, nextState;
reg [5:0] fsm_o;
wire l_RESET, l_NUMBER_IN, l_DATA_IN, l_STATION_POP, l_STATION_IN, l_DONE;

reg [3:0] data1_station [0:9];
reg [3:0] data2_station [0:9];
reg [3:0] pop_station [0:9];
reg [3:0] total_train;
reg [3:0] data_index, station_index, pop_index;
wire [3:0] station_index_minus_one = station_index - 4'd1;
integer i;

////////////////////////FSM/////////////////////////
always @(*) begin
    case (currState)
        NUMBER_IN:   nextState = DATA_IN;
        DATA_IN:     nextState = (data_index == total_train - 4'd1) ? STATION_POP : DATA_IN;
        STATION_POP: nextState = ((station_index > 4'd0) && (pop_station[station_index_minus_one] == data1_station[data_index])) ? STATION_POP : STATION_IN;
        STATION_IN:  nextState = (pop_index == total_train + 4'd1) ? DONE : STATION_POP;
        DONE:        nextState = RESET;
        RESET:       nextState = NUMBER_IN;
        default:     nextState = NUMBER_IN;
    endcase
end

always @(posedge clk or posedge reset) begin
    if (reset) currState <= NUMBER_IN;
    else currState <= nextState;
end

always @(*) begin
    case (currState)
        NUMBER_IN:   fsm_o = 6'b100000;
        DATA_IN:     fsm_o = 6'b010000;
        STATION_POP: fsm_o = 6'b001000;
        STATION_IN:  fsm_o = 6'b000100;
        DONE:        fsm_o = 6'b000010;
        RESET:       fsm_o = 6'b000001;
        default:     fsm_o = 6'b000000;
    endcase
end

assign {l_NUMBER_IN, l_DATA_IN, l_STATION_POP, l_STATION_IN, l_DONE, l_RESET} = fsm_o;


//////////////////////datapath//////////////////////
always @(posedge clk or posedge reset) begin
    if (reset) begin
        for(i = 0; i < 10; i = i + 1) pop_station[i] <= 4'b1111;
        valid         <= 1'd0;
        result1       <= 1'd0;
        result2       <= 1'd0;
        total_train   <= 4'd0;
        data_index    <= 4'd0;
        station_index <= 4'd0;
        pop_index     <= 4'd1;
    end

    else if (l_NUMBER_IN) begin
        total_train <= number;
    end

    else if (l_DATA_IN) begin
        data1_station[data_index] <= data1;
        data_index <= (data_index == total_train - 4'd1) ? 4'd0 : data_index + 1;
    end

    else if (l_STATION_POP) begin
        if((station_index > 4'd0) && (pop_station[station_index_minus_one] == data1_station[data_index])) begin
            data_index    <= data_index + 4'd1;
            station_index <= station_index - 4'd1;
        end
    end

    else if (l_STATION_IN) begin
        pop_station[station_index] <= pop_index;
        station_index <= station_index + 4'd1;
        pop_index     <= pop_index + 4'd1;
    end

    else if (l_DONE) begin
        valid <= 1;
        result1 <= (data_index == total_train) ? 1 : 0;
        result2 <= (result1 == 0) ? 0 : 1;
    end

    else if (l_RESET) begin
        for(i = 0; i < 10; i = i + 1) pop_station[i] <= 4'b1111;
        valid         <= 1'd0;
        result1       <= 1'd0;
        result2       <= 1'd0;
        total_train   <= 4'd0;
        data_index    <= 4'd0;
        station_index <= 4'd0;
        pop_index     <= 4'd1;
    end
end
endmodule