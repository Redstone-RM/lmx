/*
 * crt0.S -- startup file for m68k-coff
 *
 * Copyright (c) 1995, 1996 Cygnus Support
 *
 * The authors hereby grant permission to use, copy, modify, distribute,
 * and license this software and its documentation for any purpose, provided
 * that existing copyright notices are retained in all copies and that this
 * notice is included verbatim in any distributions. No written agreement,
 * license, or royalty fee is required for any of the authorized uses.
 * Modifications to this software may be copyrighted by their authors
 * and need not follow the licensing terms described here, provided that
 * the new terms are clearly indicated on the first page of each file where
 * they apply.
 */

/* modified by Scott Howard, scott@objsw.com
 * - optional initialization of peripherals via crt0_initialization_list
 * - copy .data section from ROM image (if there is one) to RAM
 * - optional clearing of bss, based on value of external long word 'crt0_flags'
 * - optional call of hardware_init_hook immediately after peripheral initialization
 *   hardware_init_hook may be called via jsr or jmp, based on value of 'crt0_flags'
 * - Default exception handler re-starts system, saving the vector number
 *   of the exception that caused the restart as well as the program counter where
 *   the exception occurred.
 */

/* 21 Sep 2013 dpa	Modified to optionall update data segment from rom. */

#include "asm.h"

	.title "crt0.S for m68k-coff"
/*
 * Define an empty environment.
 */
/* deleted -- dpa 
        .data
        .align 2
SYM (environ):
        .long 0
*/

/* dpa -- define a 32bit checksum as first element of data segment */

	.data
	.align 2
	.globl SYM (__data_checksum)
SYM (__data_checksum):
		.long 0

/* Define a variable that indicates which exception handler got us
 * into the startup code. For a reset, it's always set to zero;
 * entry through other exceptions stores the vector number here (if possible;
 * see comments around __vector_default at the end of this file).
 */

 		.globl SYM (__unhandled_exception)
SYM (__unhandled_exception):
 		.long 0

/* __unhandled_exception_pc saves the program counter value where the exception occurred. */

 		.globl SYM (__unhandled_exception_pc)
SYM (__unhandled_exception_pc):
 		.long 0

 	.align	2
	.text

/*
 * These symbols are defined in C code, so they need to always be
 * named with SYM because of the difference between object file formats.
 */

/* These are defined in C code. */
	.extern SYM (main)
	.extern SYM (exit)
	.extern SYM (hardware_init_hook)
	.extern SYM (software_init_hook)
	.extern SYM (atexit)
	.extern SYM(__do_global_dtors)
	.extern SYM(crt0_flags)
	.extern SYM(crt0_initialization_list)

/*
 * These values are set in the linker script, so they must be
 * explicitly named here without SYM.
 */
	.extern __stack
	.extern __bss_start
	.extern __data_start_rom
	.extern __data_start
	.extern _end

/*
 * set things up so the application will run. This *must* be called start.
 */
	.global SYM (start)

SYM (start):
/* hardware reset puts a zero in __unhandled_exception. */
	moveql	#0,d7

/* if the user provided us with flags (symbol name 'crt0_flags') for the startup code,
 * load them now.  If not, use defaults.
 */
001:
	movel	IMM(SYM(crt0_flags)),d2	/* flags defined? */
	jbeq	002f		/* skip if symbol not defined */
	movel	d2,a0		/* flags were defined - load them */
	movel	(a0),d2

/* if user provided an initialization list, process it now
 * This is typically used to set up hardware that is critical to system operation,
 * for example chip selects, watchdog timers, etc.
 */
002:	movel	IMM(SYM(crt0_initialization_list)),d0
	jbeq	40f		/* skip if no list provided */

/* the init list is a series of records that look like this:
 * (4 bytes) start address
 * (2 bytes) write count	bits 14 and 15 indicate size: 0:0 = byte, 0:1 = word, else long
 * (<count * size> bytes) data	data to be written
 * if count is zero, then the start address is a function pointer
 * and the function is called as void (*ftn) (void)
 */
005:	movel	d0,a0		/* get address of next list entry */
00:	movel	(a0)+,d0	/* get next address to initialize */
	movel	d0,a1		/* point A1 at address */
	jbeq	40f		/* address is zero - end of list */
	movew	(a0)+,d0	/* get byte/word/longword count */
	jbeq	04f		/* count == 0 - it's a function pointer */
	movew	d0,d1		/* copy into d1 */
#ifdef	__mcf5200__
	andil	IMM(0x3fff),d0	/* remove size code from count */
	andil	IMM(0xc000),d1	/* get size code */
	jbeq	03f		/* size code == 0: byte write */
	cmpil	IMM(0x4000),d1	/* size code == 1? */
	jbeq	02f		/* yes - word move */

