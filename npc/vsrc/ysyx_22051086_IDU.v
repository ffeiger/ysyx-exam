module ysyx_22051086_IDU (
    input clk,
    input rst,
    output [4:0]  reg_raddr1,
    output [4:0]  reg_raddr2,
    input  [63:0] reg_rdata1,
    input  [63:0] reg_rdata2,
    output inst_ebreak,
    output [11:0] csr_wnum,
    output csr_wen,
    output [63:0] csr_wdata,
    output [63:0] csr_wmask,
    output [11:0] csr_rnum,
    input [63:0] csr_rdata,
    output ecall,
    output mret,
    output [63:0] id_pc,
    input ex_allowin,
    output id_allowin,
    input if_to_id_valid,
    output id_to_ex_valid,
    input [95:0] if_to_id_bus,
    output [345:0] id_to_ex_bus,
    output [65:0] br_bus,
    output reg id_valid,
    input [70:0] ex_fwd_bus,
    input [70:0] ls_fwd_bus,
    input [69:0] wb_fwd_bus
);

wire [31:0] id_inst;
reg [95:0] if_to_id_bus_r;

wire id_ready_go;
assign id_ready_go = !load_block;
assign id_allowin = !id_valid || id_ready_go && ex_allowin;
assign id_to_ex_valid = id_valid && id_ready_go;
always @(posedge clk)begin
    if(if_to_id_valid && id_allowin)
        if_to_id_bus_r <= if_to_id_bus;
    
    if (rst) 
        id_valid <= 1'b0;
    else if (id_allowin) 
        id_valid <= if_to_id_valid;
end
assign {id_pc,id_inst} = if_to_id_bus_r;
assign id_to_ex_bus = {
    id_pc,
    aluop,
    alu_src1,
    alu_src2,
    load,
    store,
    inst_ld,
    inst_lwu,
    inst_lw,
    inst_lh,
    inst_lhu,
    inst_lbu,
    inst_lb,
    inst_sd,
    inst_sw,
    inst_sh,
    inst_sb,
    wdata,
    reg_wen,
    reg_waddr,
    csr,
    csr_rdata,
    special_64
};

wire [6:0] opcode;
wire [2:0] func3;
wire [6:0] func7;
wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;
wire [5:0] shamt_si;
wire [11:0] immI;
wire [19:0] immU;
wire [19:0] immJ;
wire [11:0] immB;
wire [11:0] immS;
wire [63:0] alu_src1;
wire [63:0] alu_src2;
wire [63:0] wdata;

assign opcode = id_inst[6:0];
assign func3 = id_inst[14:12];
assign func7 = id_inst[31:25];
assign rs1 = id_inst[19:15];
assign rs2 = id_inst[24:20];
assign rd= id_inst[11:7];
assign shamt_si = id_inst[25:20];
assign immI = id_inst[31:20];
assign immU = id_inst[31:12];
assign immJ = {id_inst[31],id_inst[19:12],id_inst[20],id_inst[30:21]};
assign immB = {id_inst[31],id_inst[7],id_inst[30:25],id_inst[11:8]};
assign immS = {id_inst[31:25],id_inst[11:7]};

wire reg_wen = inst_jalr || (alu_add_op && !store) || alu_and_op || alu_or_op || alu_sub_op|| alu_divuw_op ||
                alu_xor_op || alu_sll_op || alu_sra_op || alu_srl_op || alu_mul_op || alu_mulw_op || alu_divu_op ||
                alu_divw_op || alu_div_op || alu_rem_op || alu_remu_op|| alu_remuw_op || alu_slt_op || alu_sltu_op|| alu_sllw_op || alu_sraw_op || alu_srlw_op ||load || csr;
assign reg_raddr1 = rs1;
assign reg_raddr2 = rs2;
wire [4:0] reg_waddr = rd;

