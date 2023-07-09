#include <dlfcn.h>
#include <stdio.h>
#include <assert.h>
#include <iostream>
#include <stdlib.h>
#include <unistd.h>

extern int visit_device;

typedef unsigned int paddr_t ;
typedef unsigned long int vaddr_t;
enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };
void (*ref_difftest_memcpy)(paddr_t addr, void *buf, size_t n, bool direction) = NULL;
void (*ref_difftest_regcpy)(void *dut, bool direction, bool device) = NULL;
void (*ref_difftest_exec)(uint64_t n) = NULL;
void (*ref_difftest_raise_intr)(uint64_t NO) = NULL;

static bool is_skip_ref = false;
static int skip_dut_nr_inst = 0;

void difftest_skip_ref() {
  is_skip_ref = true;
  skip_dut_nr_inst = 0;
}

void difftest_skip_dut(int nr_ref, int nr_dut) {
  skip_dut_nr_inst += nr_dut;

  while (nr_ref -- > 0) {
    ref_difftest_exec(1);
  }
}

#define MAX_MEM 0x8000000
extern uint64_t *cpu_gpr;
extern unsigned long int pmem[MAX_MEM];
void init_difftest(char *ref_so_file, long img_size, int port) {
  assert(ref_so_file != NULL);

  printf("%s\n",ref_so_file);

  void *handle;
  handle = dlopen(ref_so_file, RTLD_LAZY);
  assert(handle);

  ref_difftest_memcpy = (void(*)(paddr_t addr, void *buf, size_t n, bool direction))dlsym(handle, "difftest_memcpy");
  assert(ref_difftest_memcpy);

  ref_difftest_regcpy = (void(*)(void *dut, bool direction, bool device))dlsym(handle, "difftest_regcpy");
  assert(ref_difftest_regcpy);

  ref_difftest_exec = (void(*)(uint64_t n))dlsym(handle, "difftest_exec");
  assert(ref_difftest_exec);

  ref_difftest_raise_intr = (void(*)(uint64_t NO))dlsym(handle, "difftest_raise_intr");
  assert(ref_difftest_raise_intr);

  void (*ref_difftest_init)(int) = (void(*)(int))dlsym(handle, "difftest_init");
  assert(ref_difftest_init);

  ref_difftest_init(port);
  ref_difftest_memcpy(0x80000000,(void *)pmem, img_size, DIFFTEST_TO_REF);
  ref_difftest_regcpy(cpu_gpr, DIFFTEST_TO_REF, false);
}

extern void *vmem ;
typedef struct {
  unsigned long int gpr[32];
  vaddr_t pc;
 // u_int64_t vmem[60000];
} CPU_state;
extern 
bool isa_difftest_checkregs(CPU_state *ref_r, vaddr_t pc) {
  int i;
  if(ref_r->pc != pc)
  {
    printf("ref_pc:%016lx,npc:%016lx\n",ref_r->pc,pc);
    return false;
  }
  
  for(i=0;i<32;i++)
  {
    if(ref_r->gpr[i]!=cpu_gpr[i]){
      printf("pc=%016lx,ref[%d]= %016lx,npc[%d]=%016lx\n",pc,i,ref_r->gpr[i],i,cpu_gpr[i]);
      return false;
    }
  }
/*
  for(i=0;i<60000;i++)
  {
    if(ref_r->vmem[i]!= *((u_int64_t*)vmem+i))
    {
      printf("vmem not match ,ref[%d]:%016lx,npc[%d]:%016lx\n",i,ref_r->vmem[i],i,*((u_int64_t*)vmem+i));
      return false;
    }
  }
  */
  //if(pc==0x80001240) printf("a4:%016lx\n",cpu_gpr[14]);
  return true;
}

static void checkregs(CPU_state *ref, vaddr_t pc) {
  if (!isa_difftest_checkregs(ref, pc)) {
    assert(0); 
  }
}

int ref_visit_device=0;
void difftest_step(long long  pc,long  long npc) {
  CPU_state ref_r;

  if (skip_dut_nr_inst > 0) {
    ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT , false);
    
    if (ref_r.pc == npc) {
      skip_dut_nr_inst = 0;
      checkregs(&ref_r, npc);
      return;
    }
    
    skip_dut_nr_inst --;
    if (skip_dut_nr_inst == 0)
      printf("can not catch up with ref.pc = 0X%016lx at pc = 0X%016lx", ref_r.pc, pc);
    return;
  }

  if(ref_visit_device)
  {
    difftest_skip_ref();
    ref_visit_device =0 ;
  }

  if(visit_device){
    ref_visit_device = 1;
    visit_device = 0;
  }
  
  if (is_skip_ref) {
    // to skip the checking of an instruction, just copy the reg state to reference design
    
    ref_difftest_regcpy(cpu_gpr, DIFFTEST_TO_REF,is_skip_ref);
    is_skip_ref = false;
    return;
  }

  ref_difftest_exec(1);
  ref_difftest_regcpy(&ref_r, DIFFTEST_TO_DUT , false);

  checkregs(&ref_r, pc);
}
