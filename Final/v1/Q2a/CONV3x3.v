`timescale 1ns/10ps
module  CONV3x3(
	input		clk,
	input		reset,
	output	reg	busy,	
	input		ready,	
			
	output reg	[11:0]	iaddr,
	input signed [12:0]	idata,
	
	output	reg 	cwr,
	output  reg	[11:0]	caddr_wr,
	output reg 	[12:0] 	cdata_wr,
	output	reg 	crd,
	output reg	[11:0] 	caddr_rd,
	input 	[12:0] 	cdata_rd,
	output reg 	csel
	);


//state param
localparam INIT = 0;
localparam ATCONV_9PIXELS = 1;
localparam LAYER0_WRITERELU = 2;
localparam MAXPOOL_4PIXELS = 3;
localparam LAYER1_WRITECEILING = 4;
localparam FINISH = 5;

//kernel & bias
wire signed [12:0] kernel [1:9];
assign kernel[1] = 13'h1FFF; assign kernel[2] = 13'h0004; assign kernel[3] = 13'h1FFF;
assign kernel[4] = 13'h1FFC; assign kernel[5] = 13'h0008; assign kernel[6] = 13'h1FFC;
assign kernel[7] = 13'h1FFF; assign kernel[8] = 13'h0004; assign kernel[9] = 13'h1FFF;
wire signed [12:0] bias;
assign bias = 13'h1FFE;

//regs
reg [2:0] state, nextState;
reg [11:0] center; // Coordinate (row, column) = (center[11:6], center[5:0])
reg [3:0] counter; 
reg signed [25:0] convSum; // {mul_integer(18bits), mul_fraction(8bits)}

//constant param
localparam LENGTH = 6'd63;
localparam ZERO = 6'd0; 

//wire constants
wire [5:0] cx_add2,cx_minus2,cy_add2,cy_minus2;
assign cy_add2 = center[11:6] + 6'd1;
assign cy_minus2 = center[11:6] - 6'd1;
assign cx_add2 = center[5:0] + 6'd1 ;
assign cx_minus2 = center[5:0] - 6'd1;

//state ctrl
always @(posedge clk or posedge reset) begin
    if(reset) state <= INIT;
    else state <= nextState;
end

//next state logic
always @(*) begin
    case (state)
        INIT:                nextState = (ready)                ? ATCONV_9PIXELS      : INIT;
        ATCONV_9PIXELS:      nextState = (counter  == 4'd9)     ? LAYER0_WRITERELU    : ATCONV_9PIXELS;
        LAYER0_WRITERELU:    nextState = (center   == 12'd4095) ? MAXPOOL_4PIXELS     : ATCONV_9PIXELS;
        MAXPOOL_4PIXELS:     nextState = (counter  == 4'd4)     ? LAYER1_WRITECEILING : MAXPOOL_4PIXELS;
        LAYER1_WRITECEILING: nextState = (caddr_wr == 12'd1023) ? FINISH              : MAXPOOL_4PIXELS; 
        FINISH:              nextState = FINISH;
        default:             nextState = INIT;
    endcase
end

//main sequential circuit
always @(posedge clk or posedge reset) begin
    if (reset) begin
        busy <= 1'd0;
        iaddr <= 12'd0;
        cwr <= 1'd0;
        caddr_wr <= 12'd0;
        cdata_wr <= 13'd0;
        crd <= 1'd1;
        caddr_rd <= 12'd0;
        csel <= 1'd0;

        center <= {6'd0 , 6'd0};
        counter <= 4'd0;
        convSum <= {{9{1'b1}}, bias, 4'd0}; // Sign extension
    end
    else begin
        case (state)
            INIT:begin
                if (ready) begin
                    busy <= 1'd1;
                end
            end

            ATCONV_9PIXELS:begin
                csel <= 1'd0;
                crd <= 1'd1;
                cwr <= 1'd0;
                // 使用具有相應內核的像素獲取和轉換（ counter==0 表示還沒有像素獲取）
                // use the pixel get and conv with corresponding kernel ( counter==0 means no pixel get yet )
                if(counter > 4'd0) begin
                    convSum <= convSum + idata*kernel[counter];
                end
                counter <= counter + 4'd1;
                // 請求下一個對應像素進行空洞卷積
                // request the next corresponding pixel for Atrous convolution
                case (counter) // -> for y axis (row)
                    0,1,2: iaddr[11:6] <= ((center[11:6] == 6'd0))? ZERO : cy_minus2;             // (0,0) , (0,1) , (0,2)
                    3,4,5: iaddr[11:6] <= center[11:6];                                                                     // (1,0) , (1,1) , (1,2)
                    6,7,8: iaddr[11:6] <= ((center[11:6] == LENGTH))? LENGTH : cy_add2;  // (2,0) , (2,1) , (2,2)
                endcase

                case (counter) // -> for x axis (column)                                    
                    0,3,6: iaddr[5:0] <= ((center[5:0] == 6'd0))? ZERO : cx_minus2;                // (0,0) , (1,0) , (2,0)
                    1,4,7: iaddr[5:0] <= center[5:0];                                                                       // (0,1) , (1,1) , (2,1)
                    2,5,8: iaddr[5:0] <= ((center[5:0] == LENGTH))? LENGTH : cx_add2;     // (0,2) , (1,2) , (2,2)
                endcase
            end

            LAYER0_WRITERELU: begin
                csel <= 1'd0;
                crd <= 1'd0;
                cwr <= 1'd1;
                caddr_wr <= center;
                cdata_wr <= (convSum[25])? 13'd0 : convSum[16:4]; // ReLU
                // 初始化 convSum 和中心 --> 內核移動到下一個中心並準備好進行空洞卷積
                // init the convSum and center --> kernel move to the next center and ready for atrous convolution
                convSum <= {{9{1'b1}}, bias, 4'd0};
                center <= center + 12'd1;
                counter <= 4'd0;
            end

            MAXPOOL_4PIXELS: begin
                csel <= 1'd0;
                crd <= 1'd1;
                cwr <= 1'd0;
                // counter==0 表示此循環將發送對第一個像素值的請求，否則比較開始
                // counter==0 means this cycle would send request for 1st pixel value, else comparison starts
                if (counter==0) begin
                    cdata_wr <= 13'd0;
                end
                else if (cdata_rd > cdata_wr) begin 
                    cdata_wr <= cdata_rd;
                end
                counter <= counter + 4'd1;
                // 請求對應地址的像素值
                // request the corresponding address' pixel value 
                case(counter) // -> for y axis  (row)
                    0,1: caddr_rd[11:6] <= {center[9:5], 1'd0};
                    2,3: caddr_rd[11:6] <= {center[9:5], 1'd1};
                endcase

                case(counter) // -> for x axis  (column)
                    0,2: caddr_rd[5:0] <= {center[4:0], 1'd0};
                    1,3: caddr_rd[5:0] <= {center[4:0], 1'd1};
                endcase
            end

            LAYER1_WRITECEILING: begin
                csel <= 1'd1;
                crd <= 1'd0;
                cwr <= 1'd1;
                caddr_wr <= center;
                cdata_wr <= { cdata_wr[12:4] + {8'd0,|cdata_wr[3:0]} , 4'd0 }; // Round up
                // 為下一個中心初始化 -> 內核移動到下一個中心
                // init for next center -> kernel move to the next center
                center <= center + 12'd1; 
                counter <= 4'd0;
            end

            FINISH: begin
                busy <= 1'd0;
            end

        endcase
    end
end

endmodule