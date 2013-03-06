#include <stdint.h>
#include "sapi.h"
#include "sapi-dylink.h"

#include "drivers/rit128x96x4.h"

extern unsigned long g_ulSystemTimeMS;

/// Dynamic Linking table.
/// This lets Forth get add key variables into the dictionary.
/// Pointer, size (bytes), count, type: Variable, Constant, and a pointer to a string
/// Note that there may be funny stuff with regards to case and Forth,
/// so the names are upper-cased. There was thought of having Forth make

const runtimelink_t dynamiclinks[] __attribute__((aligned( sizeof(runtimelink_t) ))) = {
 { { .ui  = sizeof(runtimelink_t)  },                0, 0, 'C', FORTHNAME("RECORDLEN") },
 { { .ulp = &g_ulSystemTimeMS      }, sizeof(uint32_t), 1, 'V', FORTHNAME("SYSTIMEMS") },

 { { .fp = (void (*) (void)) &RIT128x96x4StringDraw}, sizeof(uint32_t), 1, 'C', FORTHNAME("OLED_WR") },
 { { .ui = 0 } ,0,0,0,FORTHNAME("") } 
 };

