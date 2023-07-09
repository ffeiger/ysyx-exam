module ysyx_22051086_DIVIDER(
    input         clk,
    input         rst,
    input [63:0]  dividend,
    input [63:0]  divisor,
    input         div_valid,
    input         divw,
    input         div_signed,
    input         flush,
    output        div_ready,
    output        out_valid,
    output [63:0] quotient,
    output [63:0] remainder 
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
        if(div_valid && !divw)    
            next_state = RUN;
        else if(div_valid && divw)
            next_state = RUNW;
        else
            next_state = IDLE;
    end
    RUN:
    begin
        if(counter == 6'b111111)
            next_state = WAIT;
        else
            next_state = RUN;
    end
    RUNW:
    begin
        if(wcounter == 5'b11111)
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
end
always @(posedge clk)begin
    if(cur_state == IDLE)
        wcounter <= 5'b0;
    else if(cur_state == RUNW)
        wcounter <= wcounter + 1;
end
//idle 
/* verilator lint_off UNUSED */
wire [63:0] abs_dividend = dividend[63] ? ~dividend[63:0]+1:dividend[63:0] ;
wire [63:0] abs_divisor = divisor[63] ? ~divisor[63:0]+1:divisor[63:0];
reg [127:0]  reg_dividend;
reg [63:0]   reg_divisor;
wire [31:0] abs_dividend_w = dividend[31] ? ~dividend[31:0]+1:dividend[31:0] ;
wire [31:0] abs_divisor_w = divisor[31] ? ~divisor[31:0]+1:divisor[31:0];
reg [63:0]  reg_dividend_w;
reg [31:0]   reg_divisor_w;
reg          reg_divw;
reg          reg_div_signed;
reg [63:0]   reg_quotient;
//reg [63:0]   reg_remainder; 
always @(posedge clk)begin
    if(cur_state == IDLE && div_valid && !divw && !div_signed)begin
        reg_dividend <= {{64{1'b0}},dividend};
        reg_divisor <= divisor;
        reg_divw <= divw;
        reg_div_signed <= div_signed;
        reg_quotient <= 64'b0;
        //reg_remainder <= 64'b0;
    end
    else if(cur_state == IDLE && div_valid && !divw && div_signed)begin
        reg_dividend <= {{64{1'b0}},abs_dividend};
        reg_divisor <= abs_divisor;
        reg_divw <= divw;
        reg_div_signed <= div_signed;
        reg_quotient <= 64'b0;
        //reg_remainder <= 64'b0;
    end
    else if(cur_state == IDLE && div_valid && divw && !div_signed)begin
        reg_dividend_w <= {32'b0,dividend[31:0]};
        reg_divisor_w <= divisor[31:0];
        reg_divw <= divw;
        reg_div_signed <= div_signed;
        reg_quotient <= 64'b0;
        //reg_remainder <= 64'b0;
    end
    else if(cur_state == IDLE && div_valid && divw && div_signed)begin
        reg_dividend_w <= {32'b0,abs_dividend_w};
        reg_divisor_w <= abs_divisor_w[31:0];
        reg_divw <= divw;
        reg_div_signed <= div_signed;
        reg_quotient <= 64'b0;
        //reg_remainder <= 64'b0;
    end
    else if(cur_state == RUN && temp[64] == 1 )begin
        reg_quotient[63-counter] <= 0; 
        reg_dividend <= reg_dividend << 1;
    end
    else if(cur_state == RUN && temp[64] == 0 )begin
        reg_quotient[63-counter] <= 1;
        reg_dividend <= {temp[63:0],reg_dividend[62:0],1'b0};
    end
    else if(cur_state == RUNW && temp_w[32] == 1 )begin
        reg_quotient[31-wcounter] <= 0; 
        reg_dividend_w <= reg_dividend_w << 1;
    end
    else if(cur_state == RUNW && temp_w[32] == 0 )begin
        reg_quotient[31-wcounter] <= 1;
        reg_dividend_w <= {temp_w[31:0],reg_dividend_w[30:0],1'b0};
    end
end
reg res_minus_w;
reg res_minus;
always @(posedge clk)begin
    if(cur_state == IDLE && div_valid && divw )
        res_minus_w <= (dividend[31]!=divisor[31]);
    else if (cur_state == IDLE && div_valid && !divw )
        res_minus <= (dividend[63]!=divisor[63]);
end 
reg dividend_minus;
reg dividend_w_minus;
always @(posedge clk)begin
    if(cur_state == IDLE && div_valid && divw)
        dividend_w_minus <= dividend[31];
    else if(cur_state == IDLE && div_valid && !divw)
        dividend_minus <= dividend[63];
end
//run
wire [64:0] A = reg_dividend[127:63];
wire [64:0] B = ~{1'b0, reg_divisor} + 1;
wire [64:0] temp = A + B;
wire [32:0] A_w = reg_dividend_w[63: 31];
wire [32:0] B_w = ~{1'b0, reg_divisor_w[31:0]}+1;
wire [32:0] temp_w = A_w + B_w;
//wait
wire [63:0] unsigned_quotient;
wire [63:0] signed_quotient;
wire [63:0] unsigned_remainder;
wire [63:0] signed_remainder;
assign unsigned_quotient = reg_divw ? {{32{reg_quotient[31]}},reg_quotient[31:0]} : reg_quotient;
assign signed_quotient = (reg_divw && res_minus_w) ? {{32{1'b1}}, ~reg_quotient[31:0]+1}
                       : (reg_divw && !res_minus_w) ? {{32{reg_quotient[31]}},reg_quotient[31:0]}
                       : (!reg_divw && res_minus) ?  ~reg_quotient+1
                       : reg_quotient;
assign unsigned_remainder = reg_divw ? {{32{reg_dividend_w[63]}},reg_dividend_w[63:32]} : reg_dividend[127:64] ;
assign signed_remainder = (reg_divw && dividend_w_minus) ? {{32{1'b1}}, ~reg_dividend_w[63:32]+1}
                       : (reg_divw && !dividend_w_minus) ? {{32{reg_dividend_w[63]}},reg_dividend_w[63:32]}
                       : (!reg_divw && dividend_minus) ?  ~reg_dividend[127:64] +1
                       : reg_dividend[127:64] ;
assign div_ready = cur_state == IDLE;
assign out_valid = cur_state == WAIT;
assign quotient = reg_div_signed ? signed_quotient : unsigned_quotient;
assign remainder = reg_div_signed ? signed_remainder : unsigned_remainder;
endmodule
