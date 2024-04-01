module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input            clk;
input            rst;
input            ready;
input      [7:0] ascii_in;

// Output signal
output reg       valid;
output reg [6:0] result;

//-----Your design-----//
localparam DATA_IN = 2'd0;
localparam CAL     = 2'd1;
localparam DONE    = 2'd2;
localparam RESET   = 2'd3;

reg [2:0] currState, nextState;
reg [3:0] fsm_o;
wire l_DATA_IN, l_CAL, l_DONE, l_RESET;

reg [4:0] ascii_in_to_number;

reg [4:0] data_stack  [0:15];
reg [4:0] ops_stack   [0:3]; //存數學符號
reg [6:0] value_stack [0:3]; //存整個stack


reg [3:0] data_total_count; // total number and operator
reg [3:0] data_count      ;
reg [3:0] value_count     ;
reg [2:0] ops_count       ;

wire [3:0] value_count_minus_one = value_count - 4'd1;
wire [3:0] value_count_minus_two = value_count - 4'd2;
wire [2:0] ops_count_minus_one   = ops_count - 3'd1;

integer i=0;

////////////////////////FSM/////////////////////////
always @(*) begin
    case (currState)
        DATA_IN: nextState = (ascii_in_to_number == 5'd25) ? CAL : DATA_IN;
        CAL:     nextState = (data_count == data_total_count - 4'd1 && value_count == 4'd2) ? DONE : CAL;
        DONE:    nextState = RESET;
        RESET:   nextState = DATA_IN;
        default: nextState = DATA_IN;
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst) currState <= DATA_IN;
    else currState     <= nextState;
end

always @(*) begin
    case (currState)
        DATA_IN: fsm_o = 4'b1000;
        CAL:     fsm_o = 4'b0100;
        DONE:    fsm_o = 4'b0010;
        RESET:   fsm_o = 4'b0001;
        default: fsm_o = 4'b0000;
    endcase
end

assign {l_DATA_IN, l_CAL, l_DONE, l_RESET} = fsm_o;

