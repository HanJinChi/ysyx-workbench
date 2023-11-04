/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <common.h>
#include <elf.h>
#include <glob.h>

typedef struct{
  char name[100];
  int size;
  uint32_t value;
}ELF32;

extern uint64_t g_nr_guest_inst;
FILE *log_fp = NULL;
FILE *memory_log_fp = NULL;
FILE *function_log_fp = NULL;
FILE *device_log_fp = NULL;
FILE *exception_log_fp = NULL;
ELF32 elf_array[10000];
uint32_t count = 0;
int32_t space_count = 0;

void init_log(const char *log_file) {
  log_fp = stdout;
  if (log_file != NULL) {
    FILE *fp = fopen(log_file, "w");
    Assert(fp, "Can not open '%s'", log_file);
    log_fp = fp;
  }
  Log("Log is written to %s", log_file ? log_file : "stdout");
}

void init_memory_log(const char *log_file){
  memory_log_fp = stdout;
  if(log_file != NULL){
    FILE *fp = fopen(log_file, "w");
    Assert(fp, "Can not open '%s'", log_file);
    memory_log_fp = fp;
  }
  Log("Memory Log is written to %s", log_file ? log_file : "stdout");
}

void init_function_log(const char *log_file){
  function_log_fp = stdout;
  if(log_file != NULL){
    FILE *fp = fopen(log_file, "w");
    Assert(fp, "Can not open '%s'", log_file);
    function_log_fp = fp;
  }
  Log("Function Log is written to %s", log_file ? log_file : "stdout");
}

void init_device_log(const char* log_file){
  device_log_fp = stdout;
  if(log_file != NULL){
    FILE* fp = fopen(log_file, "w");
    Assert(fp, "Can not open '%s'", log_file);
    device_log_fp = fp;
  }
  Log("Device Log is written to %s", log_file ? log_file : "stdout");
}

void init_exception_log(const char* log_file){
  exception_log_fp = stdout;
  if(log_file != NULL){
    FILE* fp = fopen(log_file, "w");
    Assert(fp, "Can not open '%s'", log_file);
    exception_log_fp = fp;
  }
  Log("Exception Log is written to %s", log_file ? log_file : "stdout");
}

void add_elf_array(const char *elf_file){
  Log("elf file is %s", elf_file);
  FILE *file = fopen(elf_file, "rb");
  if (!file) {
    perror("fopen");
    return;
  }  
  Elf32_Ehdr elf_header;
  uint32_t read = fread(&elf_header, sizeof(Elf32_Ehdr), 1, file);

  // 遍历节头表查找符号表
  for (int i = 0; i < elf_header.e_shnum; i++) {
    Elf32_Shdr section_header;
    fseek(file, elf_header.e_shoff + (i * sizeof(Elf32_Shdr)), SEEK_SET);
    read = fread(&section_header, sizeof(Elf32_Shdr), 1, file);

    // 如果是符号表节，读取符号表
    if (section_header.sh_type == SHT_SYMTAB) {
      Elf32_Sym *symtab = (Elf32_Sym *)malloc(section_header.sh_size);
      fseek(file, section_header.sh_offset, SEEK_SET);
      read = fread(symtab, section_header.sh_size, 1, file);

      Elf32_Shdr symtab_str_header;
      fseek(file, elf_header.e_shoff + (section_header.sh_link * sizeof(Elf32_Shdr)), SEEK_SET);
      read = fread(&symtab_str_header, sizeof(Elf32_Shdr), 1, file);

      char *symtab_str = (char *)malloc(symtab_str_header.sh_size);
      fseek(file, symtab_str_header.sh_offset, SEEK_SET);
      read = fread(symtab_str, symtab_str_header.sh_size, 1, file);

      for (int j = 0; j < section_header.sh_size / sizeof(Elf32_Sym); j++) {
        if(ELF32_ST_TYPE(symtab[j].st_info) == 2){
          strcpy(elf_array[count].name, symtab_str + symtab[j].st_name);
          elf_array[count].size = symtab[j].st_size;
          elf_array[count].value = symtab[j].st_value;
          count++;
        }
      }
      free(symtab);
      free(symtab_str);
    }
  }
  read = read + 1;
}

void init_read_elf(const char* elf_file, const char* elf_file_array){
  add_elf_array(elf_file);
  Log("elf file array is %s", elf_file_array);
  if(elf_file_array){
    char copy_array[1000];
    strcpy(copy_array, elf_file_array);
    strcat(copy_array, "/*");
    glob_t result;
    glob(copy_array, 0, NULL, &result);
    for(int i = 0; i < result.gl_pathc; i++){
      add_elf_array(result.gl_pathv[i]);
    }
    globfree(&result);
  }
}


void ftrace_check_address(int func_type, uint32_t pc, uint32_t address){
  char *ftrace_input = malloc(100000);
  char func_name[100] = {};
  char *p = ftrace_input;
  bool include = false;
  for(int i = 0; i < count; i++){
    if(func_type == 0){
      if(address == elf_array[i].value){
        strcpy(func_name, elf_array[i].name);
        include = true;
        break;
      }
    }else{
      if(address >= elf_array[i].value && address < (elf_array[i].value + elf_array[i].size)){
        strcpy(func_name, elf_array[i].name);
        include = true;
      }
    }
  }
  if(include){
    sprintf(p, FMT_WORD ":", pc);
    p = p + 11; // only consider 32 bit 
    switch (func_type)
    {
    case 0: // jal
      space_count++;
      for(int i = 0 ; i < space_count; i++){
        strcpy(p, " ");
        p = p + 1;
      }
      sprintf(p, "call [%s@0x%08x]", func_name, address);
      break;
    case 1:
      space_count--;
      for(int i = 0 ; i < space_count; i++){
        strcpy(p, " ");
        p = p + 1;
      }
      sprintf(p, "ret [%s]", func_name);
      break;
    default:
      break;
    }
    function_log_write("%s\n", ftrace_input);
  }
  // else{
  //   printf("pc is 0x%x, address is 0x%x\n", pc, address);
  //   assert(0);
  // }
  free(ftrace_input);
}


bool log_enable() {
  return MUXDEF(CONFIG_TRACE, (g_nr_guest_inst >= CONFIG_TRACE_START) &&
         (g_nr_guest_inst <= CONFIG_TRACE_END), false);
}

bool memory_log_enable(){
  return MUXDEF(CONFIG_MTRACE, (g_nr_guest_inst >= CONFIG_TRACE_START) &&
         (g_nr_guest_inst <= CONFIG_TRACE_END), false);
}

bool function_log_enable(){
  return MUXDEF(CONFIG_FTRACE, (g_nr_guest_inst >= CONFIG_TRACE_START) &&
         (g_nr_guest_inst <= CONFIG_TRACE_END), false);
}

bool device_log_enable(){
  return MUXDEF(CONFIG_VTRACE, (g_nr_guest_inst >= CONFIG_TRACE_START) &&
         (g_nr_guest_inst <= CONFIG_TRACE_END), false);
  // return MUXDEF(CONFIG_VTRACE, true, false);
}

bool exception_log_enable(){
  return MUXDEF(CONFIG_XTRACE, (g_nr_guest_inst >= CONFIG_TRACE_START) &&
         (g_nr_guest_inst <= CONFIG_TRACE_END), false);
  // return MUXDEF(CONFIG_XTRACE, true, false);
}
