module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output reg valid;
output reg [6:0] result;


//-----Your design-----//

reg [2:0] nowState, nextState;
reg [6:0] dataBuffer [0:15];

reg [4:0] len;
reg [4:0] arrPt, stackPt, outPt;

reg [6:0] OpStack   [0:15]; 
reg [6:0] OutBuffer [0:15]; 

reg [6:0] sum [0:15]; 
reg [3:0] sumPt ;

reg readEn;

 
parameter BUFFER    = 3'd0,
          IN2POS    = 3'd1,
          POP       = 3'd2,
          CACULATE  = 3'd3,
          RESULT    = 3'd4,
          RESET     = 3'd5;

integer i;

always@(posedge clk or posedge rst) begin
    if (rst) begin
        nowState <= BUFFER;
        result <= 0;
        arrPt <= 0;
        stackPt <= 0;
        outPt <= 0;
        sumPt <= 0;
        valid <= 0; 
        len <= 0;
        readEn <= 0;
        for(i=0;i<16;i=i+1)begin
            OutBuffer[i]<=0;
            OpStack[i]<=0;
            dataBuffer[i]<=0;
            sum[i] <= 0;
        end
    end
    else begin
        nowState <= nextState;
        case(nowState)
            BUFFER:begin        
                if(ready) begin
                    readEn <= 1;   
                end 
                if(ascii_in!=61 && (ready||readEn)) begin
                    len <= len + 1;
                    case(ascii_in)      // Mapping
                        // number(0~9)
                        48:  dataBuffer[len] <= 4'd0 ;  49: dataBuffer[len] <= 4'd1 ;  50: dataBuffer[len] <= 4'd2 ;
                        51:  dataBuffer[len] <= 4'd3 ;  52: dataBuffer[len] <= 4'd4 ;  53: dataBuffer[len] <= 4'd5 ;
                        54:  dataBuffer[len] <= 4'd6 ;  55: dataBuffer[len] <= 4'd7 ;  56: dataBuffer[len] <= 4'd8 ;
                        57:  dataBuffer[len] <= 4'd9 ;  
                        // number(10~15)
                        97:  dataBuffer[len] <= 4'd10;  98: dataBuffer[len] <= 4'd11;
                        99:  dataBuffer[len] <= 4'd12; 100: dataBuffer[len] <= 4'd13; 101: dataBuffer[len] <= 4'd14; 
                        102: dataBuffer[len] <= 4'd15; 
                        // operation
                        default : dataBuffer[len] <=  ascii_in;
                    endcase
                end
            end
            IN2POS:begin
                case(dataBuffer[arrPt])
                    40:begin    // (     Put into stack
                        OpStack[stackPt] <= dataBuffer[arrPt];
                        stackPt <= stackPt + 1;
                        arrPt <= arrPt + 1;
                    end
                    41:begin    // )     Put into stack
                        if(OpStack[stackPt-1]!=40 && OpStack[stackPt-1]!=41)begin
                            OutBuffer[outPt] <= OpStack[stackPt-1];
                            outPt <= outPt + 1;
                        end
                        stackPt <= stackPt - 1;
                        if(OpStack[stackPt-1]==40) arrPt <= arrPt + 1;
                    end
                    42:begin    // *
                        if(OpStack[stackPt-1]==42 && stackPt!=0) begin 
                            OutBuffer[outPt] <= OpStack[stackPt-1];
                            stackPt <= stackPt -1 ;
                            outPt <= outPt + 1;
                        end
                        else begin
                            OpStack[stackPt] <= dataBuffer[arrPt];
                            stackPt <= stackPt + 1;
                            arrPt <= arrPt + 1;
                        end
                    end
                    43, 45:begin  // + -
                        if((OpStack[stackPt-1]==42 || OpStack[stackPt-1]==43 || OpStack[stackPt-1]==45) && stackPt!=0) begin 
                            OutBuffer[outPt] <= OpStack[stackPt-1];
                            stackPt <= stackPt -1 ;
                            outPt <= outPt + 1;
                        end
                        else begin
                            OpStack[stackPt] <= dataBuffer[arrPt];
                            stackPt <= stackPt + 1;
                            arrPt <= arrPt + 1;
                        end
                    end
                    default:begin  // Normal number
                        OutBuffer[outPt] <= dataBuffer[arrPt];
                        outPt <= outPt + 1; 
                        arrPt <= arrPt + 1;
                    end
                endcase
            end
            POP:begin
                if(stackPt!=0) begin
                    stackPt <= stackPt - 1;
                    if(OpStack[stackPt-1]!=40 && OpStack[stackPt-1]!=41)begin
                        OutBuffer[outPt] <= OpStack[stackPt-1];
                        outPt <= outPt + 1;
                    end
                end
            end
            CACULATE:begin
                stackPt <= stackPt + 1;    
                case(OutBuffer[stackPt])
                    42:begin
                        sum[sumPt-2] <= sum[sumPt-2] * sum[sumPt-1];
                        sumPt <= sumPt -1;
                    end
                    43:begin
                        sum[sumPt-2] <= sum[sumPt-2] + sum[sumPt-1];
                        sumPt <= sumPt -1;
                    end
                    45:begin
                        sum[sumPt-2] <= sum[sumPt-2] - sum[sumPt-1];
                        sumPt <= sumPt -1;
                    end
                    default:begin
                        sum[sumPt] <= OutBuffer[stackPt];
                        sumPt <= sumPt +1;
                    end
                endcase
            end
            RESULT:begin
                valid <= 1; 
                result <= sum[sumPt-1];
                arrPt <= 0;
                stackPt <= 0;
                outPt <= 0;
                sumPt <= 0;
                readEn <= 0;
                len <= 0;
                for(i=0;i<16;i=i+1)begin
                    OutBuffer[i]<=0;
                    OpStack[i]<=0;
                    dataBuffer[i]<=0;
                    sum[i] <= 0;
                end
            end
            RESET:begin
                valid <= 0;
            end
        endcase
    end
end



always@(*)begin
    case(nowState)
        BUFFER:begin
            nextState = (ascii_in==61)? IN2POS : BUFFER;
        end
        IN2POS:begin
            nextState = (arrPt==len-1)? POP : IN2POS;
        end
        POP:begin
            nextState = (stackPt==0)? CACULATE : POP;
        end
        CACULATE:begin
            nextState = (stackPt==outPt-1)? RESULT : CACULATE;
        end
        RESULT:begin
            nextState = RESET;
        end
        RESET:begin
            nextState = BUFFER;
        end
        default:begin
            nextState = BUFFER;
        end
    endcase
end

endmodule