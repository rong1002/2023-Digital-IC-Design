module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output reg valid;
output reg [6:0] result;

localparam BUFFER   = 3'd0;
localparam IN2POS   = 3'd1;
localparam POP      = 3'd2;
localparam CACULATE = 3'd3;
localparam RESULT   = 3'd4;
localparam RESET    = 3'd5;

reg [2:0] currState, nextState;
reg [5:0] fsm_o;
wire l_BUFFER, l_IN2POS, l_POP, l_CACULATE, l_RESULT, l_RESET;

reg [6:0] dataBuffer [0:15];

reg [4:0] len;
reg [4:0] arrPt, stackPt, outPt;

reg [6:0] OpStack   [0:15]; 
reg [6:0] OutBuffer [0:15]; 

reg [6:0] sum [0:15]; 
reg [3:0] sumPt ;

reg readEn;

integer i;
////////////////////////FSM/////////////////////////
always @(*) begin
    case (currState)
        BUFFER:   nextState = (ascii_in == 61)     ? IN2POS   : BUFFER;
        IN2POS:   nextState = (arrPt == len-1)     ? POP      : IN2POS;
        POP:      nextState = (stackPt == 0)       ? CACULATE : POP;
        CACULATE: nextState = (stackPt == outPt-1) ? RESULT : CACULATE;
        RESULT:   nextState = RESET;
        RESET:    nextState = BUFFER;
        default:  nextState = BUFFER;
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst) currState <= BUFFER;
    else currState     <= nextState;
end

always @(*) begin
    case (currState)
        BUFFER:   fsm_o = 6'b100000;
        IN2POS:   fsm_o = 6'b010000;
        POP:      fsm_o = 6'b001000;
        CACULATE: fsm_o = 6'b000100;
        RESULT:   fsm_o = 6'b000010;
        RESET:    fsm_o = 6'b000001;
        default:  fsm_o = 6'b000000;
    endcase
end

assign {l_BUFFER, l_IN2POS, l_POP, l_CACULATE, l_RESULT, l_RESET} = fsm_o;

//////////////////////datapath//////////////////////

// readEn, len, dataBuffer
always@(posedge clk or posedge rst) begin
    if (rst) begin
        len    <= 0;
        readEn <= 0;
        for (i=0; i<16; i = i + 1) dataBuffer[i] <= 0;
    end
    else if (l_BUFFER) begin
        if (ready) readEn <= 1;

        if (ascii_in != 61 && (ready || readEn)) begin
            len <= len + 1;
            case (ascii_in)
                //number
                48 : dataBuffer[len] <= 4'd0;
                49 : dataBuffer[len] <= 4'd1;
                50 : dataBuffer[len] <= 4'd2;
                51 : dataBuffer[len] <= 4'd3;
                52 : dataBuffer[len] <= 4'd4;
                53 : dataBuffer[len] <= 4'd5;
                54 : dataBuffer[len] <= 4'd6;
                55 : dataBuffer[len] <= 4'd7;
                56 : dataBuffer[len] <= 4'd8;
                57 : dataBuffer[len] <= 4'd9;
                97 : dataBuffer[len] <= 4'd10;
                98 : dataBuffer[len] <= 4'd11;
                99 : dataBuffer[len] <= 4'd12;
                100: dataBuffer[len] <= 4'd13;
                101: dataBuffer[len] <= 4'd14;
                102: dataBuffer[len] <= 4'd15;
                //operation
                default: dataBuffer[len] <= ascii_in;
            endcase
        end
    end
    else if (l_RESULT) begin
        len    <= 0;
        readEn <= 0;
        for (i=0; i<16; i = i + 1) dataBuffer[i] <= 0;
    end
end

