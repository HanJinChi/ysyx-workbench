#include <unistd.h>
#include <stdio.h>
#include <sys/time.h>
#include <NDL.h>

int main(){
  uint32_t old_time = NDL_GetTicks();
  while (1)
  {
    uint32_t new_time = NDL_GetTicks();
    if(old_time - new_time > 5000){
      printf("passed 5 seconds\n");
      break;
    }
  }
  
  return 0;
}