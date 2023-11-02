#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t len = 0;

  while(*s != '\0'){
    len++;
    s++;
  }
  return len;
}

char *strcpy(char *dst, const char *src) {
  char *original_dest = dst; 

  while (*src != '\0') {
    *dst = *src; 
    dst++;
    src++;
  }
    
  *dst = '\0'; 
    
  return original_dest; 
}

char *strncpy(char *dst, const char *src, size_t n) {

  while (n > 0 && *src) {
    *dst = *src;
    n--;
    dst++;
    src++;
  }

  while (n > 0) {
    *dst++ = '\0';  // 填充剩余空间
    n--;
  }

  return dst;
}

char *strcat(char *dst, const char *src) {
  char *original_dest = dst; 
  while (*dst != '\0') {
    dst++;
  } 
  while (*src != '\0') {
    *dst = *src; 
    dst++;
    src++;
  }
    
  *dst = '\0'; 
    
  return original_dest; 
}

int strcmp(const char *s1, const char *s2) {
  while (*s1 && (*s1 == *s2)) {
    s1++;
    s2++;
  }
  return *(unsigned char *)s1 - *(unsigned char *)s2;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  while (n > 0 && *s1 && *s2) {
    if (*s1 != *s2) {
      return (*s1 - *s2);  // 返回字符差值
    }
    s1++;
    s2++;
    n--;
  }

  if (n == 0) {
    return 0;  // 前n个字符都相等
  }

  return (*s1 - *s2);  // 比较长度
}

void *memset(void *s, int c, size_t n) {
  unsigned char *byte_ptr = (unsigned char *)s; 
    
  for (size_t i = 0; i < n; i++) {
    *byte_ptr = (unsigned char)c; 
    byte_ptr++;
  }
    
  return s; 
}

void *memmove(void *dest, const void *src, size_t n) {
  unsigned char *d = (unsigned char *)dest;
  const unsigned char *s = (const unsigned char *)src;

  if (d == s) {
    // Source and destination are the same, no need to move anything
    return dest;
  }
  if (s < d && s + n > d) {
    // Source and destination regions overlap
    // We need to copy in reverse to avoid overwriting data
    for (size_t i = n; i > 0; i--) {
      d[i - 1] = s[i - 1];
      }
    } else {
      // Standard copy from source to destination
      for (size_t i = 0; i < n; i++) {
        d[i] = s[i];
      }
    }
  return dest;
}

void *memcpy(void *out, const void *in, size_t n) {
  char *dst = (char*)out;
  const char *src = (const char*)in;

  for(size_t i = 0; i < n; i++){
    dst[i] = src[i];
  }
  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  const unsigned char *byte_ptr1 = (const unsigned char *)s1; 
  const unsigned char *byte_ptr2 = (const unsigned char *)s2;

  for (size_t i = 0; i < n; i++) {
    if (*byte_ptr1 != *byte_ptr2) {
      return (*byte_ptr1 - *byte_ptr2);
    }
    byte_ptr1++;
    byte_ptr2++;
  }

  return 0; 
}

#endif
