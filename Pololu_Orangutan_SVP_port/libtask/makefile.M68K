# ------------------------------------------------------------------------
# makefile for LMX libtask.a library
# 22 Jul 2015	dpa
#
# Path to the GNU M68K cross compiler
# export PATH=/usr/local/m68k-gcc/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#
# Be sure to edit "task.h" and define MACHINE as M68K
#
# ------------------------------------------------------------------------

CC = m68k-elf-gcc 
CCFLAGS = -c -mcpu32 -Os -I . -I /usr/local/m68k-gcc/m68k-elf/include 

LINK = m68k-elf-ld
LINKPATH = -L/usr/local/m68k-gcc/m68k-elf/lib/mcpu32 \
           -L/usr/local/m68k-gcc/lib/gcc/m68k-elf/5.1.0/mcpu32 \
           -L/usr/local/m68k-gcc/lib/gcc/m68k-elf/5.1.0 \
	   -L. -L./mrm332
	   
LINKOPTS = 

AR = m68k-elf-ar

# ------------------------------------------------------------------------

LDFILE = mrm332/mrm.ld

# ------------------------------------------------------------------------

libobjs = sysclock.o task.o log.o

# ------------------------------------------------------------------------

all:	libfiles 

clean:	
	rm -f $(libobjs)  libtask.a *.o *.elf *.s19 *.map

%.o:%.c	
	$(CC) $(CCFLAGS) $<

libfiles: $(libobjs)
	$(AR) -r libtask.a $(libobjs) 
	# rm $(libobjs)

# ------------------------------------------------------------------------
# eof
