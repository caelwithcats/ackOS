#pragma once

#include "kernel/io/fs_node.h"
#include "kernel/boot_protocols/uniheader.h"

struct framebuffer_write_data_info
{
    uint32_t* buff = nullptr;
    int buff_width = 0;
    int buff_height = 0;

    int x;
    int y;
};

struct framebuffer_get_fb_info
{
    int width = 0;
    int height = 0;
    int pitch = 0;
    int bpp = 0;
};

enum
{
    FRAMEBUFFER_CALL_WRITE_DATA,
    FRAMEBUFFER_CALL_GET_DISPLAY_INFO
};

class framebuffer : public fs_node
{
private:
    void* _addr_physical;
    int _width;
    int _height;
    int _pitch;
    int _bpp;

public:
    framebuffer(void* addr_physical, int width, int height, int pitch, int bpp);
    ~framebuffer();

    utils::result io_call(int request, void* arg) override;
};