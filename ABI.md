# Application Binary Interfaces 

## Implementation Levels.  

More complex implementations support more advanced power saving methods. 

_Important!!!!_  System calls should not block or spin.  The SAPI is designed to support the needs of a client application that provides its own mechanism for blocking.

- Level 0 - Putchar/EMIT,  CharsAvailable/KEY?, Getchar/KEY.
Thin wrappers around device access with output buffer feedback.   Calling functions can yield when the output fifo is full 

These are all it takes to get up and going.  Forth polls via the system calls.   This level of complexity provides clean separation between device management user code and simplifies code reuse across projects.

- Level 1 - Level 0 with interrupts for WFI support.   Pending stream I/O must wake the CPU.    

- Level 2 - Putchar/EMIT,  CharsAvailable/KEY?, Getchar/KEY.
IO Devices that generate interrupts and return a status code to indicate that the calling task should yield/pause.  

- Level 3 - Putchar/EMIT,  CharsAvailable/KEY?, Getchar/KEY, CR, TYPE IO Devices that generate interrupts and return a status code to indicate that the calling task should yield/pause.  CR and TYPE make sense on alternate  output devices.

## API Version 3.0

Version number indicate the version of the ABI in which the call
was introduced.

### SVC(0): GetABIVersion() - v1
```
unsigned GetABIVersion (
   ) 
returns the number ABI Version encoded 0xMMIIPP
Major, Minor, Patchlevel
```

### SVC(1): GetSharedData(int index) - v1
ABI Version 3 introduced indices
```
unsigned GetSharedData (
  int index
  // Specific Which data table to return.
  // Supported indices:
  // 0: Target-Specific Tables
  // 1: System Call Table 
   ) 
returns the address of the table in question, or 0
```

### SVC(2): Putchar() - v1 
```
// System Call Number 2
// Data Output.   Blocking  
int PutChar (
   // Character to transmit.  Special Characters:
   // -1 : Flush the output 
   // -2 : Close the connection, if applicable.
   int character, 
  
   int stream, 
   // Stream descriptor for the specific channel.
   // which UART, network connection, etc.
   ) 
returns the number of bytes available in the output buffer.
```

### SVC(3): GetChar(int stream) - v1 

```
// Retrieve new data.   Blocking. 
int GetChar(
  int stream );  
  // Stream descriptor for the specific channel.
  // which UART, network connection, etc.
  
  // Returns: the next byte of data.
```
### SVC(4): CharsAvailable(int stream,void *tcb) - v3

```
int CharsAvailable(
  int stream, 
  // Stream descriptor for the specific channel.
  // which UART, network connection, etc.

  void *tcb
  // Task control block of the caller, or zero    
  // If non-zero and there are no characters available, 
  // the system call will mark the task unrunnable.
  // The specifics of how to do this are implementation defined
  );
```

### SVC(7): PutCharNonBlocking(int c, int stream,void *tcb) - v3

```
int PutCharNonBlocking (
   // Character to transmit.  Optional Specials:
   // -1 : Flush the output 
   // -2 : Close the connection (if applicable) 
   int character, 
  
  int stream, 
  // Stream descriptor for the specific channel.
  // which UART, network connection, etc.
  
  void *tcb
  // Task control block of the caller, or zero    
  // If there is no more room after the operation,
  // the system call will mark the task unrunnable.
  // The specifics of how to do this are implementation defined
  ) 
returns the number of bytes available in the output buffer, or 
-1 for write failure 
```

### SVC(8): WakeRequest(void *tcb, int arg1, int arg2) - v3
```
int WakeRequest (
  void *tcb
  // Task control block of the caller, or zero.
  // The system call will mark the TCB stopped, 
  // and wake it at a later time.    

  int arg1, int arg2 

  // Arguments for the wake request.   The meaning 
  // of the arguments is implementation defined.
  ) 
returns 0 for success, negative values for failure.
```

### SVC(15): Ticks(int type)- v1

V3 Added the concept of different time scales.

```
int Ticks(
  // Type 0: milliseconds.
  );
```



