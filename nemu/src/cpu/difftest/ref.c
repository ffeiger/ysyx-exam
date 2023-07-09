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
#include <locale.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>
#include <malloc.h>

void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  uint64_t * tmp = (uint64_t *)buf;
  if(direction == DIFFTEST_TO_DUT)
  {
    int read_times =n/8;
    int i;
    for(i=0;i<read_times;i++)
    {
      tmp[i]=paddr_read(addr+i*8,8);
    }
    if(n%8!=0)
      tmp[i]=paddr_read(addr+i*8,n%8);
  }
  else if(direction == DIFFTEST_TO_REF)
  {
    int write_times=n/8;
    int i;
    for(i=0;i<write_times;i++)
    {
      paddr_write(addr+i*8,8,tmp[i]);
    }
    if(n%8!=0)
      paddr_write(addr+i*8,n%8,tmp[i]);
  }
}

extern CPU_state cpu;
void difftest_regcpy(void *dut, bool direction) {
   uint64_t* ctx = (uint64_t*)dut;
  
  if (direction == DIFFTEST_TO_DUT) {
    for (int i = 0; i < 32; i++) {
      ctx[i] = cpu.gpr[i];
    }
  } 
  else {
    for (int i = 0; i < 32; i++) {
      cpu.gpr[i]=ctx[i] ;
  }
  }
}

void difftest_exec(uint64_t n) {
  cpu_exec(n);
}

void difftest_raise_intr(uint64_t NO) {
  assert(0);
}

void difftest_init(int port) {
  /* Perform ISA dependent initialization. */
  init_isa();
}
