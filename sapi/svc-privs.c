/// \file svc-privs.c
/// \brief System calls related to MPU and User/Handler security
///
/// Note that the official list/ordinality of syscalls is defined by svc.S
//
// Copyright(C) 2011-2014 Robert Sexton
//
// Change History.

#include <stdint.h>
#include "sapi.h"

// __SAPI_11_MPULoad
// Allow a user thread to load MPU slots 2-5.
// See http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.dai0321a/BIHGJIBI.html
// No ISB required if this is followed by an exception return.
void __SAPI_11_MPULoad(uint32_t *frame) {
  __asm(
          "PUSH { R5, LR }\n"

          "LDR R0, [ R0, #0 ]\n"
          "LDR R1,=0xE000ED9C @ Region Base Address register\n"
 
          "LDR LR, [R1, #-8] @ Fetch the control register\n"
          "BIC R2, LR, #0x0  @ Stash unchanged version for later.\n"
          "DMB\n"
		  "STR R2, [ R1, #-8]\n"

          "LDMIA  R0!, {R2, R3, R4, R5}  @ Read 4 words from table\n"
          "STMIA  R1!, {R2, R3, R4, R5}  @; write 4 words to MPU\n"
          "LDMIA  R0!, {R2, R3, R4, R5}  @ Read 4 words from table\n"
          "STMIA  R1!, {R2, R3, R4, R5}  @; write 4 words to MPU\n"

		  "STR LR, [ R1, #-40] @ Enable/Put back the old value\n"
		  "DSB\n"

          "POP { R5, PC }\n"
        );
	}

// __SAPI_12_PrivMode - Get supervisor privileges.
// According the the ARM docs ( DAI0321A ) you need a ISB after this,
// but you get one for free when the exception return happens.
void __SAPI_12_GetPrivs(long *frame) { 
  __asm(
          "mrs	r0, CONTROL\n"
          "bic.w	r0, r0, #1\n"
          "msr	CONTROL, r0\n"
        );
    } 
