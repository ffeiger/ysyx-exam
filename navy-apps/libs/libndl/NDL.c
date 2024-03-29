#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>


static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;
static int canvas_w = 0, canvas_h = 0;

uint32_t NDL_GetTicks() {      //获取当前毫秒数
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return (uint32_t)(tv.tv_sec * 1000 + tv.tv_usec / 1000);
}

int NDL_PollEvent(char *buf, int len) { //轮寻事件
  int fd = open("/dev/events", O_RDONLY);
    if (read(fd, buf, len))
    {
        close(fd);
        return 1;
    }
    else
    {
        close(fd);
        return 0;
    }
}

void NDL_OpenCanvas(int *w, int *h) //创建窗口并初始化渲染
{
    if (getenv("NWM_APP"))
    {
        int fbctl = 4;
        fbdev = 5;
        screen_w = *w;
        screen_h = *h;
        char buf[64];
        int len = sprintf(buf, "%d %d", screen_w, screen_h);
        // let NWM resize the window and create the frame buffer
        write(fbctl, buf, len);
        while (1)
        {
            // 3 = evtdev
            int nread = read(3, buf, sizeof(buf) - 1);
            if (nread <= 0)
                continue;
            buf[nread] = '\0';
            if (strcmp(buf, "mmap ok") == 0)
                break;
        }
        close(fbctl);
    }
    else
    {
        int fd = open("/proc/dispinfo", O_RDONLY);

        char buf[64];
        if (read(fd, buf, sizeof(buf) - 1))
        {
            sscanf(buf, "WIDTH: %d\nHEIGHT: %d\n", &screen_w, &screen_h);          
        }

        assert(screen_w >= *w && screen_h >= *h);

        if (*w == 0 && *h == 0)
        {
            *w = screen_w;
            *h = screen_h;
        }

        canvas_w = *w;
        canvas_h = *h;

        close(fd);
    }
}

void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h)
{
    int fd = open("/dev/fb", O_RDWR);

    x += (screen_w - canvas_w) / 2;   
    y += (screen_h - canvas_h) / 2;

    for (int i = 0; i < h; i++)
    {
        lseek(fd, sizeof(int) * ((i + y) * screen_w + x), SEEK_SET);
        write(fd, pixels, sizeof(int) * w);
        pixels += w;
    }

    close(fd);
}

void NDL_OpenAudio(int freq, int channels, int samples) {
}

void NDL_CloseAudio() {
}

int NDL_PlayAudio(void *buf, int len) {
  return 0;
}

int NDL_QueryAudio() {
  return 0;
}

int NDL_Init(uint32_t flags) {
  if (getenv("NWM_APP")) {
    evtdev = 3;
  }
  return 0;
}

void NDL_Quit() {
}
