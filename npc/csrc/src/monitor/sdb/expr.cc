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
#include <memory/paddr.h>
#include <regex.h>

enum {
  TK_NOTYPE = 256, TK_NUMBER, TK_EQ, TK_ADD, TK_SUB, TK_MUL, TK_DIV, TK_LEFT_P, TK_RIGHT_P,
  TK_AND, TK_LTOE, TK_OR, TK_QUOTE, TK_REG

  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +",                TK_NOTYPE},         // spaces
  {"\\+",               TK_ADD},            // plus
  {"\\-",               TK_SUB},            // minus
  {"\\*",               TK_MUL},            // multiple
  {"\\/",               TK_DIV},            // divide
  {"-?(0x)?[0-9]+",     TK_NUMBER},         // number
  {"\\*(0x)?[0-9]+",    TK_QUOTE},          // quote
  {"\\$.{2}[0-1]{0,1}", TK_REG},            // reg
  {"==",                TK_EQ},             // equal
  {"<=",                TK_LTOE},           // less than or equal
  {"&&",                TK_AND},            // and
  {"\\|\\|",            TK_OR},             // or
  {"\\(",               TK_LEFT_P},         // left parenthesis
  {"\\)",               TK_RIGHT_P},        // right parenthesis
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

static Token tokens[1024] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

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
          case TK_ADD    : tokens[nr_token].type = TK_ADD;     nr_token++;    break;
          case TK_SUB    : tokens[nr_token].type = TK_SUB;     nr_token++;    break;
          case TK_MUL    : tokens[nr_token].type = TK_MUL;     nr_token++;    break;
          case TK_DIV    : tokens[nr_token].type = TK_DIV;     nr_token++;    break;
          case TK_EQ     : tokens[nr_token].type = TK_EQ;      nr_token++;    break;
          case TK_LTOE   : tokens[nr_token].type = TK_LTOE;    nr_token++;    break;
          case TK_AND    : tokens[nr_token].type = TK_AND;     nr_token++;    break;
          case TK_OR     : tokens[nr_token].type = TK_OR;      nr_token++;    break;
          case TK_LEFT_P : tokens[nr_token].type = TK_LEFT_P;  nr_token++;    break;
          case TK_RIGHT_P: tokens[nr_token].type = TK_RIGHT_P; nr_token++;    break;
          case TK_NUMBER : tokens[nr_token].type = TK_NUMBER; 
                           for(int i = 0; i < substr_len; i++) tokens[nr_token].str[i] = *(substr_start+i);
                           nr_token++; break;
          case TK_QUOTE  : tokens[nr_token].type = TK_QUOTE;
                           for(int i = 0; i < substr_len; i++) tokens[nr_token].str[i] = *(substr_start+i);
                           nr_token++; break;
          case TK_REG    : tokens[nr_token].type = TK_REG;
                           for(int i = 0; i < substr_len; i++) tokens[nr_token].str[i] = *(substr_start+i);
                           nr_token++; break;
          default: break;
        }
        if(rules[i].token_type == TK_SUB && (i == 0 || (tokens[nr_token-2].type != TK_NUMBER && tokens[nr_token-2].type != TK_RIGHT_P))) { 
          tokens[nr_token-1].type = 0, nr_token--; position -= substr_len; continue;
        }
        if(rules[i].token_type == TK_MUL && (i == 0 || (tokens[nr_token-2].type != TK_NUMBER && tokens[nr_token-2].type != TK_RIGHT_P))) { 
          tokens[nr_token-1].type = 0, nr_token--; position -= substr_len; continue;
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

bool check_parentheses(int p, int q, bool *success){
  bool mate = true;
  int ptr = 0;
  for(int i = p; i <= q; i++){
    if(tokens[i].type == TK_LEFT_P) {
      ptr++;
    }
    else if(tokens[i].type == TK_RIGHT_P) {
      if(ptr == 0) return false;
      else ptr--;
      if(ptr == 0 && i != q) mate = false; 
    }
  }
  *success = ptr == 0;
  return (tokens[p].type == TK_LEFT_P) && (tokens[q].type == TK_RIGHT_P) && mate && (*success);
}

word_t locate_main_operator(int p, int q){
  int pos = -1; int pos_number = -1; int operator_grade = -1;
  int ptr = 0;

  for(int i = p; i <= q; i++){
    if(tokens[i].type == TK_LEFT_P){
      ptr++;
    }else if(tokens[i].type == TK_RIGHT_P){
      ptr--;
    }else{
      switch (tokens[i].type)
      {
      case TK_MUL:
        if((ptr <= pos_number && 12 <= operator_grade) || pos == -1) { 
          pos = i; pos_number = ptr; operator_grade = 12;
        } break;
      case TK_DIV:
        if((ptr <= pos_number && 12 <= operator_grade)  || pos == -1) { 
          pos = i; pos_number = ptr; operator_grade = 12;
        } break;
      case TK_ADD:
        if((ptr <= pos_number && 11<= operator_grade)  || pos == -1) { 
          pos = i; pos_number = ptr; operator_grade = 11;
        } break;
      case TK_SUB:
        if((ptr <= pos_number && 11 <= operator_grade)  || pos == -1) { 
          pos = i; pos_number = ptr; operator_grade = 11;
        } break;
      case TK_LTOE:
        if((ptr <= pos_number && 8 <= operator_grade)  || pos == -1) { 
          pos = i; pos_number = ptr; operator_grade = 8;
        } break;
      case TK_EQ:
        if((ptr <= pos_number && 7 <= operator_grade)  || pos == -1) { 
          pos = i; pos_number = ptr; operator_grade = 7;
        } break;
      case TK_AND:
        if((ptr <= pos_number && 3 <= operator_grade)  || pos == -1) { 
          pos = i; pos_number = ptr; operator_grade = 3;
        } break;
      case TK_OR:
        if((ptr <= pos_number && 2 <= operator_grade)  || pos == -1) { 
          pos = i; pos_number = ptr; operator_grade = 2;
        } break;
      default:
        break;
      }
    }
  }
  return pos;
  
}

word_t eval(int p, int q, bool *success){
  if(p > q) {
    *success = false; return 0;
  }else if(p == q){
    *success = true;
    int val;
    switch (tokens[p].type)
    {
      case TK_QUOTE  : return paddr_read(strtol((char *)(tokens[p].str)+1, NULL, 0),4); break;
      case TK_NUMBER : return strtol(tokens[p].str, NULL, 0); break;
      case TK_REG    : val = isa_reg_str2val((char *)(tokens[p].str)+1, success); 
                       if(*success) return val; else return 0;
                       break;
      default: assert(0);
    }
  }
  else if(check_parentheses(p, q, success)){
    return eval(p+1, q-1, success);
  }else{
    if(*success == false) return 0;
    int op = locate_main_operator(p, q);
    int val1 = eval(p, op-1, success);
    if(*success == false) return 0;
    int val2 = eval(op+1, q, success);
    if(*success == false) return 0;
    switch (tokens[op].type)
    {
    case TK_ADD   : return val1  + val2;  break;
    case TK_SUB   : return val1  - val2;  break;
    case TK_MUL   : return val1  * val2;  break;
    case TK_DIV   : return val1  / val2;  break;
    case TK_EQ    : return val1 == val2;  break;
    case TK_LTOE  : return val1 <= val2;  break;
    case TK_AND   : return val1 && val2;  break;
    case TK_OR    : return val1 || val2;  break;
    default:
      assert(0);
    }
  }

}


word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  /* TODO: Insert codes to evaluate the expression. */
  return eval(0, nr_token-1, success);
}
