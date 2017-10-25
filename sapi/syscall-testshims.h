/// @file syscall-testshim.h
/// @brief Function Prototypes for SAPI Calls via the SVC  layer
/// 
// Copyright (C) 2017, Robert Sexton.  All rights reserved.
// Covered by the terms of the supplied Licence.txt file

// Applies to SAPI ABI 2.05
// 

// ------------------------------------
// Standard IO Calls.
// ------------------------------------
bool PutChar(int stream, uint8_t c, unsigned long *tcb);
int GetChar(int stream,unsigned long *tcb);
int GetCharAvail(int stream);

