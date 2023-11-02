#include <fs.h>


extern size_t ramdisk_read(void *buf, size_t offset, size_t len);
extern size_t ramdisk_write(const void *buf, size_t offset, size_t len);

extern size_t serial_write(const void *buf, size_t offset, size_t len);
extern size_t events_read(void *buf, size_t offset, size_t len);

extern size_t dispinfo_read(void *buf, size_t offset, size_t len);
extern size_t fb_write(const void *buf, size_t offset, size_t len);


enum {FD_STDIN, FD_STDOUT, FD_STDERR, FD_FB};

size_t invalid_read(void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}

size_t invalid_write(const void *buf, size_t offset, size_t len) {
  panic("should not reach here");
  return 0;
}



/* This is the information about all files in disk. */
Finfo file_table[] __attribute__((used)) = {
  [FD_STDIN]  = {"stdin", 0, 0, 0, invalid_read, invalid_write},
  [FD_STDOUT] = {"stdout", 0, 0, 0, invalid_read, serial_write},
  [FD_STDERR] = {"stderr", 0, 0, 0, invalid_read, serial_write},
  [FD_FB]     = {"/dev/fb", 0, 0, 0, invalid_read, fb_write},
  {"/dev/events", 0, 0, 0, events_read, invalid_write},
  {"/proc/dispinfo", 0, 0, 0, dispinfo_read, invalid_write},
#include "files.h"
};

void init_fs() {
  // TODO: initialize the size of /dev/fb
  int w = io_read(AM_GPU_CONFIG).width;
  int h = io_read(AM_GPU_CONFIG).height;
  file_table[FD_FB].size = w*h*4;
}

int fs_open(const char* pathname, int flags, int mode){
  for(int i = 0; i < sizeof(file_table)/sizeof(Finfo); i++){
    if(strcmp(pathname, file_table[i].name) == 0){
      return i;
    }
  }
  panic("pathname not found!");
}

size_t fs_read(int fd, void* buf, size_t len){
  size_t ret;
  if(file_table[fd].read){
    ret = file_table[fd].read(buf, file_table[fd].open_offset, len);
  }else{
    if(file_table[fd].open_offset + len > file_table[fd].size)
      len = file_table[fd].size - file_table[fd].open_offset;
    ret = ramdisk_read(buf, file_table[fd].disk_offset + file_table[fd].open_offset, len);
  }
  file_table[fd].open_offset = file_table[fd].open_offset + len;
  return ret;
}

size_t fs_write(int fd, const void* buf, size_t len){
  size_t ret;
  if(file_table[fd].write){
    ret = file_table[fd].write(buf, file_table[fd].open_offset, len);
  }else{
    ret = ramdisk_write(buf, file_table[fd].disk_offset + file_table[fd].open_offset, len);
  }
  file_table[fd].open_offset = file_table[fd].open_offset + len;
  return ret;
}

int fs_close(int fd){
  file_table[fd].open_offset = 0;
  return 0;
}

size_t fs_lseek(int fd, size_t offset, int whence){
  if(whence == SEEK_SET){
    assert(offset <= file_table[fd].size);
    file_table[fd].open_offset = offset;
  }else if(whence == SEEK_CUR){
    assert(file_table[fd].open_offset+offset <= file_table[fd].size);
    file_table[fd].open_offset = file_table[fd].open_offset + offset;
  }else if(whence == 2){
    assert(offset <= file_table[fd].size);
    file_table[fd].open_offset = file_table[fd].size + offset;
  }
  return file_table[fd].open_offset;
}
