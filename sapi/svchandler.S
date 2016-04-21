@ SVC Call trampoline.
@ All system calls have to take args from the 
@ Stack, so this code figures out which stack,
@ and passes it along to the routine as r0
@ We're now in supervisor mode, so r0-r4 are 
@ free for us to use as we see fit.

#include "sapiopts.h"

.text
.syntax unified

__SAPI_00_ABIVersion:
	mov r1, #0x400
	str r1, [r0, #0]
	bx lr  

@ Hang out and wait for debugger help.
__SAPI_RFU:
	b __SAPI_RFU

.thumb_func     @  Make sure the linker puts it in the table.
.global SVC_Handler
SVC_Handler:

	@ bkpt #0

	tst	lr,#0x4		@ Figure out which stack
	ite	eq
	mrseq	r0,msp		@ Main stack
	mrsne	r0,psp		@ Process/Thread Stack

	ldr	r1,[r0,#24]	@ Get the stacked PC
	ldrb	r1,[r1,#-2]	@ Extract the svc call number

	@ Range Checking goes here.
	@ That is, assuming that you don't trust yourself...
	
	ldr  r2,=syscall_table 
	ldr  r2, [r2, r1, LSL #2]

	mov pc,r2
	
	@ No more code...  We've already jumped.

	.align 1

// ------------------------------------------------------------
// The first 16 are whats required for bootstrapping forth.
// TYPE and CR are 
// ------------------------------------------------------------

syscall_table:
	@ Required
	.word	__SAPI_00_ABIVersion		@ SVC 0
	  
	@ This is the main syscall for runtime linking - symbolic lists, 
	@ jump tables, etc.
	.word	__SAPI_01_GetRuntimeData	@ SVC 1  - 
	.extern __SAPI_01_GetRuntimeData	- 

	@ Putchar should return -1 for failure.
	@ The user must be prepared to retry.
	.word	__SAPI_02_PutChar		@ SVC 2/emit
	.extern __SAPI_02_PutChar

	.word	__SAPI_03_GetChar		@ SVC 3/key
	.extern	__SAPI_03_GetChar

	.word	__SAPI_04_GetCharAvail	@ SVC 4/key?	
	.extern	__SAPI_04_GetCharAvail

	@ Optional - These can improve performance.
	@ Designed for retry - Returns the number of chars emitted.
	.word	__SAPI_05_PutString     @ SVC 5/type	 
	.extern	__SAPI_05_PutString     @ SVC 5

	@ Returns -1 for failure.
	.word	__SAPI_06_EOL			@ SVC 6/cr	 
	.extern	__SAPI_06_EOL

	.word	__SAPI_RFU @ 7
	.word	__SAPI_RFU @ 8
	.word	__SAPI_RFU @ 9
	.word	__SAPI_RFU @ 10
	.word	__SAPI_RFU @ 11
	.word	__SAPI_RFU @ 12
	.word	__SAPI_RFU @ 13

	@ These two are optional but likely to be useful.
	.word	__SAPI_14_PetWatchdog	 
	.extern	__SAPI_14_PetWatchdog	

	.word   __SAPI_15_GetTimeMS     @ SVC 15/ticks
	.extern __SAPI_15_GetTimeMS

@ --------------------------------------------------
@ End of reserved vectors.
@ --------------------------------------------------

@ When running on a system that uses supervisor/thread
@ Separation, there are a few things that need to be system 
@ Calls

@ Implies user+supervisor mode
#if (SAPI_MPU)
	@ Request upgrade to supervisor mode.
	.word	__SAPI_16_GetPrivs		 
	.extern	__SAPI_16_GetPrivs		 

	@ A hook so the scheduler can install selected MPU slots.
	.word	__SAPI_17_MPULoad		  
	.extern	__SAPI_17_MPULoad		 

	@ This one may require privileges
	.word	__SAPI_18_HWReset 
	.extern __SAPI_18_HWReset 

	@ Depending on the security model, 
	@ This may be better off as a system call
	@ rather than direct manipulation of registers.
	.word	__SAPI_19_LaunchUserApp 
	.extern __SAPI_19_LaunchUserApp 
	
#else
	.word	__SAPI_RFU @ 16
	.word	__SAPI_RFU @ 17
	.word	__SAPI_RFU @ 18
	.word	__SAPI_RFU @ 19
#endif


#if (SAPI_LWIP) 

	.word __SAPI_20_GetIP
	.extern __SAPI_20_GetIP

	.word __SAPI_21_PBuf_Ram_Alloc
	.extern __SAPI_21_PBuf_Ram_Alloc

	.word __SAPI_22_PBuf_Free
	.extern __SAPI_22_PBuf_Free

	.word __SAPI_23_DNS_GetHostByName
	.extern __SAPI_23_DNS_GetHostByName

	.word __SAPI_24_UDP_GetPCB
	.extern __SAPI_24_UDP_GetPCB

	.word __SAPI_25_UDP_Connect
	.extern __SAPI_25_UDP_Connect

	.word __SAPI_26_UDP_Recv
	.extern __SAPI_26_UDP_Recv

	.word __SAPI_27_UDP_Send
	.extern __SAPI_27_UDP_Send
	
	
#endif

syscall_table_end:

.end

