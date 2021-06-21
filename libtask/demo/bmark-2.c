/* -------------------------------------- */
/* Test of LMX multi-tasking on ARDUINO
 *  
 *  04 Sep 2015 dpa Created.  Mega2560
 *  
 */
/* -------------------------------------- */

#define VERSION "BMARK-2.1.2"

/* -------------------------------------- */

#include <stdio.h>
#include "../task.h"
#include "../log.h"
#include "../sysclock.h"

/* -------------------------------------- */

#if (MACHINE == MACH_M68K)  /* MRM332 */
#include "../68332/mrm332/mrm332.h"
#define PRINTF printsci
#define SPRINTF sprintf
#endif

#if (MACHINE == MACH_ARM)  /* Teensy3.1 */
#include <TimerThree.h>
#define PRINTF Serial.println
#define SPRINTF sprintf
#endif

#if (MACHINE == MACH_AVR)  /* Mega2560, Mega328 Teensy-LC */
#define PRINTF Serial.println
#define SPRINTF sprintf
#endif

void printkbuf(char *s) {

   #if ((MACHINE == MACH_AVR) || (MACHINE == MACH_ARM))
   PRINTF(s);
   #endif
   #if (MACHINE == MACH_M68K)
   PRINTF("%s\n",s);
   #endif
}


/* -------------------------------------- */
/* Choose one of the below:  */

// #define WAIT(d)  { d *= 10; cnt = 0; while (cnt++ < d) defer(); }
// #define WAIT(d)  { msleep(d); }
#define WAIT(d)  { wake_after(d); }

/* -------------------------------------- */
/* 3 leds on Arduino pins 11,12,13  */

#if ((MACHINE == MACH_AVR) || (MACHINE == MACH_ARM))  /* ARM is Teensy3.1 */
#define LED1_ON  digitalWrite(11, HIGH)
#define LED1_OFF digitalWrite(11, LOW)

#define LED2_ON  digitalWrite(12, HIGH)
#define LED2_OFF digitalWrite(12, LOW)

#define LED3_ON  digitalWrite(13, HIGH)
#define LED3_OFF digitalWrite(13, LOW)
#endif

/* -------------------------------------- */
/* 2 leds on mrm332 board */

#if (MACHINE == MACH_M68K)
#define LED1_ON  led_on(RED_LED)
#define LED1_OFF led_off(RED_LED)

#define LED2_ON  { asm("nop"); }
#define LED2_OFF { asm("nop"); }

#define LED3_ON  led_on(GREEN_LED)
#define LED3_OFF led_off(GREEN_LED)
#endif

/* -------------------------------------- */
/* Count idle cycles per second */

unsigned long idle_cnt;

void cpu_idle(ASIZE ignored)
{
    unsigned long t;
    unsigned long cnt;
    
    t = sysclock + 1000;
    while (1) {
        idle_cnt = proc_counter;
        proc_counter = 0;
        // WAIT(1000);
        PERIOD(&t,1000);
    }
}

/* -------------------------------------- */

void led1(ASIZE delay)
{
  unsigned long cnt;
  
  while (1) {
    WAIT(delay);
    LED1_ON;
    WAIT(delay);
    LED1_OFF;
  }  
}

/* -------------------------------------- */

void led2(ASIZE delay)
{
  unsigned long cnt;
  while (1) {
    WAIT(delay);
    LED2_ON;
    WAIT(delay);
    LED2_OFF;
  }  
}

/* -------------------------------------- */
/* led3: flash and hang on a semaphore */

#define FLASH 7
int flash_sem;

void led3(ASIZE delay)
{
    int i;
    unsigned long cnt;
    
    while (1) {
        semaphore_obtain(&flash_sem);
        for (i = 0; i < FLASH; i++) {
          LED3_ON;
          WAIT(delay);
          LED3_OFF;
          WAIT(delay);
        }
    }
}

/* -------------------------------------- */
/* Flash led3 periodically */

void flash(ASIZE delay)
{
  unsigned long cnt;
    while (1) {
      semaphore_release(&flash_sem);
      WAIT(delay);
    }
}
/* ----------------------------------------- */

void stats_task(ASIZE delay)
{
    TSIZE t;
    t = sysclock + delay;

    while (1) {
      // WAIT(delay);
      PERIOD(&t,delay);
      PRINTF("\n");
      SPRINTF(sbuf,"# Sysclock\t%ld\tSampleclock\t%ld\tIdleHz\t%ld",
              sysclock,sampleclock,idle_cnt);
      PRINTF(sbuf);
      PRINTF("\n");
      print_llist(1);
    }
}
/* ----------------------------------------- */
/* AVR led port init */

#if ((MACHINE == MACH_AVR) || (MACHINE == MACH_ARM)) /* ARM is Teensy3.1 */
void led_init(void)
{
    pinMode(13, OUTPUT); 
    pinMode(12, OUTPUT);
    pinMode(11, OUTPUT);
}
#endif

/* ----------------------------------------- */
/* system_init */

void system_init(void)
{
#if (MACHINE == MACH_M68K)
    /* MRM332 */
    libmrm_init(0xff);
    sysclock_init();
    ENABLE_INTERRUPTS;
#else
    /* AVR & ARM Teesy3.1  */
    led_init();
    sysclock_init();
    Serial.begin(57600);
#endif
}
/* ----------------------------------------- */
/* Create signon and terminate task */

void signon(ASIZE version)
{
  PRINTF(VERSION);
  PRINTF("\n");
  wake_after(2000);
  PRINTF("# SIGNON Messages signing off!\n");
  DELAY(1000);
  terminate();
}

/* ----------------------------------------- */
/* main */

#if ((MACHINE == MACH_AVR) || (MACHINE == MACH_ARM))  /* ARM is Teensy3.1 */
/* this is for the Arduino IDE "sketch" set up */
void setup()
#else
int main()
#endif
{
    system_init();
    printv = printkbuf;

    PRINTF("Howdy Console!\n");

    pid_count = 0; current = 0;

    create_task("LED1",led1,500,MINSTACK);
    create_task("LED2",led2,333,MINSTACK);
    create_task("LED3",led3,30,MINSTACK);
    create_task("FLASH",flash,2111,MINSTACK);
    create_task("IDLE",cpu_idle,0,MINSTACK);
    create_task("STATS",stats_task,10000,MINSTACK*3);
    create_task("SIGNON",signon,1,MINSTACK*3);

    scheduler();
    PRINTF("Should never get here.");

    while (1);
    #if ((MACHINE != MACH_AVR) && (MACHINE != MACH_ARM))
    return 0;
    #endif
}

void loop() 
{
  /* nothing to see here, move along */
  asm("nop");
}
    
/* ----------------------------------------- */
/* EOF */


