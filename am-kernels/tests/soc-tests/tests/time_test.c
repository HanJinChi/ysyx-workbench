#include "trap.h"

int main(){
  AM_TIMER_UPTIME_T x = io_read(AM_TIMER_UPTIME);
  // printf("read time is %x\n", x);
}