///
/// @file lm3s-userapp.c
/// @brief Launch Code and PendSV handler for starting up forth.
/// Code to setup PendSV varies by platform/library.

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


