//CACHE大小相关的参数
`define CACHE_SIZE 8192          //8K字节
`define NUM_OF_WAY 4             //暂定四路组相连
`define CACHELINE_SIZE 32        //cacheline的大小，暂定128位,即16字节
`define CACHELINE_DATA_SIZE 256  //用bit表示CACHELINE_SIZE
`define SIZE_PER_WAY  2048           //CACHE_SIZE/NUM_OF_WAY
`define NUM_OF_CACHELINE_PER_WAY 64 //SIZE_PER_WAY/CACHELINE_SIZE

//tag、index、offset的位宽
`define OFFSET_WIDTH 5               //log2(CACHELINE_SIZE)
`define INDEX_WIDTH 6                //log2(NUM_OF_CACHELINE_PER_WAY)
`define TAG_WIDTH 21
`define OFFSET_LOC `OFFSET_WIDTH-1:0
`define INDEX_LOC `OFFSET_WIDTH+`INDEX_WIDTH-1:`OFFSET_WIDTH
`define TAG_LOC 31:`OFFSET_WIDTH+`INDEX_WIDTH                 

module ysyx_22051086_ICACHE(
    input         rst,
    input         clk,
    input [31:0]  raddr,           //读地址，32位的pc？
    input         rwen,
    output [31:0] rdata,           //读数据，即指令码
    output        rdata_valid      //读数据有效
    //axi
    /*
    output [31:0] axi_araddr,
    output        axi_arvalid,
    output [3:0]  axi_arlen,
    output [2:0]  axi_arsize,
    output [1:0]  axi_arburst,
    input         axi_arready,
    input [63:0]  axi_rdata,
    input         axi_rlast,
    input         axi_rvalid,
    output        axi_rready 
*/
);

//解析读地址
reg [`OFFSET_WIDTH-1:0] reg_offset;
reg [`INDEX_WIDTH-1:0] reg_index;
reg [`TAG_WIDTH-1:0] reg_tag;
always @(posedge clk)begin
    if(cur_state == IDLE && rwen)begin
        reg_offset <= raddr[`OFFSET_LOC];
        reg_index <= raddr[`INDEX_LOC];
        reg_tag <= raddr[`TAG_LOC];
    end
end

//定义cache
/*
S011HD1P_X32Y2D128_BW(
    output [127:0] Q,              //读数据
    input          CLK,             
    input          CEN,            //使能信号，低电平有效
    input          WEN,            //写使能信号，低电平有效
    input [127:0]  BWEN,           //写掩玛，低电平有效
    input [5:0]    A,              //读写地质
    input [127:0]  D               //写数据
)
*/
reg [`TAG_WIDTH-1:0] way0_tag [`NUM_OF_CACHELINE_PER_WAY-1:0];
reg [`NUM_OF_CACHELINE_PER_WAY-1:0] way0_valid; 
S011HD1P_X32Y2D128_BW way0_data_low(way0_Q_low,clk,way0_CEN,way0_WEN_low,way0_BWEN,way0_A_low,way0_D_low);
S011HD1P_X32Y2D128_BW way0_data_high(way0_Q_high,clk,way0_CEN,way0_WEN_high,way0_BWEN,way0_A_high,way0_D_high);

reg [`TAG_WIDTH-1:0] way1_tag [`NUM_OF_CACHELINE_PER_WAY-1:0];
reg [`NUM_OF_CACHELINE_PER_WAY-1:0] way1_valid;
S011HD1P_X32Y2D128_BW way1_data_low(way1_Q_low,clk,way1_CEN,way1_WEN_low,way1_BWEN,way1_A_low,way1_D_low);
S011HD1P_X32Y2D128_BW way1_data_high(way1_Q_high,clk,way1_CEN,way1_WEN_high,way1_BWEN,way1_A_high,way1_D_high);

reg [`TAG_WIDTH-1:0] way2_tag [`NUM_OF_CACHELINE_PER_WAY-1:0];
reg [`NUM_OF_CACHELINE_PER_WAY-1:0] way2_valid;
S011HD1P_X32Y2D128_BW way2_data_low(way2_Q_low,clk,way2_CEN,way2_WEN_low,way2_BWEN,way2_A_low,way2_D_low);
S011HD1P_X32Y2D128_BW way2_data_high(way2_Q_high,clk,way2_CEN,way2_WEN_high,way2_BWEN,way2_A_high,way2_D_high);

reg [`TAG_WIDTH-1:0] way3_tag [`NUM_OF_CACHELINE_PER_WAY-1:0];
reg [`NUM_OF_CACHELINE_PER_WAY-1:0] way3_valid;
S011HD1P_X32Y2D128_BW way3_data_low(way3_Q_low,clk,way3_CEN,way3_WEN_low,way3_BWEN,way3_A_low,way3_D_low);
S011HD1P_X32Y2D128_BW way3_data_high(way3_Q_high,clk,way3_CEN,way3_WEN_high,way3_BWEN,way3_A_high,way3_D_high);

