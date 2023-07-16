module ysyx_22051086_SRAM(
    input         clk,
    input         rst,

    input [31:0]  araddr, 
    input [3:0]   arlen,    //4'b0011:4个数据
    input [2:0]   arsize,   //3'b011：8字节
    input [1:0]   arburst,  //暂时没用？
    input         arvalid,
    output        arready,

    output [63:0] rdata,
    output [1:0]  rresp,
    output        rlast,
    output        rvalid,
    input         rready,

    input [31:0] awaddr,
    input        awvalid,
    output       awready,
    input [3:0]  awlen,
    input [2:0]  awsize,
    input [1:0]  awburst,

    input [63:0] wdata,
    input [63:0] wstrb,
    input        wvalid,
    output       wready,

    output [1:0] bresp,
    output       bvalid,
    output       wlast,
    input        bready     
);

assign arready = 1;
assign rvalid = (cur_state == READ);
assign rresp = 2'b00;//OKAY
assign rlast = (reg_arlen == 0);

assign awready = 1;
assign wready = 1;
assign bvalid = (cur_state == WRITE);
assign bresp = 2'b00;
assign wlast = (reg_awlen == 0);

parameter IDLE = 2'b00;
parameter WRITE = 2'b01;
parameter READ = 2'b10;

reg [1:0]  cur_state;
reg [1:0]  next_state;

always @(posedge clk) 
	if (rst)
		cur_state <= IDLE;
	else
		cur_state <= next_state;

always @(*) begin
    case(cur_state)
        IDLE:
        begin
            if(arvalid && arready)
                next_state = READ;
            else if(awvalid && awready && wvalid && wready)
                next_state = WRITE;
            else
                next_state = IDLE;
        end
        READ:
        begin
            if(arvalid && arready)
                next_state = READ;
            else if(rvalid && rready && rlast)
                next_state = IDLE;
            else 
                next_state = READ;
        end
        WRITE:
        begin
            if(bvalid && bready && wlast)
                next_state = IDLE;
            else
                next_state = WRITE;
        end
        default:
            next_state = cur_state;
    endcase
end

reg [31:0] reg_araddr;
reg [3:0]  reg_arlen;
reg [2:0]  reg_arsize;   
reg [1:0]  reg_arburst; 

always @(posedge clk) begin
    if(arvalid && arready) begin
        reg_araddr <= araddr;
        reg_arsize <= arsize;
        reg_arburst <= arburst;
    end
    else if(cur_state == READ && reg_arburst == 2'b01)
        reg_araddr <= reg_araddr + (1 << reg_arsize);
end
always @(posedge clk) begin
    if(arvalid && arready)
        reg_arlen <= arlen;
    else if(cur_state == READ)
        reg_arlen <= reg_arlen-1;
end

reg [31:0] reg_awaddr;
reg [63:0] reg_wstrb;
reg [3:0]  reg_awlen;
reg [2:0]  reg_awsize;
reg [1:0]  reg_awburst;
always @(posedge clk)begin
    if(awvalid && awready) begin
        reg_awaddr <=awaddr;
        reg_wstrb <= wstrb;
        reg_awsize <= awsize;
        reg_awburst <= awburst;
    end
    else if(cur_state == WRITE && reg_awburst == 2'b01)
        reg_awaddr <= reg_awaddr + (1 << reg_awsize);
end
always @(posedge clk) begin
    if(awvalid && awready)
        reg_awlen <= awlen;
    else if(cur_state == WRITE)
        reg_awlen <= reg_awlen-1;
end

import "DPI-C" function void pmem_read(input longint raddr, output longint rdata);
import "DPI-C" function void pmem_write(input longint waddr, input longint wdata, input longint wstrb);
always_latch begin
if(cur_state == READ)
    pmem_read({32'b0,reg_araddr}, rdata);
else if(cur_state == WRITE)
    pmem_write({32'b0,reg_awaddr}, wdata,reg_wstrb);
end


         
endmodule
