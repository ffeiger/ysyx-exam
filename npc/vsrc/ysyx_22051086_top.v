import "DPI-C" function void ebreak(input int a);
import "DPI-C" function void invalid_inst(input int a);
import "DPI-C" function void getpc(input longint a);
import "DPI-C" function void get_inst(input int a);
import "DPI-C" function void get_one_inst(input int a);
module ysyx_22051086_top (
    input clk,
    input rst,

    output reg [63:0] pc,
    output wire [31:0] inst
);

wire [95:0] if_to_id_bus;
wire [345:0] id_to_ex_bus;
wire [347:0] ex_to_ls_bus;
wire [133:0] ls_to_wb_bus;

/* verilator lint_off UNUSED */
wire inst_ebreak;
wire ls_load;
wire [63:0] ls_raddr;
wire [63:0] ex_waddr;
wire [63:0] ex_wdata;
wire [7:0] ls_wmask;
wire [7:0] ex_wmask;

wire [70:0] ex_fwd_bus;
wire [70:0] ls_fwd_bus;
wire [69:0] wb_fwd_bus;

wire if_allowin;
wire id_allowin;
wire ex_allowin;
wire ls_allowin;
wire wb_allowin;
wire if_to_id_valid;
wire id_to_ex_valid;
wire ex_to_ls_valid;
wire ls_to_wb_valid;

wire [63:0] nextpc;
wire [65:0] br_bus;
ysyx_22051086_IFU if_stage(
    .clk(clk),
    .rst(rst),
    .pc(pc),
    .nextpc(nextpc),
    .if_allowin(if_allowin),
    .id_allowin(id_allowin),
    .id_valid(id_valid),
    .if_to_id_valid(if_to_id_valid),
    .inst(inst),
    .br_bus(br_bus),
    .if_to_id_bus(if_to_id_bus),
    .if_arvalid(if_arvalid),
    .cache_rdata(icache_rdata),
    .cache_rdata_valid(icache_rdata_valid),
    .ecall(ecall),
    .mret(mret),
    .csr_rdata(csr_rdata)
);

wire [63:0] id_pc;
reg id_valid;
ysyx_22051086_IDU id_stage(
    .clk(clk),
    .rst(rst),
    .reg_raddr1(reg_raddr1),
    .reg_raddr2(reg_raddr2),
    .reg_rdata1(reg_rdata1),
    .reg_rdata2(reg_rdata2),
    .inst_ebreak(inst_ebreak),
    .csr_wnum(csr_wnum),
    .csr_wen(csr_wen),
    .csr_wdata(csr_wdata),
    .csr_wmask(csr_wmask),
    .csr_rnum(csr_rnum),
    .csr_rdata(csr_rdata),
    .ecall(ecall),
    .mret(mret),
    .id_pc(id_pc),
    .id_allowin(id_allowin),
    .ex_allowin(ex_allowin),
    .if_to_id_valid(if_to_id_valid),
    .id_to_ex_valid(id_to_ex_valid),
    .if_to_id_bus(if_to_id_bus),
    .id_to_ex_bus(id_to_ex_bus),
    .br_bus(br_bus),
    .id_valid(id_valid),
    .ex_fwd_bus(ex_fwd_bus),
    .ls_fwd_bus(ls_fwd_bus),
    .wb_fwd_bus(wb_fwd_bus)
);
wire ex_wvalid;
ysyx_22051086_EXU exe_stage(
    .clk(clk),
    .rst(rst),
    .ex_waddr(ex_waddr),
    .ex_wdata(ex_wdata),
    .ex_wmask(ex_wmask),
    .ex_allowin(ex_allowin),
    .ls_allowin(ls_allowin),
    .id_to_ex_valid(id_to_ex_valid),
    .ex_to_ls_valid(ex_to_ls_valid),
    .id_to_ex_bus(id_to_ex_bus),
    .ex_to_ls_bus(ex_to_ls_bus),
    .ex_wvalid(ex_wvalid),
    .wvalid(dcache_wdata_valid),
    .ex_fwd_bus(ex_fwd_bus)
);

