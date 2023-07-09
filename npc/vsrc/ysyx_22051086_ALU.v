module ysyx_22051086_ALU (
    input       ex_valid,
    input       clk,
    input       rst,
    input [4:0] aluop,
    input [63:0] alu_src1,
    input [63:0] alu_src2,
    output [63:0] alu_res,
    output        alu_busy 
);

/* verilator lint_off UNUSED */
wire [63:0] add_sub_result; 
wire [63:0] slt_result; 
wire [63:0] sltu_result;
wire [63:0] and_result;
wire [63:0] or_result;
wire [63:0] xor_result;
wire [63:0] sll_result; 
wire [127:0] sr_result; 
wire [31:0] sllw_result; 
wire [63:0] srw_result;  
wire [63:0] slt_result;
wire [63:0] sltu_result;

//adder
/* verilator lint_off WIDTH */
wire [63:0] adder_a   = alu_src1;
wire [63:0] adder_b   = (aluop==5'b10001||aluop==5'b01011||aluop==5'b01100) ? ~alu_src2 : alu_src2;
wire adder_cin = (aluop==5'b10001||aluop==5'b01011||aluop==5'b01100) ? 1'b1      : 1'b0;
wire adder_cout;
assign {adder_cout, add_sub_result} = adder_a + adder_b + adder_cin;

//bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign xor_result = alu_src1 ^ alu_src2;

//shifter
assign sll_result = alu_src1 << alu_src2;
assign sr_result = {{64{~aluop[0] & alu_src1[63]}},alu_src1[63:0]} >> alu_src2;
assign sllw_result = alu_src1[31:0] << alu_src2;
assign srw_result ={{32{~aluop[4] & alu_src1[31]}} ,alu_src1[31:0]} >> alu_src2;


//slt or sltu
assign sltu_result[63:1]=63'b0;
assign sltu_result[0]=~adder_cout;
assign slt_result[63:1]=63'b0;
assign slt_result[0]=(alu_src1[63] & ~alu_src2[63]) | ((alu_src1[63] ~^ alu_src2[63]) & add_sub_result[63]);

//mulw or mul
wire mul_valid = op_mul && !mul_doing && !mul_out_valid && ex_valid && !mul_has_sent;
reg mul_doing;
reg mul_has_sent;
always @ (posedge clk)begin
    if(rst)
        mul_has_sent <= 1'b0;
    else if(mul_valid)
        mul_has_sent <= 1'b1;
    else if(!mul_doing)
        mul_has_sent <= 1'b0;
end
always @(posedge clk)begin
    if(rst)begin
        mul_doing <= 1'b0;
    end
    else if(mul_out_valid)begin
        mul_doing <= 1'b0;
    end
    else if(mul_valid && mul_ready)begin
        mul_doing <= 1'b1;
    end
end
wire op_mul = (aluop == 5'b01000 || aluop ==5'b01101);
wire op_mulw = aluop == 5'b01000;
wire op_mul_signed = (aluop == 5'b01000 || aluop ==5'b01101);
wire mul_ready;
wire mul_out_valid;
wire [63:0] mul_res_hi;
wire [63:0] mul_res_lo;
ysyx_22051086_MULTIPLIER mymultiplier(clk,rst,mul_valid,flush,op_mulw,op_mul_signed,alu_src1,alu_src2,mul_ready,mul_out_valid,mul_res_hi,mul_res_lo);

//divw
wire div_valid = op_div && !div_doing && !div_out_valid && ex_valid && !div_has_sent;
wire div_ready;
wire div_out_valid;
reg div_doing;
reg div_has_sent;
always @ (posedge clk)begin
    if(rst)
        div_has_sent <= 1'b0;
    else if(div_valid)
        div_has_sent <= 1'b1;
    else if(!div_doing)
        div_has_sent <= 1'b0;
end
always @(posedge clk)begin
    if(rst)begin
        div_doing <= 1'b0;
    end
    else if(div_out_valid)begin
        div_doing <= 1'b0;
    end
    else if(div_valid && div_ready)begin
        div_doing <= 1'b1;
    end
end
wire op_divw = (aluop == 5'b01001 || aluop == 5'b01010 || aluop == 5'b10011 || aluop == 5'b10100); 
wire op_div_signed = (aluop == 5'b01001 || aluop == 5'b01010 || aluop == 5'b10110);
wire op_div = (aluop == 5'b01001 || aluop == 5'b01010 || aluop == 5'b10010 || aluop == 5'b10011 || aluop == 5'b10100  || aluop == 5'b10101 || aluop==5'b10110);
wire flush = 0;
wire [63:0] quotient;
wire [63:0] remainder;
ysyx_22051086_DIVIDER mydivider(
    .clk(clk),
    .rst(rst),
    .dividend(alu_src1),
    .divisor(alu_src2),
    .div_valid(div_valid),
    .divw(op_divw),
    .div_signed(op_div_signed),
    .flush(flush),
    .div_ready(div_ready),
    .out_valid(div_out_valid),
    .quotient(quotient),
    .remainder(remainder)
    );

assign alu_busy = op_div ? (div_doing || div_valid)
                : op_mul ? (mul_doing || mul_valid)
                : 0;

assign alu_res = (aluop == 5'b00001 || aluop ==5'b10001)? add_sub_result
               : (aluop == 5'b00010)? and_result
               : (aluop == 5'b00011)? or_result
               : (aluop == 5'b00100)? xor_result
               : (aluop == 5'b00101)? sll_result
               : (aluop == 5'b00110 || aluop == 5'b00111)? sr_result[63:0]
               : (aluop == 5'b01000 || aluop == 5'b01101)? mul_res_lo
               : (aluop == 5'b01001 || aluop == 5'b10010 || aluop == 5'b10011 || aluop == 5'b10110)? quotient
               : (aluop == 5'b01010 || aluop == 5'b10100 || aluop == 5'b10101)? remainder
               : (aluop == 5'b01011) ? slt_result
               : (aluop == 5'b01100) ? sltu_result
               : (aluop == 5'b01110)? {32'b0,sllw_result}
               : (aluop == 5'b01111 || aluop == 5'b10000)? srw_result
               :0;
endmodule