//cache状态机(只读)
parameter IDLE = 3'b000;
parameter READ = 3'b001;
parameter HIT = 3'b010; 
parameter MISS = 3'b011;
parameter REFILL = 3'b100;
parameter HIT_AFTER_REFILL = 3'b101;
parameter WAIT_READ_CACHE = 3'b110;

reg [2:0]  cur_state;
reg [2:0]  next_state;

always @(posedge clk) 
	if (rst)
		cur_state <= IDLE;
	else
		cur_state <= next_state;

always @(*) begin
    case(cur_state)
        IDLE:
        begin
            if(rwen)
                next_state = READ;
            else
                next_state = IDLE;
        end
        READ:
        begin
            if(hit)                            
                next_state = HIT;
            else 
                next_state = MISS;
        end
        HIT:
        begin
            next_state = IDLE;
        end
        MISS:
        begin
            if(axi_arvalid && axi_arready)
                next_state = REFILL;
            else
                next_state = MISS;
        end
        REFILL:
        begin
            if(axi_rlast)
                next_state = HIT_AFTER_REFILL;
            else
                next_state = REFILL;
        end
        HIT_AFTER_REFILL:
        begin
            next_state = WAIT_READ_CACHE;
        end
        WAIT_READ_CACHE:
        begin
            next_state = IDLE;
        end
        default:
            next_state = cur_state;
    endcase
end

//hit  hit_after_refill
/*
offset:**00 **04 **08 **0c 
*/
wire [`NUM_OF_WAY-1:0] hit_which_way;
wire hit = |hit_which_way;
wire [31:0] way0_hit_data;
wire [31:0] way1_hit_data;
wire [31:0] way2_hit_data;
wire [31:0] way3_hit_data;
wire [31:0] hit_data;
wire [31:0] hit_after_refill_data;
assign hit_which_way[0] = (cur_state == READ && way0_valid[reg_index] && (reg_tag == way0_tag[reg_index])) 
                        ||(cur_state == HIT_AFTER_REFILL && rand_way == 2'b00);
assign hit_which_way[1] = (cur_state == READ && way1_valid[reg_index] && (reg_tag == way1_tag[reg_index]))
                        ||(cur_state == HIT_AFTER_REFILL && rand_way == 2'b01);
assign hit_which_way[2] = (cur_state == READ && way2_valid[reg_index] && (reg_tag == way2_tag[reg_index]))
                        ||(cur_state == HIT_AFTER_REFILL && rand_way == 2'b10);
assign hit_which_way[3] = (cur_state == READ && way3_valid[reg_index] && (reg_tag == way3_tag[reg_index]))
                        ||(cur_state == HIT_AFTER_REFILL && rand_way == 2'b11);
assign way0_hit_data = (reg_offset==5'b00000)? way0_Q_low[31:0]
                     : (reg_offset==5'b00100)? way0_Q_low[63:32]
                     : (reg_offset==5'b01000)? way0_Q_low[95:64]
                     : (reg_offset==5'b01100)? way0_Q_low[127:96]
                     : (reg_offset==5'b10000)? way0_Q_high[31:0]
                     : (reg_offset==5'b10100)? way0_Q_high[63:32]
                     : (reg_offset==5'b11000)? way0_Q_high[95:64]
                     : (reg_offset==5'b11100)? way0_Q_high[127:96]
                     : 0;
assign way1_hit_data = (reg_offset==5'b00000)? way1_Q_low[31:0]
                     : (reg_offset==5'b00100)? way1_Q_low[63:32]
                     : (reg_offset==5'b01000)? way1_Q_low[95:64]
                     : (reg_offset==5'b01100)? way1_Q_low[127:96]
                     : (reg_offset==5'b10000)? way1_Q_high[31:0]
                     : (reg_offset==5'b10100)? way1_Q_high[63:32]
                     : (reg_offset==5'b11000)? way1_Q_high[95:64]
                     : (reg_offset==5'b11100)? way1_Q_high[127:96]
                     : 0;
assign way2_hit_data = (reg_offset==5'b00000)? way2_Q_low[31:0]
                     : (reg_offset==5'b00100)? way2_Q_low[63:32]
                     : (reg_offset==5'b01000)? way2_Q_low[95:64]
                     : (reg_offset==5'b01100)? way2_Q_low[127:96]
                     : (reg_offset==5'b10000)? way2_Q_high[31:0]
                     : (reg_offset==5'b10100)? way2_Q_high[63:32]
                     : (reg_offset==5'b11000)? way2_Q_high[95:64]
                     : (reg_offset==5'b11100)? way2_Q_high[127:96]
                     : 0;
assign way3_hit_data = (reg_offset==5'b00000)? way3_Q_low[31:0]
                     : (reg_offset==5'b00100)? way3_Q_low[63:32]
                     : (reg_offset==5'b01000)? way3_Q_low[95:64]
                     : (reg_offset==5'b01100)? way3_Q_low[127:96]
                     : (reg_offset==5'b10000)? way3_Q_high[31:0]
                     : (reg_offset==5'b10100)? way3_Q_high[63:32]
                     : (reg_offset==5'b11000)? way3_Q_high[95:64]
                     : (reg_offset==5'b11100)? way3_Q_high[127:96]
                     : 0;
assign hit_data = reg_hit_which_way[0] ? way0_hit_data
                : reg_hit_which_way[1] ? way1_hit_data
                : reg_hit_which_way[2] ? way2_hit_data
                : reg_hit_which_way[3] ? way3_hit_data :0;
assign hit_after_refill_data = reg_hit_which_way[0] ? way0_hit_data
                : reg_hit_which_way[1] ? way1_hit_data
                : reg_hit_which_way[2] ? way2_hit_data
                : way3_hit_data;
reg [3:0] reg_hit_which_way;
always @(posedge clk)begin
    if((cur_state == READ && hit) || cur_state == HIT_AFTER_REFILL)
        reg_hit_which_way <= hit_which_way;
end

/*用for循环
genvar index_of_way;
generate
    for(index_of_way = 0; index_of_way < `NUM_OF_WAY ; index_of_way = index_of_way + 1)
    begin
        hit_which_way[index_of_way] = r_tag 
    end
