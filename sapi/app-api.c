///
/// @file sapi.c
/// @brief Sockpuppet api library for testing with C
 
// Copyright (c) 2011-2016, Robert Sexton.  All rights reserved.
// Covered by the terms of the supplied Licence.txt file

#include "sapi.h"

/* Return a version number */
/* 0xAABB Major Minor */ 
//static inline int SAPI_Version()  is inlined from sapi.h
/* Put a character to the UART */
int  SAPI_Version() 				{ __asm("svc #0"); }
void SAPI_StreamPutChar(int desc, int payload) 	{ __asm("svc #2"); }
int  SAPI_StreamGetChar(int desc)               { __asm("svc #3"); }
int  SAPI_StreamCharsAvail(int desc)            { __asm("svc #4"); }
int  SAPI_GetUsage()				{ __asm("svc #9"); }
int  SAPI_GetTimeMS()				{ __asm("svc #10"); }

