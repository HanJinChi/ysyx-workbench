#include <common.h>
#include "syscall.h"
#include "fs.h"
#include <sys/time.h>
#include <proc.h>

extern int fs_open(const char *pathname, int flags, int mode);
extern int fs_close(int fd);
extern size_t fs_read(int fd, void *buf, size_t len);
extern size_t fs_lseek(int fd, size_t offset, int whence);
size_t fs_write(int fd, const void *buf, size_t len);
extern void naive_uload(PCB *pcb, const char *filename);

extern Finfo file_table[];

void do_syscall(Context *c) {
  uintptr_t a[4];
  a[0] = c->GPR1;
  a[1] = c->GPR2;
  a[2] = c->GPR3;
  a[3] = c->GPR4;

  switch (a[0]) {
    case SYS_yield: SYSCALL_Log("syscall yield"); yield(); c->GPRx = 0; ;break;
    case SYS_exit: SYSCALL_Log("syscall exit, param0 is %d, param1 is %d", a[1], a[2]); halt(a[2]); break;
    case SYS_write:
      SYSCALL_Log("syscall write, param0 is %s, param1 is 0x%x, param2 is %d", file_table[a[1]].name, a[2], a[3]);
      c->GPRx = fs_write(a[1], (const void*)a[2], a[3]);
      break; 
    case SYS_brk:
      c->GPRx = 0;
      SYSCALL_Log("syscall brk, param0 is 0x%x", a[1]);
      break;
    case SYS_close:
      SYSCALL_Log("syscall close, param0 is %d", a[1]);
      c->GPRx = fs_close(a[1]);
      break;
    case SYS_open:
      // SYSCALL_Log("syscall open, param0 is %s, param1 is %d, param2 is %d", a[1], a[2], a[3]);
      c->GPRx = fs_open((const char*)a[1], a[2], a[3]);
      break;
    case SYS_read:
      // SYSCALL_Log("syscall read, param0 is %s, param1 is 0x%x, param2 is %d", file_table[a[1]].name, a[2], a[3]);
      c->GPRx = fs_read(a[1], (void*)a[2], a[3]);
      break;
    case SYS_lseek:
      SYSCALL_Log("syscall lseek, param0 is %s, param1 is 0x%x, param2 is %d", file_table[a[1]].name, a[2], a[3]);
      c->GPRx = fs_lseek(a[1], a[2], a[3]);
      break;
    case SYS_gettimeofday:
      SYSCALL_Log("syscall gettimeofday, param0 is 0x%x, param1 is 0x%x", a[1], a[2]);
      struct timeval* val = (struct timeval*)a[1];
      uint64_t time = io_read(AM_TIMER_UPTIME).us;
      val->tv_sec = time / 1000000;
      val->tv_usec = time % 1000000;
      c->GPRx = 0;
      break;
    case SYS_execve:
      SYSCALL_Log("syscall execve, param0 is %s, param1 is %s, oaram is %s", a[1], a[2], a[3]);
      naive_uload(NULL, (const char*)a[1]);
      break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
