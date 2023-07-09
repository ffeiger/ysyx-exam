module ysyx_22051086_CSR (
    input clk,
    input rst,
    input [63:0] pc,
    input [11:0] csr_wnum,
    input csr_wen,
    input [63:0] csr_wdata,
    input [63:0] csr_wmask,
    input [11:0] csr_rnum,
    output [63:0] csr_rdata,
    input ecall
);

reg [63:0] MEPC;
reg [63:0] MSTATUS;
reg [63:0] MCAUSE;
reg [63:0] MTVEC;

always @(posedge clk) begin
    if (csr_wen && csr_wnum == 12'h341) 
        MEPC <= csr_wdata | csr_wmask;
    else if(ecall)
        MEPC <= pc;
end

always @(posedge clk) begin
    if(rst)
        MSTATUS <= 64'ha00001800;
    else if (csr_wen && csr_wnum == 12'h300) 
        MSTATUS <= csr_wdata | csr_wmask;
end

always @(posedge clk) begin
    if (csr_wen && csr_wnum == 12'h342) 
        MCAUSE <= csr_wdata | csr_wmask;
    else if(ecall) begin
        MCAUSE[3:0] <= 4'b1011;
    end
end

always @(posedge clk) begin
    if (csr_wen && csr_wnum == 12'h305) 
        MTVEC <= csr_wdata | csr_wmask;
end

assign csr_rdata = (csr_rnum == 12'h341)? MEPC
          : (csr_rnum == 12'h300)? MSTATUS
          : (csr_rnum == 12'h342)? MCAUSE
          : (csr_rnum == 12'h305)? MTVEC
          : 0;


endmodule
