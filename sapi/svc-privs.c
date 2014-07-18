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

// __SAPI_07_MPULoad
// Allow a user thread to load MPU slots 2-5.
 
void __SAPI_07_MPULoad(uint32_t *frame) {
  __asm(
          "push { r5 }\n"
          "ldr r1, [ r0, #0 ]\n"
          "LDR R0,=0xE000ED9C @ Region Base Address register\n"
          "LDMIA  R1!, {R2, R3, R4, R5}  @ Read 4 words from table\n"
          "STMIA  R0!, {R2, R3, R4, R5}  @; write 4 words to MPU\n"
          "LDMIA  R1!, {R2, R3, R4, R5}  @ Read 4 words from table\n"
          "STMIA  R0!, {R2, R3, R4, R5}  @; write 4 words to MPU\n"
          "pop { r5 }\n"
        );
	}

