/// @file blocking.h
/// A Shared data structure for managing blocking IO with Forth.

typedef struct {
		unsigned long *tcb;
		unsigned blocked_count_tx;
		unsigned blocked_count_rx;
		bool blocked_tx;
		bool blocked_rx;

		// Two things for use with software flow control.
		unsigned xoff_count;
		int8_t pended_fc_char; // Send at the next opportunity.
		} sIOBlockingData;

#define FORTH_THREAD_STOP(x) (x)->tcb[2] &= ~1; // Clear it using the unsafe technique. 
#define FORTH_THREAD_START(x) (x)->tcb[2] |= 1; 

