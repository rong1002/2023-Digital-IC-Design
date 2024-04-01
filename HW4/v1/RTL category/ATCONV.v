`timescale 1ns/10ps
module  ATCONV(
    input        clk,
    input        reset,
    output reg   busy,
    input        ready,

    output reg    [11:0] iaddr,
    input  signed [12:0] idata,

    output reg        cwr,
    output reg [11:0] caddr_wr,
    output reg [12:0] cdata_wr,
    
    output reg        crd,
    output reg [11:0] caddr_rd,
    input      [12:0] cdata_rd,
    
    output reg csel
    );

//=================================================
//            write your design below
//=================================================
localparam CONV    = 2'd0;
localparam LAYER0  = 2'd1;
localparam LAYER1  = 2'd2;
localparam DONE    = 2'd3;
reg [1:0] currState, nextState;
reg [3:0] fsm_o;
wire l_CONV, l_LAYER0, l_LAYER1, l_DONE;

reg [5:0] left_index [0:2];
reg [5:0] right_index[0:2];

reg [11:0] addr_stack[0:2];
reg [17:0] conv_stack[0:2];
reg [17:0] data_stack[0:2];

reg [1:0] addr_count;
reg [1:0] stack_count;
reg [1:0] shift_count;

reg [11:0] addr;
reg [11:0] next_addr;

reg down_shift;
reg [1:0] right_shift;

reg [12:0] roundup;
reg [11:0] layer0_addr;
reg [11:0] layer1_addr;

wire [11:0] shift_stack[0:3];
assign shift_stack[0] = 12'd0;
assign shift_stack[1] = 12'd1;
assign shift_stack[2] = 12'd64;
assign shift_stack[3] = 12'd65;


integer i;
////////////////////////FSM/////////////////////////
always @(*) begin
    case (currState)
        CONV   : nextState = (addr_count == 2)     ? LAYER0 : CONV;
        LAYER0 : nextState = (addr_count == 2)     ? LAYER1 : LAYER0;
        LAYER1 : nextState = (layer1_addr == 4095) ? DONE   : CONV;
        DONE   : nextState = DONE;
        default: nextState = CONV;
    endcase
end

always @(posedge clk or posedge reset) begin
    currState <= (reset) ? CONV : nextState;
end

always @(*) begin
    case (currState)
        CONV   : fsm_o = 4'b1000;
        LAYER0 : fsm_o = 4'b0100;
        LAYER1 : fsm_o = 4'b0010;
        DONE   : fsm_o = 4'b0001;
        default: fsm_o = 4'b1111;
    endcase
end
assign {l_CONV, l_LAYER0, l_LAYER1, l_DONE} = fsm_o;

//////////////////////datapath//////////////////////

// left_index, right_index
always @(*) begin
    left_index [0] = (addr[11:6] < 6'd2) ? 6'd0 : addr[11:6] - 6'd2;
    right_index[0] = (addr[ 5:0] < 6'd2) ? 6'd0 : addr[ 5:0] - 6'd2;
    left_index [1] = addr[11:6];
    right_index[1] = addr[ 5:0];
    left_index [2] = (addr[11:6] > 6'd61) ? 6'd63 : addr[11:6] + 6'd2;
    right_index[2] = (addr[ 5:0] > 6'd61) ? 6'd63 : addr[ 5:0] + 6'd2;
end

// addr_stack
always @(*) begin 
    if (l_CONV)begin
        case (right_shift)
            2'd0: begin
                addr_stack[0] = {left_index[0], right_index[0]};
                addr_stack[1] = {left_index[1], right_index[0]};
                addr_stack[2] = {left_index[2], right_index[0]};
            end
            2'd1: begin
                addr_stack[0] = {left_index[0], right_index[1]};
                addr_stack[1] = {left_index[1], right_index[1]};
                addr_stack[2] = {left_index[2], right_index[1]};
            end
            default: begin
                addr_stack[0] = {left_index[0], right_index[2]};
                addr_stack[1] = {left_index[1], right_index[2]};
                addr_stack[2] = {left_index[2], right_index[2]};
            end
        endcase
    end
    else begin
        for (i = 0; i < 3; i = i + 1) addr_stack [i] = 6'd1;
    end
end

// conv_stack
always@(posedge clk or posedge reset)begin
    if(reset)begin
        for(i = 0; i < 3; i = i + 1) conv_stack[i] <= 0;
    end
    else if (l_CONV) begin
        if(addr_count == 2'd0)begin
            conv_stack[0] <= data_stack[1];
            conv_stack[1] <= data_stack[2];
            conv_stack[2] <= 0;
        end
    
        else begin
            for(i = 0; i < 3; i = i + 1) conv_stack[i] <= data_stack[i];
        end
    end
end

// data_stack
always@(*)begin
    if (reset) begin
        for(i = 0; i < 3; i = i + 1) data_stack[i] = 18'd0;
    end
    else if (l_CONV || l_LAYER0) begin
        case(stack_count)
            2'd1: begin
                data_stack[0] = conv_stack[0] - idata;
                data_stack[1] = conv_stack[1] - (idata << 1);
                data_stack[2] = conv_stack[2] - idata;
            end
            2'd2: begin
                data_stack[0] = conv_stack[0] - (idata << 2);
                data_stack[1] = conv_stack[1] + (idata << 4);
                data_stack[2] = conv_stack[2] - (idata << 2);
            end
            2'd0: begin
                data_stack[0] = conv_stack[0] - idata - 18'd192;
                data_stack[1] = conv_stack[1] - (idata << 1);
                data_stack[2] = conv_stack[2] - idata;
            end
            default: begin
                for(i = 0; i < 3; i = i + 1) data_stack[i] = data_stack[i];
            end
        endcase
    end
    else begin
        for(i = 0; i < 3; i = i + 1) data_stack[i] = data_stack[i];
    end
end

// stack_count
always @(posedge clk or posedge reset) begin
    if (reset) begin
        stack_count <= 2'd0;
    end

    else if (l_CONV)begin
        case (stack_count)
            2'd0, 2'd1: begin
                stack_count <= stack_count + 2'd1;
            end
            default: begin
                stack_count <= 2'd0;
            end
        endcase
    end
end

// addr_count
always @(posedge clk or posedge reset) begin
    if (reset) begin
        addr_count <= 2'd0;
    end

    else if (l_CONV)begin
        case (addr_count)
            2'd0, 2'd1: begin
                addr_count <= addr_count + 2'd1;
            end
            default: begin
                addr_count <= addr_count;
            end
        endcase
    end
    else if(l_LAYER1) begin
        addr_count <= 2'd0;
    end
end

// iaddr
always@(posedge clk or posedge reset)begin
    if(reset) iaddr <= 12'd0;
    else if (l_CONV) iaddr <= addr_stack[addr_count];

end

//down_shift,
always@(posedge clk or posedge reset)begin
    if (reset) down_shift <= 1'b0;
    else if (l_CONV) down_shift <= (addr[5:0] > 6'd61) ? 1'b1 : 1'b0;
end

// next_addr
always@(posedge clk or posedge reset)begin
    if (reset) begin
        next_addr  <= 12'd0;
    end
    else if (l_CONV) begin
        if(addr[5:0] > 6'd61) begin
            next_addr <= (addr[11:6] > 6'd61) ? shift_stack[shift_count + 2'd1] : addr + 12'd66;
        end
        else begin
            next_addr <= addr + 12'd2;
        end 
    end
end

// addr, right_shift
always @(posedge clk or posedge reset) begin
    if (reset) begin
        addr <= 12'd0;
        right_shift <= 2'd0;
    end
    else if (l_CONV)begin
        if (addr_count == 2'd2) begin
            if(right_shift == 2'd2)begin
                addr <= next_addr; 
                right_shift <= (down_shift) ? 2'd0 : right_shift;
            end
            else begin
                right_shift <= right_shift + 2'd1;
            end
        end
    end
end

// roundup
always@(*)begin
    if (reset) roundup = 0;
    else if(layer0_addr == layer1_addr) roundup = 0; 
    else roundup = (cdata_wr[3:0] > 4'd0) ? {cdata_wr[12:4] + 9'd1, 4'd0} : {cdata_wr[12:4], 4'b0000};
end

// shift_count
always @(posedge clk or posedge reset) begin
    if (reset) begin
        shift_count <= 2'd0;
    end
    else if(l_LAYER1) begin
        shift_count <= (layer0_addr < layer1_addr) ? shift_count + 2'd1 : shift_count;
    end

end

// layer0_addr
always @(posedge clk or posedge reset) begin
    if (reset) begin
        layer0_addr <= 12'd0;
    end
    else if (l_LAYER0) begin
        layer0_addr <= addr;
    end
end

// layer1_addr
always @(posedge clk or posedge reset) begin
    if (reset) begin
        layer1_addr <= 12'd0;
    end
    else if (l_LAYER1) begin
        layer1_addr <= layer0_addr;
    end
end

// cwr, crd, csel
always @(posedge clk or posedge reset) begin
    if (reset) begin
        cwr  <= 1'd0;
        crd  <= 1'd0;
        csel <= 1'd0;
    end
    else if (l_LAYER0) begin
        cwr  <= 1'd1;
        crd  <= 1'd0;
        csel <= 1'd0;
    end
    else if (l_LAYER1) begin
        cwr  <= 1'd1;
        crd  <= 1'd0;
        csel <= 1'd1;
    end
    else begin
        cwr  <= 1'd0;
        crd  <= 1'd1;
        csel <= 1'd1;
    end
end

// caddr_rd
always @(posedge clk or posedge reset) begin
    if (reset) begin
        caddr_rd <= 12'd0;
    end
    else if (l_CONV)begin
        caddr_rd <= (addr_count == 2'd2) ? {2'b00, layer0_addr[11:7], layer0_addr[5:1]} : caddr_rd;
    end
end

//caddr_wr, cdata_wr
always @(posedge clk or posedge reset) begin
    if (reset) begin
        caddr_wr <= 12'd0;
        cdata_wr <= 13'd0;
    end
    else if (l_LAYER0) begin
        caddr_wr <= layer0_addr;
        cdata_wr <= (data_stack[0][17]) ? 13'd0 : data_stack[0][16:4];
    end
    else if (l_LAYER1) begin
        caddr_wr <= {2'b00, layer1_addr[11:7], layer1_addr[5:1]};
        cdata_wr <= (shift_count == 2'd0 || roundup > cdata_rd) ? roundup : cdata_rd;
    end
end

//busy
always @(posedge clk or posedge reset) begin
    if (reset) begin
        busy <= 1'd0;
    end
    else if(ready) begin
        busy <= 1'd1;
    end
    else if (l_DONE)begin
        busy <= 1'd0;
    end
end

endmodule