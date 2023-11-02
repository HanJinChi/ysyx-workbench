#include <common.h>

#if defined(MULTIPROGRAM) && !defined(TIME_SHARING)
# define MULTIPROGRAM_YIELD() yield()
#else
# define MULTIPROGRAM_YIELD()
#endif

#define NAME(key) \
  [AM_KEY_##key] = #key,

static const char *keyname[256] __attribute__((used)) = {
  [AM_KEY_NONE] = "NONE",
  AM_KEYS(NAME)
};

size_t serial_write(const void *buf, size_t offset, size_t len) {
  for(int i = 0; i < len; i++){
    putch(*((char*)buf+i));
  }
  return len;
}

size_t events_read(void *buf, size_t offset, size_t len) {
  AM_INPUT_KEYBRD_T ev = io_read(AM_INPUT_KEYBRD);
  if(ev.keycode == AM_KEY_NONE) {
    return 0;
  }
  return snprintf(buf, len, "Got kbd: %s (%d) %s\n", keyname[ev.keycode], ev.keycode, ev.keydown ? "DOWN" : "UP"); 
}

size_t dispinfo_read(void *buf, size_t offset, size_t len) {
  int w = io_read(AM_GPU_CONFIG).width;
  int h = io_read(AM_GPU_CONFIG).height;
  return snprintf(buf, len, "WIDTH: %d\nHEIGHT: %d\n", w, h)+1;
}

size_t fb_write(const void *buf, size_t offset, size_t len) {
  int w = io_read(AM_GPU_CONFIG).width;
  offset = offset / 4;
  int y = offset/w;
  int x = offset%w;
  int w0 = len/4;
  int h0 = 1;
  io_write(AM_GPU_FBDRAW, x, y, (uint32_t*)buf, w0, h0, true);
  return len;
}

void init_device() {
  Log("Initializing devices...");
  ioe_init();
}
