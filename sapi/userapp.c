//! \addtogroup SAPI
//! @{
///
/// Userspace - Check for and launch a user mode executable.
///

#include "userapp.h"

/// @brief See it there is a valid executable ready to go
///
/// Return a 1 if it looks like there is a valid user app in place
///
/// Do this by checking for a sane stack pointer and a program counter
/// that points to the right place in memory and has the thumb bit set
int user_app_present(unsigned long addr) {

	unsigned long *pulApp;

    pulApp = (unsigned long *)addr;
    if (((pulApp[0] & 0xfff00000) != 0x20000000) ||
        ((pulApp[1] & 0xfff00001) != 0x00000001))         
        return(0);
	else return(1);
	}

///
/// @brief Assembly Wrapper that loads up SP and PC and jumps to the app.
/// Callable from thread mode.  Restarting the app from exception mode requires the 
/// next function
void user_app_launch(unsigned long addr) {

     // Allow the client to own the whole thing.
     __asm(    "@ Base Address of next Image is in r0\n"
	     "ldr r1, [r0]   @ This should be the stack pointer\n"
	     "msr psp, r1    @ Load it into the process sp\n"
	     "ldr r1,[r0, #4] @ Load up the program counter\n"
	     "mov pc,r1 @ branch to official code\n"
	     );

} 

///
/// @brief Assembly wrapper to start the app by exiting from exception mode.
/// The basic trick here is to create a custom stack frame and cleanup the master stack.
///
/// This doesn't actually work as a function, but if you use this code in a bare 
/// PendSV handler, after de-pending the PendSV, it will.
/// The crucial part is falling off the end with a bx lr
/// The stack type check is so it'll work when called repeatedly.
///
/// Ideally, this would first call some high-level code that would do it's thing
/// and leave the stack in a clean state.

void user_app_exception_launch(unsigned long addr) {
    __asm(
	  "TST 	LR,#0x04        @ Check to see which stack\n"
	  "it     eq             \n"
	  "addeq   sp, #32       @ Reset the supervisor stack frame\n"

          "ORR   lr, lr, #4    @ Return into thread mode from PSP\n"
	        	
	  "ldr   r0, =0x08008000        \n"
          "ldr   r1, [r0]      @ New SP\n"
          "sub   r1, #32       @ Point it at the bottom of a fake stack frame\n"
          "msr   psp, r1       @ Load it into the process sp\n"

          "ldr   r3, [r0, #4]  @ New PC\n"
          "str   r3, [r1, #24] @ Into the new stack frame\n"
	  
	  "ldr   r2, = 0x01000000 @ XPSR Thumb mode\n"
          "str   r2, [r1, #28] @ Into the stack\n"
	  );
}

// Close the Doxygen group
//!
//! @}

