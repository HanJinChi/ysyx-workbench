#include "sdb.h"
#include <isa.h>
#include <cpu/cpu.h>
#include <memory/paddr.h>
#include <readline/readline.h>
#include <readline/history.h>

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();
void init_bp_pool();


static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(npc) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}

static int cmd_si(char *args){
  int num;
  if(args == NULL){
    num = 1;
  }
  else{
    num = atoi(args);
  }
  cpu_exec(num);
  return 0;
}

static int cmd_q(char *args) {
  npc_state.state = NPC_QUIT;
  return -1;
}

static int cmd_info(char *args){
  if(strcmp(args, "r") == 0){
    isa_reg_display();
  }else if(strcmp(args, "w") == 0){
    info_watchpoint();
  }else if(strcmp(args, "b") == 0){
    info_breakpoint();
  }
  return 0;
}

static int cmd_x(char *args){
  int N;
  word_t value;
  int j = 0;
  // extract first parameters 
  char* args_0 = strtok(args, " ");
  /* treat the remaining string as the arguments,
  *  which may need further parsing
  */
  args = args_0 + strlen(args_0) + 1;
  
  // Convert a string to a number
  bool success = false;
  N = atoi(args_0); 
  value = expr(args, &success); // TODO : EXPR
  for(int i = 0; i < N/16; i++){
    for(int j = 0; j<16; j++){
      if(j == 0) 
        printf("0x%-9x: ", value+16*i);
      printf("%02x ", paddr_read(value+i*16+j,1));
      if(j == 15)
        printf("\n");
    }
  }
  for(int j = 0; j < N%16; j++){
    if(j == 0) 
      printf("0x%-9x: ", value+16*(N/16));
    printf("%02x ", paddr_read(value+16*(N/16)+j,1));
    if(j == (N%16-1))
      printf("\n");
  }
  return 0;
}

static int cmd_p(char *args){
  bool success;
  int val = expr(args, &success);
  if(success) printf("%u\n", val);
  return 0;
}

static int cmd_w(char* args){
  store_watchpoint(args);
  return 0;
}

static int cmd_b(char* args){
  store_breakpoint(args);
  return 0;
}

static int cmd_dw(char *args){
  int n = strtol(args, NULL, 0);
  delete_watchpoint(n);
  return 0;
}

static int cmd_db(char *args){
  int n = strtol(args, NULL, 0);
  delete_breakpoint(n);
  return 0;
}

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NPC", cmd_q },
  { "si", "Pause NPC after running [N] instructions", cmd_si },
  { "info", "Print relevant information", cmd_info },
  { "x", "Scan Memory", cmd_x },
  { "p", "Calculate the value of [expr]", cmd_p },
  { "w", "watch the value of [expr]", cmd_w },
  { "b", "set breakpoint", cmd_b },
  { "dw", "delete all watchpoint", cmd_dw },
  { "db", "delete all breakpoint", cmd_db },
  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

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

void init_sdb(){
  init_regex();

  init_wp_pool();

  init_bp_pool();
}