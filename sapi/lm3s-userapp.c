///
/// @file lm3s-userapp.c
/// @brief Launch Code and PendSV handler for starting up forth, plus system reset.
/// Code to setup PendSV varies by platform/library.
// Copyright (c) 2011-2016, Robert Sexton.  All rights reserved.
// Covered by the terms of the supplied Licence.txt file

#include <stdint.h>
#include <stdbool.h>

#include "inc/hw_types.h"
#include "inc/hw_nvic.h"
#include "inc/hw_memmap.h"

#include "sapi.h"

void launchuserapp(uint32_t *frame) {
	// This is a write-1-to set register, so an OR is not required.
	HWREG(NVIC_INT_CTRL) = NVIC_INT_CTRL_PEND_SV;
	app_restart_requested = frame[0];
	}

// This is a NVIC operation, but it's described 
// differently in different compilation environments
void __SAPI_08_NVICReset(uint32_t *frame) {
	// HWREG(0xe000ed0c) = 0x05fa0004;
	HWREG(NVIC_APINT) = 0x05fa0004;
	return;
	}



