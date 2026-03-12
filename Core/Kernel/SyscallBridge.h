#ifndef SYSCALL_BRIDGE_H
#define SYSCALL_BRIDGE_H

#include <stdint.h>
#include <stddef.h>
#include <string>

namespace XeniOS {
namespace Kernel {

/**
 * W^X JIT Toggle Macros — iOS requires Write XOR Execute.
 * These macros wrap pthread_jit_write_protect_np for safe code emission.
 *
 * Usage:
 *   JIT_BEGIN_WRITE();
 *   memcpy(codeBuffer, generatedCode, size);
 *   JIT_END_WRITE();
 *   // Now codeBuffer is executable
 */
#ifdef __APPLE__
extern "C" void pthread_jit_write_protect_np(int protect);

#define JIT_BEGIN_WRITE()  pthread_jit_write_protect_np(0)
#define JIT_END_WRITE()    pthread_jit_write_protect_np(1)
#define JIT_IS_APPLE       1
#else
#define JIT_BEGIN_WRITE()  ((void)0)
#define JIT_END_WRITE()    ((void)0)
#define JIT_IS_APPLE       0
#endif

/// RAII helper for batching JIT write protection toggles
/// Instantiate this on the stack before emitting a block of JIT code.
/// It unprotects memory on creation and re-protects on destruction.
class ScopedJITWrite {
public:
    ScopedJITWrite() { JIT_BEGIN_WRITE(); }
    ~ScopedJITWrite() { JIT_END_WRITE(); }
    
    // Non-copyable
    ScopedJITWrite(const ScopedJITWrite&) = delete;
    ScopedJITWrite& operator=(const ScopedJITWrite&) = delete;
};

/// Syscall result
struct SyscallResult {
    int64_t returnValue;
    int     errorCode;       // errno equivalent
    bool    handled;         // true if we intercepted, false for passthrough
};

/**
 * SyscallBridge — Native syscall hooking and fast-path I/O.
 *
 * 1. File Access Interception: Catches Wine/emulator file open/read/write
 *    calls and routes them through low-level Unix syscalls, bypassing
 *    Cocoa/FileManager overhead.
 * 2. W^X Toggle: Provides JIT_BEGIN_WRITE / JIT_END_WRITE macros for
 *    safe dynamic code emission on iOS.
 * 3. Fast Path: Frequently accessed paths (drive_c, system32) get
 *    pre-resolved and cached file descriptors.
 */
class SyscallBridge {
public:
    SyscallBridge();
    ~SyscallBridge();

    /// Initialize with the Wine prefix root path.
    bool Initialize(const std::string& prefixRoot);

    // ─── File System Fast Path ───
    /// Open a file via direct syscall (bypass NSFileManager/fopen wrappers).
    int FastOpen(const char* guestPath, int flags);
    /// Read from fd via direct syscall.
    ssize_t FastRead(int fd, void* buffer, size_t count);
    /// Write to fd via direct syscall.
    ssize_t FastWrite(int fd, const void* buffer, size_t count);
    /// Close fd.
    int FastClose(int fd);

    // ─── Path Translation ───
    /// Translate a Windows-style path (C:\...) to the iOS sandbox path.
    std::string TranslatePath(const char* windowsPath) const;

    // ─── Syscall Interception ───
    /// Intercept a Wine syscall by number. Returns result.
    SyscallResult InterceptSyscall(int syscallNumber, uint64_t arg1,
                                    uint64_t arg2, uint64_t arg3);

    /// Get stats.
    std::string GetStats() const;

private:
    std::string m_prefixRoot;
    std::string m_driveC;       // Cached drive_c path
    std::string m_system32;     // Cached system32 path

    uint64_t m_totalSyscalls;
    uint64_t m_interceptedSyscalls;
    uint64_t m_fastPathHits;
};

} // namespace Kernel
} // namespace XeniOS

#endif // SYSCALL_BRIDGE_H
