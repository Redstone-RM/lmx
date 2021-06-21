/* ---------------------------------------------------------------------------- */
/* machine.h	Machine Specific Definitions for A Lightweight Multi-Tasking 	*/
/*		Executive (LMX):  M68K						*/
/*

25 Aug 2015 dpa	LOAD_FRAME and STORE_FRAME.  M68K asm code, compiled with -Os
29 Aug 2015 dpa	DISABLE_TIMERS, ENABLE_TIMERS
		(*current->func)(current->arg)
05 Sep 2015 dpa	LOAD_SP, STORE_SP;
08 Sep 2015 dpa	ENABLE_INT, DISABLE_INT, save regs
*/
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