//OpStack, OutBuffer, arrPt, outPt, stackPt
always@(posedge clk or posedge rst) begin
    if (rst) begin
        arrPt   <= 0;
        outPt   <= 0;
        stackPt <= 0;
        for (i=0; i<16; i = i + 1) OpStack[i]   <= 0;
        for (i=0; i<16; i = i + 1) OutBuffer[i] <= 0;
    end

    else if (l_IN2POS) begin
        case (dataBuffer[arrPt])
            40: begin // (    Put into stack
                OpStack[stackPt] <= dataBuffer[arrPt];
                stackPt <= stackPt + 1;
                arrPt   <= arrPt + 1;
            end
            41: begin // )    Put into stack
                if (OpStack[stackPt - 1] != 40 && OpStack[stackPt - 1] != 41) begin
                    OutBuffer[outPt] <= OpStack[stackPt - 1];
                    outPt <= outPt + 1;
                end
                stackPt <= stackPt - 1;
                if(OpStack[stackPt - 1] == 40) arrPt <= arrPt + 1;
            end
            42: begin // * (遇到*, 直接pop * 到OutBuffer), (遇到+-, 把*丟進去OpStack)
                if(OpStack[stackPt - 1] == 42 && stackPt != 0) begin 
                    OutBuffer[outPt] <= OpStack[stackPt - 1];
                    stackPt <= stackPt - 1;
                    outPt   <= outPt   + 1;
                end
                else begin
                    OpStack[stackPt] <= dataBuffer[arrPt];
                    stackPt <= stackPt + 1;
                    arrPt   <= arrPt   + 1;
                end
            end
            43, 45: begin // + - (遇到+-*, 直接pop +- 到OutBuffer), (遇到空的, 把+-丟進去OpStack)
                if((OpStack[stackPt - 1] == 42 || OpStack[stackPt - 1] == 43 || OpStack[stackPt - 1] == 45) && stackPt != 0) begin 
                    OutBuffer[outPt] <= OpStack[stackPt - 1];
                    stackPt <= stackPt - 1;
                    outPt   <= outPt   + 1;
                end
                else begin
                    OpStack[stackPt] <= dataBuffer[arrPt];
                    stackPt <= stackPt + 1;
                    arrPt   <= arrPt   + 1;
                end
            end
            default: begin // Normal number
                OutBuffer[outPt] <= dataBuffer[arrPt];
                outPt <= outPt + 1; 
                arrPt <= arrPt + 1;
            end
        endcase
    end

    else if (l_POP) begin //if OpStack 裡還有operator
        if(stackPt != 0) begin
            stackPt <= stackPt - 1;
            if(OpStack[stackPt - 1] != 40 && OpStack[stackPt - 1] != 41)begin
                OutBuffer[outPt] <= OpStack[stackPt - 1];
                outPt <= outPt + 1;
            end
        end
    end

    else if (l_RESULT) begin
        arrPt   <= 0;
        outPt   <= 0;
        stackPt <= 0;
        for (i=0; i<16; i = i + 1) OpStack[i]   <= 0;
        for (i=0; i<16; i = i + 1) OutBuffer[i] <= 0;
    end
end

//sumPt, sum, stackPt
always@(posedge clk or posedge rst) begin
    if (rst) begin
        sumPt <= 0;
        for (i=0; i<16; i = i + 1) sum[i] <= 0;
    end

    else if (l_CACULATE) begin
        stackPt <= stackPt + 1;
        case(OutBuffer[stackPt])
            42:begin
                sum[sumPt - 2] <= sum[sumPt - 2] * sum[sumPt - 1];
                sumPt <= sumPt - 1;
            end
            43:begin
                sum[sumPt - 2] <= sum[sumPt - 2] + sum[sumPt - 1];
                sumPt <= sumPt - 1;
            end
            45:begin
                sum[sumPt - 2] <= sum[sumPt - 2] - sum[sumPt - 1];
                sumPt <= sumPt - 1;
            end
            default:begin
                sum[sumPt] <= OutBuffer[stackPt];
                sumPt <= sumPt + 1;
            end
        endcase
    end

    else if (l_RESULT) begin
        sumPt <= 0;
        for (i=0; i<16; i = i + 1) sum[i] <= 0;
    end
end

//result, valid
always@(posedge clk or posedge rst) begin
    if (rst) begin
        result <= 0;
        valid <= 0; 
    end
    else if (l_RESULT) begin
        valid  <= 1; 
        result <= sum[sumPt - 1];
    end
    else if (l_RESET) begin
        valid <= 0;
    end
end

endmodule