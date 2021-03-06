#include <fcntl.h>
#include <liback/utils/result.h>
#include "kernel/io/fdm.h"
#include "kernel/io/handle.h"
#include "kernel/io/stream.h"

#define HANDLE_LIMIT 512

namespace fdm
{
    handle* _handles[HANDLE_LIMIT];
    int _used_file_descs;

    int set_handle_at(int fd, device_node* node, int flags)
    {
        _handles[fd] = new handle(fd, flags, node);;

        _used_file_descs++;

        return fd;
    }

    int append_handle(device_node* node, int flags)
    {
       return set_handle_at(_used_file_descs + 1, node, flags); 
    }

    void delete_handle(int fd)
    {
        if(_handles[fd] != nullptr)
        {
            delete _handles[fd];
            _handles[fd] = NULL;
        }
    }

    void init()
    {
        stream* stdin_node = new stream;
        set_handle_at(0, stdin_node, O_RDONLY);

        stream* stdout_node = new stream;
        set_handle_at(1, stdout_node, O_WRONLY);

        stream* stderr_node = new stream;
        set_handle_at(2, stderr_node, O_WRONLY);
    }

    utils::result read(int fd, void* buff, size_t size, size_t* total_read)
    {
        *total_read = 0; /* make sure it's set to zero */

        if(fd > HANDLE_LIMIT || fd < 0)
        {
            return utils::result::ERR_OUT_OF_BOUNDS;
        }
        else if(_handles[fd] == nullptr)
        {
            return utils::result::ERR_INVALID_FD;
        }

        return _handles[fd]->read(buff, size, total_read);
    }

    utils::result write(int fd, const void* buff, size_t size, size_t* total_written)
    {
        *total_written = 0;

        if(fd > HANDLE_LIMIT || fd < 0)
        {
            return utils::result::ERR_OUT_OF_BOUNDS;
        }
        else if(_handles[fd] == nullptr)
        {
            return utils::result::ERR_INVALID_FD;
        }

        return _handles[fd]->write(buff, size, total_written);
    }
}
