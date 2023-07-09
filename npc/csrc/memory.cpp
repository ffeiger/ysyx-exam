#include <stdio.h>
#include <sys/time.h>
#include <time.h>

extern long long pc;

extern void i8042_data_io_handler();

#define uint8_t unsigned char
#define uint16_t unsigned short
#define uint32_t unsigned int 
#define uint64_t unsigned long 

#define CONFIG_MBASE 0x80000000
#define CONFIG_MSIZE 0x8000000
#define DEVICE_BASE 0xa0000000
#define MMIO_BASE 0xa0000000

#define SERIAL_PORT (DEVICE_BASE + 0x00003f8)
#define KBD_ADDR (DEVICE_BASE + 0x0000060)
#define RTC_ADDR (DEVICE_BASE + 0x0000048)
#define VGACTL_ADDR (DEVICE_BASE + 0x0000100)
#define AUDIO_ADDR (DEVICE_BASE + 0x0000200)
#define DISK_ADDR (DEVICE_BASE + 0x0000300)
#define FB_ADDR (MMIO_BASE + 0x1000000)
#define FB_SIZE 400*300*32
#define AUDIO_SBUF_ADDR (MMIO_BASE + 0x1200000)

unsigned long int pmem[0X8000000]={0};
extern uint32_t vgactl_port_base[2];
extern uint32_t i8042_data_port_base;
extern void *vmem ;

static uint64_t boot_time = 0;
uint32_t lo = 0;
uint32_t hi = 0;

int visit_device=0;

static uint64_t get_time_internal()
{
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC_COARSE, &now);
    uint64_t us = now.tv_sec * 1000000 + now.tv_nsec / 1000;
    return us;
}

uint64_t get_time()
{
    if (boot_time == 0)
    {
        boot_time = get_time_internal();
    }

    uint64_t now = get_time_internal();
    return now - boot_time;
}

extern "C" void pmem_read(long long raddr, long long *rdata) {
    //printf("%016lx\n",raddr);
    long long aligned_raddr = raddr & ~0x7ull;
    if(raddr==RTC_ADDR)
    {
        uint64_t us = get_time();
        *rdata=(uint64_t)us;
        visit_device = 1;
    }  
    else if(raddr==VGACTL_ADDR)
    {
       // printf("read vgactl_port_base0\n");
        *rdata=(uint64_t)vgactl_port_base[0];
        visit_device = 1;
    }
    else if(raddr==VGACTL_ADDR+4)
    {
        printf("read vgactl_port_base1\n");
        *rdata=(uint64_t)vgactl_port_base[1];
        visit_device = 1;
    }
    else if(aligned_raddr == KBD_ADDR)
    {
        i8042_data_io_handler();
        *rdata=(uint64_t)i8042_data_port_base;
        visit_device =1 ; 
    }
    else {
        *rdata = pmem[(aligned_raddr-0x80000000)/8]; 
        //if(pc==0x8000123c) printf("rdata from lbu:%016lx\n",rdata);
    }
}
extern "C" void pmem_read_inst(long long raddr,int *rdata) {
  if(raddr%8==0)
    *rdata = (int)pmem[(raddr-0x80000000)/8];
  else
    *rdata = (int)(pmem[(raddr-0x80000000)/8]>>32);
}


extern "C" void pmem_write(long long waddr, long long wdata, long long wstrb) {
  long long aligned_waddr = waddr & ~0x7ull;
  long long rdata = pmem[(aligned_waddr-0x80000000)/8];
  long long real_wdata;

  if(aligned_waddr == SERIAL_PORT)
  {
    putchar(char(wdata));
    visit_device = 1;
  }
  else if(waddr == VGACTL_ADDR+4)
  {
    //printf("vgactl_port_base1 visit pc:%016lx\n",pc);
    vgactl_port_base[1]=(uint32_t)wdata;
    visit_device = 1;
  }
  else if(aligned_waddr == KBD_ADDR)
  {
    i8042_data_port_base = wdata;
    visit_device =1 ; 
  }
  else if(waddr >= FB_ADDR && waddr <= FB_ADDR + FB_SIZE/8)
  {
     //if(wdata !=0)
       //printf("pc:%016lx wdata:%016lx waddr:%016lx\n",pc,wdata,waddr);
    *(uint8_t *)((uint8_t *)vmem+waddr-FB_ADDR)=wdata;
    visit_device = 1;
  }
  else {

    switch((uint64_t)wstrb){
      case 0xff: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xff) | (rdata & ~0xffull);break;
      case 0xff00: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xff)<<8 | (rdata & 0xffffffffffff00ff);break;
      case 0xff0000: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xff)<<16 | (rdata & 0xffffffffff00ffff);break;
      case 0xff000000: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xff)<<24 | (rdata & 0xffffffff00ffffff);break;
      case 0xff00000000: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xff)<<32 | (rdata & 0xffffff00ffffffff);break;
      case 0xff0000000000: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xff)<<40 | (rdata & 0xffff00ffffffffff);break;
      case 0xff000000000000: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xff)<<48 | (rdata & 0xff00ffffffffffff);break;
      case 0xff00000000000000: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xff)<<56 | (rdata & 0x00ffffffffffffff);break;
      case 0xffff: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xffff) | (rdata & ~0xffffull);break;
      case 0xffff0000: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xffff)<< 16 | (rdata & 0xffffffff0000ffff);break;
      case 0xffff00000000: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xffff)<< 32 | (rdata & 0xffff0000ffffffff);break;
      case 0xffff000000000000: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xffff)<< 48 | (rdata & 0x0000ffffffffffff);break;
      case 0xffffffff: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0x00000000ffffffff) | (rdata & 0xffffffff00000000); break;
      case 0xffffffff00000000: pmem[(aligned_waddr-0x80000000)/8] = (wdata & 0xffffffff)<<32 | (rdata & 0x00000000ffffffff);break;
      case 0xffffffffffffffff: pmem[(aligned_waddr-0x80000000)/8] = wdata;break;
      default:
        printf("pmem write error!\n");break;
    }
    
     //pmem[(aligned_waddr-0x80000000)/8] = wdata;
     //printf("waddr:%016lx wdata:%016lx\n",waddr,wdata);
  }
}
