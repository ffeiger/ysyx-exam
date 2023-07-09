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

#include "sdb.h"

#define NR_WP 32

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].prior = (i == 0 ? NULL: &wp_pool[i - 1]);
    wp_pool[i].expr = (char*)malloc(30*sizeof(char));
    wp_pool[i].last_val=0;
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */
WP* new_wp()
{
  if(free_==NULL)
    assert(0);
  
  WP *p = free_;
  
  while (p->next!=NULL)//链表最后一个
  {
    p=p->next;
  }

  if(p!=free_)
    p->prior->next=NULL;
  else //use out
  {
    free_=NULL;
  }

  if(head==NULL){
    p->next=NULL;p->prior=NULL;
    head=p;
  }
  else{
    p->next=head->next;
    head->next=p;
    p->prior=head;
  }
  
  return p;
}

void free_wp(WP *wp)
{
  wp->expr=NULL;
  if(wp->prior==NULL)
  {
    head=wp->next;
    wp->next=NULL;
  }
  else 
  {
    wp->prior->next=wp->next;
    wp->next->prior=wp->prior;
  }

  if(free_==NULL)
  {  
    free_=wp;
    wp->next=NULL;
    wp->prior=NULL;
  }
  else{
    wp->next=free_->next;
    wp->next->prior=wp;
    free_->next=wp;
    wp->prior=free_;
  } 
  
}

void compare_val()
{
  WP *p=head;
  bool *success=(bool*)malloc(sizeof(bool));
  while(p!=NULL)
  {
    if(expr(p->expr,success)!=p->last_val){
      uint64_t new_val=expr(p->expr,success);
      nemu_state.state = NEMU_STOP;
      printf("watchpoint %s has changed\n",p->expr);
      printf("old val=%lu new val=%lu\n",p->last_val,new_val);
      p->last_val=new_val;
    }
    p=p->next;
  }
  free(success);
}

void delete_w(int n)
{
  WP *p=head;
  while(p!=NULL && p->NO!=n)
  {
    p=p->next;
  }
  free_wp(p);
}

void w_display()
{
  WP *p=head;
  if(p==NULL)
  {
    printf("no watchpoint!\n");
    return;
  }
  while(p!=NULL)
  {
    printf("no:%d  expr:%s  val:%lu\n",p->NO,p->expr,p->last_val);
    p=p->next;
  }
}