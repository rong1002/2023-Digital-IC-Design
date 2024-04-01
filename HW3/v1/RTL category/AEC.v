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
localparam DATA_IN = 3'd0;
localparam STACK   = 3'd1;
localparam CAL     = 3'd2;
localparam DONE    = 3'd3;
localparam RESET   = 3'd4;

reg [2:0] currState, nextState;
reg [4:0] fsm_o;
// wire l_DATA_IN, l_STACK, l_CAL, l_DONE, l_RESET;

reg [4:0] ascii_in_to_number;

reg [4:0] data_stack   [0:15];
reg [4:0] output_stack [0:15]; //存整個stack
reg [4:0] oper_stack   [0:4]; //存數學符號
reg [6:0] cal_stack    [0:3]; 

reg  [3:0] data_total_count;
reg  [3:0] data_count      ;
reg  [3:0] num_count       ;
reg  [2:0] oper_total_count;
reg  [2:0] oper_count      ;
reg  [2:0] cal_oper_count  ;
reg  [3:0] cal_count       ;
reg  [3:0] count           ;
wire [2:0] oper_count_minus_one  = oper_count - 3'd1;

integer i=0;

////////////////////////FSM/////////////////////////
always @(*) begin
    case (currState)
        DATA_IN: nextState = (ascii_in_to_number == 5'd25) ? STACK : DATA_IN;
        STACK:   nextState = (num_count == data_total_count - 4'd1) ? CAL : STACK;
        CAL:     nextState = (oper_total_count == cal_oper_count) ? DONE : CAL;
        DONE:    nextState = RESET;
        RESET:   nextState = DATA_IN;
        default: nextState = STACK;
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst) currState <= DATA_IN;
    else currState     <= nextState;
end

always @(*) begin
    case (currState)
        DATA_IN: fsm_o = 5'b10000;
        STACK:   fsm_o = 5'b01000;
        CAL:     fsm_o = 5'b00100;
        DONE:    fsm_o = 5'b00010;
        RESET:   fsm_o = 5'b00001;
        default: fsm_o = 5'b00000;
    endcase
end

// assign {l_DATA_IN, l_STACK, l_CAL, l_DONE, l_RESET} = fsm_o;

//////////////////////datapath//////////////////////

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for(i=0; i < 16; i = i + 1) data_stack[i]   <= 5'b11111;
        for(i=0; i < 16; i = i + 1) output_stack[i] <= 5'b11111;
        for(i=0; i < 5 ; i = i + 1) oper_stack[i]   <= 5'b11111;
        for(i=0; i < 4 ; i = i + 1) cal_stack[i]    <= 7'b1111111;
        valid            <= 1'd0;
        result           <= 7'd0;
        data_total_count <= 4'd0;
        data_count       <= 4'd0;
        num_count        <= 4'd0;
        oper_count       <= 3'd0;
        cal_oper_count   <= 3'd0;
        oper_total_count <= 3'd0;
        count            <= 4'd0;
        cal_count        <= 4'd0;
    end
    
    else begin
        case (fsm_o)
        
            5'b10000: begin
                data_stack[data_total_count] <= ascii_in_to_number;
                data_total_count             <= data_total_count + 4'd1;
            end

            5'b01000: begin
                case (data_stack[data_count])

                    5'd25: begin //=
                        output_stack[num_count] <= oper_stack[oper_count_minus_one];
                        num_count  <= num_count  + 4'd1;
                        oper_count <= oper_count - 3'd1;
                    end

                    5'd20: begin //(
                        oper_stack[oper_count] <= data_stack[data_count];
                        oper_count <= oper_count + 3'd1;
                        data_count <= data_count + 4'd1;
                    end

                    5'd21: begin //)
                        if (oper_stack[oper_count_minus_one] != 5'd20) begin
                            output_stack[num_count] <= oper_stack[oper_count_minus_one];
                            num_count        <= num_count  + 4'd1;
                            oper_count       <= oper_count - 3'd1;
                            data_total_count <= data_total_count - 4'd1;
                        end
                        else begin
                            oper_count       <= oper_count - 3'd1;
                            data_count       <= data_count + 4'd1;
                            data_total_count <= data_total_count - 4'd1;
                        end
                    end

                    5'd22: begin //*
                        if (oper_stack[oper_count_minus_one] == 5'd22) begin
                            output_stack[num_count] <= oper_stack[oper_count_minus_one];
                            num_count  <= num_count  + 4'd1;
                            oper_count <= oper_count - 3'd1;
                        end
            
                        else begin
                            oper_stack[oper_count] <= data_stack[data_count];
                            oper_count       <= oper_count + 3'd1;
                            data_count       <= data_count + 4'd1;
                            oper_total_count <= oper_total_count + 3'd1;
                        end
                    end

                    5'd23, 5'd24: begin //+
                        if (oper_stack[oper_count_minus_one] == 5'd22 || oper_stack[oper_count_minus_one] == 5'd23 || oper_stack[oper_count_minus_one] == 5'd24) begin
                            output_stack[num_count] <= oper_stack[oper_count_minus_one];
                            num_count  <= num_count  + 4'd1;
                            oper_count <= oper_count - 3'd1;
                        end
                        
                        else begin
                            oper_stack[oper_count] <= data_stack[data_count];
                            oper_count       <= oper_count + 3'd1;
                            data_count       <= data_count + 4'd1;
                            oper_total_count <= oper_total_count + 3'd1;
                        end
                    end
                    
                    default: begin //number
                        output_stack[num_count] <= data_stack[data_count];
                        num_count  <= num_count  + 4'd1;
                        data_count <= data_count + 4'd1;
                    end
                endcase
            end

            5'b00100: begin
                if (output_stack[count] <= 5'd15) begin
                    cal_stack[cal_count] <= {2'b00, output_stack[count]};
                    count     <= count + 4'd1;
                    cal_count <= cal_count + 4'd1;
                end
                else begin
                    case (output_stack[count])
                        5'd22: cal_stack[cal_count - 4'd2] <= cal_stack[cal_count - 4'd2] * cal_stack[cal_count - 4'd1];
                        5'd23: cal_stack[cal_count - 4'd2] <= cal_stack[cal_count - 4'd2] + cal_stack[cal_count - 4'd1];
                        5'd24: cal_stack[cal_count - 4'd2] <= cal_stack[cal_count - 4'd2] - cal_stack[cal_count - 4'd1];
                    endcase
                    count          <= count + 4'd1;
                    cal_count      <= cal_count - 4'd1;
                    cal_oper_count <= cal_oper_count + 3'd1;
                end
            end

            5'b00010: begin
                valid  <= 1;
                result <= cal_stack[0];
            end

            5'b00001: begin
                valid             <= 1'd0;
                result            <= 7'd0;
                data_total_count  <= 4'd0;
                data_count        <= 4'd0;
                num_count         <= 4'd0;
                oper_count        <= 3'd0;
                cal_oper_count    <= 3'd0;
                oper_total_count  <= 3'd0;
                count             <= 4'd0;
                cal_count         <= 4'd0;
            end
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
