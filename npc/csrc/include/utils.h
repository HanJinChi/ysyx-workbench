#ifndef __UTILS_H__
#define __UTILS_H__

#include <common.h>


// ----------- state -----------

enum { NPC_RUNNING, NPC_STOP, NPC_END, NPC_ABORT, NPC_QUIT };

typedef struct {
  int state;
  uint32_t halt_pc;
  uint32_t halt_ret;
} NPCState;

extern NPCState npc_state;

uint64_t get_time();

#define ANSI_FG_BLACK   "\33[1;30m"
#define ANSI_FG_RED     "\33[1;31m"
#define ANSI_FG_GREEN   "\33[1;32m"
#define ANSI_FG_YELLOW  "\33[1;33m"
#define ANSI_FG_BLUE    "\33[1;34m"
#define ANSI_FG_MAGENTA "\33[1;35m"
#define ANSI_FG_CYAN    "\33[1;36m"
#define ANSI_FG_WHITE   "\33[1;37m"
#define ANSI_BG_BLACK   "\33[1;40m"
#define ANSI_BG_RED     "\33[1;41m"
#define ANSI_BG_GREEN   "\33[1;42m"
#define ANSI_BG_YELLOW  "\33[1;43m"
#define ANSI_BG_BLUE    "\33[1;44m"
#define ANSI_BG_MAGENTA "\33[1;35m"
#define ANSI_BG_CYAN    "\33[1;46m"
#define ANSI_BG_WHITE   "\33[1;47m"
#define ANSI_NONE       "\33[0m"

#define ANSI_FMT(str, fmt) fmt str ANSI_NONE



#define log_write(...)  \
  do { \
    extern FILE* log_fp; \
    extern bool log_enable(); \
    if (log_enable()) { \
      fprintf(log_fp, __VA_ARGS__); \
      fflush(log_fp); \
    } \
  } while (0) \

#define memory_log_write(...)  \
  do { \
    extern FILE* memory_log_fp; \
    extern bool memory_log_enable(); \
    if (memory_log_enable()) { \
      fprintf(memory_log_fp, __VA_ARGS__); \
      fflush(memory_log_fp); \
    } \
  } while (0) \


#define function_log_write(...)  \
  do { \
    extern FILE* function_log_fp; \
    extern bool function_log_enable(); \
    if (function_log_enable()) { \
      fprintf(function_log_fp, __VA_ARGS__); \
      fflush(function_log_fp); \
    } \
  } while (0) \

#define device_log_write(...) \
  do { \
    extern FILE* device_log_fp; \
    extern bool device_log_enable(); \
    if (device_log_enable()) { \
      fprintf(device_log_fp, __VA_ARGS__); \
      fflush(device_log_fp); \
    } \
  } while (0) \

#define exception_log_write(...) \
  do { \
    extern FILE* exception_log_fp; \
    extern bool exception_log_enable(); \
    if (exception_log_enable()) { \
      fprintf(exception_log_fp, __VA_ARGS__); \
      fflush(exception_log_fp); \
    } \
  } while (0) \

#define _Log(...) \
  do { \
    printf(__VA_ARGS__); \
    log_write(__VA_ARGS__); \
  } while (0)

#endif