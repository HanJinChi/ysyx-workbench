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
#define NR_BP 32

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;
  char str[32];
  word_t state;
} WP;

typedef struct breakpoint {
  int NO;
  struct breakpoint *next;
  char str[32];
} BP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

static BP bp_pool[NR_BP] = {};
static BP *bp_head = NULL, *bp_free_ = NULL;

WP* new_wp(){
  if(free_ == NULL) assert(0);
  WP* p = free_;
  free_ = free_->next;
  p->next = NULL; 
  return p;
}
void free_wp(WP* wp){
  wp->next = free_;
  wp->state = 0;
  free_ = wp;
}

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    wp_pool[i].state = 0;
  }

  head = NULL;
  free_ = wp_pool;
}

void store_watchpoint(char *str){
  bool success = false;
  word_t state = expr(str, &success);
  if(!success) {
    printf("invalid watchpoint\n");
    return;
  }
  WP* w = new_wp();
  w->state = state;
  strcpy(w->str, str);
  if(head == NULL){
    head = w;
  }
  else{
    WP* p = head;
    while(p->next != NULL){
      p = p->next;
    }
    p->next = w;
    w->next = NULL;
  }
}

void delete_watchpoint(int n){
  WP* p = head;
  WP* q = head;
  while(p != NULL){
    if(p->NO == n){
      q->next = p->next;
      p->next = NULL;
      if(p == head) head = NULL;
      free_wp(p);
      break;
    }
    if(p == head){
      p = p->next;
    }else{
      p = p->next;
      q = q->next;
    }
  }
}

void info_watchpoint(){
  WP* p = head;
  if(p != NULL) printf("%-8s %-15s %-4s\n", "Num", "Type", "What");
  while(p != NULL){
    printf("%-8d %-15s %-s\n", p->NO, "watchpoint", p->str);
    p = p->next;  
  }
}

bool check_watchpoint(){
  int val;
  bool success = false;
  WP* p = head;
  while(p != NULL){
    val = expr(p->str, &success);
    if(val != p->state){
      p->state = val;
      return true;    
    }
    p = p->next;
  }
  return false;
}

BP* new_bp(){
  if(bp_free_ == NULL) assert(0);
  BP* p = bp_free_;
  bp_free_ = bp_free_->next;
  p->next = NULL; 
  return p;
}
void free_bp(BP* bp){
  bp->next = bp_free_;
  bp_free_ = bp;
}

void init_bp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    bp_pool[i].NO = i;
    bp_pool[i].next = (i == NR_WP - 1 ? NULL : &bp_pool[i + 1]);
  }

  bp_head = NULL;
  bp_free_ = bp_pool;
}

void store_breakpoint(char *str){
  BP* w = new_bp();
  strcpy(w->str, str);
  if(bp_head == NULL){
    bp_head = w;
  }
  else{
    BP* p = bp_head;
    while(p->next != NULL){
      p = p->next;
    }
    p->next = w;
    w->next = NULL;
  }
}

void delete_breakpoint(int n){
  BP* p = bp_head;
  BP* q = bp_head;
  while(p != NULL){
    if(p->NO == n){
      q->next = p->next;
      p->next = NULL;
      if(p == bp_head) bp_head = NULL;
      free_bp(p);
      break;
    }
    if(p == bp_head){
      p = p->next;
    }else{
      p = p->next;
      q = q->next;
    }
  }
}

void info_breakpoint(){
  BP* p = bp_head;
  if(p != NULL) printf("%-8s %-15s %-4s\n", "Num", "Type", "What");
  while(p != NULL){
    printf("%-8d %-15s %-s\n", p->NO, "breakpoint", p->str);
    p = p->next;  
  }
}

bool check_breakpoint(word_t pc){
  word_t val;
  bool success = false;
  BP* p = bp_head;
  while(p != NULL){
    val = expr(p->str, &success);
    if(val == pc){
      return true;    
    }
    p = p->next;
  }
  return false;
}

