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
// Copyright(C) 2011-2014 Robert Sexton
//
//
// Change History.
// API Version 0203.  Add a return code to StreamPutChar for back-pressure.
// Re-organize the code to make it less machine specific.
#include <stdint.h>

// *******************************************************************
// MANDATORY CALLS
// *******************************************************************

/// @brief SVC 0: Return an API Version 
void __SAPI_00_Version(uint32_t *frame) {
	frame[0] = 0x0203;
	return;
	}

/// SVC 1: Return the address of the runtime link list
void __SAPI_01_GetLinkList(uint32_t *frame) {
        frame[0] = (uint32_t) dynamiclinks;
        }

// *******************************************************************
// Helper Functions
// *******************************************************************
/// While(1) loop for catching Reserved API Calls
void __SAPI_RFU(uint32_t *frame) {
	while(1) { ; }
	}

/// Catch Disabled API Calls, and return a nonsense value
/// This one was a hang loop, but its better to do something
/// harmless
/// @brief Return a bogus value for disabled calls.
void __SAPI_Disabled(uint32_t *frame) {
	frame[0] = 0xdead;
	frame[1] = 0xbeef;
	}