/* long word move */
01:	movel	(a0)+,(a1)+
	subql	IMM(1),d0	/* decrement and branch till done */
	jbne	01b
	jbra	00b

/* word move */
02:	movew	(a0)+,(a1)+
	subql	IMM(1),d0	/* decrement and branch till done */
	jbne	02b
	jbra	00b

/* byte move */
03:	moveb	(a0)+,(a1)+
	subql	IMM(1),d0	/* decrement and branch till done */
	jbne	03b
	movel	a0,d0		/* get pointer in D0 to word-align */
	btst	IMM(0),d0	/* word-align before fetching */
	jbeq	00b		/* it's already aligned - skip */
	addl	IMM(1),d0	/* misaligned, so increment to next word boundary */
	jbra	005b		/* next entry */

#else
	andiw	IMM(0x3fff),d0	/* remove size code from count */
	subqw	IMM(1),d0	/* adjust for dbcc terminal count == 0xffff */
	andiw	IMM(0xc000),d1	/* get size code */
	jbeq	03f		/* size code == 0: byte write */
	cmpiw	IMM(0x4000),d1	/* size code == 1? */
	jbeq	02f		/* yes - word move */

/* long word move */
01:	movel	(a0)+,(a1)+
	dbra	d0,01b		/* decrement and branch till done */
	jbra	00b

/* word move */
02:	movew	(a0)+,(a1)+
	dbra	d0,02b		/* decrement and branch till done */
	jbra	00b

/* byte move */
03:	moveb	(a0)+,(a1)+
	dbra	d0,03b		/* decrement and branch till done */
	movel	a0,d0		/* get pointer in D0 to word-align */
	btst	IMM(0),d0	/* word-align before fetching */
	jbeq	00b		/* it's already aligned - skip */
	addl	IMM(1),d0	/* misaligned, so increment to next word boundary */
	jbra	005b		/* next entry */
#endif

/* count == 0: call function through function pointer */
04:	jsr	(a1)
	jbra	00b

40:
/* See if user supplied their own stack (__stack != 0).
 * If not, then leave it as set by the ROM monitor/exception vector.
 */
	movel	IMM(__stack), a0
	cmpl	IMM(0), a0
	jbeq    1f
	movel	a0, sp
1:

/* if the user provided a hardware init function, call it now.
 * this is done first so that hardware is all set up for the rest of crt0
 */
	lea	SYM(hardware_init_hook), a0
	cmpl	IMM(0),a0
	jbeq	4f
/* There is an init function, so execute it.
 * If bit 0 of crt0_flags is set, then do a jump to the init routine
 * with the return address in D0; otherwise do a normal jsr.
 */
	btst	IMM(0),d2
	jbeq	401f
	movel	IMM(4f),d0	/* put ret addr in D0... */
	jmp	(a0)		/* and jump to the routine */
401:	jsr     (a0)		/* flag bit is clear - normal jsr */
4:
/*
 * If bit 1 of crt0_flags is clear, then zero out the bss section.
 * we do this with a clr.l instruction, since it's a lot faster than the
 * clr.b instruction on most of the 68k CPUs, and we can be sure that
 * the bss section will always be a multiple of sizeof (long).
 */
	btst	IMM(1),d2	/* check the flag bit */
	jbne	3f		/* flag bit is set - don't clear bss */
	movel	IMM(__bss_start), d1
	movel	IMM(_end), d0
	cmpl	d0, d1
	jbeq	3f
	movl	d1, a0
	subl	d1, d0
	asrl	IMM(2),d0	/* calculate size in long words */
#ifndef __mcf5200__
	subql	IMM(1),d0	/* compensate for dbra terminal count = -1 */
	movl	d0,d1		/* make a copy in d1 */
	swap	d1		/* d1 tracks high word */
#endif
2:
	clrl	(a0)+
#ifndef __mcf5200__
	dbra	d0, 2b
	subqw	IMM(1), d1
	jbcc	2b
#else
	subql	IMM(1), d0
	jne	2b
#endif

3:

/* copy .data image, if there is one, from ROM to RAM.
 * We do this with a move.l instruction, since it's a lot faster than the
 * move.b instruction.
 * The linker script must ensure that the data section will always be
 * word-aligned, and its size will always be a multiple of sizeof (long).
 */
	movel	IMM(__data_start_rom), d1	/* get source address */
	jbeq	31f			/* skip if not defined */
	movl	d1, a0			/* source addr in a0 */
	movl	IMM(__data_start), a1	/* dest addr in a1 */
	movl	IMM(_edata), d0		/* end address in d0 */
	movl	a1, d1			/* calculate size in long words */
	subl	d1, d0
	jbeq	31f			/* skip if it's zero */
	asrl	IMM(2),d0
