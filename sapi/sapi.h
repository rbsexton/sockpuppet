/// \file sapi.h
/// \brief Required headers for compilation.

#ifndef __STDINT_H__
#include <stdint.h>
#endif

#include "sapiopts.h"  // The official place for local customization.

// Needed for user app launch.
extern uint32_t app_restart_requested;
extern void launchuserapp(uint32_t *);

// MPE Forth does not actually require a MS counter in the basic config, 
// but I consider it to be a requirement.  Networking stacks will be doing this anyway.
extern volatile uint32_t MSCOUNTER;