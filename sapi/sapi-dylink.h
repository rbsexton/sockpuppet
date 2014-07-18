/// @file sapi-dylink.h
/// @brief Define the record used for runtime linking.

#ifndef __STDINT_H__
#include <stdint.h>
#endif

/// This structure allows forth to easily look up things on the C
/// side of the world.  
/// 
/// Special Rules:
/// - The very first item is the size of the record.
/// 

// This could be packed more tightly, but its now exactly
// 16 bytes per record, which is nice.  Make sure that doesnt
// change.

// Conventions: 
// Size is the size of the fundamental thing in bytes, 
// and count is the number of them.
// char array[64] = 1,64
// struct { a, b } s; sizeof(s),1

// Adjust the size of the string so you get a 32-byte record.

#define DYNLINKNAMEMLEN 22

typedef struct {
	// This union is a bit crazy, but its the simplest way of 
	// getting the compiler to shut up.
	union { 
		void (*fp) (void);
		int*  ip;
		unsigned int    ui;
		unsigned int*  uip;
		unsigned long* ulp;
		} p;   ///< Pointer to the object of interest (4)
	int16_t size;  ///< Size in bytes (6)
	int16_t count; ///< How many (8)
	int8_t kind;   ///< Is this a variable or a constant? (9)
	uint8_t strlen;   ///< Length of the string (10)
	const char name[DYNLINKNAMEMLEN]; ///< Null-Terminated C string.
	} runtimelink_t;


/// Helper Macro.
#define FORTHNAME(x) ( (int8_t) sizeof(x)-1), x

extern const runtimelink_t dynamiclinks[];

