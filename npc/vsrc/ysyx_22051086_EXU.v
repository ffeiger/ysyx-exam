module ysyx_22051086_EXU (
    input clk,
    input rst,
    output [63:0] ex_waddr,
    output [63:0] ex_wdata,
    output [7:0] ex_wmask,
    input ls_allowin,
    output ex_allowin,
    input id_to_ex_valid,
    output ex_to_ls_valid,
    input [345:0] id_to_ex_bus,
    output [347:0] ex_to_ls_bus,
    output ex_wvalid,
    input wvalid,
    output [70:0] ex_fwd_bus
);

wire [63:0] ex_pc;
wire [4:0] ex_aluop; 
wire [63:0] ex_alu_src1;
wire [63:0] ex_alu_src2;
//wire [63:0] ex_wdata;
wire ex_load;
wire ex_store;
wire ex_inst_sd;
wire ex_inst_sw;
wire ex_inst_sh;
wire ex_inst_sb;
wire ex_inst_ld;
wire ex_inst_lwu;
wire ex_inst_lw;
wire ex_inst_lh;
wire ex_inst_lhu;
wire ex_inst_lbu;
wire ex_inst_lb;
wire ex_reg_wen;
wire [4:0] ex_reg_waddr;
wire ex_csr;
wire [63:0] ex_csr_rdata;
wire ex_special_64;
reg [345:0] id_to_ex_bus_r;
wire ex_ready_go;
reg ex_valid;
assign ex_ready_go = (ex_store && ex_valid && ex_waddr[31:28] != 4'b1010)? wvalid : !alu_busy ; 
assign ex_allowin     = !ex_valid || ex_ready_go && ls_allowin;
assign ex_to_ls_valid =  ex_valid && ex_ready_go;
always @(posedge clk) begin
  if(id_to_ex_valid && ex_allowin)
    id_to_ex_bus_r <= id_to_ex_bus;
  
  if (rst) 
    ex_valid <= 1'b0;
  else if (ex_allowin) 
    ex_valid <= id_to_ex_valid;
end
assign {
  ex_pc,
  ex_aluop,
  ex_alu_src1,
  ex_alu_src2,
  ex_load,
  ex_store,
  ex_inst_ld,
  ex_inst_lwu,
  ex_inst_lw,
  ex_inst_lh,
  ex_inst_lhu,
  ex_inst_lbu,
  ex_inst_lb,
  ex_inst_sd,
  ex_inst_sw,
  ex_inst_sh,
  ex_inst_sb,
  ex_wdata,
  ex_reg_wen,
  ex_reg_waddr,
  ex_csr,
  ex_csr_rdata,
  ex_special_64
} = id_to_ex_bus_r;
wire ex_block_valid =  ex_valid && ex_load;
wire [63:0] ex_reg_wdata = ex_alu_res;
assign ex_fwd_bus = {ex_block_valid ,ex_reg_wen && ex_valid,ex_reg_waddr,ex_reg_wdata};


assign ex_wvalid = ex_valid && ex_store && (ex_waddr[31:28] != 4'b1010);
wire   ex_device_wvalid = ex_valid && ex_store && (ex_waddr[31:28] == 4'b1010);

wire [63:0] ex_alu_res;
wire alu_busy;
ysyx_22051086_ALU myalu(ex_valid,clk,rst,ex_aluop,ex_alu_src1,ex_alu_src2,ex_alu_res,alu_busy);

wire [63:0] ex_raddr = ex_alu_res;
assign ex_waddr = ex_alu_res;
wire [2:0] ex_waddr_offset = ex_waddr[2:0];
wire [2:0] ex_raddr_offset = ex_waddr[2:0];
wire [7:0] sd_wmask=8'b11111111;
wire [7:0] sw_wmask=(ex_waddr_offset==3'b000)? 8'b00001111:8'b11110000;
wire [7:0] sh_wmask=(ex_waddr_offset==3'b000)? 8'b00000011
                   :(ex_waddr_offset==3'b010)? 8'b00001100
                   :(ex_waddr_offset==3'b100)? 8'b00110000
                   :8'b11000000;
wire [7:0] sb_wmask= (ex_waddr_offset==3'b000)? 8'b00000001
                   :(ex_waddr_offset==3'b001)? 8'b00000010
                   :(ex_waddr_offset==3'b010)? 8'b00000100
                   :(ex_waddr_offset==3'b011)? 8'b00001000
                   :(ex_waddr_offset==3'b100)? 8'b00010000
                   :(ex_waddr_offset==3'b101)? 8'b00100000
                   :(ex_waddr_offset==3'b110)? 8'b01000000
                   :8'b10000000;
assign ex_wmask = ex_inst_sd ? sd_wmask
             : ex_inst_sw ? sw_wmask
             : ex_inst_sh ? sh_wmask
             : ex_inst_sb ? sb_wmask
             : 0;

assign ex_to_ls_bus = {
  ex_pc,
  ex_raddr,
  ex_waddr,
  ex_wmask,
  ex_load,
  ex_inst_ld,
  ex_inst_lwu,
  ex_inst_lw,
  ex_inst_lh,
  ex_inst_lhu,
  ex_inst_lbu,
  ex_inst_lb,
  ex_raddr_offset,
  ex_store,
  ex_reg_wen,
  ex_reg_waddr,
  ex_csr,
  ex_csr_rdata,
  ex_special_64,
  ex_alu_res
};

import "DPI-C" function void pmem_write(input longint waddr, input longint wdata, input longint wstrb);
always @(*) begin
  if(ex_device_wvalid)
    pmem_write(ex_waddr, ex_wdata , 64'hffffffffffffffff);
end
endmodule
