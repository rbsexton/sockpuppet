# Advanced system design on Cortex-M devices with Forth 

The Cortex-M architecture has features that make it well suited to high-efficiency, low power applications.  CPU cycles spent polling consume power without 
producing usable work.  Cortex-M devices are good at entering low-power states
and waking up quickly to do useful work.
  
- The processor has a Wait For Interrupt (WFI) instruction that puts the CPU into a low-power sleep state with a low-latency wakeup.
- Interrupt handler register stacking and vectoring is automatic.

Most devices include very low power sleep states that take longer to enter and exit.   

The Cortex-M interrupt controller has other useful features that are beyond the scope of this document.   Most notably, the processor has a system call interrupt that 
can be used to create atomic operations or communicate safely with interrupt handlers.

## Applicability to other languages

The techniques described here apply equally well to other languages.  The requirements are a task loop and tasks with a wake/sleep control.   See Appendix A for an example.

## The Supervisor / Client model

An effective way to meet latency requirements is to divide interrupt processing
into a traditional top half / bottom half arrangement.   The top half (and 
interrupt handler) responds to events and schedules/wakes processing by the 
bottom half.  Interrupt handlers with a short activity period are less likely
to preempt or delay other handlers.

## Dealing with race conditions

### The Problem

The supervisor/user model with interrupts has two possible race conditions:

- Line 3: The user task loads the existing value of the run/stop bit into a register
- Line 3: Interrupt handler preempts the task. sets the run bit in the run/stop word
- Line 4: The task over-writes the mask.  Wake event is lost. 

````c
bool nowork = work_queue_empty(); // Line 1 
if ( nowork ) {                   // line 2
  newvalue = task.runstop & ~1;   // line 3
  task.runstop newvalue;          // line 4 
  yield(); 
}
````

This race condition can be mitigated by using a counting semaphore with atomic
operations by disabling interrupts, system calls, or software triggered interrupts.

````c
bool nowork = work_queue_empty(); // Line 1 
if ( nowork ) {                   // line 2
  atomic_add(&task.runstop,-1);   // line 3
  yield(); 
}
````

### Race Condition Mitigation

The best way to handle this problem depends on the application.  If the task 
does not require a 1:1 mapping between interrupts and wake events such that
lost wake events don't impact system performance, the system can wake the
task frequently, eg: _system tickers_.   Atomic operations are not required.   

#### Race Mitigation on Cortex-M0 

The M0 has no atomic operation instructions.   Interrupt handlers are atomic 
relative to other interrupts and system calls (SVC) at the same interrupt 
priority level.  Its possible to create atomic operators on Cortex-M0 
devices by disabling interrupts.

There are two ways enter exception/interrupt mode from user code:

- Software Triggered Interrupt via a write to the STIR register.   Most devices
 have more interrupt vectors than devices that require interrupt service.
  Software triggered interrupts do not allow arguments, but can be used with shared pointers
or data structures.   Software triggered interrupts that share data structures with 
peripheral interrupt handlers must run at the same interrupt priority to prevent 
race conditions.   A software triggered interrupt has at least 12 CPU cycles of overhead.
 
- System Calls. System calls on the Cortex-M behave the same way as ordinary 
functions.   This requires an assembly language handler to move function arguments
to and from the exception stack.  A system call will require a minimum 50 clock
cycles, depending on the device.  [Sample Handler:](https://github.com/rbsexton/sockpuppet/blob/master/sapi/svchandler-m0.s)

On systems that implement system calls, the best option is to put the interrupt handler in charge of the run/stop bit or run semaphore.  This works well with UARTs because the interrupt handler or system call is in the best position to determine whether or not the task should sleep.  This technique can be used to implement blocking I/O.  The System call manages the run/stop bit, and the user thread 
examines the return code from the system call to determine whether or not to 
yield to other tasks.  [Sample Code:](https://github.com/rbsexton/gecko/blob/master/common/console_leuart.c)

#### Race Mitigation on Cortex-M3

Cortex-M3s have several different mechanisms for atomic operations that
can be used to prevent race conditions.

- Software triggered interrupts (see Cortex-M0 section)
- Creating atomic operations by disabling interrupts.
- Atomic operations with exclusive load/store instructions (LDREX/STREX).



The Cortex-M3 atomic operators that can be used for interrupt-safe clearing 
of run/wake bits in producer/consumer applications.   The worker thread should be written to check for work regardless of the run/stop state.  If the attempt 
to clear the run bit fails, the thread will try again after finding no work. 

 
3.  Run/Stop control with an individual bit.  Cortex-M3 (v7m and later) LDREX/STREX instructions.   These atomic operators allow the CPU to atomically change bits.  Unlike traditional LDREX/STREX code, code should be _best effort_.   If the 
code takes an interrupt in the critical window, the store will fail, and the 
run/stop control bit will be in the state preferred by the interrupt handler.  This 
technique lessens, but does not completely eliminate the race condition.

Adding atomic operations or disabling interrupts is only sufficient if done 
correctly.  There is still a potential race condition if the system takes
an interrupt between line 1 and line 2 of the race condition example. 

## Appendix A: Sample code thats vulnerable to race conditons



## Appendix A: A simple C task loop for use in main()

```c
struct TaskControlBlock {
  struct TaskControlBlock *next; 
  int runcontrol; 
  void (*func)(void);
  }; 

main( ) {
  struct TaskControlBlock tcbs[]; // Initialization omitted.
  struct TaskControlBlock *p;  
  
  while(1) {
    p = tcbs;         // Reset to the first item
    int runcount = 0; // Do a WFI if we don't find anything runnable.
    do {
        if ( p->runcontrol ) {
          runcount++;
          p->func(); 
        }
        p = p->next; 
    } while ( p != tcbs ) ; // One iteration, max.
    
    if ( runcount == 0 )  WFI;   
  }  
}
````

## Appendix B: Best effort atomic operations on Cortex-M3

A worker thread that looks for work regardless of run/wake state 
can use LDREX/STREX for _best effort_ clearing of a run bit.  This
is a normal exclusive operator without a retry. 

````
# Address: R0, Mask: R1
# pass/fail returned in R0  
# Clear the mask bits from the contents of address.
trybicex: 
    ldrex r2, [ r0 ]
    bic r2, r2, r1
    strex r3, r2, [ r0 ]
    cmp r3, # 0
    ite eq
    mov r0, # 1 // Pass
    mov r0, # 0 // Fail
    b lr 
````
