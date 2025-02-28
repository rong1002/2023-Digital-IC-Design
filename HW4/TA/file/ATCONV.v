module  ATCONV(
    input        clk,
    input        reset,
    output reg   busy,    
    input        ready,    
            
    output reg   [11:0] iaddr,
    input signed [12:0] idata,
    
    output reg          cwr,
    output reg   [11:0] caddr_wr,
    output reg   [12:0] cdata_wr,
    output reg          crd,
    output reg   [11:0] caddr_rd,
    input        [12:0] cdata_rd,
    output reg          csel
    );

localparam INIT                = 3'd0;
localparam ATCONV_9PIXELS      = 3'd1;
localparam LAYER0_WRITERELU    = 3'd2;
localparam MAXPOOL_4PIXELS     = 3'd3;
localparam LAYER1_WRITECEILING = 3'd4;
localparam FINISH              = 3'd5;

reg [2:0] currState, nextState;
reg [5:0] fsm_o;
wire l_INIT, l_ATCONV_9PIXELS, l_LAYER0_WRITERELU, l_MAXPOOL_4PIXELS, l_LAYER1_WRITECEILING, l_FINISH;


//kernel & bias
wire signed [12:0] kernel [1:9];
assign kernel[1] = 13'h1FFF; 
assign kernel[2] = 13'h1FFE; 
assign kernel[3] = 13'h1FFF;
assign kernel[4] = 13'h1FFC; 
assign kernel[5] = 13'h0010; 
assign kernel[6] = 13'h1FFC;
assign kernel[7] = 13'h1FFF; 
assign kernel[8] = 13'h1FFE; 
assign kernel[9] = 13'h1FFF;

wire signed [12:0] bias;
assign bias = 13'h1FF4;

//regs
reg [11:0] center; // Coordinate (row, column) = (center[11:6], center[5:0])
reg [ 3:0] counter; 
reg signed [25:0] convSum; // {mul_integer(18bits), mul_fraction(8bits)}

//constant param
localparam LENGTH = 6'd63;
localparam ZERO = 6'd0; 

//wire constants
wire [5:0] cx_add2;
wire [5:0] cx_minus2;
wire [5:0] cy_add2;
wire [5:0] cy_minus2;
assign cy_add2   = center[11:6] + 6'd2;
assign cy_minus2 = center[11:6] - 6'd2;
assign cx_add2   = center[ 5:0] + 6'd2;
assign cx_minus2 = center[ 5:0] - 6'd2;

