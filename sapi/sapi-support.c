/// @file sapi-support.c
///
/// Glue functions that are handy in the SAPI environment
///
/// Sometimes it's necessary for the C support layer to issue a 
/// callback.  This little function exists to allow that to happen
/// It will write a 1 to an arbitrary address.  If you combine that 
/// with bitbanding, you get a way to set an arbitrary bit in response
/// to a callback.

#include "sapi-support.h"

void ring(int *p) {
	*p = 1;
	}


