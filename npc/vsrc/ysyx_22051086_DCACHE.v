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

module ysyx_22051086_DCACHE(
    input         rst,
    input         clk,
    input [31:0]  raddr,           //读地址，32位的pc？
    input         rwen,
    output [63:0] rdata,           //读数据，即指令码
    output        rdata_valid,      //读数据有效
    input [31:0]  waddr,
    input         wen,
    input [63:0]  wdata,
    input [63:0]  wmask,
    output        wdata_valid 
);

//解析读/写地址
/* verilator lint_off UNUSED */
reg [`OFFSET_WIDTH-1:0] reg_read_offset;
reg [`INDEX_WIDTH-1:0] reg_read_index;
reg [`TAG_WIDTH-1:0] reg_read_tag;
always @(posedge clk)begin
    if(cur_state == IDLE && rwen)begin
        reg_read_offset <= raddr[`OFFSET_LOC];
        reg_read_index <= raddr[`INDEX_LOC];
        reg_read_tag <= raddr[`TAG_LOC];
    end
end
reg [`OFFSET_WIDTH-1:0] reg_write_offset;
reg [`INDEX_WIDTH-1:0] reg_write_index;
reg [`TAG_WIDTH-1:0] reg_write_tag;
reg [63:0] reg_wdata;
reg [63:0] reg_wmask;
always @(posedge clk)begin
    if(cur_state == IDLE &&  wen )begin
        reg_write_offset <= waddr[`OFFSET_LOC];
        reg_write_index <= waddr[`INDEX_LOC];
        reg_write_tag <= waddr[`TAG_LOC];
        reg_wdata <= wdata;
        reg_wmask <= wmask;
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
reg [`NUM_OF_CACHELINE_PER_WAY-1:0] way0_dirty;
S011HD1P_X32Y2D128_BW way0_data_low(way0_Q_low,clk,way0_CEN,way0_WEN_low,way0_BWEN_low,way0_A_low,way0_D_low);
S011HD1P_X32Y2D128_BW way0_data_high(way0_Q_high,clk,way0_CEN,way0_WEN_high,way0_BWEN_high,way0_A_high,way0_D_high);

reg [`TAG_WIDTH-1:0] way1_tag [`NUM_OF_CACHELINE_PER_WAY-1:0];
reg [`NUM_OF_CACHELINE_PER_WAY-1:0] way1_valid;
reg [`NUM_OF_CACHELINE_PER_WAY-1:0] way1_dirty;
S011HD1P_X32Y2D128_BW way1_data_low(way1_Q_low,clk,way1_CEN,way1_WEN_low,way1_BWEN_low,way1_A_low,way1_D_low);
S011HD1P_X32Y2D128_BW way1_data_high(way1_Q_high,clk,way1_CEN,way1_WEN_high,way1_BWEN_high,way1_A_high,way1_D_high);

reg [`TAG_WIDTH-1:0] way2_tag [`NUM_OF_CACHELINE_PER_WAY-1:0];
reg [`NUM_OF_CACHELINE_PER_WAY-1:0] way2_valid;
reg [`NUM_OF_CACHELINE_PER_WAY-1:0] way2_dirty;
S011HD1P_X32Y2D128_BW way2_data_low(way2_Q_low,clk,way2_CEN,way2_WEN_low,way2_BWEN_low,way2_A_low,way2_D_low);
S011HD1P_X32Y2D128_BW way2_data_high(way2_Q_high,clk,way2_CEN,way2_WEN_high,way2_BWEN_high,way2_A_high,way2_D_high);

reg [`TAG_WIDTH-1:0] way3_tag [`NUM_OF_CACHELINE_PER_WAY-1:0];
reg [`NUM_OF_CACHELINE_PER_WAY-1:0] way3_valid;
reg [`NUM_OF_CACHELINE_PER_WAY-1:0] way3_dirty;
S011HD1P_X32Y2D128_BW way3_data_low(way3_Q_low,clk,way3_CEN,way3_WEN_low,way3_BWEN_low,way3_A_low,way3_D_low);
S011HD1P_X32Y2D128_BW way3_data_high(way3_Q_high,clk,way3_CEN,way3_WEN_high,way3_BWEN_high,way3_A_high,way3_D_high);

//cache状态机(只读)
parameter IDLE = 4'b0000;                     //0
parameter READ = 4'b0001;                     //1
parameter WRITE = 4'b0010;                    //2
parameter READ_HIT = 4'b0011;                 //3
parameter READ_MISS = 4'b0100;                //4
parameter WRITE_HIT = 4'b0101;                //5
parameter WRITE_MISS = 4'b0110;               //6
parameter READ_REFILL = 4'b0111;              //7
parameter WRITE_REFILL = 4'b1000;             //8
parameter WRITE_REPLACE = 4'b1001;            //9
parameter READ_HIT_AFTER_REFILL = 4'b1010;    //a
parameter READ_WAIT_READ_CACHE = 4'b1011;     //b
parameter WRITE_AFTER_REFILL = 4'b1100;       //c
parameter READ_REPLACE = 4'b1101;             //d

reg [3:0]  cur_state;
reg [3:0]  next_state;

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
            else if(wen)
                next_state = WRITE;
            else
                next_state = IDLE;
        end
        READ:
        begin
            if(read_hit)                            
                next_state = READ_HIT;
            else 
                next_state = READ_MISS;
        end
        WRITE:
        begin
            if(write_hit)
                next_state = WRITE_HIT;
            else
                next_state = WRITE_MISS;
        end
        READ_HIT:
        begin
            next_state = IDLE;
        end
        READ_MISS:
        begin
            if(replace)
                next_state = READ_REPLACE;
            else if(axi_arvalid && axi_arready)
                next_state = READ_REFILL;
            else
                next_state = READ_MISS;
        end
        READ_REPLACE:
        begin
            if(axi_wlast)
                next_state = READ_MISS;
            else
                next_state = READ_REPLACE;
        end
        READ_REFILL:
        begin
            if(axi_rlast)
                next_state = READ_HIT_AFTER_REFILL;
            else
                next_state = READ_REFILL;
        end
        READ_HIT_AFTER_REFILL:
        begin
            next_state = READ_WAIT_READ_CACHE;
        end
        READ_WAIT_READ_CACHE:
        begin
            next_state = IDLE;
        end
        WRITE_HIT:
        begin
            next_state = IDLE;
        end
        WRITE_MISS:                                       
        begin
            if(replace)                            //该cacheline有有效的脏数据
                next_state = WRITE_REPLACE;
            else if(axi_arvalid && axi_arready)           //没脏数据\脏数据写回后时发送读请求并等待读回的64位数据
                next_state = WRITE_REFILL;
            else
                next_state = WRITE_MISS;
        end
        WRITE_REPLACE:
        begin
            if(axi_wlast)                                   //axi写数据完成返回WRITE_MISS发读请求
                next_state = WRITE_MISS;
            else
                next_state = WRITE_REPLACE;
        end
        WRITE_REFILL:
        begin
            if(axi_rlast)
                next_state = WRITE_AFTER_REFILL;
            else 
                next_state = WRITE_REFILL;
        end
        WRITE_AFTER_REFILL:
        begin
            next_state =IDLE;
        end
        default:
            next_state = cur_state;
    endcase
end

//read_hit  read_hit_after_refill
wire [`NUM_OF_WAY-1:0] read_hit_which_way;
wire read_hit = |read_hit_which_way;
wire [63:0] read_way0_hit_data;
wire [63:0] read_way1_hit_data;
wire [63:0] read_way2_hit_data;
wire [63:0] read_way3_hit_data;
wire [63:0] read_hit_data;
assign read_hit_which_way[0] = (cur_state == READ && way0_valid[reg_read_index] && (reg_read_tag == way0_tag[reg_read_index])) 
                        ||(cur_state == READ_HIT_AFTER_REFILL && rand_way == 2'b00);
assign read_hit_which_way[1] = (cur_state == READ && way1_valid[reg_read_index] && (reg_read_tag == way1_tag[reg_read_index]))
                        ||(cur_state == READ_HIT_AFTER_REFILL && rand_way == 2'b01);
assign read_hit_which_way[2] = (cur_state == READ && way2_valid[reg_read_index] && (reg_read_tag == way2_tag[reg_read_index]))
                        ||(cur_state == READ_HIT_AFTER_REFILL && rand_way == 2'b10);
assign read_hit_which_way[3] = (cur_state == READ && way3_valid[reg_read_index] && (reg_read_tag == way3_tag[reg_read_index]))
                        ||(cur_state == READ_HIT_AFTER_REFILL && rand_way == 2'b11);
assign read_way0_hit_data = (reg_read_offset[4:3]==2'b00)? way0_Q_low[63:0]
                          : (reg_read_offset[4:3]==2'b01)? way0_Q_low[127:64]
                          : (reg_read_offset[4:3]==2'b10)? way0_Q_high[63:0]
                          : way0_Q_high[127:64];
assign read_way1_hit_data = (reg_read_offset[4:3]==2'b00)? way1_Q_low[63:0]
                          : (reg_read_offset[4:3]==2'b01)? way1_Q_low[127:64]
                          : (reg_read_offset[4:3]==2'b10)? way1_Q_high[63:0]
                          : way1_Q_high[127:64];
assign read_way2_hit_data = (reg_read_offset[4:3]==2'b00)? way2_Q_low[63:0]
                          : (reg_read_offset[4:3]==2'b01)? way2_Q_low[127:64]
                          : (reg_read_offset[4:3]==2'b10)? way2_Q_high[63:0]
                          : way2_Q_high[127:64];
assign read_way3_hit_data = (reg_read_offset[4:3]==2'b00)? way3_Q_low[63:0]
                          : (reg_read_offset[4:3]==2'b01)? way3_Q_low[127:64]
                          : (reg_read_offset[4:3]==2'b10)? way3_Q_high[63:0]
                          : way3_Q_high[127:64];
assign read_hit_data = reg_read_hit_which_way[0] ? read_way0_hit_data
                : reg_read_hit_which_way[1] ? read_way1_hit_data
                : reg_read_hit_which_way[2] ? read_way2_hit_data
                : reg_read_hit_which_way[3] ? read_way3_hit_data :0;
reg [3:0] reg_read_hit_which_way;
always @(posedge clk)begin
    if((cur_state == READ && read_hit) || cur_state == READ_HIT_AFTER_REFILL)
        reg_read_hit_which_way <= read_hit_which_way;
end

//write_hit
wire [`NUM_OF_WAY-1:0] write_hit_which_way;
wire write_hit = |write_hit_which_way;
assign write_hit_which_way[0] = (cur_state == WRITE && way0_valid[reg_write_index] && (reg_write_tag == way0_tag[reg_write_index])) 
                        ||(cur_state == WRITE_AFTER_REFILL && rand_way == 2'b00);
assign write_hit_which_way[1] = (cur_state == WRITE && way1_valid[reg_write_index] && (reg_write_tag == way1_tag[reg_write_index]))
                        ||(cur_state == WRITE_AFTER_REFILL && rand_way == 2'b01);
assign write_hit_which_way[2] = (cur_state == WRITE && way2_valid[reg_write_index] && (reg_write_tag == way2_tag[reg_write_index]))
                        ||(cur_state == WRITE_AFTER_REFILL && rand_way == 2'b10);
assign write_hit_which_way[3] = (cur_state == WRITE && way3_valid[reg_write_index] && (reg_write_tag == way3_tag[reg_write_index]))
                        ||(cur_state == WRITE_AFTER_REFILL && rand_way == 2'b11);

reg [3:0] reg_write_hit_which_way;
always @(posedge clk)begin
    if((cur_state == WRITE && write_hit) || cur_state == WRITE_AFTER_REFILL)
        reg_write_hit_which_way <= write_hit_which_way;
end

//miss
wire replace = (cur_state == WRITE_MISS && rand_way == 2'b00 && way0_valid[reg_write_index] && way0_dirty[reg_write_index])
             ||(cur_state == WRITE_MISS && rand_way == 2'b01 && way1_valid[reg_write_index] && way1_dirty[reg_write_index])
             ||(cur_state == WRITE_MISS && rand_way == 2'b10 && way2_valid[reg_write_index]&& way2_dirty[reg_write_index])
             ||(cur_state == WRITE_MISS && rand_way == 2'b11 && way3_valid[reg_write_index] && way3_dirty[reg_write_index])
             ||(cur_state == READ_MISS && rand_way == 2'b00 && way0_valid[reg_read_index] && way0_dirty[reg_read_index])
             ||(cur_state == READ_MISS && rand_way == 2'b01 && way1_valid[reg_read_index] && way1_dirty[reg_read_index])
             ||(cur_state == READ_MISS && rand_way == 2'b10 && way2_valid[reg_read_index]&& way2_dirty[reg_read_index])
             ||(cur_state == READ_MISS && rand_way == 2'b11 && way3_valid[reg_read_index] && way3_dirty[reg_read_index]);
//write replace 读出了cacheline256位，但是axi每次只能写64位，需要突发传输四次
/* verilator lint_off UNUSED */
reg [255:0] reg_way_data;
always @(posedge clk)begin
    if((cur_state == WRITE_REPLACE || cur_state==READ_REPLACE) &&rand_way == 2'b00 && replace_counter == 2'b00)
        reg_way_data <= {way0_Q_high,way0_Q_low};
    else if((cur_state == WRITE_REPLACE || cur_state==READ_REPLACE)&&rand_way == 2'b01 && replace_counter == 2'b00)
        reg_way_data <= {way1_Q_high,way1_Q_low};
    else if((cur_state == WRITE_REPLACE || cur_state==READ_REPLACE)&&rand_way == 2'b10 && replace_counter == 2'b00)
        reg_way_data <= {way2_Q_high,way2_Q_low};
    else if((cur_state == WRITE_REPLACE || cur_state==READ_REPLACE)&&rand_way == 2'b11 && replace_counter == 2'b00)
        reg_way_data <= {way3_Q_high,way3_Q_low};
end
reg [1:0] replace_counter;
always @(posedge clk)begin
    if(rst)
        replace_counter <= 2'b00;
    else if(cur_state == WRITE_REPLACE || cur_state == READ_REPLACE)
        replace_counter <= replace_counter + 1;
    else 
        replace_counter <= 2'b00;
end
//write refill 无需要定义的信号
//write after refill


//miss时 向axi发请求
/* verilator lint_off UNUSED */
wire [31:0] axi_araddr = (cur_state == READ_MISS && !replace) ? {reg_read_tag , reg_read_index , 5'b0} : {reg_write_tag , reg_write_index , 5'b0};
wire        axi_arvalid = (cur_state == READ_MISS && !replace)||(cur_state == WRITE_MISS && !replace) ;
wire [3:0]  axi_arlen =  4'b0011;
wire [2:0]  axi_arsize = 3'b011;
wire [1:0]  axi_arburst = 2'b01;
wire        axi_arready;
wire [63:0] axi_rdata;
wire [1:0]  axi_rresp;
wire        axi_rlast;
wire        axi_rvalid;
wire        axi_rready = 1;
wire [31:0] axi_awaddr = (cur_state == WRITE_MISS && rand_way == 2'b00)? {way0_tag[reg_write_index], reg_write_index , 5'b0} 
                       : (cur_state == WRITE_MISS && rand_way == 2'b01)? {way1_tag[reg_write_index], reg_write_index , 5'b0} 
                       : (cur_state == WRITE_MISS && rand_way == 2'b10)? {way2_tag[reg_write_index], reg_write_index , 5'b0} 
                       : (cur_state == WRITE_MISS && rand_way == 2'b11)? {way3_tag[reg_write_index], reg_write_index , 5'b0} 
                       : (cur_state == READ_MISS && rand_way == 2'b00)? {way0_tag[reg_read_index], reg_read_index , 5'b0} 
                       : (cur_state == READ_MISS && rand_way == 2'b01)? {way1_tag[reg_read_index], reg_read_index , 5'b0} 
                       : (cur_state == READ_MISS && rand_way == 2'b10)? {way2_tag[reg_read_index], reg_read_index , 5'b0} 
                       : {way3_tag[reg_read_index] , reg_read_index , 5'b0};
wire        axi_awvalid = (cur_state == WRITE_MISS || cur_state == READ_MISS)&&replace;
wire        axi_awready;
wire [63:0] axi_wdata = (replace_counter == 2'b00 && rand_way == 2'b00) ? way0_Q_low[63:0]
                      : (replace_counter == 2'b00 && rand_way == 2'b01) ? way1_Q_low[63:0]
                      : (replace_counter == 2'b00 && rand_way == 2'b10) ? way2_Q_low[63:0]
                      : (replace_counter == 2'b00 && rand_way == 2'b11) ? way3_Q_low[63:0]
                      : (replace_counter == 2'b01) ? reg_way_data[127:64]
                      : (replace_counter == 2'b10) ? reg_way_data[191:128]
                      : reg_way_data[255:192];
wire [63:0] axi_wstrb = 64'hffffffffffffffff;
wire        axi_wvalid = axi_awvalid ;
wire        axi_wready;
wire [3:0]  axi_awlen = 4'b0011;
wire [2:0]  axi_awsize = 3'b011;
wire [1:0]  axi_awburst = 2'b01;
wire  [1:0] axi_bresp; 
wire        axi_bvalid;
wire        axi_wlast;
wire        axi_bready = 1;
ysyx_22051086_SRAM mydcache_sram(
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
    if((cur_state == READ && !read_hit) || (cur_state == WRITE && !write_hit))
        rand_way <= lfsr[1:0];
end
always @(posedge clk) begin   //valid  tag  dirty
    if(rst)begin
        way0_valid <= 0;
        way1_valid <= 0;
        way2_valid <= 0;
        way3_valid <= 0;
        way0_dirty <= 0;
        way1_dirty <= 0;
        way2_dirty <= 0;
        way3_dirty <= 0;

    end
    else if(cur_state == READ_REFILL && rand_way == 2'b00)begin
        way0_valid[reg_read_index] <= 1;
        way0_tag[reg_read_index] <= reg_read_tag;
    end
    else if(cur_state == READ_REFILL && rand_way == 2'b01)begin
        way1_valid[reg_read_index] <= 1;
        way1_tag[reg_read_index] <= reg_read_tag;
    end
    else if(cur_state == READ_REFILL && rand_way == 2'b10)begin
        way2_valid[reg_read_index] <= 1;
        way2_tag[reg_read_index] <= reg_read_tag;
    end
    else if(cur_state == READ_REFILL&& rand_way == 2'b11)begin
        way3_valid[reg_read_index] <= 1;
        way3_tag[reg_read_index] <= reg_read_tag;
    end
    else if(cur_state == WRITE_REFILL && rand_way == 2'b00)begin
        way0_valid[reg_write_index] <= 1;
        way0_tag[reg_write_index] <= reg_write_tag;
    end
    else if(cur_state == WRITE_REFILL && rand_way == 2'b01)begin
        way1_valid[reg_write_index] <= 1;
        way1_tag[reg_write_index] <= reg_write_tag;
    end
    else if(cur_state == WRITE_REFILL && rand_way == 2'b10)begin
        way2_valid[reg_write_index] <= 1;
        way2_tag[reg_write_index] <= reg_write_tag;
    end
    else if(cur_state == WRITE_REFILL&& rand_way == 2'b11)begin
        way3_valid[reg_write_index] <= 1;
        way3_tag[reg_write_index] <= reg_write_tag;
    end
    else if((cur_state == WRITE_HIT || cur_state == WRITE_AFTER_REFILL) && rand_way ==2'b00)begin
        way0_dirty[reg_write_index] <= 1;
    end
    else if((cur_state == WRITE_HIT || cur_state == WRITE_AFTER_REFILL) && rand_way ==2'b01)begin
        way1_dirty[reg_write_index] <= 1;
    end
    else if((cur_state == WRITE_HIT || cur_state == WRITE_AFTER_REFILL) && rand_way ==2'b10)begin
        way2_dirty[reg_write_index] <= 1;
    end
    else if((cur_state == WRITE_HIT || cur_state == WRITE_AFTER_REFILL) && rand_way ==2'b11)begin
        way3_dirty[reg_write_index] <= 1;
    end
    else if(cur_state == WRITE_REPLACE && rand_way == 2'b00)begin
        way0_valid[reg_write_index] <= 0;
        way0_tag[reg_write_index] <= reg_write_tag;
    end
    else if(cur_state == WRITE_REPLACE && rand_way == 2'b01)begin
        way1_valid[reg_write_index] <= 0;
        way1_tag[reg_write_index] <= reg_write_tag;
    end
    else if(cur_state == WRITE_REPLACE && rand_way == 2'b10)begin
        way2_valid[reg_write_index] <= 0;
        way2_tag[reg_write_index] <= reg_write_tag;
    end
    else if(cur_state == WRITE_REPLACE && rand_way == 2'b11)begin
        way3_valid[reg_write_index] <= 0;
        way3_tag[reg_write_index] <= reg_write_tag;
    end
    else if(cur_state == READ_REPLACE && rand_way == 2'b00)begin
        way0_valid[reg_read_index] <= 0;
        way0_tag[reg_read_index] <= reg_read_tag;
    end
    else if(cur_state == READ_REPLACE && rand_way == 2'b01)begin
        way1_valid[reg_read_index] <= 0;
        way1_tag[reg_read_index] <= reg_read_tag;
    end
    else if(cur_state == READ_REPLACE && rand_way == 2'b10)begin
        way2_valid[reg_read_index] <= 0;
        way2_tag[reg_read_index] <= reg_read_tag;
    end
    else if(cur_state == READ_REPLACE && rand_way == 2'b11)begin
        way3_valid[reg_read_index] <= 0;
        way3_tag[reg_read_index] <= reg_read_tag;
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
    if(cur_state == READ_MISS || cur_state == WRITE_MISS)
        wcounter <= 0;
    else if(cur_state == READ_REFILL || cur_state == WRITE_REFILL)
        wcounter <= wcounter + 1;
end
reg [63:0] reg_axi_rdata;
always @(posedge clk)begin
    if((cur_state == READ_REFILL || cur_state == WRITE_REFILL)&& wcounter[0] == 0)
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
wire         way0_CEN = 0;
wire         way1_CEN = 0;
wire         way2_CEN = 0;
wire         way3_CEN = 0;//!((cur_state == READ) || (cur_state == READ_REFILL) || (cur_state == READ_HIT_AFTER_REFILL) || (cur_state == WRITE_HIT) || (cur_state == WRITE_MISS));
wire         way0_WEN_low_read_refill = cur_state == READ_REFILL && rand_way == 2'b00 && wcounter == 2'b01;
wire         way1_WEN_low_read_refill = cur_state == READ_REFILL && rand_way == 2'b01 && wcounter == 2'b01;
wire         way2_WEN_low_read_refill = cur_state == READ_REFILL && rand_way == 2'b10 && wcounter == 2'b01;
wire         way3_WEN_low_read_refill = cur_state == READ_REFILL && rand_way == 2'b11 && wcounter == 2'b01;
wire         way0_WEN_high_read_refill = cur_state == READ_REFILL && rand_way == 2'b00 && wcounter == 2'b11;
wire         way1_WEN_high_read_refill = cur_state == READ_REFILL && rand_way == 2'b01 && wcounter == 2'b11;
wire         way2_WEN_high_read_refill = cur_state == READ_REFILL && rand_way == 2'b10 && wcounter == 2'b11;
wire         way3_WEN_high_read_refill = cur_state == READ_REFILL && rand_way == 2'b11 && wcounter == 2'b11;
wire         way0_WEN_low_write_hit = cur_state == WRITE_HIT && reg_write_hit_which_way[0] && reg_write_offset[4]==0;
wire         way1_WEN_low_write_hit = cur_state == WRITE_HIT && reg_write_hit_which_way[1] && reg_write_offset[4]==0;
wire         way2_WEN_low_write_hit = cur_state == WRITE_HIT && reg_write_hit_which_way[2] && reg_write_offset[4]==0;
wire         way3_WEN_low_write_hit = cur_state == WRITE_HIT && reg_write_hit_which_way[3] && reg_write_offset[4]==0;
wire         way0_WEN_high_write_hit = cur_state == WRITE_HIT && reg_write_hit_which_way[0] && reg_write_offset[4]==1;
wire         way1_WEN_high_write_hit = cur_state == WRITE_HIT && reg_write_hit_which_way[1] && reg_write_offset[4]==1;
wire         way2_WEN_high_write_hit = cur_state == WRITE_HIT && reg_write_hit_which_way[2] && reg_write_offset[4]==1;
wire         way3_WEN_high_write_hit = cur_state == WRITE_HIT && reg_write_hit_which_way[3] && reg_write_offset[4]==1;
wire         way0_WEN_low_write_refill = cur_state == WRITE_REFILL && rand_way == 2'b00 && wcounter == 2'b01;
wire         way1_WEN_low_write_refill = cur_state == WRITE_REFILL && rand_way == 2'b01 && wcounter == 2'b01;
wire         way2_WEN_low_write_refill = cur_state == WRITE_REFILL && rand_way == 2'b10 && wcounter == 2'b01;
wire         way3_WEN_low_write_refill = cur_state == WRITE_REFILL && rand_way == 2'b11 && wcounter == 2'b01;
wire         way0_WEN_high_write_refill = cur_state == WRITE_REFILL && rand_way == 2'b00 && wcounter == 2'b11;
wire         way1_WEN_high_write_refill = cur_state == WRITE_REFILL && rand_way == 2'b01 && wcounter == 2'b11;
wire         way2_WEN_high_write_refill = cur_state == WRITE_REFILL && rand_way == 2'b10 && wcounter == 2'b11;
wire         way3_WEN_high_write_refill = cur_state == WRITE_REFILL && rand_way == 2'b11 && wcounter == 2'b11;
wire         way0_WEN_low_write_after_refill = cur_state == WRITE_AFTER_REFILL && rand_way == 2'b00 && reg_write_offset[4]==0;
wire         way1_WEN_low_write_after_refill = cur_state == WRITE_AFTER_REFILL && rand_way == 2'b01 && reg_write_offset[4]==0;
wire         way2_WEN_low_write_after_refill = cur_state == WRITE_AFTER_REFILL && rand_way == 2'b10 && reg_write_offset[4]==0;
wire         way3_WEN_low_write_after_refill = cur_state == WRITE_AFTER_REFILL && rand_way == 2'b11 && reg_write_offset[4]==0;
wire         way0_WEN_high_write_after_refill = cur_state == WRITE_AFTER_REFILL && rand_way == 2'b00 && reg_write_offset[4]==1;
wire         way1_WEN_high_write_after_refill = cur_state == WRITE_AFTER_REFILL && rand_way == 2'b01 && reg_write_offset[4]==1;
wire         way2_WEN_high_write_after_refill = cur_state == WRITE_AFTER_REFILL && rand_way == 2'b10 && reg_write_offset[4]==1;
wire         way3_WEN_high_write_after_refill = cur_state == WRITE_AFTER_REFILL && rand_way == 2'b11 && reg_write_offset[4]==1;
wire         way0_WEN_low = !(way0_WEN_low_read_refill || way0_WEN_low_write_hit || way0_WEN_low_write_refill || way0_WEN_low_write_after_refill);
wire         way1_WEN_low = !(way1_WEN_low_read_refill || way1_WEN_low_write_hit || way1_WEN_low_write_refill || way1_WEN_low_write_after_refill);
wire         way2_WEN_low = !(way2_WEN_low_read_refill || way2_WEN_low_write_hit || way2_WEN_low_write_refill || way2_WEN_low_write_after_refill);
wire         way3_WEN_low = !(way3_WEN_low_read_refill || way3_WEN_low_write_hit || way3_WEN_low_write_refill || way3_WEN_low_write_after_refill);
wire         way0_WEN_high = !(way0_WEN_high_read_refill || way0_WEN_high_write_hit || way0_WEN_high_write_refill || way0_WEN_high_write_after_refill);
wire         way1_WEN_high = !(way1_WEN_high_read_refill || way1_WEN_high_write_hit || way1_WEN_high_write_refill || way1_WEN_high_write_after_refill);
wire         way2_WEN_high = !(way2_WEN_high_read_refill || way2_WEN_high_write_hit || way2_WEN_high_write_refill || way2_WEN_high_write_after_refill);
wire         way3_WEN_high = !(way3_WEN_high_read_refill || way3_WEN_high_write_hit || way3_WEN_high_write_refill || way3_WEN_high_write_after_refill);
wire [127:0] way0_BWEN_low = ((way0_WEN_low_write_hit || way0_WEN_low_write_after_refill) && reg_write_offset[3]==0) ? {{64{1'b1}},~reg_wmask}
                           : ((way0_WEN_low_write_hit || way0_WEN_low_write_after_refill) && reg_write_offset[3]==1) ? {~reg_wmask,{64{1'b1}}}
                           : 128'b0;
wire [127:0] way1_BWEN_low = ((way1_WEN_low_write_hit || way1_WEN_low_write_after_refill) && reg_write_offset[3]==0) ? {{64{1'b1}},~reg_wmask}
                           : ((way1_WEN_low_write_hit || way1_WEN_low_write_after_refill) && reg_write_offset[3]==1) ? {~reg_wmask,{64{1'b1}}}
                           : 128'b0;
wire [127:0] way2_BWEN_low = ((way2_WEN_low_write_hit || way2_WEN_low_write_after_refill) && reg_write_offset[3]==0) ? {{64{1'b1}},~reg_wmask}
                           : ((way2_WEN_low_write_hit || way2_WEN_low_write_after_refill) && reg_write_offset[3]==1) ? {~reg_wmask,{64{1'b1}}}
                           : 128'b0;
wire [127:0] way3_BWEN_low = ((way3_WEN_low_write_hit || way3_WEN_low_write_after_refill) && reg_write_offset[3]==0) ? {{64{1'b1}},~reg_wmask}
                           : ((way3_WEN_low_write_hit || way3_WEN_low_write_after_refill) && reg_write_offset[3]==1) ? {~reg_wmask,{64{1'b1}}}
                           : 128'b0;
wire [127:0] way0_BWEN_high = ((way0_WEN_high_write_hit || way0_WEN_high_write_after_refill) && reg_write_offset[3]==0) ? {{64{1'b1}},~reg_wmask}
                           : ((way0_WEN_high_write_hit  || way0_WEN_high_write_after_refill) && reg_write_offset[3]==1) ? {~reg_wmask,{64{1'b1}}}
                           : 128'b0;
wire [127:0] way1_BWEN_high = ((way1_WEN_high_write_hit || way1_WEN_high_write_after_refill)&& reg_write_offset[3]==0) ? {{64{1'b1}},~reg_wmask}
                           : ((way1_WEN_high_write_hit || way1_WEN_high_write_after_refill)&& reg_write_offset[3]==1) ? {~reg_wmask,{64{1'b1}}}
                           : 128'b0;
wire [127:0] way2_BWEN_high = ((way2_WEN_high_write_hit || way2_WEN_high_write_after_refill)&& reg_write_offset[3]==0) ? {{64{1'b1}},~reg_wmask}
                           : ((way2_WEN_high_write_hit || way2_WEN_high_write_after_refill)&& reg_write_offset[3]==1) ? {~reg_wmask,{64{1'b1}}}
                           : 128'b0;
wire [127:0] way3_BWEN_high = ((way3_WEN_high_write_hit || way3_WEN_high_write_after_refill)&& reg_write_offset[3]==0) ? {{64{1'b1}},~reg_wmask}
                           : ((way3_WEN_high_write_hit || way3_WEN_high_write_after_refill)&& reg_write_offset[3]==1) ? {~reg_wmask,{64{1'b1}}}
                           : 128'b0;
wire         way0_write_replace = cur_state == WRITE_MISS && replace && rand_way == 2'b00;
wire         way1_write_replace = cur_state == WRITE_MISS && replace && rand_way == 2'b01;
wire         way2_write_replace = cur_state == WRITE_MISS && replace && rand_way == 2'b10;
wire         way3_write_replace = cur_state == WRITE_MISS && replace && rand_way == 2'b11;
wire [5:0]   way0_A_low = (way0_WEN_low_write_hit || way0_WEN_low_write_refill || way0_WEN_low_write_after_refill || way0_write_replace) ? reg_write_index : reg_read_index;
wire [5:0]   way1_A_low = (way1_WEN_low_write_hit || way1_WEN_low_write_refill || way1_WEN_low_write_after_refill || way1_write_replace) ? reg_write_index : reg_read_index;
wire [5:0]   way2_A_low = (way2_WEN_low_write_hit || way2_WEN_low_write_refill || way2_WEN_low_write_after_refill || way2_write_replace) ? reg_write_index : reg_read_index;
wire [5:0]   way3_A_low = (way3_WEN_low_write_hit || way3_WEN_low_write_refill || way3_WEN_low_write_after_refill || way3_write_replace) ? reg_write_index : reg_read_index;
wire [5:0]   way0_A_high = (way0_WEN_high_write_hit || way0_WEN_high_write_refill || way0_WEN_high_write_after_refill || way0_write_replace) ? reg_write_index : reg_read_index;
wire [5:0]   way1_A_high = (way1_WEN_high_write_hit || way1_WEN_high_write_refill || way1_WEN_high_write_after_refill || way1_write_replace) ? reg_write_index : reg_read_index;
wire [5:0]   way2_A_high = (way2_WEN_high_write_hit || way2_WEN_high_write_refill || way2_WEN_high_write_after_refill || way2_write_replace) ? reg_write_index : reg_read_index;
wire [5:0]   way3_A_high = (way3_WEN_high_write_hit || way3_WEN_high_write_refill || way3_WEN_high_write_after_refill || way3_write_replace) ? reg_write_index : reg_read_index;
wire [63:0]  reg_wdata_handled = (reg_wmask == 64'hff00) ? reg_wdata << 8
                               : (reg_wmask == 64'hff0000) ? reg_wdata << 16
                               : (reg_wmask == 64'hff000000) ? reg_wdata << 24
                               : (reg_wmask == 64'hff00000000) ? reg_wdata << 32
                               : (reg_wmask == 64'hff0000000000) ? reg_wdata << 40
                               : (reg_wmask == 64'hff000000000000) ? reg_wdata << 48
                               : (reg_wmask == 64'hff00000000000000) ? reg_wdata << 56
                               : (reg_wmask == 64'hffff0000) ? reg_wdata << 16
                               : (reg_wmask == 64'hffff00000000) ? reg_wdata << 32
                               : (reg_wmask == 64'hffff000000000000) ? reg_wdata << 48
                               : (reg_wmask == 64'hffffffff00000000) ? reg_wdata << 32
                               : reg_wdata;
wire [127:0] way0_D_low = (way0_WEN_low_write_hit || way0_WEN_low_write_after_refill) ? {reg_wdata_handled,reg_wdata_handled}:{axi_rdata,reg_axi_rdata};
wire [127:0] way1_D_low = (way1_WEN_low_write_hit || way1_WEN_low_write_after_refill)? {reg_wdata_handled,reg_wdata_handled}:{axi_rdata,reg_axi_rdata};
wire [127:0] way2_D_low = (way2_WEN_low_write_hit || way2_WEN_low_write_after_refill)? {reg_wdata_handled,reg_wdata_handled}:{axi_rdata,reg_axi_rdata};
wire [127:0] way3_D_low = (way3_WEN_low_write_hit || way3_WEN_low_write_after_refill)? {reg_wdata_handled,reg_wdata_handled}:{axi_rdata,reg_axi_rdata};
wire [127:0] way0_D_high = (way0_WEN_high_write_hit || way0_WEN_high_write_after_refill)? {reg_wdata_handled,reg_wdata_handled}:{axi_rdata,reg_axi_rdata};
wire [127:0] way1_D_high = (way1_WEN_high_write_hit || way1_WEN_high_write_after_refill)? {reg_wdata_handled,reg_wdata_handled}:{axi_rdata,reg_axi_rdata};
wire [127:0] way2_D_high = (way2_WEN_high_write_hit || way2_WEN_high_write_after_refill)? {reg_wdata_handled,reg_wdata_handled}:{axi_rdata,reg_axi_rdata};
wire [127:0] way3_D_high = (way3_WEN_high_write_hit || way3_WEN_high_write_after_refill)? {reg_wdata_handled,reg_wdata_handled}:{axi_rdata,reg_axi_rdata};



assign rdata =  read_hit_data ;         
assign rdata_valid = (cur_state == READ_HIT || cur_state == READ_WAIT_READ_CACHE);
assign wdata_valid = cur_state == WRITE_HIT || cur_state == WRITE_AFTER_REFILL;
endmodule
