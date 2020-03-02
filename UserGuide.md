# SOCKPuppet User Guide

The SAPI interface is a minimal system call layer to support the needs of Forth or any application which benefits from an application / supervisor division. The core of Sockpuppet is the Cortex-M System Call (SVC) instruction.

The SAPI layer does NOT provide task-management.  Task/thread management is provided by the client application.

##  Terminology
- _Supervisor_ runs at power-on reset and uses the master stack pointer.   It initializes all hardware and then loads the program stack pointer from the client image and launches the client.   

- _Client_ This is a simplified Cortex-M binary.   It only requires the first two Cortex-M vectors -The initial stack pointer and the initial program counter.

The sample code includes a SVC Exception handler that interfaces to the system calls which in this case are written in C.

System Call Parameters/Return codes are documented in svchandler.S

## Launching the Client Application 

There are several levels of user/supervisor separation.

1. None.   The User and the supervisor share a common stack and memory space.
2. Two-Stack.  The user code and the supervisor code have separate stacks.   
3. Two stack with user mode thread.   This mode is required to make best use the MPU.   Not all Cortex-Ms support uprivileged thread mode. 

The SOCKPuppet code includes a PendSV handler for making the switch via the interrupt mechanism.    It construct a stack frame that unrolls from exception mode and starts the client.

There are several ways to do this.   The PendSV approach support application restart after application faults.   For simpler solutions, see [bl_launcher.s](https://github.com/rbsexton/cm3lib/blob/master/bl_launcher.s) 

## Power Reduction.

The most basic thing is to issue a WFI.  Levels of complexity:

0. No Multitasker - have KEY issue a WFI if no input before trying again.

1. Multitasker without integrated WFI
 Create a task that does wfi, pause forever and add it to the task list.
 see cm3forthtools/idlewfi for an example.

2. Multitasker with integrated WFI
 Idle task must STOP themselves.  The multitasker will issue the WFI when there are no runnable tasks.   This is the best performing solution, but the most complex to implement.

## Blocking IO.

If the scheduler supports it, blocking IO is very efficient.  The 
system call takes a task control block pointer as an argument.  If the call needs to block, the system call then puts the task to sleep by clearing bit 0 of the task's status byte, and saves the pointer to use when a wake event happens.  When the wake event happens, the supervisor sets bit zero of the status word to 1.

While the task could put itself to sleep, that creates a hazard - 
the task could put itself to sleep immediately after a wake-triggering exception.

This is predicated upon the use of a thread scheduler with integrated WFI.  A sample is available.

The blocking calls can be used in partially-implemented systems -
Define SAPIWakeSupport? in for the system call words to pass UP to the system calls. Leave it undefined to pass in 0, disabling wake events.

The supervisor calls can also ignore the supplied TCB, in which case the system call words will just spin through PAUSE or WFI until something unblocks.

## Implementation Levels.  

As the implementation complexity level goes up, more power-saving techniques are possible.  To reduce power, use the WFI instruction whenever possible to power down the CPU until something interesting happens.

_Important!!!!_  System calls should not block or spin.  The SAPI is designed to support the needs of a client application that provides its own mechanism for blocking.

- Level 0 - Putchar/EMIT,  CharsAvailable/KEY?, Getchar/KEY.
Thin wrappers around device access with output buffer feedback.   Calling functions can yield when the output fifo is full 

These are all it takes to get up and going.  Forth polls via the system calls.   This level of complexity provides clean separation between device management user code and simplifies code reuse across projects.

- Level 1 - Level 0, with interrupts for WFI support.   Pending stream I/O must wake the CPU.    

- Level 2 - Putchar/EMIT,  CharsAvailable/KEY?, Getchar/KEY.
IO Devices that generate interrupts and return a status code to indicate that the calling task should yield/pause.  

- Level 3 - Putchar/EMIT,  CharsAvailable/KEY?, Getchar/KEY, CR, TYPE IO Devices that generate interrupts and return a status code to indicate that the calling task should yield/pause.  CR and TYPE make sense on alternate  output devices.

## Dynamic Linking/Jump Tables.

The supplied code includes a basic mechanism for exporting C (or other language) memory addresses or parameters to forth.  It defines a simple data structure
that dylink.fth parses to create CONSTANTS at runtime or update the contents of VALUES.

The GetRuntimeData syscall returns this value when called with an argument of zero.

## Appendix A: Standard API Version 3.0

```
// System Call Number 2
// Data Output.   Blocking  
int PutChar (
   // Character to transmit, or
   // -1 : Flush the output 
   int character, 
  
  int stream, 
  // Stream descriptor for the specific channel.
  // which UART, network connection, etc.
  
  ) 
returns the number of bytes available in the output buffer.
```

```
// System Call Number 3
// Retrieve new data.   Blocking, which may not be what you want.   
int GetChar(
  int stream) 
  // Stream descriptor for the specific channel.
  // which UART, network connection, etc.
  
  returns the next byte of data.  
```

```
// System Call Number 4
// Check for new data 
int CharsAvailable(
  int stream, 
  // Stream descriptor for the specific channel.
  // which UART, network connection, etc.

  void *tcb,
  // Task control block of the caller, or zero    
  // If non-zero and there are no characters available, 
  // the system call will mark the task unrunnable.
  // The specifics of how to do this are implementation defined
  )
```

```
// System Call Number 7
// Data Output 
PutCharNonBlocking (
   // Character to transmit, or
   // -1 : Flush the output 
   int character, 
  
  int stream, 
  // Stream descriptor for the specific channel.
  // which UART, network connection, etc.
  
  void *tcb,
  // Task control block of the caller, or zero    
  // If there is no more room after the operation,
  // the system call will mark the task unrunnable.
  // The specifics of how to do this are implementation defined
  ) 
returns the number of bytes available in the output buffer, or 
-1 for write failure 
```