wire [63:0] ls_waddr; 
ysyx_22051086_LSU ls_stage(
    .clk(clk),
    .rst(rst),
    .ex_to_ls_bus(ex_to_ls_bus),
    .ls_to_wb_bus(ls_to_wb_bus),
    .ls_allowin(ls_allowin),
    .wb_allowin(wb_allowin),
    .ex_to_ls_valid(ex_to_ls_valid),
    .ls_to_wb_valid(ls_to_wb_valid),
    .ls_raddr(ls_raddr),
    .ls_waddr(ls_waddr),
    .ls_wmask(ls_wmask),
    .ls_load(ls_load),
    .rdata(dcache_rdata),
    .rvalid(dcache_rdata_valid),
    //.wvalid(dcache_wdata_valid),
    .ls_arvalid(ls_arvalid),
    .ls_fwd_bus(ls_fwd_bus)
);
reg wb_valid;
wire [63:0] wb_pc;
ysyx_22051086_WBU wb_stage(
    .clk(clk),
    .rst(rst),
    .ls_to_wb_bus(ls_to_wb_bus),
    .wb_allowin(wb_allowin),
    .ls_to_wb_valid(ls_to_wb_valid),
    .wb_reg_wen(wb_reg_wen),
    .wb_reg_waddr(wb_reg_waddr),
    .wb_reg_wdata(wb_reg_wdata),
    .wb_valid(wb_valid),
    .wb_fwd_bus(wb_fwd_bus),
    .wb_pc(wb_pc)
);

wire        wb_reg_wen;
wire        reg_wen = wb_valid && wb_reg_wen;
wire [4:0]  reg_raddr1;
wire [4:0]  reg_raddr2;
wire [4:0]  wb_reg_waddr;
wire [4:0]  reg_waddr = wb_valid ? wb_reg_waddr : 5'b0;
wire [63:0] reg_rdata1;
wire [63:0] reg_rdata2;
wire [63:0] wb_reg_wdata;
ysyx_22051086_REGFILE myregfile(
    .clk(clk),
    .wdata(wb_reg_wdata),
    .waddr(reg_waddr),
    .raddr1(reg_raddr1),
    .raddr2(reg_raddr2),
    .wen(reg_wen),
    .rdata1(reg_rdata1),
    .rdata2(reg_rdata2)
);



wire        if_arvalid;
wire        ls_arvalid;
wire [63:0] wstrb = {{8{ex_wmask[7]}} , {8{ex_wmask[6]}} , {8{ex_wmask[5]}} , {8{ex_wmask[4]}} ,
                    {8{ex_wmask[3]}} , {8{ex_wmask[2]}} , {8{ex_wmask[1]}} , {8{ex_wmask[0]}}};
wire [31:0] icache_rdata;
wire        icache_rdata_valid;
wire [63:0] dcache_rdata;
wire        dcache_rdata_valid;
wire        dcache_wdata_valid;
ysyx_22051086_ICACHE myicache(
    .rst(rst),
    .clk(clk),
    .raddr(nextpc[31:0]),           
    .rwen(if_arvalid),
    .rdata(icache_rdata),           
    .rdata_valid(icache_rdata_valid)      
);
ysyx_22051086_DCACHE mydcache(
    .rst(rst),
    .clk(clk),
    .raddr(ls_raddr[31:0]),           
    .rwen(ls_arvalid),
    .rdata(dcache_rdata),           
    .rdata_valid(dcache_rdata_valid),
    .waddr(ex_waddr[31:0]),
    .wen(ex_wvalid),
    .wdata(ex_wdata),
    .wmask(wstrb),
    .wdata_valid(dcache_wdata_valid)      
);

wire [11:0] csr_wnum;
wire [11:0] csr_rnum;
wire csr_wen;
wire [63:0] csr_wdata;
wire [63:0] csr_wmask;
wire [63:0] csr_rdata;
wire ecall;
wire mret;

ysyx_22051086_CSR mycsr(
    .clk(clk),
    .rst(rst),
    .pc(id_pc),
    .csr_wnum(csr_wnum),
    .csr_wen(csr_wen),
    .csr_wdata(csr_wdata),
    .csr_wmask(csr_wmask),
    .csr_rnum(csr_rnum),
    .csr_rdata(csr_rdata),
    .ecall(ecall)
);

always @(*)
begin
    ebreak({31'b0,inst_ebreak});
end
always @(*)
begin
    getpc(wb_pc);
end

always @(*)
begin
    if(!rst)
    get_inst(inst);
end

always @(*)
begin
    get_one_inst({31'b0,wb_valid});
end
endmodule
