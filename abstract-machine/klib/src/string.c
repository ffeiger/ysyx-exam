#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>
#include <assert.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t i=0;
  while(s[i]!='\0')
  {
    i++;
  }
  return i;
}

char *strcpy(char *dst, const char *src) {
  char *tmp=dst;
  int i=0;
  while(src[i]!='\0')
  {
    tmp[i]=src[i];
    i++;
  }
  tmp[i]='\0';
  return tmp;
}

char *strncpy(char *dst, const char *src, size_t n) {
  char* tmp = dst;
	while (n && (*dst++ = *src++))
	{
		n--;
	}
	if (n)
	{
		while (n--)
		{
			*dst++ = '\0';
		}
	}
	return tmp;
}

char *strcat(char *dst, const char *src) {
  int len1=strlen(dst);
  int len2=strlen(src);
  char *tmp=dst;
  for(int i=len1;i<=len1+len2;i++)
  {
    tmp[i]=src[i-len1];
  }
  return tmp;
}

int strcmp(const char *s1, const char *s2) {
  while ((*s1) && (*s1 == *s2))
	{
		s1++;
		s2++;
	}
 
	if (*(unsigned char*)s1 != *(unsigned char*)s2)
	{
		return *(unsigned char*)s1-*(unsigned char*)s2;
	}
	else
	{
		return 0;
	}  
}

int strncmp(const char *s1, const char *s2, size_t n) {
    if(s1 == NULL && s2 == NULL)
		return -1;
    int res = 0;
    while (n-- != 0)
    {
        res = *s1 - *s2;
        if (res != 0)
            break;
        s1++;
        s2++;
    }
    return res;
}

void *memset(void *s, int c, size_t n) {
  if (s == NULL || n < 0)
	{
		return NULL;
	}
	char *pdest = (char *)s;
	while (n-->0)
	{
		*pdest++ = c;
	}
	return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  //assert(dst && src);
	void* ret = dst;
	if (src > dst)
	{
		//顺顺序
		while (n--)
		{
			*(char*)dst = *(char*)src;
			dst = (char*)dst + 1;
			src = (char*)src + 1;
		}
	}
	else
	{
		//逆顺序
		while (n--)
		{
			*((char*)dst+n) = *((char*)src + n);
		}
	}
	return ret;
}

void *memcpy(void *out, const void *in, size_t n) {
  //assert(out && in);
	void* ret = out;
  while(n--)
  {
    *(char*)out=*(char*)in;
    out=(char*)out+1;
    in=(char*)in+1;
  }
  return ret;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  while (n--)
	{
		if (*(char*)s1 == *((char*)s2))
		{
			s1 = (char*)s1 + 1;
			s2 = (char*)s2 + 1;
		}
		else
			return (*(char*)s1 - *((char*)s2));
	}
	return 0;
}


#endif
