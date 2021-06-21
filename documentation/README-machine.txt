/* ---------------------------------------------------------------------------- */

  Processor-Dependent Definitions for A Lightweight Multi-Tasking Executive (LMX)

  27 Aug 2015 dpa 	Created from machine.h.  
  30 Aug 2015 dpa	NEW_TASK mods for AVR.
  15 Sep 2015 dpa	ARM.
/* ---------------------------------------------------------------------------- */

I. 	Intro.

A round-robin cooperative multi-tasking executive is implemented by the 'defer()'
system call defined in the 'task.c' source code file in this directory.  It uses a 
linked list of 'TASK' data structures defined in 'task.h'.  

defer() does its work by manipulating the processor's Frame Pointer and Stack Pointer.
These are implemented by most C compilers (gcc) on most hardware as processor registers.

The C pre-processor definitions in this file allow direct manipulation from C code of the
processor Frame Pointer and Stack Pointer registers used by the defer() call.

They are implemented as C asm(" ") inline assembly instructions, following the conventions
of the GNU gcc compiler.  In principle these macros should be the only processor-dependent
pieces of the executive.

II. 	Machine-Dependent Multi-Tasking Macros.

	In the following pseudo-code definitions:

	"FP" and "SP" are the processor's frame pointer and stack pointer registers.
		    The stack is assumed to be full descending.  
	"PC"        is the processor's program counter, used implicitly by the "rts" instruction.

	"ARG1"      is a machine-dependent method for passing argument 1 to a subroutine,
		    either in a register or on a stack.
	"RUNNING"   is a constant defined in task.h.  
	"current"   is a global pointer to a TASK struct, also defined in task.h.  

	------------------------------------------------------------------
		Macro Name		Assembly Pseudo-code
	------------------------------------------------------------------

	A. 	Load and store the frame pointer in the current TASK struct:

		#define STORE_FP	{ current->FP = FP; }	
		#define LOAD_FP		{ FP = current->FP; }	

	B.	Link and Unlink the frame pointer:
	
		#define LINK		{--(*SP) = FP; FP = SP; }	
		#define UNLINK		{ SP = FP; FP = (*SP)++; }  

	C.	Push and Pop protected registers:

		#define PUSH_REGS	{ --(*SP) = Rx-Ry; }
		#define POP_REGS	{ Ry-Rx = (*SP)++; }

	D.	Return from subroutine without a stack frame unlink.

		#define RETURN		{ PC = (*SP)++; }


III.	Machine-Independent Multi-Tasking Macros.

	These macros are generated automatically from the machine-dependent 
	definitions above.

	A.	Load and store a task frame:

		#define STORE_FRAME	{ PUSH_REGS; LINK; STORE_FP; }	
		#define LOAD_FRAME	{ LOAD_FP; UNLINK; POP_REGS; }	

	B.	Setup and execute an uninitialized task:

		#define SETSTATE	current->state = RUNNING
		#define NEW_TASK 	{ SETSTATE; LOAD_FP; UNLINK; (*current->func)(current->arg); }


IV.	LMX Macros for M68K, ARM, and AVR processors.


/* ---------------------------------------------------------------------------- */
/*			 Macros for the Motorola MC68332			*/
/* ---------------------------------------------------------------------------- */

#define DISABLE_INT	asm("nop")
#define ENABLE_INT	asm("nop")

#define SAVE_REGS	asm("move.l %a0, -(%sp)")
#define LOAD_REGS	asm("move.l (%sp)+, %a0")

#define STORE_FP  	{ SAVE_REGS; asm("move.l current,%a0; move.l %fp,FP(%a0)"); LOAD_REGS; }
#define LOAD_FP   	{ SAVE_REGS; asm("move.l current,%a0; move.l FP(%a0),%fp"); LOAD_REGS; } 

#define PUSH_REGS	asm("movem.l %d2-%d7/%a2-%a5,-(%sp)")
#define POP_REGS	asm("movem.l (%sp)+,%a5-%a2/%d7-%d2")

#define LINK		asm("link %fp,#0")
#define UNLINK    	asm("unlk %fp")

#define FIX_FRAME	asm("move.l -4(%fp),%a2")
#define RETURN    	asm("rts")

