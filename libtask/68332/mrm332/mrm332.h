/* ------------------------------------------------------------------- */
/* mrm332.h	Machine-Specific Defines for Mini Robo-Minds MC68332   */
/*
22 Jul 15 dpa	Created.
*/
/* ---------------------------------------------------------------------------- */

#define ENABLE_INTERRUPTS  asm("move.w #0x2500,%sr")    /* Enable level 6&7 */
#define DISABLE_INTERRUPTS asm("move.w #0x2000,%sr")    /* Disable level 6&7 */

/* ---------------------------------------------------------------------------- */

#define RED_LED   0x20
#define GREEN_LED 0x10
void led_on(int color);
void led_off(int color);

/* ---------------------------------------------------------------------------- */

int libmrm_init(int flag);
int interrupt_catch(void (*func)(), int vecnum, int *oldvec);
void printsci(const char *fmt, ...);

#define ALL_INIT 0xff

/* ------------------------------------------------------------------- */
/* EOF task.h */

