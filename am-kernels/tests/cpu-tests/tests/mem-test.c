#include "trap.h"

int main(){
    int* ptr = (int *)malloc(0x25*sizeof(int));
    // // step 1: write in
    for(int i = 0; i < 0x25; i++)
        ptr[i] = (uintptr_t)ptr & 0xff;
    for(int i = 0; i < 0x25; i++)
        check(ptr[i] == ((uintptr_t)(ptr[i]) & 0xff));
    for(int i = 0; i < 0x25; i++)
        ptr[i] = (uintptr_t)(ptr[i]) & 0xffff;
    for(int i = 0; i < 0x25; i++)
        check(ptr[i] == ((uintptr_t)(ptr[i]) & 0xffff));
    for(int i = 0; i < 0x25; i++)
        ptr[i] = (uintptr_t)(ptr[i]) & 0xffffffff;
    for(int i = 0; i < 0x25; i++)
        check(ptr[i] == ((uintptr_t)(ptr[i]) & 0xffffffff));
}