/* ---------------------------------------------------------------------------- */

#define STORE_FRAME	{ DISABLE_INT; PUSH_REGS; LINK; STORE_FP; ENABLE_INT; }
#define LOAD_FRAME	{ DISABLE_INT; LOAD_FP; UNLINK; POP_REGS; ENABLE_INT; }

#define SETSTATE	current->state = RUNNING
#define EXECUTE		(*current->func)(current->arg)

#define NEW_TASK	{ SETSTATE; LOAD_FP; UNLINK; EXECUTE; }
#define NEXT_FRAME	{ LOAD_FRAME; FIX_FRAME; UNLINK; RETURN; }

#define DISABLE_TIMERS	{ run_level_state = run_level; run_level = 0; }
#define ENABLE_TIMERS	{ run_level = run_level_state; }

/* ---------------------------------------------------------------------------- */
/* EOF */

/* ---------------------------------------------------------------------------- */
/*			 Macros for the ARM processor				*/
/* ---------------------------------------------------------------------------- */

#define DISABLE_INT     { asm("nop");}
#define ENABLE_INT      { asm("nop");}

#define STORE_FP        asm("ldr r0,=current; ldr r0, [r0, #0]; str fp, [r0, #FP]") 
#define LOAD_FP         asm("ldr r0,=current; ldr r0, [r0, #0]; ldr fp, [r0, #FP]") 

#define LINK            asm("stmfd sp!,{fp, lr}; mov fp, sp;  add fp, fp, #4")
#define UNLINK          asm("sub fp, fp, #4; mov sp, fp; add fp, fp, #4; ldmfd sp!, {fp, lr}") 

#define UNLINK_TASK     asm("add fp, fp, #4; mov sp, fp; ldmfd sp!, {fp}")
#define LOAD_TASK       asm("ldmfd sp!, {r0}; ldr lr,=current; ldr lr, [lr, #0];ldr lr, [lr, #FUNC]")
                 
#define PUSH_REGS       asm("stmfd sp!, {r4-r12}")
#define POP_REGS        asm("ldmfd sp!, {r4-r12}")

#define FIX_FRAME       asm("nop")
#define RETURN          asm("bx lr")

/* ---------------------------------------------------------------------------- */

#define STORE_FRAME     { DISABLE_INT; PUSH_REGS; LINK; STORE_FP; ENABLE_INT; }
#define LOAD_FRAME      { DISABLE_INT; LOAD_FP; UNLINK; POP_REGS; ENABLE_INT; }

#define SETSTATE        { current->state = RUNNING; }
#define NEW_TASK        { SETSTATE; LOAD_FP; UNLINK_TASK; LOAD_TASK; RETURN; }
#define NEXT_FRAME      { LOAD_FRAME; FIX_FRAME; RETURN; }

#define DISABLE_TIMERS  { run_level_state = run_level; run_level = 0; }
#define ENABLE_TIMERS   { run_level = run_level_state; }

/* ---------------------------------------------------------------------------- */
/* EOF */

/* ---------------------------------------------------------------------------- */
/*			 Macros for the AVR processor				*/
/* ---------------------------------------------------------------------------- */

#define __AVR_ATmega2560__
#include  <avr/interrupt.h>
#include  <avr/io.h>

/* ---------------------------------------------------------------------------- */

#define SAVE_REGS       asm volatile ("mov r4, r28"); \
			asm volatile ("mov r5, r29"); \
			asm volatile ("mov r6, r30"); \
			asm volatile ("mov r7, r31")

#define LOAD_REGS	asm volatile ("mov r31, r7"); \
			asm volatile ("mov r30, r6"); \
			asm volatile ("mov r29, r5"); \
			asm volatile ("mov r28, r4")

#define STORE_SP	{ SAVE_REGS; \
			asm volatile ("in r28, __SP_L__"); \
                        asm volatile ("in r29, __SP_H__"); \
			asm volatile ("lds r30,current");  \
                        asm volatile ("lds r31,current+1");\
                        asm volatile ("std Z+FP,   r28");  \
                        asm volatile ("std Z+FP+1, r29");  \
			LOAD_REGS; }

