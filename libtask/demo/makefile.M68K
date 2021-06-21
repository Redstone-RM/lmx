# ------------------------------------------------------------------------
# makefile for LMX libtask.a library
# 22 Jul 2015
# dpa
#	make 		builds libtask.a library.
#	make demo	builds demo.s19 executable.  Change this to your own format.
#
# Path to the GNU M68K cross compiler
# export PATH=/usr/local/m68k-gcc/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# ------------------------------------------------------------------------

CC = m68k-elf-gcc 
CCFLAGS = -c -mcpu32 -Os -I . -I ../ -I /usr/local/m68k-gcc/m68k-elf/include 

LINK = m68k-elf-ld
LINKPATH = -L/usr/local/m68k-gcc/m68k-elf/lib/mcpu32 \
           -L/usr/local/m68k-gcc/lib/gcc/m68k-elf/5.1.0/mcpu32 \
           -L/usr/local/m68k-gcc/lib/gcc/m68k-elf/5.1.0 \
	   -L. -L../68332/mrm332
	   
LINKOPTS = ../libtask.a

AR = m68k-elf-ar

OBJCOPY = m68k-elf-objcopy

# how to make srecords from elf object files:
S19 = $(OBJCOPY) -O srec

# ------------------------------------------------------------------------

LDFILE = ../68332/mrm332/mrm.ld

# ------------------------------------------------------------------------

all:	bmark-2.s19 

clean:	
	rm -f *.o *.elf *.s19 *.map

%.o:%.c	
	$(CC) $(CCFLAGS) $<

# ------------------------------------------------------------------------

bmark-2.elf: bmark-2.o $(LDFILE)
	$(LINK) $(LINKPATH) -M -o bmark-2.elf $(LINKOPTS) bmark-2.o -T $(LDFILE) > bmark-2.map
       
bmark-2.s19: bmark-2.elf 
	$(S19) bmark-2.elf bmark-2.s19
	rm bmark-2.o bmark-2.elf 

# ------------------------------------------------------------------------
# eof
