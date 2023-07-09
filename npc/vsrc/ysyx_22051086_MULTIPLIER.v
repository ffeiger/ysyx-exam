module ysyx_22051086_MULTIPLIER(
    input         clk,
    input         rst,
    input         mul_valid,
    input         flush,
    input         mulw,
    input         mul_signed,
    input [63:0]  multiplicand,
    input [63:0]  multiplier,
    output        mul_ready,
    output        out_valid,
    output [63:0] result_hi,
    output [63:0] result_lo
);

parameter IDLE = 2'b00;
parameter RUN = 2'b01;
parameter RUNW = 2'b10;
parameter WAIT = 2'b11;
reg [1:0] cur_state;
reg [1:0] next_state;

always @(posedge clk) 
	if (rst || flush)
		cur_state <= IDLE;
	else
		cur_state <= next_state;

always @(*)begin
    case(cur_state)
    IDLE:
    begin
        if(mul_valid && !mulw)    
            next_state = RUN;
        else if(mul_valid && mulw)
            next_state = RUNW;
        else
            next_state = IDLE;
    end
    RUN:
    begin
        if(counter == 6'b100000)  //to do
            next_state = WAIT;
        else
            next_state = RUN;
    end
    RUNW:
    begin
        if(wcounter == 5'b10000) // to do
            next_state = WAIT;
        else
            next_state = RUNW;
    end
    WAIT:
    begin
        next_state = IDLE;
    end
    endcase
end

//counter wcounter
reg [5:0] counter;
reg [4:0] wcounter;
always @(posedge clk)begin
    if(cur_state == IDLE)
        counter <= 6'b0;
    else if(cur_state == RUN)
        counter <= counter + 1;
    else
        counter <= 6'b0;
end
always @(posedge clk)begin
    if(cur_state == IDLE)
        wcounter <= 5'b0;
    else if(cur_state == RUNW)
        wcounter <= wcounter + 1;
    else
        wcounter <= 5'b0;
end
//idle
reg         reg_mulw;
reg [131:0] reg_multiplicand;
reg [65:0] reg_multiplier;
reg [67:0] reg_multiplicand_w;
reg [33:0] reg_multiplier_w;
always @(posedge clk)begin
    if(cur_state == IDLE && mul_valid && !mulw && mul_signed)begin
        reg_multiplicand <= {{68{multiplicand[63]}},multiplicand};
        reg_multiplier <= {multiplier[63],multiplier,1'b0};
    end
    else if(cur_state == IDLE && mul_valid && !mulw && !mul_signed)begin
        reg_multiplicand <= {{68{1'b0}},multiplicand};
        reg_multiplier <= {1'b0,multiplier,1'b0};
    end
    else if(cur_state == IDLE && mul_valid && mulw && mul_signed)begin
        reg_multiplicand_w <= {{36{multiplicand[31]}},multiplicand[31:0]};
        reg_multiplier_w <= {multiplier[31],multiplier[31:0],1'b0};
    end
    else if(cur_state == IDLE && mul_valid && mulw && !mul_signed)begin
        reg_multiplicand_w <= {{36{1'b0}},multiplicand[31:0]};
        reg_multiplier_w <= {1'b0,multiplier[31:0],1'b0};
    end
    else if(cur_state == RUNW)begin
        reg_multiplier_w <= reg_multiplier_w >> 2;
        reg_multiplicand_w <= reg_multiplicand_w << 2;
    end
    else if(cur_state == RUN)begin
        reg_multiplier <= reg_multiplier >> 2;
        reg_multiplicand <= reg_multiplicand << 2;
    end
end
always @ (posedge clk) begin
    if(cur_state == IDLE && mul_valid)begin
        reg_mulw <= mulw;
       // reg_mul_signed <= mul_signed;
    end
end
//runw
reg [67:0] res_w;
always @(posedge clk)begin
    if(cur_state == IDLE)
        res_w <= 68'b0;
    else if(cur_state == RUNW)
        res_w <= res_w + p_w + c_w;
end
//wire [67:0] reg_multiplicand_w_bu = reg_multiplicand_w[67] ?  ~reg_multiplicand_w +1 :reg_multiplicand_w;
wire [67:0] p_w = ~(~({68{sel_negative_w}} & ~reg_multiplicand_w) & ~({68{sel_double_negative_w}} & ~(reg_multiplicand_w << 1)) 
                & ~({68{sel_positive_w}} & reg_multiplicand_w ) & ~({68{sel_double_positive_w}} & (reg_multiplicand_w<< 1)));
wire [67:0] c_w = (sel_negative_w || sel_double_negative_w) ? {67'b0,1'b1}:0;
wire y_add_w,y_w,y_sub_w;
assign {y_add_w,y_w,y_sub_w} = reg_multiplier_w[2:0];
wire sel_negative_w =  y_add_w & (y_w & ~y_sub_w | ~y_w & y_sub_w);
wire sel_positive_w = ~y_add_w & (y_w & ~y_sub_w | ~y_w & y_sub_w);
wire sel_double_negative_w =  y_add_w & ~y_w & ~y_sub_w;
wire sel_double_positive_w = ~y_add_w &  y_w &  y_sub_w;
//run
//wire [131:0] reg_multiplicand_bu = reg_multiplicand[131] ?  ~reg_multiplicand +1 :reg_multiplicand;
reg [131:0] res;
always @(posedge clk)begin
    if(cur_state == IDLE)
        res <= 132'b0;
    else if(cur_state == RUN)
        res <= res + p + c;
end
wire [131:0] p = ~(~({132{sel_negative}} & ~reg_multiplicand) & ~({132{sel_double_negative}} & ~(reg_multiplicand << 1)) 
                & ~({132{sel_positive}} & reg_multiplicand) & ~({132{sel_double_positive}} & (reg_multiplicand << 1)));
wire [131:0] c = (sel_negative || sel_double_negative) ? {131'b0,1'b1}:0;
wire y_add,y,y_sub;
assign {y_add,y,y_sub} = reg_multiplier[2:0];
wire sel_negative =  y_add & (y & ~y_sub | ~y & y_sub);
wire sel_positive = ~y_add & (y & ~y_sub | ~y & y_sub);
wire sel_double_negative =  y_add & ~y & ~y_sub;
wire sel_double_positive = ~y_add &  y &  y_sub;

//wait
assign result_hi = reg_mulw ? {{32{res_w[63]}},res_w[63:32]} : res[127:64];
assign result_lo = reg_mulw ? {{32{res_w[31]}},res_w[31:0]} : res[63:0];
assign out_valid = cur_state == WAIT;
assign mul_ready = cur_state == IDLE;

endmodule
