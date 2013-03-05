/// @file sapi-dylink.h
/// @brief Define the record used for runtime linking.

/// This structure allows forth to easily look up things on the C
/// side of the world.  
/// 
/// Special Rules:
/// - The very first item is the size of the record.
typedef struct {
        void *p;       ///< Pointer to the object of interest
	int16_t size;  ///< Size in bytes
	int16_t count; ///< How many
	int8_t kind;   ///< Is this a variable or a constant?
	uint8_t namelen; ///< C string length
	char  name[19]; ///< C string.
	} runtimelink_t;


/// Helper Macro.
#define FORTHNAME(x) (sizeof(x)-1),x

extern runtimelink_t dynamiclinks[];

