#include "RuntimeBridge.h"

// SDK Patch: Define missing type to prevent hangs during module compilation
typedef void* os_workgroup_interval_t;
