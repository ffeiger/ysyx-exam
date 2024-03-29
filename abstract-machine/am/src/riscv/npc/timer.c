#include <am.h>
#include "npc.h"
#include <stdio.h>

static uint64_t boot_time = 0;

static uint64_t get_time()
{
  uint64_t time =  *(volatile uint64_t *)RTC_ADDR;
  return time;
}

void __am_timer_init() {
  boot_time = get_time();
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = get_time()-boot_time;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
