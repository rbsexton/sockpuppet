/// \file svc-userapp.c
/// \brief Sockpuppet API System Call functions
/// \defgroup SAPI Sockpuppet 
//! \addtogroup SAPI
//! @{
/// 
/// Launching a user-space app by the book requires that we 
/// trigger PendSV and alter the stack.
///
/// This one is pretty simple.   Just put an address into 
/// app_start_address and trigger PendSV.    This could 
/// be wrapped into a system call if the app needs to self-restart
///
/// This approach is necessary to support re-starting forth on the 
/// fly.   For one-time startup, there is simpler code in cm3lib
/// 
// Copyright(C) 2011-2016 Robert Sexton
// Covered by the terms of the supplied Licence.txt file

//
#include <stdint.h>

#include "efm32lg990f256.h"

#include "core_cm3.h"

volatile uint32_t app_start_address = 0;

void LaunchApp(uint32_t address) {
	app_start_address = address;
	
	SCB->ICSR = SCB_ICSR_PENDSVSET_Msk;
	
	// If your read the CMSIS Docs, you might be foolish enough to think
	// that this works:  NVIC_SetPendingIRQ(PendSV_IRQn);
	// It doesn't.  Shame on Arm for not documenting this.		
	}

/// This is the last thing that happens.   Call a hooked user function,
/// and afterwards, check to see if  userapp_address is non-zero.
/// if its non-zero, do the required stack manipulation to launch forth.
/// Don't forget that this must be the lowest priority handler in the system.
/// It cannot share a pre-emption priority level with anthing else.
void PendSV_Handler() {

#ifdef UserPendSVHook 
	UserPendSVHook();
#endif	

  // Look for the hook from the SVC that indicates we need to load up the 
  // user app and refresh its stack.
  if ( app_start_address ) {

    // This is a potential gotcha here.  If we're called via the MSP,
    // we need to unwind the now-unneeded stack frame.
    // If called from something that was using the PSP, thats not needed.

    __asm(
	  "TST 	LR,#0x04       @ Check to see which stack\n"
	  "it     eq          \n"
	  "addeq   sp, #32     @ Discard the supervisor stack frame\n"

	  "orr   lr, lr, #4    @ Force Return into thread mode from PSP\n"
	        	
	  "ldr   r0, [ %[base], #0 ] @ Fetch the address of the client app.\n"
      "ldr   r1, [r0, #0 ]       @ Retrieve the client PSP\n"
      "sub   r1, #32             @ Point it at the bottom of a fake stack frame\n"
      "msr   psp, r1             @ Load it into the process sp\n"

      "ldr   r0, [r0, #4]  @ New PC\n"
      "str   r0, [r1, #24] @ Save it into the soon-to be unwound stack frame\n"
	  
	  "mov   r0, 0x01000000 @ Legal value for XPSR.\n"
      "str   r0, [r1, #28]  @ Into the stack\n"

          : : [base] "r" (&app_start_address) : "r0", "r1" );

    app_start_address = 0;
	// When we return from exception, the client app will run.
  }
}


