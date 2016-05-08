\ SysTickCM3_sapi.fth LPC17xx - Cortex-M3 ticker for the SAPI interface.
\ Limitations:
\ 1 - Its a ms counter.  End of story.
\ 2 - Its always on.
\ 3 - Its read-only. (subject to change)

\ Copyright (c) 2011-2016, Robert Sexton.  All rights reserved.
\ Covered by the terms of the supplied Licence.txt file


((

Derived from the LPC17xx code.

))

only forth definitions
decimal

\ ===========
\ *! systick
\ *T System Ticker
\ ===========
\ *P The system ticker is managed by the SockPuppet Layer.  Its ms.

[undefined] ms [if]
: ms            \ n --
\ *G Waits for n milliseconds.
  ticks +
  begin
[ tasking? ] [if] pause [else] [asm wfi asm] [then]
    dup ticks - 0<
  until
  drop
;
[then]

\ ********************
\ Time base extensions
\ ********************

timebase? [if]
: start-timers  \ -- ; Start internal time clock
\ *G Initialise the TIMEBASE system.
  stop-clock init-timers start-clock
;

: stop-Timers   \ -- ; disable timer system
\ *G Stop the TIMEBASE ticker.
  stop-clock
;
[then]


\ ======
\ *> ###
\ ======

decimal

