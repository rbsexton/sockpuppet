/// @file syscalls.h
/// @brief Private functions wrapped by the syscall dispatcher.
///
/// SAPI Implementations must comply with this API
///
// Copyright (C) 2016-2017, Robert Sexton.  All rights reserved.
// Covered by the terms of the supplied Licence.txt file

// Applies to SAPI ABI 2.05
// 

#define __SAPI_SYSCALLS_H__

void SVC_Handler();

uint32_t __SAPI_00_ABIVersion();
void* __SAPI_01_GetRuntimeData(int which);

// ------------------------------------
// Standard IO Calls.
// ------------------------------------
bool __SAPI_02_PutChar(int stream, uint8_t c, unsigned long *tcb);
int __SAPI_03_GetChar(int stream,unsigned long *tcb);
int __SAPI_04_GetCharAvail(int stream);

// ------------------------------------
// Emulatable IO Calls
// ------------------------------------
bool __SAPI_05_PutString(int stream, int count, uint8_t *p,  unsigned long *tcb);
bool __SAPI_06_EOL(int stream, unsigned long *tcb);

// ------------------------------------
// Wake Request / Callback Requests
// Don't even bother defining the request types.
// the can be very platform specific.
// ------------------------------------
bool __SAPI_12_WakeRequest( int request_type, int arg, unsigned long *tcb);

// ------------------------------------
// Diagnostics.  Return value is implementation defined.
// ------------------------------------
unsigned __SAPI_13_CPUUsage();

// ------------------------------------
// Argument value is implementation defined.
// ------------------------------------
void __SAPI_14_PetWatchdog(unsigned howmuch);

// ------------------------------------
// Timekeeping.
// There are different aspects to time.   Different
// timescales, and different ways of finding out.
// ------------------------------------
typedef enum {
	ms_value = 0,         // The raw value.
	ms_value_address = 1, // The location of the value in memory.
	ms_64bit_value = -1,  // A 64-bit value.
	} tTimeType;

unsigned __SAPI_15_GetTime(tTimeType whatform);
