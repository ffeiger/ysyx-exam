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

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>
#include <stdlib.h>
#include <malloc.h>
#include <memory/vaddr.h>


enum {
  TK_NOTYPE = 256,TK_EQ,TK_NUMTYPE,
  TK_HEXNUMTYPE,TK_REGNAME,TK_NE,
  TK_AND,DEREF,TK_MINUS,

  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE}, 
  {"0[xX][A-Fa-f0-9]+",TK_HEXNUMTYPE},
  {"[0-9]+",TK_NUMTYPE},   
  {"\\$[0a-z]+[0-9]*",TK_REGNAME},
  {"\\+", '+'},         // plus 
  {"\\-", '-'},
  {"\\*", '*'},
  {"\\/", '/'},
  {"\\(", '('},          
  {"\\)", ')'},
  {"==", TK_EQ},        // equal
  {"!=",TK_NE},
  {"&&",TK_AND}

};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[65536] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */
        
        switch (rules[i].token_type) {
          case TK_NUMTYPE:case TK_HEXNUMTYPE:case TK_REGNAME:
              tokens[nr_token].type=rules[i].token_type;
              for(int j=0;j<substr_len;j++){
                tokens[nr_token].str[j]=substr_start[j];
              }
              if(substr_len<=32)
                tokens[nr_token].str[substr_len]='\0';
              nr_token++;
              break;
          case '+':case '-':case '*':
          case '/':case '(':case ')':
          case TK_EQ:case TK_NE:case TK_AND:
              tokens[nr_token].type=rules[i].token_type;
              nr_token++;
              break;
          default: break;
        }

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

int is_legal(Token *e,int p,int q)
{
  int len=q-p+1;
  if(len==0)
    return 1;
  int s[3000];
  int top=-1;
    for(int i=p;i<p+len;i++)
    {
        if(e[i].type=='(')
        {
            top++;
            s[top]=e[i].type;    
        }
        else if(e[i].type==')'&&top>=0 && s[top]=='(')
        {
            top--;
        }
        else if(e[i].type==')'&&top<0)
        {
          return -1;
        }
    }
  if(top==-1)
    return 1;
  else 
    return -1;
}

int check_parentheses(Token *e,int p,int q)
{
  if(e[p].type!='('||e[q].type!=')')
    return 0;
  else
    return is_legal(e,p+1,q-1);
}

int is_op(int a)
{
  if(a=='+'||a=='-'||a=='*'||a=='/'||a==TK_EQ||a==TK_NE||a==TK_AND)
    return 1;
  else return 0;
}

int bra[65536]={0};
void is_in_brackets(Token *e,int p,int q)
{
  int len=q-p+1;
  int s[10000];
  int top=-1;
    for(int i=p;i<p+len;i++)
    {
        if(e[i].type=='(')
        {
            top++;
            s[top]=e[i].type;    
        }
        else if(e[i].type==')'&&top>=0 && s[top]=='(')
        {
            top--;
        }
        else if(e[i].type=='+'||e[i].type=='-'||e[i].type=='*'||e[i].type=='/')
        {
          if(top>=0)
            bra[i]=1;
          else
            bra[i]=0; 
        }
    }
  
}

int prior(int a)
{
  if(a=='+'||a=='-')
    return 0;
  else if(a=='*'||a=='/')
    return 1;
  else if(a==TK_EQ||a==TK_NE)
    return 2;
  else if(a==TK_AND)
    return 3;
  return 0;
}

int find_mainop(Token *e,int p,int q)
{
  int possible_mainop=0;
  int standard=4;
  for(int i=p;i<=q;i++)
  {
    if(!is_op(e[i].type))
      continue;
    if(bra[i]==1)
      continue;
    if(prior(e[i].type)<=standard){
      possible_mainop =i;
      standard=prior(e[i].type);
    }
  }
  int mainop=possible_mainop;
  return mainop;
}

u_int64_t eval(Token *e,int p,int q) {
  is_in_brackets(e,p,q);
  if(p > q || is_legal(e,p,q)==-1)
    {
      printf("Illegal expression!\n");
      assert(0);
    }
  else if (p==q) {
    if(e[p].type==TK_NUMTYPE)     
      return atoi(e[p].str);
    else if(e[p].type==TK_HEXNUMTYPE)
      return strtol(e[p].str, NULL, 16);
    else if(e[p].type==TK_REGNAME)
      {
      bool *success=(bool*)malloc(sizeof(bool));
      u_int64_t reg_val= isa_reg_str2val(e[p].str, success);
      free(success);
      return reg_val;
      }
  } 
  else if (check_parentheses(e ,p, q)==1) {
    /* The expression is surrounded by a matched pair of parentheses.
     * If that is the case, just throw away the parentheses.
     */
    return eval(e,p + 1, q - 1);
  }
  else if(find_mainop(e,p,q)!=0){
    int op = find_mainop(e,p,q);
    
    u_int32_t val1 = eval(e,p, op - 1);
    u_int32_t val2 = eval(e,op + 1, q);

    switch (e[op].type) {
      case '+': return val1 + val2;
      case '-': return val1 - val2;
      case '*': return val1 * val2;
      case '/': return val1 / val2;
      case TK_EQ:return (val1==val2);
      case TK_NE:return (val1!=val2);
      case TK_AND:return val1 && val2;
      default: assert(0);
    }
  }
  else if(e[p].type==TK_MINUS)
    return -eval(e,p+1,q);
  else if(e[p].type==DEREF)
    return vaddr_read(eval(e,p+1,q),4);   
  return 0;
}

int is_minus(int i)
{
  if(i==0 || tokens[i - 1].type=='(' || tokens[i - 1].type=='+' || tokens[i - 1].type=='-'
          || tokens[i - 1].type=='*' || tokens[i - 1].type=='/' || tokens[i - 1].type== TK_EQ 
          || tokens[i - 1].type== TK_NE || tokens[i - 1].type==TK_AND || tokens[i - 1].type==TK_MINUS)
    return 1;
  else 
    return 0;
}

int is_deref(int i)
{
  if(i==0 || tokens[i - 1].type=='(' || tokens[i - 1].type=='+' || tokens[i - 1].type=='-'
          || tokens[i - 1].type=='*' || tokens[i - 1].type=='/' || tokens[i - 1].type== TK_EQ 
          || tokens[i - 1].type== TK_NE || tokens[i - 1].type==TK_AND || tokens[i - 1].type==TK_MINUS
          || tokens[i - 1].type==TK_MINUS || tokens[i - 1].type==DEREF)
    return 1;
  else 
    return 0;
}

u_int64_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  for (int i = 0; i < nr_token; i ++) {
  if (tokens[i].type == '-' && is_minus(i)){
    tokens[i].type = TK_MINUS;
  }
  }

  for (int i = 0; i < nr_token; i ++) {
  if (tokens[i].type == '*' && is_deref(i)) {
    tokens[i].type = DEREF;
  }
  
}

  /* TODO: Insert codes to evaluate the expression. */
  u_int64_t res=eval(tokens,0,nr_token-1);
  nr_token=0;
  return res;
}
