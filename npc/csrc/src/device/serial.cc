#include <utils.h>
#include <device/map.h>

#define CH_OFFSET 0

static uint8_t *serial_base = NULL;

void serial_putc(char ch){
  putc(ch, stderr);
}
void serial_io_handler(uint32_t offset, int len, bool is_write){
  assert(len == 1);
  switch (offset){
    case CH_OFFSET:
      if(is_write) serial_putc(serial_base[0]);
      else panic("don't support read");
      break;
    default: panic("don't support offset = %d", offset);
  }
}


void init_serial(){
  serial_base = new_space(8);
  add_mmio_map("serial", CONFIG_SERIAL_MMIO, serial_base, 8, serial_io_handler);
}