#include <nterm.h>
#include <stdarg.h>
#include <unistd.h>
#include <SDL.h>

char handle_key(SDL_Event *ev);

static void sh_printf(const char *format, ...) {
  static char buf[256] = {};
  va_list ap;
  va_start(ap, format);
  int len = vsnprintf(buf, 256, format, ap);
  va_end(ap);
  term->write(buf, len);
}

static void sh_banner() {
  sh_printf("Built-in Shell in NTerm (NJU Terminal)\n\n");
}

static void sh_prompt() {
  sh_printf("sh> ");
}

static void sh_handle_cmd(const char *cmd) {
  char inst[64];
  strcpy(inst, cmd);
  inst[strlen(inst) - 1] = '\0';
  
  char *token = strtok(inst, " ");
  char *argv[16];
  int argc = 0;
  
  while(token) {
    argv[argc++] = token;
    token = strtok(NULL, " ");
  }
  argv[argc] = NULL;
  
  execvp(argv[0], argv);
  /*
  char command[128];
  strcpy(command, cmd);
  command[strlen(command) - 1] = '\0';

  const char split[2] = " ";
  char *token;
  char *argv[16];
  int argc = 0;

  token = strtok(command, split);
  while(token) {
    argv[argc++] = token;
    token = strtok(NULL, split);
  }
  argv[argc] = NULL;
  
  execvp(argv[0], argv);
  */
}

void builtin_sh_run() {
  sh_banner();
  sh_prompt();
  
  setenv("PATH", "/bin:/usr/bin", 0);
  while (1) {
    SDL_Event ev;
    if (SDL_PollEvent(&ev)) {
      if (ev.type == SDL_KEYUP || ev.type == SDL_KEYDOWN) {
        const char *res = term->keypress(handle_key(&ev));
        if (res) {
          sh_printf("load...");
          sh_handle_cmd(res);
          sh_prompt();
        }
      }
    }
    refresh_terminal();
  }
}