//////////////////////datapath//////////////////////
always @(posedge clk or posedge rst) begin
    if (rst) begin
        valid            <= 1'd0;
        result           <= 7'd0;
        data_total_count <= 4'd0;
        data_count       <= 4'd0;
        ops_count        <= 3'd0;
        value_count      <= 4'd0;
    end
    
    else if (l_DATA_IN) data_total_count <= data_total_count + 4'd1;
    
    else if (l_CAL) begin
        case (data_stack[data_count])

        5'd25: begin //=
            ops_count   <= ops_count_minus_one;
            value_count <= value_count_minus_one;
        end

        5'd20: begin //(
            ops_count  <= ops_count  + 3'd1;
            data_count <= data_count + 4'd1;
        end

        5'd21: begin //)
            if (ops_stack[ops_count_minus_one] != 5'd20) begin
                ops_count   <= ops_count_minus_one;
                value_count <= value_count_minus_one;
            end
            else begin
                ops_count  <= ops_count_minus_one;
                data_count <= data_count + 4'd1;
            end
        end

        5'd22: begin //*
            if (ops_stack[ops_count_minus_one] == 5'd22) begin
                ops_count   <= ops_count_minus_one;
                value_count <= value_count_minus_one;
            end
            else begin
                ops_count  <= ops_count + 3'd1;
                data_count <= data_count + 4'd1;
            end
        end

        5'd23, 5'd24: begin //+, -
            if (ops_stack[ops_count_minus_one] == 5'd22 || ops_stack[ops_count_minus_one] == 5'd23 || ops_stack[ops_count_minus_one] == 5'd24) begin
                ops_count   <= ops_count_minus_one;
                value_count <= value_count_minus_one;
            end
            else begin
                ops_count  <= ops_count  + 3'd1;
                data_count <= data_count + 4'd1;
            end
        end

        default: begin //number
            data_count  <= data_count  + 4'd1;
            value_count <= value_count + 4'd1;
        end
    endcase
    end
    
    else if (l_DONE) begin
        valid  <= 1;
        result <= value_stack[0];
    end
    
    else begin
        valid            <= 1'd0;
        result           <= 7'd0;
        data_total_count <= 4'd0;
        data_count       <= 4'd0;
        value_count      <= 4'd0;
        ops_count        <= 3'd0;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for(i=0; i < 16; i = i + 1) data_stack[i]  <= 5'b11111;
    end
    
    else if (l_DATA_IN) begin
        data_stack[data_total_count] <= ascii_in_to_number;
    end

end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for(i=0; i < 4 ; i = i + 1) ops_stack[i]   <= 5'b11111;
        for(i=0; i < 4 ; i = i + 1) value_stack[i] <= 7'b1111111;
    end

    else if (l_CAL) begin
        case (data_stack[data_count])

        5'd25: begin //=
            case (ops_stack[ops_count_minus_one])
                5'd22: value_stack[value_count_minus_two] <= value_stack[value_count_minus_two] * value_stack[value_count_minus_one];
                5'd23: value_stack[value_count_minus_two] <= value_stack[value_count_minus_two] + value_stack[value_count_minus_one];
                5'd24: value_stack[value_count_minus_two] <= value_stack[value_count_minus_two] - value_stack[value_count_minus_one];
            endcase
        end

        5'd20: begin //(
            ops_stack[ops_count] <= data_stack[data_count];
        end

        5'd21: begin //)
            if (ops_stack[ops_count_minus_one] != 5'd20) begin
                case (ops_stack[ops_count_minus_one])
                    5'd22: value_stack[value_count_minus_two] <= value_stack[value_count_minus_two] * value_stack[value_count_minus_one];
                    5'd23: value_stack[value_count_minus_two] <= value_stack[value_count_minus_two] + value_stack[value_count_minus_one];
                    5'd24: value_stack[value_count_minus_two] <= value_stack[value_count_minus_two] - value_stack[value_count_minus_one];
                endcase
                ops_stack[ops_count_minus_one] <= 5'b11111;
            end
        end

        5'd22: begin //*
            if (ops_stack[ops_count_minus_one] == 5'd22) value_stack[value_count_minus_two] <= value_stack[value_count_minus_two] * value_stack[value_count_minus_one];
            else ops_stack[ops_count] <= data_stack[data_count];
        end

        5'd23, 5'd24: begin //+, -
            if (ops_stack[ops_count_minus_one] == 5'd22 || ops_stack[ops_count_minus_one] == 5'd23 || ops_stack[ops_count_minus_one] == 5'd24) begin
                case (ops_stack[ops_count_minus_one])
                    5'd22: value_stack[value_count_minus_two] <= value_stack[value_count_minus_two] * value_stack[value_count_minus_one];
                    5'd23: value_stack[value_count_minus_two] <= value_stack[value_count_minus_two] + value_stack[value_count_minus_one];
                    5'd24: value_stack[value_count_minus_two] <= value_stack[value_count_minus_two] - value_stack[value_count_minus_one];
                endcase
                ops_stack[ops_count_minus_one] <= 5'b11111;

            end
            else ops_stack[ops_count] <= data_stack[data_count];
        end

        default: value_stack[value_count] <= data_stack[data_count]; //number
    endcase
    end
end

//ascii_in to number
always @(*) begin
    case (ascii_in)
        8'd48:   ascii_in_to_number = 5'd0;  //0
        8'd49:   ascii_in_to_number = 5'd1;  //1
        8'd50:   ascii_in_to_number = 5'd2;  //2
        8'd51:   ascii_in_to_number = 5'd3;  //3
        8'd52:   ascii_in_to_number = 5'd4;  //4
        8'd53:   ascii_in_to_number = 5'd5;  //5
        8'd54:   ascii_in_to_number = 5'd6;  //6
        8'd55:   ascii_in_to_number = 5'd7;  //7
        8'd56:   ascii_in_to_number = 5'd8;  //8
        8'd57:   ascii_in_to_number = 5'd9;  //9
        8'd97:   ascii_in_to_number = 5'd10;  //10
        8'd98:   ascii_in_to_number = 5'd11;  //11
        8'd99:   ascii_in_to_number = 5'd12;  //12
        8'd100:  ascii_in_to_number = 5'd13;  //13
        8'd101:  ascii_in_to_number = 5'd14;  //14
        8'd102:  ascii_in_to_number = 5'd15;  //15

        8'd40:   ascii_in_to_number = 5'd20;  //(
        8'd41:   ascii_in_to_number = 5'd21;  //)
        8'd42:   ascii_in_to_number = 5'd22;  //*
        8'd43:   ascii_in_to_number = 5'd23;  //+
        8'd45:   ascii_in_to_number = 5'd24;  //-
        8'd61:   ascii_in_to_number = 5'd25;  //=
        default: ascii_in_to_number = 5'd31;
    endcase
end

endmodule
