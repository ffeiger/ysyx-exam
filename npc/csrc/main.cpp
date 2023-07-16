#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vysyx_22051086_top.h"
#include "svdpi.h"
#include "Vysyx_22051086_top__Dpi.h"
#include "verilated_dpi.h"
#include <getopt.h>
#include <iostream>
#include <cassert>
#include <string.h>
#include "declare.h"
using namespace std;
extern unsigned long int pmem[0X2000000];
#define ARRLEN(arr) (int)(sizeof(arr) / sizeof(arr[0]))
#define NR_CMD ARRLEN(cmd_table)

VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;

static Vysyx_22051086_top* top;

int ebreak_flag=0;
void ebreak(int i){ebreak_flag=i;}

int inv_flag=0;
void invalid_inst(int i){inv_flag=i;}

int npc_inst;
void get_inst(int i){npc_inst=i;}

long long pc;
long long nextpc;
void getpc(long long a){pc=a;}  

int one_inst;
void get_one_inst(int i){one_inst=i;}

void step_and_dump_wave(){
  top->eval();
  top->clk=!top->clk;
  top->eval();
 // contextp->timeInc(1);
 // tfp->dump(contextp->time());
}

 void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
static void npc_exec_once()
{
  //printf("%016lx\n",top->pc);
  while(one_inst==0){
    step_and_dump_wave();
    step_and_dump_wave();  
  }
  if(one_inst == 1)
  {
    one_inst=0;
  }
  char inst_info[32];
  //disassemble(inst_info, 32 ,top->pc , (uint8_t*)&top->inst, 4);
  //difftest_step(pc,nextpc);
  
  if(inv_flag)
  {
    printf("HIT BAD TRAP at pc:%016lx!\n",pc);
    assert(inv_flag==0);
  } 
  
  device_update();
}

static int cmd_q(char *args) {
  return -1;
}

static int cmd_c(char *args) {
  top->rst=0;
  while (ebreak_flag==0) {
    npc_exec_once();
  } 
  return 0;
}

static int cmd_si(char *args) {
  char *arg = strtok(NULL," ");
  top->rst=0;
  if(arg==NULL){
    npc_exec_once();
  }
  else {
    int n= (int)strtol(args,NULL,10); 
    while (n!=0) {
      npc_exec_once();
      n--;
    } 
  }
  return 0;
}

static int cmd_x(char *args) {
  char *arg1 = strtok(NULL," ");
  char *arg2 = strtok(NULL," ");
  int n=(int)strtol(arg1,NULL,10);
  unsigned int start_point=strtol(arg2,NULL,16);
  for(int i=0;i<n;i++)
    printf("%#08X:%#016lX\n",start_point+i*4,pmem[start_point+i*4-0x80000000]);
  return 0;
}

uint64_t *cpu_gpr = NULL;
extern "C" void set_gpr_ptr(const svOpenArrayHandle r) {
  cpu_gpr = (uint64_t *)(((VerilatedDpiOpenVar*)r)->datap());
}
static int cmd_info(char *args) {
  char *arg = strtok(NULL," ");
  
  if(arg==NULL)
  {
    printf("Info what?\n");
  }
  else if(*arg=='r'){
    for (int i = 0; i < 32; i++) {
      printf("gpr[%d] = 0x%lx\n", i, cpu_gpr[i]);
    }
  }
    
  return 0;
}

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "c", "Continue the execution of the program", cmd_c },
  { "si","Execute one step", cmd_si },
  { "q", "Exit NPC", cmd_q },
  { "info", "Print the state of program", cmd_info},
  { "x", "Scan the memory",cmd_x}
};

static char* rl_gets() {
  static char line_read[20];

  memset(line_read,0,strlen(line_read));  

  printf("(npc)");
  int a=scanf("%[^\n]%*c",line_read);


  return line_read;
}

bool is_batch_mode;
void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}

long img_size;
static char *log_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static char *elf_file = NULL;
static int difftest_port = 1234;

static long load_img() {
  if (img_file == NULL) {
    printf("No image is given. Use the default build-in image.\n");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  assert(fp);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  printf("The image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret;
  if(size%8==0)
     ret = fread(pmem, 8, size/8 , fp);
  else{
      ret= fread(pmem, 8 , size/8 ,fp);
      fseek(fp, size/8*8, SEEK_SET);
      ret= fread(pmem+size/8, size%8 , 1 ,fp);
  }
  assert(ret != -1);

  fclose(fp);
  return size;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}
static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"help"     , no_argument      , NULL, 'h'},
    {"elf"      , required_argument, NULL, 'e'},                              
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:d:p:e:", table, NULL)) != -1) {
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'p': sscanf(optarg, "%d", &difftest_port); break;
      case 'l': log_file = optarg; break;
      case 'd': diff_so_file = optarg; break;
      case 'e': elf_file=optarg; break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

void sim_init(){
  contextp = new VerilatedContext;
  //tfp = new VerilatedVcdC;
  top = new Vysyx_22051086_top;
  //contextp->traceEverOn(true);
  //top->trace(tfp, 0);
 // tfp->open("dump.vcd");
  img_size = load_img();
}

void sim_exit(){
  step_and_dump_wave();
  //tfp->close();
  printf("HIT GOOD TRAP!\n");
}

int main(int argc, char *argv[]) {
  parse_args(argc, argv);

  sim_init();
  
  init_device();

  top->clk=0;top->rst=1;step_and_dump_wave();top->rst=0;
  for(int i=0;i<26;i++)//26
    step_and_dump_wave();

  init_difftest(diff_so_file, img_size, difftest_port);

  sdb_mainloop();

  sim_exit();
}


