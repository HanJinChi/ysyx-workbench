#include <isa.h>
#include <device/map.h>
#include <memory/vaddr.h>
#include <memory/host.h>

#define IO_SPACE_MAX (2*1024*1024)

static uint8_t *io_space = NULL;
static uint8_t *p_space = NULL;

uint8_t* new_space(int size){
  uint8_t *p = p_space;
  // page aligned;
  size = (size + (PAGE_SIZE - 1)) & ~PAGE_MASK;
  p_space += size;
  assert(p_space - io_space < IO_SPACE_MAX);
  return p; 
}

void check_bound(IOMap *map, paddr_t addr) {
  if (map == NULL) {
    Assert(map != NULL, "address (" FMT_WORD ") is out of bound at pc = " FMT_WORD, addr, cpu.pc);
  } else {
    Assert(addr <= map->high && addr >= map->low,
        "address (" FMT_WORD ") is out of bound {%s} [" FMT_WORD ", " FMT_WORD "] at pc = " FMT_WORD,
        addr, map->name, map->low, map->high, cpu.pc);
  }
}

void invoke_callback(io_callback_t c, paddr_t offset, int len, bool is_write) {
  if (c != NULL) { c(offset, len, is_write); }
}

void init_map(){
  io_space = (uint8_t*)malloc(IO_SPACE_MAX);
  assert(io_space);
  p_space = io_space;
}

void free_map(){
  free(io_space);
}

word_t map_read(paddr_t addr, int len, IOMap *map){
  assert(len >= 1 && len <= 8);
  check_bound(map, addr);
  paddr_t offset = addr - map->low;
  invoke_callback(map->callback, offset, len, false); // let device prepare data
  word_t ret = host_read(map->space + offset, len);
  #ifdef CONFIG_VTRACE
    device_log_write("pc is 0x%8x, device %s read addr is 0x%x, %d byte: 0x%x\n", cpu.pc, map->name, addr, len, ret);
  #endif
  return ret;
}

void map_write(paddr_t addr, int len, word_t data, IOMap *map) {
  assert(len >= 1 && len <= 8);
  check_bound(map, addr);
  paddr_t offset = addr - map->low;
  host_write(map->space + offset, len, data);
  invoke_callback(map->callback, offset, len, true);
  #ifdef CONFIG_VTRACE
    device_log_write("pc is 0x%8x, to device %s write %d byte: 0x%x\n", cpu.pc, map->name, len, data); 
  #endif
}