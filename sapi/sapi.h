// sockpuppet.h
// Define the sockpuppet API.
// These are listed in numeric order.

extern int  SAPI_Version();	  // 0 Get API Version

extern void SAPI_StreamPutChar(int, int); // 1 Put a char to a descriptor
extern int  SAPI_StreamGetChar(int);	  // 2 get a char from a descriptor

extern int  SAPI_StreamCharsAvail(int);	  // 3 is data available?

extern void SAPI_StreamPuts(int, char*); // Put a char to a descriptor

extern int SAPI_GetTimeMS();
extern void SAPI_SetTimeMS(int);

