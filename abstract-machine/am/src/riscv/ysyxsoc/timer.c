#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = inl(RTC_ADDR + 4);
  uptime->us <<= 32;
  uptime->us += inl(RTC_ADDR);

  uptime->us = (uptime->us)*4; // 需要根据实际使用仿真机器进行调整
}


void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
