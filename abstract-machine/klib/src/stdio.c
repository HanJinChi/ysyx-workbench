#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

void reverseString(char str[], int length) {
    int start = 0;
    int end = length - 1;
    while (start < end) {
        char temp = str[start];
        str[start] = str[end];
        str[end] = temp;
        start++;
        end--;
    }
}
void intToString(int num, char str[], int *length, int base) {
  bool isNegative = false;
  if (num < 0) { 
    isNegative = true;
    num = -num;
  }
  int index = 0;
  if (num == 0) {
    str[index++] = '0';
  }
  while (num > 0) {
    int digit = num % base;
    str[index++] = digit + '0';
    num = num / base;
  }
  if (isNegative) {
    str[index++] = '-';
  }
  reverseString(str, index);
  str[index] = '\0';
  *length = index;
}

void hexToString(uint32_t num, char str[], int *length){
  int index = 0;
  if(num == 0){
    str[index++] = '0';
  }
  while(num > 0){
    int digit = num % 16;
    if(digit < 10) str[index++] = digit + '0';
    else           str[index++] = digit -10 + 'A';
    num = num / 16;
  }
  reverseString(str, index);
  str[index] = '\0';
  *length = index;
}

int printf(const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  char buffer[2560];
  vsprintf(buffer, fmt, args);
  putstr(buffer);
  va_end(args);
  return 0;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  int written = 0;
  uint32_t i = 0;
  while(fmt[i] != '\0'){
    if(fmt[i] != '%'){
      out[written++] = fmt[i];
    }
    else{
      i++;
      if(fmt[i] == 's'){
        char* ap_array = va_arg(ap, char*);
        while(*ap_array != '\0'){
          out[written++] = *ap_array;
          ap_array++;
        }
      }else if(fmt[i] == 'd'){
        int num = va_arg(ap, int);
        char num_array[100]; int len = 0;
        intToString(num, num_array, &len, 10);
        int j = 0;
        while (num_array[j] != '\0'){
          out[written++] = num_array[j];
          j++;
        }
      }else if(fmt[i] == 'c'){
        char c = va_arg(ap, int);
        out[written++] = c;
      }else if(fmt[i] == 'p'){
        void* ptr = va_arg(ap, void*);
        uintptr_t addr = (uintptr_t)ptr;
        char num_array[100]; int len = 0;
        hexToString(addr, num_array, &len);
        int j = 0;
        while (num_array[j] != '\0'){
          out[written++] = num_array[j];
          j++;
        }
      }else if(fmt[i] == 'x'){
        uint32_t num = va_arg(ap, uint32_t);
        char num_array[100]; int len = 0;
        hexToString(num, num_array, &len);
        int j = 0;
        while (num_array[j] != '\0'){
          out[written++] = num_array[j];
          j++;
        }
      }
    }
    i++;
  }
  out[written] = '\0';
  return written;
}

int sprintf(char *out, const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  int written = vsprintf(out, fmt, args);
  va_end(args);
  return written;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);

  int written = vsnprintf(out, n, fmt, args);

  va_end(args);

  return written;
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  int written = 0;
  uint32_t i = 0;
  while(fmt[i] != '\0' && written < n){
    if(fmt[i] != '%'){
      out[written++] = fmt[i];
    }
    else{
      i++;
      if(fmt[i] == 's'){
        char* ap_array = va_arg(ap, char*);
        while(*ap_array != '\0'){
          out[written++] = *ap_array;
          ap_array++;
        }
      }else if(fmt[i] == 'd'){
        int num = va_arg(ap, int);
        char num_array[100]; int len = 0;
        intToString(num, num_array, &len, 10);
        int j = 0;
        while (num_array[j] != '\0'){
          out[written++] = num_array[j];
          j++;
        }
      }else if(fmt[i] == 'c'){
        char c = va_arg(ap, int);
        out[written++] = c;
      }else if(fmt[i] == 'p'){
        void* ptr = va_arg(ap, void*);
        uintptr_t addr = (uintptr_t)ptr;
        char num_array[100]; int len = 0;
        hexToString(addr, num_array, &len);
        int j = 0;
        while (num_array[j] != '\0'){
          out[written++] = num_array[j];
          j++;
        }
      }else if(fmt[i] == 'x'){
        uint32_t num = va_arg(ap, uint32_t);
        char num_array[100]; int len = 0;
        hexToString(num, num_array, &len);
        int j = 0;
        while (num_array[j] != '\0'){
          out[written++] = num_array[j];
          j++;
        }
      }
    }
    i++;
  }
  out[written] = '\0';
  return written;
}

#endif
