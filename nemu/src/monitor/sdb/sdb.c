/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"
#include <memory/vaddr.h>
#include <string.h>
#include <stdio.h>


static int is_batch_mode = false;
extern void open_difftest();

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }
	
  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}


static int cmd_q(char *args) {
  nemu_state.state = NEMU_QUIT;
  return -1;
}

static int cmd_si(char *args) {
  char *arg = strtok(NULL," ");
  
  if(arg==NULL){
    cpu_exec(1);
  }
  else {
    int n= (int)strtol(args,NULL,10); 
    cpu_exec(n);
  }
  return 0;
}

static int cmd_info(char *args) {
  char *arg = strtok(NULL," ");
  
  if(arg==NULL)
  {
    printf("Info what?\n");
  }
  else if(*arg=='r'){
    isa_reg_display();
  }
  else if(*arg=='w')
  {
    w_display();
  }
  return 0;
}

static int cmd_x(char *args) {
  char *arg1 = strtok(NULL," ");
  char *arg2 = strtok(NULL," ");
  int n=(int)strtol(arg1,NULL,10);
  vaddr_t start_point=strtol(arg2,NULL,16);
  for(int i=0;i<n;i++)
    printf("%#016lX:%#016lX\n",start_point+i*4,vaddr_read((start_point+i*4),4));
  return 0;
}

static int cmd_w(char *args){
  char *arg = strtok(NULL," ");
  
  if(arg!=NULL)
  {
    WP *wp=new_wp();
    bool* success = (bool*)malloc(sizeof(bool));
    int i=0;
    while(arg[i]!='\0'){
      wp->expr[i]=arg[i];
      i++;
    }
    wp->expr[i]='\0';
    wp->last_val=expr(arg,success);
    printf("wp_no:%d wp_expr:%s wp_val:%lu\n",wp->NO,wp->expr,wp->last_val);
    free(success);
  }
  else
  {
    printf("No watchpoint pointed!\n");
  }
  return 0;
}

static int cmd_d(char* args){
  char *arg = strtok(NULL," ");
  if(arg==NULL)
    {
      printf("No number!\n");
      return 0;
    }
  int n=(int)strtol(arg,NULL,10);
  delete_w(n);
  return 0;
}

static int cmd_p(char* args){
  bool *success=(bool*)malloc(sizeof(bool));
  printf("%lu\n",expr(args,success));
  free(success);
  return 0;
}

static int cmd_help(char *args);

int is_difftest_open=0;
static int cmd_detach(char* args){
  is_difftest_open = 0;
  return 0;
}

static int cmd_attach(char* args){
  is_difftest_open = 1;
  //open_difftest();
  return 0;
}

static int cmd_save(char* args){
  printf("not implemented\n");
  assert(0);  
}

static int cmd_load(char* args){
  printf("not implemented\n");
  assert(0);  
}

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },
  { "si","Execute one step", cmd_si },
  { "info", "Print the state of program", cmd_info},
  { "x", "Scan the memory",cmd_x},
  { "w", "Set watchpoint",cmd_w},
  { "d", "delete watchpoint",cmd_d},
  { "p", "evaluate the expression",cmd_p},
  { "detach", "exit difftest", cmd_detach},
  { "attach", "open difftest", cmd_attach},
  { "save", "save the state", cmd_save},
  { "load", "load the state", cmd_load}

  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

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

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

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

void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
