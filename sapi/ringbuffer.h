// 
// Ringbuffer routines tailored to my particular needs.
// Copyright(C) 2012 Robert Sexton
//
 
struct ringbuf_t {
	uint8_t* buf; // Pointer to the storage area. 
	int bufsize;  // Length of the storage area 
	int bufmask;  // Used for masking the index.
	int freecount;
	int next_write;
	int next_read;
	};

typedef struct ringbuf_t RINGBUF;

void ringbuffer_init(RINGBUF* , uint8_t*, int);
int ringbuffer_free(RINGBUF*);
int ringbuffer_used(RINGBUF*);
void ringbuffer_addchar(RINGBUF*, uint8_t);
uint8_t ringbuffer_getchar(RINGBUF*); 


