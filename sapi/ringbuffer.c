// 
// Ringbuffer routines tailored to my particular needs.
// Copyright(C) 2012 Robert Sexton
//
// Basic Model - Struct with external storage
// - No interrupt protection.  Thats externally supplied.
// - Dynamically created so that the same code does many
// - Counted contents so you can put in a big chunk.
// - Checkpoints.  This is so that you throw away lines
// - Requires power of two sizing.
// There are edge conditions when its full.
//
// Unit tests worth writing:
// Put a char in, get the same one out.   Repeat until wrap
// Put three in, then pull one out.  Add one.  repeat util wrap.
//
// Second generation.   Update it to better comply with lock-free behavior

// #include "ringbuffer.h"
#include <stdint.h>

#include "ringbuffer.h"

void ringbuffer_init(RINGBUF* rb, uint8_t* buf, int size) {
	rb->buf = buf;
	rb->bufsize = size;
	rb->bufmask = size - 1;
	rb->freecount = size;
	rb->next_write=0;
	rb->next_read=0;
	}

int ringbuffer_free(RINGBUF* rb) {
	return(rb->freecount);
	}
int ringbuffer_used(RINGBUF* rb) {
	return(rb->bufsize - rb->freecount);
	}

void ringbuffer_addchar(RINGBUF* rb, uint8_t c) {
	if ( rb->freecount > 1 ) {
		rb->buf[rb->next_write] = c;
		(rb->freecount)--;
		rb->next_write = ++(rb->next_write) & rb->bufmask;
		}
	else { // It gets complicated.  Steal one
		rb->buf[rb->next_write] = c;
		rb->next_write = ++(rb->next_write) & rb->bufmask;
		rb->next_read = ++(rb->next_read) & rb->bufmask;
		// No change in freecount
		}
	}
// Do the converse of add.  
uint8_t ringbuffer_getchar(RINGBUF* rb) {
	uint8_t c;
	// If empty, lie rather than make it worse.
	// otherwise, theres more room now.
	if ( rb->freecount >= rb->bufsize ) { return(0); }
	else { (rb->freecount)++; }

	// Get the char, then advance the pointer
	c = rb->buf[rb->next_read];
	rb->next_read = ++(rb->next_read) & rb->bufmask;
	return(c);
	}


