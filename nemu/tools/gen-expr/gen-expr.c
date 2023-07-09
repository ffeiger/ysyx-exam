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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

#define BUF_MAX 65536

// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";
int Index=0;
int overflow=0;
int divide=0;

uint32_t choose(uint32_t n)
{
  return rand()%n;
}

void gen_num()
{
  //srand(time(NULL));
  int n=rand();
  char str[32];
  sprintf(str,"%d",n);
  for(int i=0;i<strlen(str);i++)
  {
    if(Index+i<BUF_MAX)
      buf[Index+i]=str[i];
    else 
    {
      overflow=1;
    }
  }
  Index+=strlen(str);
}

void gen(char a)
{
  if(Index<BUF_MAX)
    buf[Index++]=a;
  else 
    overflow=1;
}

void gen_rand_op()
{
  if(Index<BUF_MAX)
  {
    switch(choose(4))
    {
      case 0:buf[Index++]='+';break;
      case 1:buf[Index++]='-';break;
      case 2:buf[Index++]='*';break;
      default:buf[Index++]='/';divide=1;break;
    }
  }
  else 
    overflow=1;
}

static void gen_rand_expr() {
  if(divide)
  {
    if(Index<BUF_MAX-1)
    {
      buf[Index++]='1';
      buf[Index++]='+';
      divide=0;
    }
    else 
    {
      overflow=1;
    }
  }
  switch (choose(3)) {
    case 0: gen_num(); break;
    case 1: gen('('); gen_rand_expr(); gen(')'); break;
    default: gen_rand_expr(); gen_rand_op(); gen_rand_expr(); break;
  }
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  for (i = 0; i < loop; i ++) {
    gen_rand_expr();
    
    if(overflow)
    {
      Index=0;
      i--;
      break;
    }
    buf[Index] = '\0';
    Index=0;

    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc /tmp/.code.c -o /tmp/.expr");
    if (ret != 0) continue;

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    fscanf(fp, "%d", &result);
    pclose(fp);

    printf("%u %s\n", result, buf);
  }
  return 0;
}