#ifndef __mcf5200__
	subql	IMM(1),d0		/* compensate for dbra terminal count = -1 */
	movl	d0,d1			/* make a copy in d1 */
	swap	d1			/* d1 tracks high word */
#endif
21:
	movl	(a0)+,(a1)+
#ifndef __mcf5200__
	dbra	d0, 21b
	subqw	IMM(1), d1
	jbcc	21b
#else
	subql	IMM(1), d0
	jne	21b
#endif

31:

/* Save the pc value when the exception occurred. */
	movel	d6,SYM(__unhandled_exception_pc)

/* Save vector number of the exception that got us here. */
	movel	d7,SYM(__unhandled_exception)

/* set up initial stack frame */
	link	a6, IMM(-8)

/*
 * initialize target specific stuff. Only execute this
 * function if it exists.
 */
	lea	SYM (software_init_hook), a0
	cmpl	IMM(0),a0
	jbeq	5f
	jsr     (a0)
5:

/*
 * call the main routine from the application to get it going.
 * main (argc, argv, environ)
 * we pass argv as a pointer to NULL.
 */

#ifdef ADD_DTORS
	/* put __do_global_dtors in the atexit list so the destructors get run */
	movel	IMM (SYM(__do_global_dtors)),(sp)
	jsr	SYM (atexit)
#endif
	movel	IMM (__FINI_SECTION__),(sp)
	jsr	SYM (atexit)

	jsr	__INIT_SECTION__

        pea     0
        pea     SYM (environ)
        pea     sp@(4)
#ifdef	__MSHORT__
        movew	IMM(0),sp@-
	jsr	SYM (main)
	movew	d0, sp@-
#else
        pea     0
	jsr	SYM (main)
	movel	d0, sp@-
#endif

/*
 * drop down into exit incase the user doesn't. This should drop
 * control back to the ROM monitor, if there is one. This calls the
 * exit() from the C library so the C++ tables get cleaned up properly.
 */
        jsr     SYM (exit)


/* Define a default handler for exceptions not otherwise handled in the application code.
 * We save
 * Three versions:
 * - for the original MC68000 and equivalents, we can't determine which vector got us here;
 *   so we put -1 in __unhandled_exception
 * - for the Coldfire, the vector number is contained in the byte at offset 1 from the stack pointer
 * - for all other M68K devices, we calculate the vector number
 *   from the vector offset value in the 4th word on the stack.
 *
 * for MC68000 & friends, we provide special handlers for bus error and address error
 * because we can capture the program counter address and vector no. for these exceptions.
 */

	.globl	SYM(__vector_buserror_default)
SYM (__vector_buserror_default):

#if	!defined (__mcf5200__) && !defined (__mcpu32__) && !defined (__mc68332__) && !defined(__mc68010__) && !defined (__mc68020__) && !defined (__mc68030__) && !defined (__mc68040__) && !defined (__mc68060__)
	ori	IMM(0x700),sr
	movel	sp@(10),d6
	moveql	IMM(2),d7
	bra	001b
#endif

	.globl	SYM(__vector_addrerror_default)
SYM (__vector_addrerror_default):

#if	!defined (__mcf5200__) && !defined (__mcpu32__) && !defined (__mc68332__) && !defined(__mc68010__) && !defined (__mc68020__) && !defined (__mc68030__) && !defined (__mc68040__) && !defined (__mc68060__)
	ori	IMM(0x700),sr
	movel	sp@(10),d6
	moveql	IMM(3),d7
	bra	001b
#endif

	.globl	SYM(__vector_default)
SYM (__vector_default):
#ifdef	__mcf5200__
/* Coldfire version:
 * - put exception PC into __unhandled_exception_pc
 * - get vector number from stack into d7
 * - then join the party at 'start'.
 */
	move	IMM(0x2700),sr
	movel	sp@(4),d6
	clrl	d7
	moveb	sp@(1),d7
	bra	001b

#elif	defined (__mcpu32__) || defined (__mc68332__) || defined(__mc68010__) || defined (__mc68020__) || defined (__mc68030__) || defined (__mc68040__) || defined (__mc68060__)
/* everybody but the MC68000 and coldfire put a vector offset on the stack. */
	ori		IMM(0x700),sr
	movel	sp@(2),d6
	clrl	d7
	movew	sp@(6),d7
	lsrw	IMM(2),d7
	andiw	IMM(0xff),d7
	bra	001b

#else

/* MC68000 version */
	ori		IMM(0x700),sr
	moveq	IMM(-1),d7
	bra	001b
#endif
