
module ysyx_22051086_IFU (
    input clk,
    input rst,
    output reg [63:0] pc,
    output [63:0] nextpc,
    output if_allowin,
    input id_allowin,
    input id_valid,
    output if_to_id_valid,
    output [31:0] inst,
    input  [65:0] br_bus,
    output [95:0] if_to_id_bus,
    output if_arvalid,
    input [31:0] cache_rdata,
    input cache_rdata_valid,
    input ecall,
    input mret,
    input [63:0] csr_rdata
);

wire if_ready_go;
reg if_valid;
wire to_if_valid;
wire to_if_ready_go;
wire [63:0] seq_pc;
wire br_stall;
wire br_taken;
wire [63:0] br_target;
reg reg_cache_rdata_valid;
reg first;
reg [31:0] reg_cache_rdata;
always @(posedge clk)begin
    if(cache_rdata_valid) begin
        reg_cache_rdata_valid <= 1'b1;
        reg_cache_rdata <= cache_rdata;
    end
    else if(if_arvalid)begin 
        reg_cache_rdata_valid <= 1'b0;
    end
end
always @ (posedge clk)begin
    if(cache_rdata_valid) 
        first <= 1'b1;
    else 
        first <= 1'b0;
end
//pre-if
assign {br_stall,br_taken,br_target} = br_bus;
assign to_if_ready_go = !br_stall;
assign to_if_valid = !rst && to_if_ready_go;
assign seq_pc = pc + 4;
assign nextpc = (ecall || mret)? csr_rdata
              : (br_taken && !br_stall) ? br_target 
              : seq_pc;

//if
wire first_inst = (nextpc == 64'h0000000080000000);
assign if_ready_go = reg_cache_rdata_valid ;
assign if_allowin = !if_valid || if_ready_go && id_allowin;
assign if_to_id_valid = if_valid && if_ready_go && first;
always @(posedge clk) begin
    if (rst) 
        pc <= 64'h000000007ffffffc;
    else if(to_if_valid && if_allowin && first_inst) 
        pc <= nextpc;
    else if(to_if_valid && if_allowin && !first_inst && id_valid) 
        pc <= nextpc;

    if (rst) 
        if_valid <= 1'b0;
    else if (if_allowin) 
        if_valid <= to_if_valid;
end

assign inst = reg_cache_rdata;
assign if_to_id_bus = {pc,inst};
assign if_arvalid =  first_inst ? to_if_valid &&  if_allowin :to_if_valid &&  if_allowin && id_valid; 


endmodule