endgenerate
*/

//miss时 向axi发请求
/* verilator lint_off UNUSED */
wire [31:0] axi_araddr = {reg_tag , reg_index , 5'b0};
wire        axi_arvalid = cur_state == MISS;
wire [3:0]  axi_arlen = 4'b0011;
wire [2:0]  axi_arsize = 3'b011;
wire [1:0]  axi_arburst = 2'b01;
wire        axi_arready;
wire [63:0] axi_rdata;
wire [1:0]  axi_rresp;
wire        axi_rlast;
wire        axi_rvalid;
wire        axi_rready = 1;
//屏蔽写端口
wire [31:0] axi_awaddr = 0;
wire        axi_awvalid = 0;
wire        axi_awready;
wire [3:0]  axi_awlen = 4'b0011;
wire [2:0]  axi_awsize = 3'b011;
wire [1:0]  axi_awburst = 2'b01;
wire [63:0] axi_wdata = 0;
wire [63:0] axi_wstrb = 0;
wire        axi_wvalid = 0;
wire        axi_wready;
wire  [1:0] axi_bresp; 
wire        axi_wlast;
wire        axi_bvalid;
wire        axi_bready = 0;
ysyx_22051086_SRAM myicache_sram(
    .clk(clk),
    .rst(rst),
    .araddr(axi_araddr), 
    .arlen(axi_arlen),
    .arsize(axi_arsize),
    .arburst(axi_arburst),
    .arvalid(axi_arvalid),
    .arready(axi_arready),
    .rdata(axi_rdata),
    .rresp(axi_rresp),
    .rlast(axi_rlast),
    .rvalid(axi_rvalid),
    .rready(axi_rready),
    .awaddr(axi_awaddr),
    .awvalid(axi_awvalid),
    .awready(axi_awready),
    .awlen(axi_awlen),
    .awsize(axi_awsize),
    .awburst(axi_awburst),
    .wdata(axi_wdata),
    .wstrb(axi_wstrb),
    .wvalid(axi_wvalid),
    .wready(axi_wready),
    .bresp(axi_bresp),
    .bvalid(axi_bvalid),
    .wlast(axi_wlast),
    .bready(axi_bready)  
);

//refill暂时使用随机算法(lfsr) fifo?
reg [31:0] lfsr;
reg [1:0] rand_way; //位款随有多少路而定 
always @(posedge clk) begin
    if(rst)
        lfsr <= 32'hdeadbeef;
    else
        lfsr <= {lfsr[30:0] , lfsr[0]^lfsr[1]^lfsr[2]^lfsr[3]};
end
always @(posedge clk) begin
    if(cur_state == MISS)
        rand_way <= lfsr[1:0];
end
always @(posedge clk) begin   //valid  tag
    if(rst)begin
        way0_valid <= 0;
        way1_valid <= 0;
        way2_valid <= 0;
        way3_valid <= 0;
    end
    else if(cur_state == REFILL && rand_way == 2'b00)begin
        way0_valid[reg_index] <= 1;
        way0_tag[reg_index] <= reg_tag;
    end
    else if(cur_state == REFILL && rand_way == 2'b01)begin
        way1_valid[reg_index] <= 1;
        way1_tag[reg_index] <= reg_tag;
    end
    else if(cur_state == REFILL && rand_way == 2'b10)begin
        way2_valid[reg_index] <= 1;
        way2_tag[reg_index] <= reg_tag;
    end
    else if(cur_state == REFILL && rand_way == 2'b11)begin
        way3_valid[reg_index] <= 1;
        way3_tag[reg_index] <= reg_tag;
    end
end
/*
S011HD1P_X32Y2D128_BW(
    output [127:0] Q,              //读数据
    input          CLK,             
    input          CEN,            //使能信号，低电平有效
    input          WEN,            //写使能信号，低电平有效
    input [127:0]  BWEN,           //写掩玛，低电平有效
    input [5:0]    A,              //读写地质
    input [127:0]  D               //写数据
)
*/
reg [1:0] wcounter;
always @ (posedge clk)begin
    if(cur_state == MISS)
        wcounter <= 0;
    else if(cur_state == REFILL)
        wcounter <= wcounter + 1;
end
reg [63:0] reg_axi_rdata;
always @(posedge clk)begin
    if(cur_state == REFILL && wcounter[0] == 0)
        reg_axi_rdata <= axi_rdata;
end
wire [127:0] way0_Q_low;
wire [127:0] way1_Q_low;
wire [127:0] way2_Q_low;
wire [127:0] way3_Q_low;
wire [127:0] way0_Q_high;
wire [127:0] way1_Q_high;
wire [127:0] way2_Q_high;
wire [127:0] way3_Q_high;
wire         way0_CEN = !((cur_state == READ) || (cur_state == REFILL) || (cur_state == HIT_AFTER_REFILL));
wire         way1_CEN = !((cur_state == READ) || (cur_state == REFILL) || (cur_state == HIT_AFTER_REFILL));
wire         way2_CEN = !((cur_state == READ) || (cur_state == REFILL) || (cur_state == HIT_AFTER_REFILL));
wire         way3_CEN = !((cur_state == READ) || (cur_state == REFILL) || (cur_state == HIT_AFTER_REFILL));
wire         way0_WEN_low = !(cur_state == REFILL && rand_way == 2'b00 && wcounter == 2'b01 );
wire         way1_WEN_low = !(cur_state == REFILL && rand_way == 2'b01 && wcounter == 2'b01 );
wire         way2_WEN_low = !(cur_state == REFILL && rand_way == 2'b10 && wcounter == 2'b01 );
wire         way3_WEN_low = !(cur_state == REFILL && rand_way == 2'b11 && wcounter == 2'b01 );
wire         way0_WEN_high = !(cur_state == REFILL && rand_way == 2'b00 && wcounter == 2'b11);
wire         way1_WEN_high = !(cur_state == REFILL && rand_way == 2'b01 && wcounter == 2'b11);
wire         way2_WEN_high = !(cur_state == REFILL && rand_way == 2'b10 && wcounter == 2'b11);
wire         way3_WEN_high = !(cur_state == REFILL && rand_way == 2'b11 && wcounter == 2'b11);
wire [127:0] way0_BWEN = 128'b0;
wire [127:0] way1_BWEN = 128'b0;
wire [127:0] way2_BWEN = 128'b0;
wire [127:0] way3_BWEN = 128'b0;
wire [5:0]   way0_A_low = reg_index;
wire [5:0]   way1_A_low = reg_index;
wire [5:0]   way2_A_low = reg_index;
wire [5:0]   way3_A_low = reg_index;
wire [5:0]   way0_A_high = reg_index;
wire [5:0]   way1_A_high = reg_index;
wire [5:0]   way2_A_high = reg_index;
wire [5:0]   way3_A_high = reg_index;
wire [127:0] way0_D_low = {axi_rdata,reg_axi_rdata};
wire [127:0] way1_D_low = {axi_rdata,reg_axi_rdata};
wire [127:0] way2_D_low = {axi_rdata,reg_axi_rdata};
wire [127:0] way3_D_low = {axi_rdata,reg_axi_rdata};
wire [127:0] way0_D_high = {axi_rdata,reg_axi_rdata};
wire [127:0] way1_D_high = {axi_rdata,reg_axi_rdata};
wire [127:0] way2_D_high = {axi_rdata,reg_axi_rdata};
wire [127:0] way3_D_high = {axi_rdata,reg_axi_rdata};




assign rdata = (cur_state == HIT) ? hit_data : hit_after_refill_data;          
assign rdata_valid = (cur_state == HIT || cur_state == WAIT_READ_CACHE);

endmodule
