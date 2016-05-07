/// \file lm3s-uart.c
/// \brief TI/Stellaris Code to implement the UART calls.
/// \defgroup SAPI Sockpuppet 
//! \addtogroup SAPI
//! @{
/// 
// Copyright(C) 2011-2014 Robert Sexton
// Covered by the terms of the supplied Licence.txt file

// The SAPI Chario layer is a dispacher.   Here are the low-level UART functions.
// This driver layer implements software flow control via XON/XOFF
//
// Change History.

#include <stdint.h>
#include <stdbool.h>

#include "inc/hw_types.h"
#include "inc/hw_nvic.h"
#include "inc/hw_memmap.h"
#include "inc/hw_uart.h"
#include "driverlib/uart.h"

#include "sapi.h"
#include "sapiopts.h"

static unsigned long uart_ports[] = {
	UART0_BASE,
	UART1_BASE
	};

#define XONCHAR  0x11
#define XOFFCHAR 0x13


// ----------------------------------------------------------------------------
/// putchar_uart(frame) 
/// Push a character into the uart.   Return 0 if there is room for more,
/// -1 if we need for them to throttle.
///
/// Throttling - We use the FIFO level bits to detect when its more than 
/// half full.   When this happens, lower the FIFO threshhold from 4/8 to 
/// 2/8, and enable the interrupt so that the WFI will clear when there is 
/// more room in the FIFO.
///
/// @param frame[0]/R0 Port number/Descriptor
/// @param frame[1]/R1 Character to output
/// @returns Success:  0
/// @returns Quench:  -1
// ----------------------------------------------------------------------------

unsigned int count_sapi_putchar_out=0;
unsigned int count_sapi_putchar_highwater=0;

void putchar_uart(uint32_t *frame) {

	count_sapi_putchar_out++;

	// This will block if the FIFO is full.
  	UARTCharPut(uart_ports[frame[0]],frame[1]);

	// The RIS bit gets set when you have room for more while in FIFO mode.
	// If the TX bit was set before, there was room
	// If its still set now, there is still room. 
    if ( (HWREG(uart_ports[frame[0]] + UART_O_RIS) & UART_RIS_TXRIS) != 0 ) {
        frame[0] = 0;
        return;
        }

	// From here on, we're dealing with throttling
	uint32_t FIFOlevTX, FIFOlevRX;
	
	// If the FIFO is full, or we have triggered highwater, we will adjust the 
	// FIFO Trigger level and enable the IRQ
    UARTFIFOLevelGet(uart_ports[frame[0]],&FIFOlevTX,&FIFOlevRX);
 		                             
    // If we were below before, and we are above now, its highwater.
    // Set the FIFO level down so that we'll take an interrupt
    // when it drains.        
    if ( (HWREG(uart_ports[frame[0]] + UART_O_RIS) & UART_RIS_TXRIS) == 0 ) {
       	count_sapi_putchar_highwater++;
     	UARTFIFOLevelSet(uart_ports[frame[0]],UART_FIFO_TX2_8,FIFOlevRX);
        }

    // Enable the IRQ so that the handler can wake us.
    HWREG(uart_ports[frame[0]] + UART_O_IM) |= UART_IM_TXIM;

	// In either case, we tell the App.
	frame[0] = -1;
		
    return;
	}

// ----------------------------------------------------------------------------
/// getchar_uart 
/// Pull a character out of the stream of choice
/// This gets called when CharsAvail says there is work to do,
/// so we know that there is at least one.
// ----------------------------------------------------------------------------
unsigned int count_sapi_streamgetchar=0;
unsigned int count_sapi_streamgetchar_xon=0;