assign csr_wnum = csr ? id_inst[31:20] : 0;
assign csr_rnum = csr ? id_inst[31:20]
                : mret ? 12'h341
                : ecall ? 12'h305
                : 0; 
assign csr_wen =  inst_csrrw || (inst_csrrs && rs1 != 0);
assign csr_wdata = inst_csrrw ? reg_real_rdata1 : csr_rdata;
assign csr_wmask = inst_csrrw ? 0 : reg_real_rdata1 ;

//U TYPE
wire inst_auipc = (opcode == 7'b0010111);
wire inst_lui = (opcode==7'b0110111);
//R TYPE
wire inst_slt = (opcode == 7'b0110011) && (func3==3'b010) && (func7==7'b0);
wire inst_sltu = (opcode == 7'b0110011) && (func3==3'b011) && (func7==7'b0);
wire inst_add =(opcode == 7'b0110011) && (func3==3'b000) && (func7==7'b0);
wire inst_and = (opcode == 7'b0110011) && (func3==3'b111) && (func7==7'b0);
wire inst_xor =(opcode == 7'b0110011) && (func3==3'b100) && (func7==7'b0);
wire inst_or =(opcode == 7'b0110011) && (func3==3'b110) && (func7==7'b0);
wire inst_addw = (opcode == 7'b0111011) && (func3==3'b000) && (func7==7'b0);
wire inst_sub = (opcode == 7'b0110011) && (func3==3'b000) && (func7==7'b0100000);
wire inst_subw = (opcode == 7'b0111011) && (func3==3'b000) && (func7==7'b0100000);
wire inst_mul = (opcode == 7'b0110011) && (func3==3'b000) && (func7==7'b0000001);
wire inst_mulw = (opcode == 7'b0111011) && (func3==3'b000) && (func7==7'b0000001);
wire inst_div  = (opcode == 7'b0110011) && (func3==3'b100) && (func7==7'b0000001);
wire inst_divu = (opcode == 7'b0110011) && (func3==3'b101) && (func7==7'b0000001);
wire inst_divw = (opcode == 7'b0111011) && (func3==3'b100) && (func7==7'b0000001);
wire inst_divuw = (opcode == 7'b0111011) && (func3==3'b101) && (func7==7'b0000001);
wire inst_remu = (opcode == 7'b0110011) && (func3==3'b111) && (func7==7'b0000001);
wire inst_remw = (opcode == 7'b0111011) && (func3==3'b110) && (func7==7'b0000001);
wire inst_remuw = (opcode == 7'b0111011) && (func3==3'b111) && (func7==7'b0000001);
wire inst_sll = (opcode == 7'b0110011) && (func3==3'b001) && (func7==7'b0);
wire inst_srl = (opcode == 7'b0110011) && (func3==3'b101) && (func7==7'b0);
wire inst_sra = (opcode == 7'b0110011) && (func3==3'b101) && (func7==7'b0100000);
wire inst_sllw = (opcode == 7'b0111011) && (func3==3'b001) && (func7==7'b0);
wire inst_srlw = (opcode == 7'b0111011) && (func3==3'b101) && (func7==7'b0);
wire inst_sraw = (opcode == 7'b0111011) && (func3==3'b101) && (func7==7'b0100000);
//I TYPE
wire inst_ld = (opcode == 7'b0000011) && (func3==3'b011);
wire inst_lbu = (opcode == 7'b0000011) && (func3==3'b100);
wire inst_lb = (opcode == 7'b0000011) && (func3==3'b000);
wire inst_lh = (opcode == 7'b0000011) && (func3==3'b001);
wire inst_lhu = (opcode == 7'b0000011) && (func3==3'b101);
wire inst_lw = (opcode == 7'b0000011) && (func3==3'b010);
wire inst_lwu = (opcode == 7'b0000011) && (func3==3'b110);
wire load =inst_lb || inst_ld || inst_lbu || inst_lh || inst_lhu || inst_lw || inst_lwu;
wire inst_addi = (opcode == 7'b0010011) && (func3==3'b000);
wire inst_addiw = (opcode == 7'b0011011) && (func3==3'b000);
wire inst_andi = (opcode == 7'b0010011) && (func3==3'b111);
wire inst_xori = (opcode == 7'b0010011) && (func3==3'b100);
wire inst_ori = (opcode == 7'b0010011) && (func3==3'b110);
wire inst_slti = (opcode == 7'b0010011) && (func3==3'b010);
wire inst_sltiu = (opcode == 7'b0010011) && (func3==3'b011);
wire inst_jalr = (opcode ==7'b1100111);
//S TYPE
wire inst_sd = (opcode == 7'b0100011 ) && (func3==3'b011);
wire inst_sb = (opcode == 7'b0100011 ) && (func3==3'b000);
wire inst_sh = (opcode == 7'b0100011 ) && (func3==3'b001);
wire inst_sw = (opcode == 7'b0100011 ) && (func3==3'b010);
wire store = inst_sd || inst_sb || inst_sh || inst_sw;
//B TYPE
wire inst_beq = (opcode == 7'b1100011 ) && (func3==3'b000);
wire inst_bne = (opcode == 7'b1100011 ) && (func3==3'b001);
wire inst_blt = (opcode == 7'b1100011 ) && (func3==3'b100);
wire inst_bltu = (opcode == 7'b1100011 ) && (func3==3'b110);
wire inst_bge = (opcode == 7'b1100011 ) && (func3==3'b101);
wire inst_bgeu = (opcode == 7'b1100011 ) && (func3==3'b111);
//J TYPE
wire inst_jal = (opcode == 7'b1101111);
//wire inst_branch = inst_beq || inst_bne || inst_blt || inst_bltu || inst_bge || inst_bgeu || inst_jal || inst_jalr;
//SI TYPE
wire inst_srai = (opcode == 7'b0010011 ) && (func3==3'b101) && (id_inst[31:26]==6'b010000);
wire inst_srli = (opcode == 7'b0010011 ) && (func3==3'b101) && (id_inst[31:26]==6'b0);
wire inst_slli = (opcode == 7'b0010011 ) && (func3==3'b001) && (id_inst[31:26]==6'b0);
wire inst_slliw = (opcode == 7'b0011011 ) && (func3==3'b001) && (func7==7'b0);
wire inst_sraiw = (opcode == 7'b0011011 ) && (func3==3'b101) && (func7==7'b0100000);
wire inst_srliw = (opcode == 7'b0011011 ) && (func3==3'b101) && (func7==7'b0);
//ebreak
assign inst_ebreak = (id_inst==32'h00100073);
//csr
wire inst_csrrw = (opcode == 7'b1110011) && (func3 == 3'b001);
wire inst_csrrs = (opcode == 7'b1110011) && (func3 == 3'b010);
wire csr = inst_csrrw || inst_csrrs;
//
wire inst_ecall = (opcode ==7'b1110011) && (id_inst[31:7]==0);
wire inst_mret = (opcode ==7'b1110011) && (id_inst[31:21]==11'b00110000001) && (id_inst[20:7]==0);
assign ecall = inst_ecall && id_valid;
assign mret = inst_mret && id_valid;
//inv
wire inst_inv = !(inst_auipc || inst_lui || inst_slt || inst_sltu||inst_add ||inst_and|| inst_xor || inst_divu || inst_divuw || inst_or ||inst_addw ||inst_sub ||inst_subw ||inst_mul ||inst_mulw ||inst_divw || inst_remu ||inst_remw || inst_remuw ||inst_sllw 
             || inst_sll || inst_srl || inst_sra || inst_srlw ||inst_sraw ||inst_ld||inst_lbu || inst_lb ||inst_lh ||inst_lhu ||inst_lw || inst_lwu || inst_addi ||inst_addiw ||inst_andi ||inst_xori || inst_ori || inst_slti || inst_sltiu 
             || inst_jalr ||inst_sd ||inst_sb ||inst_sh ||inst_sw || inst_beq || inst_bne || inst_blt || inst_bltu || inst_bge || inst_bgeu || inst_jal || inst_srai || inst_srli || inst_slli || inst_slliw || inst_sraiw || inst_srliw ||inst_ebreak
             || inst_csrrs || inst_csrrw || inst_ecall || inst_mret || inst_div) && id_valid;
always @(*)
begin
    invalid_inst({31'b0,inst_inv});
end

wire special_64 = inst_subw || inst_addiw || inst_addw || inst_slliw || inst_sraiw ||inst_srliw ||
                    inst_sllw || inst_sraw ||inst_srlw || inst_divw || inst_remw || inst_remuw || inst_mulw || inst_divuw;

wire br_taken;
wire br_stall;
wire [63:0] br_target;
assign br_stall = 0;
assign br_taken = ((inst_beq && (reg_real_rdata1 == reg_real_rdata2)) || 
                (inst_bne && (reg_real_rdata1 != reg_real_rdata2)) || 
                (inst_bge && ($signed(reg_real_rdata1) >= $signed(reg_real_rdata2))) ||
                (inst_blt && ($signed(reg_real_rdata1) < $signed(reg_real_rdata2))) || 
                (inst_bltu && ($unsigned(reg_real_rdata1) < $unsigned(reg_real_rdata2))) ||
                (inst_bgeu && ($unsigned(reg_real_rdata1) >= $unsigned(reg_real_rdata2))) || 
                (inst_jal || inst_jalr)) && id_valid;
assign br_target = inst_jal ? id_pc + {{43{immJ[19]}},immJ,1'b0}
                 : inst_jalr ? reg_real_rdata1 + {{52{immI[11]}},immI}
                 : br_taken ? id_pc + {{51{immB[11]}},immB,1'b0}
                 : 0;
assign br_bus = {br_stall, br_taken, br_target};
/*
assign nextpc = (ecall || mret)? csr_rdata
              : inst_jal ? id_pc + {{43{immJ[19]}},immJ,1'b0}
              : inst_jalr ? reg_rdata1 + {{52{immI[11]}},immI}
              : br_taken ? id_pc + {{51{immB[11]}},immB,1'b0}
              : id_pc + 4; 
*/
wire alu_add_op = inst_lui || inst_add || inst_addi || inst_addiw || inst_addw || inst_auipc || inst_jal ||inst_jalr|| load || store;
wire alu_sub_op = inst_sub || inst_subw ;
wire alu_and_op = inst_and || inst_andi;
wire alu_or_op = inst_or ||inst_ori;
wire alu_xor_op = inst_xori || inst_xor;
wire alu_sll_op = inst_slli || inst_sll;
wire alu_sra_op = inst_srai || inst_sra;
wire alu_srl_op = inst_srli || inst_srl;
wire alu_sllw_op = inst_sllw || inst_slliw ;
wire alu_sraw_op = inst_sraw || inst_sraiw ;
wire alu_srlw_op = inst_srlw || inst_srliw ;
wire alu_mul_op = inst_mul;
wire alu_mulw_op = inst_mulw;
wire alu_div_op = inst_div;
wire alu_divw_op = inst_divw ;
wire alu_divu_op = inst_divu;
wire alu_divuw_op = inst_divuw;
wire alu_rem_op = inst_remw ;
wire alu_remu_op = inst_remu ;
wire alu_remuw_op = inst_remuw;
wire alu_slt_op = inst_slt || inst_slti;
wire alu_sltu_op = inst_sltu || inst_sltiu;
wire [4:0] aluop = alu_add_op ? 5'b00001
             : alu_and_op ? 5'b00010 
             : alu_or_op ? 5'b00011
             : alu_xor_op ? 5'b00100             
             : alu_sll_op ? 5'b00101
             : alu_sra_op ? 5'b00110
             : alu_srl_op ? 5'b00111
             : alu_mulw_op ? 5'b01000
             : alu_divw_op ? 5'b01001
             : alu_rem_op ? 5'b01010
             : alu_slt_op ? 5'b01011
             : alu_sltu_op ? 5'b01100
             : alu_mul_op ? 5'b01101
             : alu_sllw_op ? 5'b01110
             : alu_sraw_op ? 5'b01111
             : alu_srlw_op ? 5'b10000
             : alu_sub_op ? 5'b10001
             : alu_divu_op ? 5'b10010
             : alu_divuw_op ? 5'b10011
             : alu_remuw_op ? 5'b10100 
             : alu_remu_op ? 5'b10101
             : alu_div_op ? 5'b10110
             : 0;
wire [63:0] reg_real_rdata1;
wire [63:0] reg_real_rdata2;
wire ex_block_valid;
wire ls_block_valid;
wire load_block;
wire ex_reg_wen;
wire ls_reg_wen;
wire wb_reg_wen;
wire [4:0] ex_reg_waddr;
wire [4:0] ls_reg_waddr;
wire [4:0] wb_reg_waddr;
wire [63:0] ex_reg_wdata;
wire [63:0] ls_reg_wdata;
wire [63:0] wb_reg_wdata;
assign {ex_block_valid,ex_reg_wen,ex_reg_waddr,ex_reg_wdata} = ex_fwd_bus;
assign {ls_block_valid,ls_reg_wen,ls_reg_waddr,ls_reg_wdata} = ls_fwd_bus;
assign {wb_reg_wen,wb_reg_waddr,wb_reg_wdata} = wb_fwd_bus;
assign load_block = (ex_block_valid && (ex_reg_waddr == reg_raddr1 || ex_reg_waddr == reg_raddr2))
                  ||(ls_block_valid && (ls_reg_waddr == reg_raddr1 || ls_reg_waddr == reg_raddr2));
assign reg_real_rdata1 = (ex_reg_wen && ex_reg_waddr == reg_raddr1 && reg_raddr1 !=0) ? ex_reg_wdata
                       : (ls_reg_wen && ls_reg_waddr == reg_raddr1 && reg_raddr1 !=0) ? ls_reg_wdata
                       : (wb_reg_wen && wb_reg_waddr == reg_raddr1 && reg_raddr1 !=0) ? wb_reg_wdata
                       : reg_rdata1;
assign reg_real_rdata2 = (ex_reg_wen && ex_reg_waddr == reg_raddr2 && reg_raddr2 !=0) ? ex_reg_wdata
                       : (ls_reg_wen && ls_reg_waddr == reg_raddr2 && reg_raddr2 !=0) ? ls_reg_wdata
                       : (wb_reg_wen && wb_reg_waddr == reg_raddr2 && reg_raddr2 !=0) ? wb_reg_wdata
                       : reg_rdata2;       
assign alu_src1 = (inst_auipc || inst_jal || inst_jalr) ? id_pc
                : inst_lui ? 0
                : reg_real_rdata1;
assign alu_src2 = (inst_addi || inst_addiw || inst_andi || inst_xori || inst_ori || load || inst_sltiu || inst_slti) ?  {{52{immI[11]}},immI}
                : (inst_sra || inst_srl || inst_sll) ? {58'b0,reg_real_rdata2[5:0]}
                : (inst_slli || inst_srai || inst_srli ||inst_slliw || inst_sraiw || inst_srliw) ? {58'b0,shamt_si}
                : (inst_sllw || inst_sraw || inst_srlw) ? {59'b0,reg_real_rdata2[4:0]}
                : (inst_auipc || inst_lui)?  {{32{immU[19]}},immU,12'b0} 
                : (inst_jal || inst_jalr) ?  4
                : store ? {{{52{immS[11]}},immS}}
                : reg_real_rdata2;

assign wdata = reg_real_rdata2;


endmodule





