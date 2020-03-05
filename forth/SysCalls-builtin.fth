\ Wrappers for SAPI functions, ABI 3.x

\ *G Get the version of the binary ABI in use. 
SVC(  #0 ) int SAPIVERSION( );              ( -- ver )

\ * Get a pointer to any shared data structures.
SVC(  #1 ) int SHARED_P( int x );                 ( -- addr )

\ *G EMIT - Stream IO
\ Emit a character and return 0 when the output buffer is full.
\ Blocking/Spinning. 
\ -1 for output flush.
SVC(  #2 ) int __EMIT( int x, int stream);  ( char channel -- room )

\ *G KEY? - Read a Key.  
\ Blocking.  Use with SERKEY? to detect blocking situations.
SVC(  #3 ) int __KEY(int stream);  ( base -- key )

\ *G SERKEY? - Stream IO
\ Return the number of characters available in the input queue,
\ or empty/full.  Pass in a tcb to request a wakeup on new data. 
SVC(  #4 ) int __KEY?(int stream, int tcb);      ( base -- int )

\ *G EMIT_NB - Non-blocking emit  
\ Returns -1 if the write failed.  Pass in a TCB 
SVC(  #7 ) int __EMIT_NB(int c, int stream,  int tcb);  ( base tcb -- key )

\ *G WAKEREQUEST  
\ Request a task wake.  The system call will stop the task. 
SVC(  #8 ) void WAKEREQUEST(int tcb, int arg1, int arg2 );  ( base tcb -- key )

SVC( #15 ) int TICKS( );          ( -- ms )
