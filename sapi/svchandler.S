@ SVC Call trampoline.
@ All system calls have to take args from the 
@ Stack, so this code figures out which stack,
@ and passes it along to the routine as r0
@ We're now in supervisor mode, so r0-r4 are 
@ free for us to use as we see fit.

#include "sapiopts.h"

.text
.syntax unified
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

	.extern __SAPI_00_Version
	.extern __SAPI_01_GetLinkList
	.extern __SAPI_02_PutChar
	.extern __SAPI_03_GetChar
	.extern __SAPI_04_CharsAvail
	.extern __SAPI_08_WatchdogKick
	.extern __SAPI_GetTimeMS
	.extern __SAPI_GetUsage

	.word	__SAPI_00_Version		@ SVC 0
	.word	__SAPI_01_GetLinkList	@ SVC 1
	.word	__SAPI_02_PutChar		@ SVC 2
	.word	__SAPI_03_GetChar		@ SVC 3
	.word	__SAPI_04_CharsAvail	@ SVC 4
	.word	__SAPI_05_LauchUserApp  @ SVC 5
	.word	__SAPI_Disabled			@ SVC 6 
	.word	__SAPI_Disabled			@ SVC 7 
	.word	__SAPI_WatchdogKick		@ SVC 8 Watchdog Kick
	.word	__SAPI_Disabled			@ SVC 8 
	.word   __SAPI_GetTimeMS        @ SVC 9
	.word   __SAPI_GetUsage         @ SVC 10

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