#define LOAD_SP		{ SAVE_REGS; \
			asm volatile ("lds r30,current"); \
                        asm volatile ("lds r31,current+1"); \
                        asm volatile ("ldd r28, Z+FP"); \
                        asm volatile ("ldd r29, Z+FP+1"); \
                        asm volatile ("out __SP_L__, r28"); \
                        asm volatile ("out __SP_H__, r29"); \
			LOAD_REGS; }

#define UNLINK		asm volatile ("pop r29"); \
                        asm volatile ("pop r28")

#define FIX_FRAME	asm("nop")

#define RETURN          asm volatile ("ret")

#define PUSH_REGS	asm volatile ("push r0"); \
			asm volatile ("push r1"); \
			asm volatile ("push r2"); \
			asm volatile ("push r3"); \
			asm volatile ("push r4"); \
			asm volatile ("push r5"); \
			asm volatile ("push r6"); \
			asm volatile ("push r7"); \
			asm volatile ("push r8"); \
			asm volatile ("push r9"); \
			asm volatile ("push r10"); \
			asm volatile ("push r11"); \
			asm volatile ("push r12"); \
			asm volatile ("push r13"); \
			asm volatile ("push r14"); \
			asm volatile ("push r15"); \
			asm volatile ("push r16"); \
			asm volatile ("push r17"); \
			asm volatile ("push r18"); \
                        asm volatile ("push r19"); \
                        asm volatile ("push r20"); \
                        asm volatile ("push r21"); \
                        asm volatile ("push r22"); \
                        asm volatile ("push r23"); \
                        asm volatile ("push r24"); \
                        asm volatile ("push r25"); \
                        asm volatile ("push r26"); \
                        asm volatile ("push r27"); \
                        asm volatile ("push r28"); \
                        asm volatile ("push r29"); \
                        asm volatile ("push r30"); \
                        asm volatile ("push r31")
                                     
#define POP_REGS        asm volatile ("pop r31"); \
                        asm volatile ("pop r30"); \
                        asm volatile ("pop r29"); \
                        asm volatile ("pop r28"); \
                        asm volatile ("pop r27"); \
                        asm volatile ("pop r26"); \
                        asm volatile ("pop r25"); \
                        asm volatile ("pop r24"); \
                        asm volatile ("pop r23"); \
                        asm volatile ("pop r22"); \
                        asm volatile ("pop r21"); \
                        asm volatile ("pop r20"); \
                        asm volatile ("pop r19"); \
                        asm volatile ("pop r18"); \
                        asm volatile ("pop r17"); \
                        asm volatile ("pop r16"); \
                        asm volatile ("pop r15"); \
                        asm volatile ("pop r14"); \
                        asm volatile ("pop r13"); \
                        asm volatile ("pop r12"); \
                        asm volatile ("pop r11"); \
                        asm volatile ("pop r10"); \
                        asm volatile ("pop r9"); \
                        asm volatile ("pop r8"); \
                        asm volatile ("pop r7"); \
                        asm volatile ("pop r6"); \
                        asm volatile ("pop r5"); \
                        asm volatile ("pop r4"); \
                        asm volatile ("pop r3"); \
                        asm volatile ("pop r2"); \
                        asm volatile ("pop r1"); \
                        asm volatile ("pop r0")

/* ---------------------------------------------------------------------- */

#define DISABLE_INT	{ sreg = SREG; cli(); }
#define ENABLE_INT	{ SREG = sreg; }

#define STORE_FRAME     { DISABLE_INT; PUSH_REGS; STORE_SP; ENABLE_INT; }
#define LOAD_FRAME      { DISABLE_INT; LOAD_SP; POP_REGS; ENABLE_INT; }
                                     
#define SETSTATE        { current->state = RUNNING; }
#define EXECUTE		{ (*current->func)(current->arg); }

#define NEW_TASK        { SETSTATE; LOAD_SP; EXECUTE; }
#define NEXT_FRAME	{ LOAD_FRAME; FIX_FRAME; UNLINK; RETURN; }

#define DISABLE_TIMERS	{ run_level_state = run_level; run_level = 0; }
#define ENABLE_TIMERS	{ run_level = run_level_state; }


/* ---------------------------------------------------------------------------- */
/* EOF */
