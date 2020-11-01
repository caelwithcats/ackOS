#include "kernel/serial.h"
#include "kernel/io.h"
#include <cstdio>

namespace serial
{
   void port_initialize(int port, int baud_rate)
   {
      outb(port + 1, 0x00); /* Disable interrupts */

      outb(port + 3, 0x80);               /* Set baud rate divisor */
      outb(port + 0, 115200 / baud_rate); /* ^ low byte */
      outb(port + 1, 0x00);               /* high byte */

      outb(port + 3, 0x03); /* 8 bits */
      outb(port + 2, 0x00); /* Enable FIFO with 14-byte threshold */
      outb(port + 4, 0x01); /* IRQ, RTS/DSR set */
   }

   int transmit_empty(int port)
   {
      return inb(port + 5) & 0x20;
   }

   void putc(int port, char a)
   {
      while (transmit_empty(port) == 0);

      outb(port, a);
   }

   void write(int port, const char *data, int size)
   {
      if (size < 0)
      {
         size = strlen(data);
      }

      for (int i = 0; i < size; i++)
      {
         putc(port, data[i]);
      }
   }
}
