#include "trap.h"

int main(){
    intptr_t addr_led = 0x10002000+8;
    
    for(int i = 0; i < 10000; i++){
        printf("const\n");
    }
}