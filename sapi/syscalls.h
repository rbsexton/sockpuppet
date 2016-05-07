// Function Prototypes for SAPI Calls.
// This serves as a basic check for supplied supervisor functions.

// Applies to SAPI ABI 2.1

void SVC_Handler();

uint32_t __SAPI_00_ABIVersion();
long* __SAPI_01_GetRuntimeData(int which);
int __SAPI_02_PutChar(int stream, uint8_t c, unsigned long *tcb);
int __SAPI_03_GetChar(int stream,unsigned long *tcb);
int __SAPI_04_GetCharAvail(int stream);
int __SAPI_05_PutString(int stream, int count, uint8_t *p,  unsigned long *tcb);
int __SAPI_06_EOL(int stream, unsigned long *tcb);
unsigned __SAPI_13_CPUUsage();
void __SAPI_14_PetWatchdog(unsigned howmuch);
unsigned __SAPI_15_GetTimeMS(int whatform);
