#include <proc.h>
#include <elf.h>

size_t ramdisk_read(void *buf, size_t offset, size_t len);
extern void* pf;

#ifdef __LP64__
# define Elf_Ehdr Elf64_Ehdr
# define Elf_Phdr Elf64_Phdr
#else
# define Elf_Ehdr Elf32_Ehdr
# define Elf_Phdr Elf32_Phdr
#endif

// #if define(__ISA_AM_NATIVE__)
// #define MAGIC 

extern int fs_open(const char *pathname, int flags, int mode);
extern int fs_close(int fd);
extern size_t fs_read(int fd, void *buf, size_t len);
extern size_t fs_lseek(int fd, size_t offset, int whence);

static uintptr_t loader(PCB *pcb, const char *filename) {
#ifdef ONE_FILE_TEST
  Elf_Ehdr ehdr;
  ramdisk_read(&ehdr, 0, sizeof(Elf_Ehdr));
  // assert((*(uint32_t *)ehdr.e_ident == 0x464c457f));

  Elf_Phdr phdr[ehdr.e_phnum];
  ramdisk_read(phdr, ehdr.e_phoff, sizeof(Elf_Phdr)*ehdr.e_phnum);
  for (int i = 0; i < ehdr.e_phnum; i++) {
    if (phdr[i].p_type == PT_LOAD) {
      ramdisk_read((void*)phdr[i].p_vaddr, phdr[i].p_offset, phdr[i].p_memsz);
      memset((void*)(phdr[i].p_vaddr+phdr[i].p_filesz), 0, phdr[i].p_memsz - phdr[i].p_filesz);
    }
  }
  return ehdr.e_entry;
#else
  int fd = fs_open(filename, 0, 0);
  Elf_Ehdr ehdr;
  fs_read(fd, &ehdr, sizeof(Elf_Ehdr));
  assert((*(uint32_t *)ehdr.e_ident == 0x464c457f));
  Elf_Phdr phdr[ehdr.e_phnum];
  fs_lseek(fd, ehdr.e_phoff, 0);
  fs_read(fd, phdr, sizeof(Elf_Phdr)*ehdr.e_phnum);
  for(int i = 0; i < ehdr.e_phnum; i++){
    if(phdr[i].p_type == PT_LOAD){
      fs_lseek(fd, phdr[i].p_offset, 0);
      fs_read(fd, (void*)phdr[i].p_vaddr, phdr[i].p_memsz);
      memset((void*)phdr[i].p_vaddr+phdr[i].p_filesz, 0, phdr[i].p_memsz - phdr[i].p_filesz);
    }
  }
  return ehdr.e_entry;
#endif
}

void naive_uload(PCB *pcb, const char *filename) {
  uintptr_t entry = loader(pcb, filename);
  Log("Jump to entry = %p", (void*)entry);
  ((void(*)())entry) ();
}

