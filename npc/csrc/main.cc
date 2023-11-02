
#include <common.h>

void init_monitor(int, char *[]);
void engine_start();
void cpu_exit();
void free_map();

int main(int argc, char* argv[]) {
  init_monitor(argc, argv);

  engine_start();

  free_map();
  cpu_exit();
}