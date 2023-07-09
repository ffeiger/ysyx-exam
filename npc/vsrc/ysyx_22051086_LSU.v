module ysyx_22051086_LSU (
    input clk,
    input rst,
    input [347:0] ex_to_ls_bus,
    output [133:0] ls_to_wb_bus,
    input wb_allowin,
    output ls_allowin,
    input ex_to_ls_valid,
    output ls_to_wb_valid,
    output [63:0] ls_raddr,
    output [63:0] ls_waddr,
    output [7:0] ls_wmask,
    output ls_load,
    input [63:0] rdata,
    input rvalid,
    //input wvalid,
    output ls_arvalid,
    output [70:0] ls_fwd_bus
);
/* verilator lint_off UNUSED */
wire [63:0] ls_pc;
wire ls_store;
wire ls_reg_wen;
wire [4:0] ls_reg_waddr;
wire ls_csr;
wire [63:0] ls_csr_rdata;
wire ls_special_64;
wire [63:0] ls_alu_res;
wire ls_inst_ld;
wire ls_inst_lwu;
wire ls_inst_lw;
wire ls_inst_lh;
wire ls_inst_lhu;
wire ls_inst_lbu;
wire ls_inst_lb;
wire [2:0] ls_raddr_offset;
wire [63:0] ls_reg_wdata;
reg [347:0] ex_to_ls_bus_r;
wire ls_ready_go;
reg ls_valid;
assign ls_ready_go    = (ls_load && ls_valid && ls_raddr[31:28] != 4'b1010) ? rvalid 
                      //: (ls_store && ls_valid && ls_waddr[31:28] != 4'b1010) ? wvalid
                      : 1;
assign ls_allowin     = !ls_valid || ls_ready_go && wb_allowin;
assign ls_to_wb_valid =  ls_valid && ls_ready_go;
always @ (posedge clk) begin
    if(rst)
        ex_to_ls_bus_r <= 0;
    else if(ex_to_ls_valid && ls_allowin)
        ex_to_ls_bus_r <= ex_to_ls_bus;

    if (rst) 
        ls_valid <= 1'b0;
    else if (ls_allowin) 
        ls_valid <= ex_to_ls_valid;
end
assign ls_arvalid = ls_valid && ls_load && ls_raddr[31:28] != 4'b1010;
wire ls_device_arvalid = ls_valid && ls_load && ls_raddr[31:28] == 4'b1010;
assign{
    ls_pc,
    ls_raddr,
    ls_waddr,
    ls_wmask,
    ls_load,
    ls_inst_ld,
    ls_inst_lwu,
    ls_inst_lw,
    ls_inst_lh,
    ls_inst_lhu,
    ls_inst_lbu,
    ls_inst_lb,
    ls_raddr_offset,
    ls_store,
    ls_reg_wen,
    ls_reg_waddr,
    ls_csr,
    ls_csr_rdata,
    ls_special_64,
    ls_alu_res
} = ex_to_ls_bus_r;
wire ls_block_valid =  ls_valid && ls_load ;
assign ls_fwd_bus = {ls_block_valid ,ls_reg_wen && ls_valid ,ls_reg_waddr,ls_reg_wdata};

assign ls_to_wb_bus = {
    ls_pc,
    ls_reg_wen,
    ls_reg_waddr,
    ls_reg_wdata
};
wire [63:0] device_or_not_rdata = ls_device_arvalid ? device_rdata : rdata;
wire [7:0] lbu_real_rdata = (ls_raddr_offset==3'b000)? device_or_not_rdata[7:0]
                          : (ls_raddr_offset==3'b001)? device_or_not_rdata[15:8]
                          : (ls_raddr_offset==3'b010)? device_or_not_rdata[23:16]
                          : (ls_raddr_offset==3'b011)? device_or_not_rdata[31:24]
                          : (ls_raddr_offset==3'b100)? device_or_not_rdata[39:32]
                          : (ls_raddr_offset==3'b101)? device_or_not_rdata[47:40]
                          : (ls_raddr_offset==3'b110)? device_or_not_rdata[55:48]
                          : (ls_raddr_offset==3'b111)? device_or_not_rdata[63:56]
                          : 0;
wire [15:0] lh_real_rdata =  (ls_raddr_offset==3'b000)? device_or_not_rdata[15:0]
                          : (ls_raddr_offset==3'b010)? device_or_not_rdata[31:16]
                          : (ls_raddr_offset==3'b100)? device_or_not_rdata[47:32]
                          :  device_or_not_rdata[63:48];
wire [31:0] lw_real_rdata = (ls_raddr_offset==3'b000)? device_or_not_rdata[31:0]:device_or_not_rdata[63:32];
wire [63:0] real_rdata = ls_inst_ld ? device_or_not_rdata
                  : ls_inst_lwu ? {32'b0,lw_real_rdata}
                  : ls_inst_lw ? {{32{lw_real_rdata[31]}},lw_real_rdata}
                  : ls_inst_lh ? {{48{lh_real_rdata[15]}},lh_real_rdata}
                  : ls_inst_lhu ? {48'b0,lh_real_rdata}
                  : ls_inst_lbu ? {56'b0,lbu_real_rdata}
                  : ls_inst_lb ? {{56{lbu_real_rdata[7]}},lbu_real_rdata}
                  : 0;                       
assign ls_reg_wdata = ls_csr ? ls_csr_rdata
                 : ls_load ? real_rdata 
                 : ls_special_64 ? {{32{ls_alu_res[31]}},ls_alu_res[31:0]} 
                 : ls_alu_res;

wire [63:0] device_rdata;
import "DPI-C" function void pmem_read(input longint raddr, output longint rdata);
always_latch  begin
if(ls_device_arvalid)
    pmem_read(ls_raddr, device_rdata);
end

endmodule
