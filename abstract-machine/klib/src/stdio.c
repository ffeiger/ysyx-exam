#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <string.h>


#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
    while (*fmt) {
        if (*fmt == '%') {
            fmt++;
            switch (*fmt) {
            case '0':{
              if(fmt[1]=='2' && fmt[2]=='d')
              {
                int num = va_arg(ap, int);
                if (num < 0) {
                    putch('-');
                    num = -num;
                }
                char str[20];
                int i = 0;
                do {
                    str[i++] = num % 10 + '0';
                    num /= 10;
                } while (num);
                for(int zero=2-i;zero>0;zero--)
                  printf("0");
                while (i > 0) {
                    i--;
                    putch(str[i]);
                }
                fmt+=2;
                break;
              }
              else{
                putch(*fmt);
                break;
              }
            }
            case 'c':
                putch(va_arg(ap, int));
                break;
            case 'd': {
                int num = va_arg(ap, int);
                if (num < 0) {
                    putch('-');
                    num = -num;
                }
                char str[20];
                int i = 0;
                do {
                    str[i++] = num % 10 + '0';
                    num /= 10;
                } while (num);
                while (i > 0) {
                    i--;
                    putch(str[i]);
                }
                break;
            }
            case 's': {
                char* str = va_arg(ap, char*);
                while (*str) {
                    putch(*str);
                    str++;
                }
                break;
            }
            default:
                putch(*fmt);
                break;
            }
        } else {
            putch(*fmt);
        }
        fmt++;
    }
    va_end(ap);
  return 0;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  va_start(ap,fmt);
  int i=0,j=0;
  while(fmt[i]!='\0')
  {
    if(fmt[i]=='%'&&fmt[i+1]=='s'){
      char *s=va_arg(ap,char *);
      for(int m=0;m<strlen(s);m++)
        out[j+m]=s[m];
      j+=strlen(s);
      i+=2;
    }
    else if(fmt[i]=='%'&&fmt[i+1]=='d'){
      int num=va_arg(ap,int);
      int len=0;
      int tmp=num;
      while(num)
      {
        num/=10;
        len++;
      }
      for(int n=j+len-1;n>=j;n--)
      {
        out[n]=tmp%10+'0';
        tmp=tmp/10;
      }
      j+=len;
      i+=2;
    }
    else
       out[j++]=fmt[i++];
  }
  out[j]='\0';
  return 0;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
