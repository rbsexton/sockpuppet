//*****************************************************************************
//
// main.c 
// Setup the system and launch Forth
//
// This runs on some custom hardware that I built, but it should be portable
// 
// 
// Principle of operation
// We run the CPU at the Full 50MHz.  
//
// PIN ASSIGNMENTS
//*****************************************************************************
#include <stdint.h>
#include <string.h>

#include <inc/hw_types.h>
#include <inc/hw_memmap.h>
#include <inc/hw_gpio.h>
#include <inc/hw_ints.h>
#include <inc/hw_timer.h>

#include <driverlib/interrupt.h>
#include <driverlib/systick.h>
#include <driverlib/gpio.h>
#include <driverlib/sysctl.h>
#include <driverlib/timer.h>
#include <driverlib/uart.h>

#include <utils/uartstdio.h>

#include "userapp.h"

/*
 * Configure the processor 
 */
static void prvSetupHardware( void ) {
  	/* Setup the System Clock. 200 / 8 = 50MHz */ 
	SysCtlClockSet(SYSCTL_SYSDIV_4 |\
		SYSCTL_USE_PLL | SYSCTL_OSC_MAIN | SYSCTL_XTAL_8MHZ);

	// Turn on Clock Gating control
	SysCtlPeripheralClockGating(true);

	// ******************************************************************
	// Bank A - SSI, UART0, and Switch 1
	
	SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOA); 
	GPIOPinTypeUART(GPIO_PORTA_BASE,GPIO_PIN_0|GPIO_PIN_1); 
	SysCtlPeripheralSleepEnable(SYSCTL_PERIPH_GPIOA);

	UARTStdioInit(0);
	UARTprintf("Booted\n");
	
	UARTFIFOEnable(UART0_BASE); // Turn on UART FIFO
	UARTFIFOLevelSet(UART0_BASE,
			UART_FIFO_TX4_8, UART_FIFO_RX1_8);
	UARTIntEnable(UART0_BASE, UART_INT_RT|UART_INT_RX|UART_INT_OE);
	
	// Bank C - Status LEDs
	SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOC); 
	SysCtlPeripheralSleepEnable(SYSCTL_PERIPH_GPIOC);
	GPIOPinTypeGPIOOutput(GPIO_PORTC_BASE,GPIO_PIN_6|GPIO_PIN_7); // LEDS
								
	SysCtlPeripheralSleepEnable(SYSCTL_PERIPH_UART0);
	SysCtlPeripheralSleepEnable(SYSCTL_PERIPH_SSI0);

	// Setup Timer 0 to only run when the processor runs, and reload the max value
	// Note that it isn't sleep enabled.
	SysCtlPeripheralEnable(SYSCTL_PERIPH_TIMER0); 
	TimerConfigure(TIMER0_BASE, TIMER_CFG_32_BIT_PER);
    TimerLoadSet(TIMER0_BASE, TIMER_A, 0xffffffff);
    TimerEnable(TIMER0_BASE, TIMER_A);

	}

/*
 * Systick Handler 
 */
unsigned long usage = 0;
unsigned long g_ulSystemTimeMS; 

void SysTickHandler(void) {
        static int usage_counter = 0;  ///< Triggers harvest of usage data.

        static int beforecount, aftercount;
        
        g_ulSystemTimeMS += TICKMS;
        
    	usage_counter += TICKMS;
    	if (usage_counter >= 1000) usage_counter=0;
        
    	if (usage_counter == 0) {
        
        // Load up the current value from the timer.
        aftercount = HWREG(TIMER0_BASE + TIMER_O_TAR); 
        usage = beforecount - aftercount;

        beforecount = aftercount;
        }
	}
	
// A basic function for testing call mechanisms 
unsigned long getMSFunction() {
	return(g_ulSystemTimeMS);
	}

//*****************************************************************************
// Main - Set things up, Launch Forth
//*****************************************************************************
unsigned long maincounter = 0;

int main(void) {
	
	// Setup the hardware.
	prvSetupHardware();

	IntPrioritySet(INT_UART0,(0<<5));
	IntPrioritySet(FAULT_SVCALL,(0<<5));
	IntPrioritySet(FAULT_SYSTICK,(1<<5));
	IntPrioritySet(FAULT_PENDSV,(7<<5));

	IntEnable(INT_UART0);
	
	//*****************************************************************
	// Turn on SysTick
	SysTickPeriodSet(CPUHZ/TICKHZ); 
	SysTickEnable();
	SysTickIntEnable();

	// Turn on all interrupts
	IntMasterEnable();

	if ( user_app_present(FORTH_ADDR) == 1) {
		UARTprintf("Starting Forth @ 0x%0x\n",FORTH_ADDR);		
		user_app_launch(FORTH_ADDR);
		}
	else { 
		UARTprintf("Cannot find Forth @ 0x%0x\n",FORTH_ADDR);		
		}
		
	// This should not happen, but we'll do it anyway.
	while(true) {
        //
        // Wait for an event to occur.
        //
        SysCtlSleep();
    	maincounter++;
    	}
     		
	}

