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
//
// Copyright(C) 2011-2016 Robert Sexton
//
#include <stdint.h>

uint32_t app_start_address = 0;

/// This is the last thing that happens.   Call a hooked user function,
/// and afterwards, check to see if  userapp_address is non-zero.
/// if its non-zero, do the required stack manipulation to launch forth.
void PendSVHandler() {

#ifdef UserPendSVHook 
	UserPendSVHook();
#endif	

  // Look for the hook from the SVC that indicates we need to load up the 
  // user app and refresh its stack.
  if ( app_start_address ) {

    // This is a potential gotcha here.  If we're called via the MSP,
    // we need to unwind.   If called from PSP, thats not needed.

    __asm(
	  "TST 	LR,#0x04        @ Check to see which stack\n"
	  "it     eq             \n"
	  "addeq   sp, #32       @ Reset the supervisor stack frame\n"

    	"ORR   lr, lr, #4    @ Return into thread mode from PSP\n"
	        	
	  	"ldr   r0, [ %[base], #0 ]\n"
        "ldr   r1, [r0, #0 ]      @ New SP\n"
        "sub   r1, #32       @ Point it at the bottom of a fake stack frame\n"
        "msr   psp, r1       @ Load it into the process sp\n"

        "ldr   r0, [r0, #4]  @ New PC\n"
        "str   r0, [r1, #24] @ Into the new stack frame\n"
	  
	  	"mov   r0, 0x01000000 @ XPSR Thumb mode\n"
        "str   r0, [r1, #28] @ Into the stack\n"

          : : [base] "r" (&app_start_address) : "r0", "r1" );

    app_start_address = 0;
  }
}


