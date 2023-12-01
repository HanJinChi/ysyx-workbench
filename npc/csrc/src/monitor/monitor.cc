
#include "isa.h"
#include <memory/paddr.h>
#include <stdio.h>

void init_rand();
void init_isa();
void init_log(const char *log_file);
void init_memory_log(const char *log_file);
void init_function_log(const char *log_file);
void init_device_log(const char *log_file);
void init_exception_log(const char* log_file);
void init_mem();
void init_difftest(char *ref_so_file, long img_size, int port);
void init_device();
void init_sdb();
void init_read_elf(const char* elf_file, const char* elf_file_array);
void init_disasm(const char *triple);
void init_cpu();

static void welcome()
{
  // Log("Trace: %s", MUXDEF(CONFIG_TRACE, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  // IFDEF(CONFIG_TRACE, Log("If trace is enabled, a log file will be generated "
  //                         "to record the trace. This may lead to a large log file. "
  //                         "If it is not necessary, you can disable it in menuconfig"));
  Log("Build time: %s, %s", __TIME__, __DATE__);
  printf("Welcome to riscv32-npc!\n");
  // printf("For help, type \"help\"\n");
}

#ifndef CONFIG_TARGET_AM
#include <getopt.h>

void sdb_set_batch_mode();

static char *log_file = NULL;
static char *memory_log_file = NULL;
static char *function_log_file = NULL;
static char *device_log_file = NULL;
static char *exception_log_file = NULL;
static char *diff_so_file = NULL;
static char *img_file = NULL;
static char *elf_file = NULL;
static char *elf_file_array = NULL;
static int difftest_port = 1234;

static long load_img()
{
  if (img_file == NULL)
  {
    Log("No image is given. Use the default build-in image.");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  
  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log("The image is %s, size = %ld", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

static int parse_args(int argc, char *argv[])
{
  const struct option table[] = {
      {"batch", no_argument, NULL, 'b'},
      {"log", required_argument, NULL, 'l'},
      {"mlog", required_argument, NULL, 'm'},
      {"flog", required_argument, NULL, 'f'},
      {"vlog", required_argument, NULL, 'v'},
      {"elf",  required_argument, NULL, 'e'},
      {"xlog", required_argument, NULL, 'x'},
      {"elf_array", required_argument, NULL, 'a'},
      {"diff", required_argument, NULL, 'd'},
      {"port", required_argument, NULL, 'p'},
      {"help", no_argument, NULL, 'h'},
      {0, 0, NULL, 0},
  };
  int o;
  while ((o = getopt_long(argc, argv, "-bhl:d:p:m:f:e:v:a:x:", table, NULL)) != -1)
  {
    switch (o)
    {
    case 'b':
      sdb_set_batch_mode();
      break;
    case 'p':
      sscanf(optarg, "%d", &difftest_port);
      break;
    case 'l':
      log_file = optarg;
      break;
    case 'm':
      memory_log_file = optarg;
    case 'd':
      diff_so_file = optarg;
      break;
    case 'f':
      function_log_file = optarg;
      break;
    case 'e':
      elf_file = optarg;
      break;
    case 'v':
      device_log_file = optarg;
      break;
    case 'x':
      exception_log_file = optarg;
      break;
    case 'a':
      elf_file_array = optarg;
      break;
    case 1:
      img_file = optarg;
      return 0;
    default:
      printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
      printf("\t-b,--batch              run with batch mode\n");
      printf("\t-l,--log=FILE           output log to FILE\n");
      printf("\t-m,--mlog=FILE          output memory log to FILE\n");
      printf("\t-f,--flog=FILE          output function log to FILE\n");
      printf("\t-v,--vlog=FILE          output device log to FILE\n");
      printf("\t-e,--e=FILE             set ELF FILE\n");
      printf("\t-a,--a=FILE             set ELF ARRAY FILE\n");
      printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
      printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
      printf("\n");
      exit(0);
    }
  }
  return 0;
}

void init_monitor(int argc, char *argv[])
{
  /* Perform some global initialization. */

  /* Parse arguments. */
  parse_args(argc, argv);

  /* Set random seed. */
  init_rand();

  /* Open the log file. */
  init_log(log_file);
  init_memory_log(memory_log_file);
  init_function_log(function_log_file);
  init_device_log(device_log_file);
  init_exception_log(exception_log_file);

  /* Initialize memory. */
  init_mem();

  /* Initialize devices. */
  IFDEF(CONFIG_DEVICE, init_device());

  /* Initialize elf read. */
  IFDEF(CONFIG_FTRACE, init_read_elf(elf_file, elf_file_array));

  /* Initialize isa*/
  init_isa();
  
  /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = load_img();

  /* Initialize cpu */
  init_cpu();

  /* Initialize differential testing. */
  IFDEF(CONFIG_DIFFTEST, init_difftest(diff_so_file, img_size, difftest_port));

  /* Initialize the simple debugger. */
  init_sdb();

  IFDEF(CONFIG_TRACE, init_disasm("riscv32-pc-linux-gnu"));
  
  /* Display welcome message. */
  welcome();
}
#else // CONFIG_TARGET_AM
static long load_img()
{
  extern char bin_start, bin_end;
  size_t size = &bin_end - &bin_start;
  Log("img size = %ld", size);
  memcpy(guest_to_host(RESET_VECTOR), &bin_start, size);
  return size;
}

void am_init_monitor()
{
  init_rand();
  init_mem();
  init_isa();
  load_img();
  IFDEF(CONFIG_DEVICE, init_device());
  welcome();
}
#endif
