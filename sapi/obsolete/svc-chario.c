/// \file syscalls-chario.c
/// \brief Sockpuppet API System Call functions for character IO
/// \defgroup SAPI Sockpuppet 
/// 
//
// Copyright (C) 2011-2014, Robert Sexton.  All rights reserved.
// Covered by the terms of the supplied Licence.txt file
//
// Change History.
// API Version 0203.  Add a return code to StreamPutChar for back-pressure.
// Re-organize the code to make it less machine specific.
// More advanced implementations will need to support both
// UARTs and USB and/or networked comms, so this is an intermediate layer
#include <stdint.h>
#include "sapi.h"

extern void putchar_uart(uint32_t *);
extern void getchar_uart(uint32_t *);
extern void chars_available_uart(uint32_t *);

/// __SAPI_02_PutChar 
// The basic putchar, with backpressure.   The called function
// should return 0 if there is room for more, or -1 if the app should
// throttle the output.
void __SAPI_02_PutChar(uint32_t *frame) {
	if (frame[0] < 10 ) {
		putchar_uart(frame);
		}
	// Network ports go here.
	return;
	}	 

/// __SAPI_03_GetChar 
/// Pull a character out of the stream of choice
/// This gets called when CharsAvail says there is work to do.
void __SAPI_03_GetChar(uint32_t *frame) {
	if (frame[0] < 10 ) {
		getchar_uart(frame);
		}
	// Network ports go here.
	return;
	}
	
/// __SAPI_04_CharsAvail
/// Check to see if there is a char available
void __SAPI_04_GetCharAvail(uint32_t *frame) {
	if (frame[0] < 10 ) {
		chars_available_uart(frame);
		}
	// Network ports go here.
	return;
	}	

/// __SAPI_05_PutCharHasRoom
/// Check to see if there is room for more in a given descriptor
/// This is currently a place holder.   Lie  
void __SAPI_05_PutCharHasRoom(uint32_t *frame) {
	frame[0] = 1;
	return;
	}	
	
/// __SAPI_06_SetIOCallback
/// The drivers can implement an optional callback via a write of 1 to a 
/// supplied address.
void __SAPI_06_SetIOCallback(uint32_t *frame) { return; }
	
	


