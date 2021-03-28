@ SVC Call trampoline.
@ All system calls have to take args from the 
@ Stack, so this code figures out which stack,
@ and passes it along to the routine as r0
@ We're now in supervisor mode, so r0-r4 are 
@ free for us to use as we see fit.
@
@ This is the core definition of whats basically a binary ABI
@ So this is as good a place as any to define it.
@ The tricky part is that the particulars of the ABI parameters are 
@ basically implementation defined.  More below.
@ This ABI was initially designed to support forth's character IO primitives:
@ getchar(), charsavail(), & putchar()
@ later it was extended to support string puts, and end-of-line. 
@ 
@ These cannot be direct substitutes for the forth words in question
@ because system calls are not allowed to block - the client
@ application must provide that functionality.
@
@ Copyright (C) 2016-2017, Robert Sexton.  All rights reserved.
@ Covered by the terms of the supplied Licence.txt file


@ Version History
@ 2.06.00 - Move the jump table to SRAM - it's faster and can be modified.
@ 2.05.00 - Officially define wake request
@ 2.04.00 - Change return codes for putchar, type and eol for use with multitasking.
@ 2.03.00 - Support 64-bit return values.
@ 2.02.01 - Change return code of EOL.
@ 2.02.00 - Add WakeRequest
@ 2.01.00 - Add CPUUsage and clarify behavior of unsupported calls.
@ 2.00.00 - Initial Release.
#include "sapiopts.h"

.text
.syntax unified
.cpu cortex-m0

.thumb_func     @  Make sure the linker puts it in the table.
.global SVC_Handler

@ Incorporate register marshalling.   Thats a little wasteful
@ since all system calls don't need it, but it makes the code 
@ cleaner at the system call and it saves a little code at the 
@ function level.
@
@ It might appear on first inspection that you don't have to pull
@ the registers from the stack.   Thats true in most conditions.
@ Its very not true in one case:  Tail-chaining by the NVIC.  If the 
@ SVC handler tail-chains after another exception running at the same 
@ pre-emption priority level, R0-R3 & R12 will no longer be valid.
@ the only safe place to get the pushed registers under all circumstances
@ is the stack.   
SVC_Handler:

  @ bkpt #0

  movs r0, #4
  mov  r1, lr 
  tst  r0, r1
  beq  use_msp 
  mrs  r0, psp
b done 
  use_msp: 
  mrs  r0, msp 
done: 

  @ Now that we have a copy of the original 
  @ stack pointer we can put more things on the stack.
  @ Put R4 onto the stack so that we can use it as a scratch variable.
  push { r4, lr }
  
  mov  r4, r0

  ldr  r1, [r0,#24] @ Get the stacked PC
  subs r1, #2       @ Address of svc call instruction. 
  ldrb r1, [r1, #0] @ Extract the svc call number
  lsls r1, r1, #2   @ Make this back into a table offset.


  @ Range Checking goes here.
  @ That is, assuming that you don't trust yourself...

  ldr  r2,  =syscall_table 
  add  r2,  r2, r1    @ Table lookup
  ldr  r2,  [r2, #0]  @ Get the address of the function
  mov  r12, r2        @ We'll be loading up R0-R3 in a moment.			

  ldr r0, [ r4,  #0 ] @ Unroll LDM.
  ldr r1, [ r4,  #4 ]
  ldr r2, [ r4,  #8 ]
  ldr r3, [ r4, #12 ]
  blx r12

  @ Support 64-bit return values.
  str r0, [ r4, #0 ]
  str r1, [ r4, #4 ] 

  pop { r4, pc }

.end

