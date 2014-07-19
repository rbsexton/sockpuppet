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
	mov r1, #0x300
	str r1, [r0, #0]
	bx lr  

.thumb_func     @  Make sure the linker puts it in the table.
.global SVCHandler
SVCHandler:

	@ bkpt #0

	tst	lr,#0x4		@ Figure out which stack
	ite	eq
	mrseq	r0,msp		@ Main stack
	mrsne	r0,psp		@ Process/Thread Stack

	ldr	r1,[r0,#24]	@ Get the stacked PC
	ldrb	r1,[r1,#-2]	@ Extract the svc call number

	@ Range Checking goes here.

	ldr  r2,=syscall_table 
	ldr  r2, [r2, r1, LSL #2]

	mov pc,r2
	
	@ No more code...  We've already jumped.

	.align 1

// ------------------------------------------------------------
// Required vectors 
// ------------------------------------------------------------

syscall_table:
	.extern __SAPI_RFU
	.extern __SAPI_Disabled

	.extern __SAPI_01_GetLinkList	@ SVC 1  - 
	.extern __SAPI_02_PutChar		@ SVC 2  - Required
	.extern	__SAPI_03_GetChar		@ SVC 3  - Required
	.extern	__SAPI_04_GetCharAvail	@ SVC 4  - Required
	.extern	__SAPI_05_PutCharHasRoom	 
	.extern	__SAPI_06_SetIOCallback	@ 
	.extern __SAPI_07_GetTimeMS     @ 

	.extern	__SAPI_10_LauchUserApp  
	.extern	__SAPI_11_MPULoad		 
	.extern	__SAPI_12_GetPrivs		 
	.extern __SAPI_13_GetUsageCPU   
	.extern	__SAPI_14_PetWatchdog	

	.word	__SAPI_00_ABIVersion	 @ SVC 0  -
	.word	__SAPI_01_GetLinkList	 @ SVC 1  - 
	.word	__SAPI_02_PutChar		 @ SVC 2  - Required
	.word	__SAPI_03_GetChar		 @ SVC 3  - Required
	.word	__SAPI_04_GetCharAvail	 @ SVC 4  - Required
	.word	__SAPI_05_PutCharHasRoom @ SVC 5
	.word	__SAPI_06_SetIOCallback	 @ 
	.word   __SAPI_07_GetTimeMS      @ SVC 07
	.word	__SAPI_Disabled			@ SVC 08
	.word	__SAPI_Disabled			@ SVC 09

	.word	__SAPI_10_LauchUserApp   
	.word	__SAPI_11_MPULoad		  
	.word	__SAPI_12_GetPrivs		 
	.word   __SAPI_13_GetUsageCPU    
	.word	__SAPI_14_PetWatchdog	 

#if (SAPI_LWIP) 
	.extern __SAPI_DNSLookup
	
	.extern __SAPI_lwIP_udp_new	
	.extern __SAPI_lwIP_udp_remove	
	
	.word   __SAPI_DNSLookup        @ SVC 11
	.word	__SAPI_Disabled			@ SVC 12
	.word	__SAPI_Disabled			@ SVC 13
	.word	__SAPI_lwIP_udp_new		@ SVC 14
	.word	__SAPI_lwIP_udp_remove  @ SVC 15
	.word	__SAPI_Disabled			@ SVC 16
	.word	__SAPI_Disabled			@ SVC 17
	.word	__SAPI_Disabled			@ SVC 18
	.word	__SAPI_Disabled			@ SVC 19
	.word	__SAPI_Disabled			@ SVC 20
#else
	.word	__SAPI_Disabled			@ SVC  11
	.word	__SAPI_Disabled			@ SVC  12
	.word	__SAPI_Disabled			@ SVC  13
	.word	__SAPI_Disabled			@ SVC  14
	.word	__SAPI_Disabled			@ SVC  15
	.word	__SAPI_Disabled			@ SVC  16
	.word	__SAPI_Disabled			@ SVC  17
	.word	__SAPI_Disabled			@ SVC  18
	.word	__SAPI_Disabled			@ SVC  19
	.word	__SAPI_Disabled			@ SVC  20
#endif

syscall_table_end:

.end

