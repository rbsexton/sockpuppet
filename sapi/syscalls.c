/// \file syscalls.c
/// \brief Sockpuppet API System Call functions
/// \defgroup SAPI Sockpuppet 
//! \addtogroup SAPI
//! @{
/// 
/// Sockpuppet API Code.  This is our
/// shim for Forth.  Should be very easy to port
/// to exotic environments.
///
/// These are all declared void because they return by modifying
/// the return stack.
///
/// Note that the official list/ordinality of syscalls is defined by svc.S
//
// Copyright(C) 2011-2013 Robert Sexton
//
//
// Change History.
// API Version 0203.  Add a return code to StreamPutChar for back-pressure.

#include <stdint.h>

#if (PLATFORM_LM3S) 
#include "inc/hw_types.h"
#include "inc/hw_nvic.h"
#include "inc/hw_memmap.h"
#include "inc/hw_uart.h"
#include "driverlib/uart.h"
#endif

#include "sapi.h"
#include "sapiopts.h"
#include "sapi-dylink.h"

#if (PLATFORM_LM3S) 
static unsigned long uart_ports[] = {
	UART0_BASE,
	UART1_BASE,
	UART2_BASE
	};
#endif

///< Watchdog support is in SAPI 0202 and later.
#if (SAPI_WATCHDOG) 
#include "wdt.h"
#endif

int pendsv_uart = 0;  //!< Indicates the cause of PendSV is the UART.
					  //!< Store the address of the UART in question here.

// *******************************************************************
// MANDATORY CALLS
// *******************************************************************

/// @brief SVC 0: Return an API Version 
void __SAPI_Version(long *frame) {
	frame[0] = 0x0203;
	return;
	}

/// SVC 1: Return the address of the runtime link list
void __SAPI_GetLinkList(long *frame) {
        frame[0] = (uint32_t) dynamiclinks;
        }

/// SVC 2: StreamPutChar 
/// There are two situations:
/// The FIFO is full.  Thats the bad scene.  Cut off the supply of CPU Cycles, possibly WDT Timeout.
/// Situation Two - We have pushed the FIFO into Highwater.  Tell them.
///
/// @param frame[0]/R0 Port number/Descriptor
/// @param frame[1]/R1 Character to output
/// @returns Success:  0
/// @returns Quench:  -1
void __SAPI_StreamPutChar(long *frame) {
	// Physical UARTS are 0-9
	if (frame[0] < 10 ) {
		frame[0] = 0;
		#if (PLATFORM_LM3S) 

		// This call will wait until there is room.
  		UARTCharPut(uart_ports[frame[0]],frame[1]);

		// There should be a check here for a full FIFO.  If its full whack PendSV
		// so that we WFI until there is room for the next character.
		if (HWREG(uart_ports[frame[0]] + UART_O_FR) & UART_FR_TXFF) {
			HWREG(NVIC_INT_CTRL) = NVIC_INT_CTRL_PEND_SV;
			pendsv_uart = uart_ports[frame[0]];
			frame[0] = -1; // By definition, if had to PendSV, that means we tell the user.
			return;
			}		

		// This bit is set to indicate that there is room for more...
		if (HWREG(uart_ports[frame[0]] + UART_O_RIS) & UART_RIS_TXRIS) {
			frame[0] = 0;
			}
		else { frame[0] = -1; }

		#endif
		return;
		}

	// For now, assume that > 10 means networking

	return;
	}

/// SVC 3: StreamGetChar 
///
/// Pull a character out of the stream of choice
void __SAPI_StreamGetChar(long *frame) {
	if (frame[0] < 10 ) {
		frame[0] = 0;
		frame[0] = UARTCharGet(uart_ports[frame[0]]);
		return;
		}
	}

/// SVC 4: StreamCharsAvail 
///
/// Check to see if there is a char available
void __SAPI_StreamCharsAvail(long *frame) {
	if (frame[0] < 10 ) {
		frame[0] = 0;
		frame[0] = UARTCharsAvail(uart_ports[frame[0]]);
		return;
		}
	

// ------- SVC 5: Reserved -------
// ------- SVC 6: Reserved -------
// ------- SVC 7: Reserved -------

#if (SAPI_WATCHDOG) 
/// @brief SVC 8: Reset the watchdog timer 
/// @param Number of clock ticks until next reset
///
/// This one will probably need a little cleanup to be 
/// cross-platform.
void __SAPI_WatchdogKick(long *frame) {
	WatchdogKick(frame[0]);       
	}

#endif 

extern unsigned long g_ulSystemTimeMS;
/// @brief SVC 9: GetTimeMS - Return the current value of the ms counter.
///
/// This could be replaced with a direct read, but this 
/// allows us to enforce monotonic behavour for updates
void __SAPI_GetTimeMS(long *frame) {
        frame[0] = g_ulSystemTimeMS;
	}

// *******************************************************************
// Optional calls
// *******************************************************************

#if (SAPI_USAGE) 
extern unsigned int usage;
/// @brief SVC 10: Return the number of CPU cycles in the last second.
void __SAPI_GetUsage(long *frame) {
	frame[0] = usage;       
	}

#endif 

// ------- SVC 11: DNSLookup - Defined in sapi-lwip-dns.c -------

// ------- SVC 12: pbuf_get - Defined in sapi_pbuf.c -------
// ------- SVC 13: pbuf_release - Defined in sapi_pbuf.c -------

// ------- SVC 14: udp_new - Defined in sapi-lwip-udp.c -------
// ------- SVC 15: udp_ - Defined in sapi-lwip-udp.c -------
// ------- SVC 16: udp_bind - Defined in sapi-lwip-udp.c -------
// ------- SVC 17: udp_connect - Defined in sapi-lwip-udp.c -------
// ------- SVC 18: udp_disconnect - Defined in sapi-lwip-udp.c -------
// ------- SVC 19: udp_send - Defined in sapi-lwip-udp.c -------
// ------- SVC 20: udp_sendto - Defined in sapi-lwip-udp.c -------

// *******************************************************************
// Helper Functions
// *******************************************************************

/// While(1) loop for catching Reserved API Calls
void __SAPI_RFU(long *frame) {
	while(1) { ; }
	}

/// Catch Disabled API Calls, and return a nonsense value
/// This one was a hang loop, but its better to do something
/// harmless
/// @brief Return a bogus value for disabled calls.
void __SAPI_Disabled(long *frame) {
	frame[0] = 0xdead;
	frame[1] = 0xbeef;
	}

// *******************************************************************
// PendSV - Target specific.
// *******************************************************************
static unsigned sapi_count_pendsv = 0; ///< Performance/Validation Counter

/// Low-Priority Handler to spin-wait until buffers drain.
///
/// Hang out here and WFI until both ringbuffers drain to an acceptable level.
/// Don't return control to thread-mode code.
///
/// NOTE NOTE NOTE:  If the NVIC doesn't use the correct priority none
/// of this will work, and it may in fact fail spectacularly
void PendSVHandler () {

	if ( pendsv_uart != 0 ) {
		// Spin and WFI until its not full 

   		while(HWREG(pendsv_uart + UART_O_FR) & UART_FR_TXFF) {
   			sapi_count_pendsv++;
			__asm("wfi");
   			}
		pendsv_uart = 0;
		}
	}

//! // Close the Doxygen group.
//! @}

