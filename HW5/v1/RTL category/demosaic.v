module demosaic(clk, reset, in_en, data_in, wr_r, addr_r, wdata_r, rdata_r, wr_g, addr_g, wdata_g, rdata_g, wr_b, addr_b, wdata_b, rdata_b, done);
input clk;
input reset;
input in_en;
input [7:0] data_in;
output reg wr_r;
output reg [13:0] addr_r;
output reg [7:0] wdata_r;
input [7:0] rdata_r;
output reg wr_g;
output reg [13:0] addr_g;
output reg [7:0] wdata_g;
input [7:0] rdata_g;
output reg wr_b;
output reg [13:0] addr_b;
output reg [7:0] wdata_b;
input [7:0] rdata_b;
output reg done;

localparam INIT = 4'd0;
localparam DATA_IN   = 4'd1;
localparam STACK     = 4'd2;
localparam DONE    = 4'd3;
localparam RESET   = 4'd4;

reg [2:0] currState, nextState;
reg [4:0] fsm_o;
wire l_INIT, l_DATA_IN, l_STACK, l_DONE, l_RESET;
reg [2:0] stack_count;
reg [13:0] addr_count;
integer i;
////////////////////////FSM/////////////////////////
always @(*) begin
    case (currState)
        INIT:    nextState = (reset == 0) ? DATA_IN : INIT;
        DATA_IN: nextState = (in_en == 0) ? STACK     : DATA_IN;
        STACK:   nextState = (addr_count == 14'd16255) ? DONE : STACK;
        DONE:    nextState =  DONE;
        RESET:   nextState = RESET;
        default: nextState = INIT;
    endcase
end

always @(posedge clk or posedge reset) begin
    if (reset) currState <= INIT;
    else currState     <= nextState;
end

always @(*) begin
    case (currState)
        INIT:    fsm_o = 5'b10000;
        DATA_IN: fsm_o = 5'b01000;
        STACK:   fsm_o = 5'b00100;
        DONE:    fsm_o = 5'b00010;
        RESET:   fsm_o = 5'b00001;
        default: fsm_o = 5'b00000;
    endcase
end

assign {l_INIT, l_DATA_IN, l_STACK, l_DONE, l_RESET} = fsm_o;

//////////////////////datapath//////////////////////
reg row_count;
reg [7:0] col_count;
// row_count
always @(posedge clk or posedge reset) begin
    if (reset) row_count <= 2'd0;
    else if (l_DATA_IN) begin
        if (col_count == 8'd127) row_count <= row_count + 2'd1;
        else if (col_count == 8'd255) row_count <= 2'd0;
        else row_count <= row_count;
    end
    else if (l_STACK) begin
        if (stack_count == 3'd5) begin
            if (col_count == 8'd127) row_count <= row_count + 2'd1;
            else if (col_count == 8'd255) row_count <= 2'd0;
            else row_count <= row_count;
        end
        else row_count <= row_count;
    end
end

// col_count
always @(posedge clk or posedge reset) begin
    if (reset) col_count <= 8'd0;
    else if (l_DATA_IN) begin
        if (col_count == 8'd255) col_count <= 8'd0;
        else col_count <= col_count + 8'd1;
    end
    else if (l_STACK) begin
        if (stack_count == 3'd5) col_count <= (col_count == 8'd255) ? 8'd0 : col_count + 8'd1;
        else row_count <= row_count;
    end
end

reg row0_count;
reg row1_count;
// row0_count
always @(posedge clk or posedge reset) begin
    if (reset) row0_count <= 2'd0;
    else if (l_DATA_IN && row_count == 0) row0_count <= (row0_count == 2'd1) ? 0 : row0_count + 2'd1;
    else if (l_STACK && row_count == 0) row0_count <= (stack_count == 3'd5) ? row0_count + 2'd1 : row0_count;
    else row0_count <= row0_count;
end

// row1_count
always @(posedge clk or posedge reset) begin
    if (reset) row1_count <= 2'd0;
    else if (l_DATA_IN && row_count == 1) row1_count <= (row1_count == 2'd1) ? 0 : row1_count + 2'd1;
    else if (l_STACK && row_count == 1) row1_count <= (stack_count == 3'd5) ? row1_count + 2'd1 : row1_count;
    else row1_count <= row1_count;
end


always @(posedge clk or posedge reset) begin
    if (reset) addr_count <= 14'd0;
    else if (l_STACK) addr_count <= (stack_count != 3'd5) ? addr_count : addr_count + 14'd1;
    else if (in_en == 0) addr_count <= 14'd128;
    else if (l_DATA_IN) addr_count <= addr_count + 14'd1;

end

reg [13:0] g_stack [0:3];
reg [13:0] r_stack [0:3];
reg [13:0] b_stack [0:3];

always @(*) begin
    if (reset) begin
        for (i=0; i<4; i = i+1) g_stack[i] = 14'd0;
        for (i=0; i<4; i = i+1) r_stack[i] = 14'd0;
        for (i=0; i<4; i = i+1) b_stack[i] = 14'd0;
    end
    
    else if (l_STACK) begin
        case (row_count)
            2'd0: begin
                case (row0_count)
                    2'd0: begin
                        g_stack[0] = addr_count - 14'd128;
                        g_stack[1] = addr_count + 14'd128;
                        g_stack[2] = addr_count - 14'd1;
                        g_stack[3] = addr_count + 14'd1;
                        r_stack[0] = addr_count - 14'd129;
                        r_stack[1] = addr_count - 14'd127;
                        r_stack[2] = addr_count + 14'd127;
                        r_stack[3] = addr_count + 14'd129;
                        b_stack[0] = addr_count;
                        b_stack[1] = 14'd0;
                        b_stack[2] = 14'd0;
                        b_stack[3] = 14'd0;
                    end
                    default: begin
                        g_stack[0] = addr_count;
                        g_stack[1] = 14'd0;
                        g_stack[2] = 14'd0;
                        g_stack[3] = 14'd0;
                        r_stack[0] = addr_count - 14'd128;
                        r_stack[1] = addr_count + 14'd128;
                        r_stack[2] = 14'd0;
                        r_stack[3] = 14'd0;
                        b_stack[0] = addr_count - 14'd1;
                        b_stack[1] = addr_count + 14'd1;
                        b_stack[2] = 14'd0;
                        b_stack[3] = 14'd0;
                    end
                endcase
            end
            default: begin
                case (row1_count)
                2'd0: begin
                    g_stack[0] = addr_count;
                    g_stack[1] = 14'd0;
                    g_stack[2] = 14'd0;
                    g_stack[3] = 14'd0;
                    r_stack[0] = addr_count - 14'd1;
                    r_stack[1] = addr_count + 14'd1;
                    r_stack[2] = 14'd0;
                    r_stack[3] = 14'd0;
                    b_stack[0] = addr_count - 14'd128;
                    b_stack[1] = addr_count + 14'd128;
                    b_stack[2] = 14'd0;
                    b_stack[3] = 14'd0;
                end
                default: begin
                    g_stack[0] = addr_count - 14'd128;
                    g_stack[1] = addr_count + 14'd128;
                    g_stack[2] = addr_count - 14'd1;
                    g_stack[3] = addr_count + 14'd1;
                    r_stack[0] = addr_count;
                    r_stack[1] = 14'd0;
                    r_stack[2] = 14'd0;
                    r_stack[3] = 14'd0;
                    b_stack[0] = addr_count - 14'd129;
                    b_stack[1] = addr_count - 14'd127;
                    b_stack[2] = addr_count + 14'd127;
                    b_stack[3] = addr_count + 14'd129;

                end
            endcase
            end
        endcase
    end
    
    else begin
        for (i=0; i<4; i = i+1) g_stack[i] = 14'd0;
        for (i=0; i<4; i = i+1) r_stack[i] = 14'd0;
        for (i=0; i<4; i = i+1) b_stack[i] = 14'd0;
    end

end

reg [7:0] g_data [0:3];
reg [7:0] r_data [0:3];
reg [7:0] b_data [0:3];

always @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i=0; i<4; i = i+1) g_data[i] <= 8'd0;
        for (i=0; i<4; i = i+1) r_data[i] <= 8'd0;
        for (i=0; i<4; i = i+1) b_data[i] <= 8'd0;
    end
    else if (l_STACK) begin
        g_data[stack_count - 1] <= (g_stack[stack_count - 1] == 14'd0) ? 8'd0 : rdata_g;
        r_data[stack_count - 1] <= (r_stack[stack_count - 1] == 14'd0) ? 8'd0 : rdata_r;
        b_data[stack_count - 1] <= (b_stack[stack_count - 1] == 14'd0) ? 8'd0 : rdata_b;
    end
        
end

// stack_count
always @(posedge clk or posedge reset) begin
    if (reset) begin
        stack_count <= 3'd0;
    end
    else if (l_STACK) begin

        stack_count <= (stack_count == 3'd5) ? 3'd0 : stack_count + 3'd1;
    end
end


reg [14:0] g_done;
reg [14:0] r_done;
reg [14:0] b_done;

always @(*) begin
    if (reset) begin
        g_done = 8'd0;
        r_done = 8'd0;
        b_done = 8'd0;
    end
    else if (l_STACK && stack_count == 3'd5) begin
        case (row_count) 
            2'd0:begin
                case (row0_count)
                2'd0: begin
                    g_done = (g_data[0] + g_data[1] + g_data[2] + g_data[3]) >> 2;
                    r_done = (r_data[0] + r_data[1] + r_data[2] + r_data[3]) >> 2;
                    b_done = b_data[0];
                end
                default : begin
                    g_done = g_data[0];
                    r_done = (r_data[0] + r_data[1]) >> 1;
                    b_done = (b_data[0] + b_data[1]) >> 1;
                end
                endcase
            end
            default: begin
                case (row1_count)
                2'd0: begin
                    g_done = g_data[0];
                    r_done = (r_data[0] + r_data[1]) >> 1;
                    b_done = (b_data[0] + b_data[1]) >> 1;
                end
                default : begin
                    g_done = (g_data[0] + g_data[1] + g_data[2] + g_data[3]) >> 2;
                    r_done = r_data[0];
                    b_done = (b_data[0] + b_data[1] + b_data[2] + b_data[3]) >> 2;
                end
                endcase
            end
        endcase

    end
    else begin
        g_done = 8'd0;
        r_done = 8'd0;
        b_done = 8'd0;
    end
end


// addr_g, addr_r, addr_b
always @(negedge clk or posedge reset) begin
    if (reset) begin
        addr_g <= 14'd0;
        addr_r <= 14'd0;
        addr_b <= 14'd0;
    end
    else if (l_DATA_IN || stack_count == 3'd5) begin
        addr_g <= addr_count;
        addr_r <= addr_count;
        addr_b <= addr_count;
    end
    else if (l_STACK) begin
        addr_g <= g_stack[stack_count];
        addr_r <= r_stack[stack_count];
        addr_b <= b_stack[stack_count];
    end
end

// wr_g
always @(negedge clk or posedge reset) begin
    if (reset) begin
        wr_g <= 2'd0;
        wr_r <= 2'd0;
        wr_b <= 2'd0;
    end
    else if (l_DATA_IN) begin
        wr_g <= 2'd1;
        wr_r <= 2'd1;
        wr_b <= 2'd1;
    end
    else if (l_STACK && stack_count == 3'd5) begin
        wr_g <= 2'd1;
        wr_r <= 2'd1;
        wr_b <= 2'd1;
    end
    else begin
        wr_g <= 2'd0;
        wr_r <= 2'd0;
        wr_b <= 2'd0;
    end
        
end

// wdata_g, wdata_r, wdata_b
always @(negedge clk or posedge reset) begin
    if (reset) begin
        wdata_g <= 8'd0;
        wdata_r <= 8'd0; 
        wdata_b <= 8'd0; 
    end
    else if (l_DATA_IN) begin
        wdata_g <= 8'd0;
        wdata_r <= 8'd0;
        wdata_b <= 8'd0;

        case (row_count)
            2'd0: begin
                case (row0_count)
                    2'd0: begin
                        wdata_g <= data_in;
                        wdata_r <= 8'd0;
                        wdata_b <= 8'd0;
                    end
                    default: begin
                        wdata_g <= 8'd0;
                        wdata_r <= data_in;
                        wdata_b <= 8'd0;
                    end
                endcase
            end

            default: begin
                case (row1_count)
                2'd0: begin
                    wdata_g <= 8'd0;
                    wdata_r <= 8'd0;
                    wdata_b <= data_in;
                end
                default: begin
                    wdata_g <= data_in;
                    wdata_r <= 8'd0;
                    wdata_b <= 8'd0;
                end
            endcase
            end
        endcase
    end

    else if (l_STACK && stack_count == 3'd5) begin
        wdata_g <= g_done;
        wdata_r <= r_done;
        wdata_b <= b_done;
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        done <= 2'd0;
    end
    else if (l_DONE) begin
        done <= 2'd1;
    end
end

endmodule
