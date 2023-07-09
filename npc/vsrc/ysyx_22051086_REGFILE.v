module ysyx_22051086_REGFILE (
    input clk,
    input [63:0] wdata,
    input [4:0] waddr,
    input [4:0] raddr1,
    input [4:0] raddr2,
    input wen,
    output [63:0] rdata1,
    output [63:0] rdata2
);

reg [63:0] rf [31:0];

always @(posedge clk) begin
    if (wen && waddr!=0) rf[waddr] <= wdata;
end

assign rdata1 = (raddr1==0) ? 0 : rf[raddr1];
assign rdata2 = (raddr2==0) ? 0 : rf[raddr2];

import "DPI-C" function void set_gpr_ptr(input logic [63:0] a []);
initial set_gpr_ptr(rf);  // rf为通用寄存器的二维数组变量

endmodule