////////////////////////FSM/////////////////////////
always @(*) begin
    case (currState)
        INIT:                nextState = (ready)                ? ATCONV_9PIXELS      : INIT;
        ATCONV_9PIXELS:      nextState = (counter  == 4'd9)     ? LAYER0_WRITERELU    : ATCONV_9PIXELS;
        LAYER0_WRITERELU:    nextState = (center   == 12'd4095) ? MAXPOOL_4PIXELS     : ATCONV_9PIXELS;
        MAXPOOL_4PIXELS:     nextState = (counter  == 4'd4)     ? LAYER1_WRITECEILING : MAXPOOL_4PIXELS;
        LAYER1_WRITECEILING: nextState = (caddr_wr == 12'd1023) ? FINISH              : MAXPOOL_4PIXELS; 
        FINISH:              nextState = FINISH;
        default:             nextState = INIT;
    endcase
end

always @(posedge clk or posedge reset) begin
    if (reset) currState <= INIT;
    else currState       <= nextState;
end

always @(*) begin
    case (currState)
        INIT:                fsm_o = 6'b100000;
        ATCONV_9PIXELS:      fsm_o = 6'b010000;
        LAYER0_WRITERELU:    fsm_o = 6'b001000;
        MAXPOOL_4PIXELS:     fsm_o = 6'b000100;
        LAYER1_WRITECEILING: fsm_o = 6'b000010;
        FINISH:              fsm_o = 6'b000001;
        default:             fsm_o = 6'b000000;
    endcase
end

assign {l_INIT, l_ATCONV_9PIXELS, l_LAYER0_WRITERELU, l_MAXPOOL_4PIXELS, l_LAYER1_WRITECEILING, l_FINISH} = fsm_o;

//////////////////////datapath//////////////////////
// busy
always @(posedge clk or posedge reset) begin
    if (reset) begin
        busy <= 1'd0;
    end

    else if (l_INIT) begin
        if (ready) busy <= 1'd1;
    end

    else if (l_FINISH) begin
        busy <= 1'd0;
    end
end

// csel, crd, cwr
always @(posedge clk or posedge reset) begin
    if (reset) begin
        csel <= 1'd0;
        crd  <= 1'd1;
        cwr  <= 1'd0;
    end

    else if (l_ATCONV_9PIXELS) begin
        csel <= 1'd0;
        crd  <= 1'd1;
        cwr  <= 1'd0;
    end

    else if (l_LAYER0_WRITERELU) begin
        csel <= 1'd0;
        crd  <= 1'd0;
        cwr  <= 1'd1;
    end

    else if (l_MAXPOOL_4PIXELS) begin
        csel <= 1'd0;
        crd  <= 1'd1;
        cwr  <= 1'd0;
    end

    else if (l_LAYER1_WRITECEILING) begin
        csel <= 1'd1;
        crd  <= 1'd0;
        cwr  <= 1'd1;
    end
end

// counter
always @(posedge clk or posedge reset) begin
    if (reset) begin
        counter <= 4'd0;
    end

    else if (l_ATCONV_9PIXELS || l_MAXPOOL_4PIXELS) begin
        counter <= counter + 4'd1;
    end
    else if (l_LAYER0_WRITERELU || l_LAYER1_WRITECEILING) begin
        counter <= 4'd0;
    end
end

// center
always @(posedge clk or posedge reset) begin
    if (reset) begin
        center <= {6'd0 , 6'd0};
    end

    else if (l_LAYER0_WRITERELU || l_LAYER1_WRITECEILING) begin
        center <= center + 12'd1;
    end
end

// iaddr
always @(posedge clk or posedge reset) begin
    if (reset) begin
        iaddr <= 12'd0;
    end

    else if (l_ATCONV_9PIXELS) begin
        // request the next corresponding pixel for Atrous convolution
        case (counter) // -> for y axis    (row)
            0,1,2: iaddr[11:6] <= ((center[11:6] == 6'd0) || (center[11:6] == 6'd1))? ZERO : cy_minus2;                // (0,0) , (0,1) , (0,2)
            3,4,5: iaddr[11:6] <= center[11:6];                                                                        // (1,0) , (1,1) , (1,2)
            6,7,8: iaddr[11:6] <= ((center[11:6] == LENGTH - 6'd1) || (center[11:6] == LENGTH))? LENGTH : cy_add2;    // (2,0) , (2,1) , (2,2)
        endcase

        case (counter) // -> for x axis    (column)                                    
            0,3,6: iaddr[5:0] <= ((center[5:0] == 6'd0) || (center[5:0] == 6'd1))? ZERO : cx_minus2;                // (0,0) , (1,0) , (2,0)
            1,4,7: iaddr[5:0] <= center[5:0];                                                                        // (0,1) , (1,1) , (2,1)
            2,5,8: iaddr[5:0] <= ((center[5:0] == LENGTH - 6'd1) || (center[5:0] == LENGTH))? LENGTH : cx_add2;        // (0,2) , (1,2) , (2,2)
        endcase
    end
end

// caddr_rd
always @(posedge clk or posedge reset) begin
    if (reset) begin
        caddr_rd <= 12'd0;
    end

    else if (l_MAXPOOL_4PIXELS) begin
        // request the corresponding address' pixel value 
        case(counter) // -> for y axis    (row)
            0,1: caddr_rd[11:6] <= {center[9:5], 1'd0};
            2,3: caddr_rd[11:6] <= {center[9:5], 1'd1};
        endcase

        case(counter) // -> for x axis    (column)
            0,2: caddr_rd[5:0] <= {center[4:0], 1'd0};
            1,3: caddr_rd[5:0] <= {center[4:0], 1'd1};
        endcase
    end
end

// convSum
always @(posedge clk or posedge reset) begin
    if (reset) begin
        convSum <= {{9{1'b1}}, bias, 4'd0}; // Sign extension
    end

    else if (l_ATCONV_9PIXELS) begin
        // use the pixel get and conv with corresponding kernel ( counter==0 means no pixel get yet )
        if(counter > 4'd0) begin
            convSum <= convSum + idata * kernel[counter];
        end
    end

    else if (l_LAYER0_WRITERELU) begin
        // init the convSum and center --> kernel move to the next center and ready for atrous convolution
        convSum <= {{9{1'b1}}, bias, 4'd0};
    end
end

// caddr_wr
always @(posedge clk or posedge reset) begin
    if (reset) begin
        caddr_wr <= 12'd0;
    end

    else if (l_LAYER0_WRITERELU) begin
        caddr_wr <= center;
    end

    else if (l_LAYER1_WRITECEILING) begin
        caddr_wr <= center;
    end
end

// cdata_wr
always @(posedge clk or posedge reset) begin
    if (reset) begin
        cdata_wr <= 13'd0;
    end

    else if (l_LAYER0_WRITERELU) begin
        cdata_wr <= (convSum[25])? 13'd0 : convSum[16:4]; // ReLU
    end
    
    else if (l_MAXPOOL_4PIXELS) begin
        // counter==0 means this cycle would send request for 1st pixel value, else comparison starts
        if (counter==0) begin
            cdata_wr <= 13'd0;
        end

        else if (cdata_rd > cdata_wr) begin 
            cdata_wr <= cdata_rd;
        end
    end

    else if (l_LAYER1_WRITECEILING) begin
        cdata_wr <= { cdata_wr[12:4] + {8'd0,|cdata_wr[3:0]} , 4'd0 }; // Round up
    end
end


endmodule