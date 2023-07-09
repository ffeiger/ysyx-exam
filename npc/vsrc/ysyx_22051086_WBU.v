module ysyx_22051086_WBU(
    input clk,
    input rst,
    input [133:0] ls_to_wb_bus,
    output wb_allowin,
    input ls_to_wb_valid,
    output wb_reg_wen,
    output [4:0] wb_reg_waddr,
    output [63:0] wb_reg_wdata,
    output reg  wb_valid,
    output [69:0] wb_fwd_bus,
    output [63:0] wb_pc
);
/* verilator lint_off UNUSED */
wire wb_ready_go;
assign wb_ready_go = 1;
assign wb_allowin = !wb_valid || wb_ready_go ;
reg [133:0] ls_to_wb_bus_r;
always @(posedge clk)begin
    if(ls_to_wb_valid && wb_allowin)
        ls_to_wb_bus_r <= ls_to_wb_bus;    
    
    if (rst) 
        wb_valid <= 1'b0;
    else if (wb_allowin) 
        wb_valid <= ls_to_wb_valid;
end
assign {
    wb_pc,
    wb_reg_wen,
    wb_reg_waddr,
    wb_reg_wdata    
} = ls_to_wb_bus_r;
assign wb_fwd_bus = {wb_reg_wen && wb_valid , wb_reg_waddr ,wb_reg_wdata};
endmodule
