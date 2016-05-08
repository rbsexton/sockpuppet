/// \file svc-stubs.c
/// \brief As of yet undefined system calls.
///
/// Note that the official list/ordinality of syscalls is defined by svc.S
//
// Copyright (C) 2011-2014, Robert Sexton.  All rights reserved.
// Covered by the terms of the supplied Licence.txt file
//
// Change History.

#include <stdint.h>
#include "sapi.h"

// Stubs.


void __SAPI_13_GetUsageCPU(uint32_t *frame) { frame[0] = 0; }
void __SAPI_14_PetWatchdog(uint32_t *frame) { frame[0] = 0; }  