void getchar_uart(uint32_t *frame) {
	count_sapi_streamgetchar++;
	unsigned long uart = frame[0];

	frame[0] = UARTCharGet(uart_ports[uart]);
		
	// If the UART isn't empty, we're done
	if ( (HWREG(uart_ports[uart] + UART_O_FR) & UART_FR_RXFE) == 0 ) {
		return;
		}

	// If we're here, the FIFO is empty now.		
	// Figure out if we need to issue the XON.
	uint32_t FIFOlevTX, FIFOlevRX;
	
	UARTFIFOLevelGet(uart_ports[uart],&FIFOlevTX,&FIFOlevRX);
	if ( FIFOlevRX != UART_FIFO_RX1_8 ) { // Send the XON and lower the level
		UARTFIFOLevelSet(uart_ports[uart],FIFOlevTX,UART_FIFO_RX1_8);
		UARTCharPut(uart_ports[uart],XONCHAR);
		count_sapi_streamgetchar_xon++;
		}

	return;
	}

// ----------------------------------------------------------------------------
/// chars_available_uart() 
///
/// Check to see if there is a char available
// ----------------------------------------------------------------------------
unsigned int count_sapi_charsavailable=0;

void chars_available_uart(uint32_t *frame) {
	count_sapi_charsavailable++;
	frame[0] = UARTCharsAvail(uart_ports[frame[0]]);
	return;
	}	

// ----------------------------------------------------------------------------
/// UART handlers - Handle the flow control.
/// The basic mechanism is to take an interrupt when the input FIFO 
/// is more than 
// ----------------------------------------------------------------------------

// The core thing here is that the scheduler does a WFI.
// So just taking the interrupt is mostly enough

void UARTHandler(uint32_t channel) {
	uint32_t FIFOlevTX, FIFOlevRX;
	uint32_t int_status;
	
	int_status = UARTIntStatus(uart_ports[channel], true);
	
	// We'll be adjusting the FIFOs, so snapshot the current state.
	UARTFIFOLevelGet(uart_ports[channel],&FIFOlevTX,&FIFOlevRX);
	
	// ------------------ TX Logic -----------------------

	// The FIFO Triggered highwater, and now it's drained.
	// Clear the IRQ and reset the FIFO trigger level.
	// Exit the handler and possible return to start over
	if ( (int_status & UART_MIS_TXMIS) != 0 ) {
			
		// We don't need another interrupt.  Disable it and restore the 
		// threshhold.  
		HWREG(uart_ports[channel] + UART_O_IM) &= ~(UART_IM_TXIM);
        UARTFIFOLevelSet(uart_ports[channel],UART_FIFO_TX4_8,FIFOlevRX);
        return;
		}

	// ------------------ RX Logic -----------------------
	//  If we're at RX 1/8, just raise it.  
	//  If we're at RX 1/4, THe FIFO is starting to overlfow.  Send the XOFF
	//  and raise the trigger level so we get another IRQ
	if ( (int_status & UART_MIS_RXMIS) != 0 ) {
		if (FIFOlevRX == UART_FIFO_RX1_8 ) {
	        UARTFIFOLevelSet(uart_ports[channel],FIFOlevTX,UART_FIFO_RX2_8);
			}
		if (FIFOlevRX == UART_FIFO_RX2_8 ) {
	        UARTFIFOLevelSet(uart_ports[channel],FIFOlevTX,UART_FIFO_RX7_8);
			UARTCharPut(uart_ports[channel],XOFFCHAR); // BLocking.  Should be OK.
			}
		}
		
	// Clear it.
	UARTIntClear(uart_ports[channel], int_status);
	}
	
void UARTHandler0() { UARTHandler(0); }
void UARTHandler1() { UARTHandler(1); }

void SAPIUARTInit(int channel) {
	UARTFIFOEnable(uart_ports[channel]);
	UARTFIFOLevelSet(uart_ports[channel], UART_FIFO_TX4_8, UART_FIFO_RX1_8);
	UARTIntEnable(uart_ports[channel], UART_INT_RT|UART_INT_RX|UART_INT_OE);
	}
	
//! // Close the Doxygen group.
//! @}

