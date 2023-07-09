void init_difftest(char *ref_so_file, long img_size, int port);
void difftest_step(long long  pc, long long  npc);
extern "C" void pmem_read(long long raddr, long long *rdata);
extern "C" void pmem_read_inst(long long raddr,int *rdata);
extern "C" void pmem_write(long long waddr, long long wdata, long long  wstrb);
void init_device();
void device_update();