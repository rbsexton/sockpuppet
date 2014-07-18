// sapi.h
// Required headers for compilation.
// 

// Needed for user app launch.
extern uint32_t app_restart_requested;
extern void launchuserapp(uint32_t *);

// Forth does not actually require a MS counter in the basic config, 
// but I consider it to be a requirement.
// Networking stacks will be doing this anyway.

extern volatile MSCOUNTER