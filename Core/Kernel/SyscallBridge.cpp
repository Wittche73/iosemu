#include "SyscallBridge.h"
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <algorithm>

namespace XeniOS {
namespace Kernel {

SyscallBridge::SyscallBridge()
    : m_totalSyscalls(0), m_interceptedSyscalls(0), m_fastPathHits(0) {}

SyscallBridge::~SyscallBridge() {}

bool SyscallBridge::Initialize(const std::string& prefixRoot) {
    m_prefixRoot = prefixRoot;
    m_driveC = prefixRoot + "/drive_c";
    m_system32 = m_driveC + "/windows/system32";

    printf("[SyscallBridge] Initialized.\n");
    printf("  Prefix Root: %s\n", m_prefixRoot.c_str());
    printf("  Drive C:     %s\n", m_driveC.c_str());
    printf("  System32:    %s\n", m_system32.c_str());

    // Verify paths exist
    struct stat st;
    if (stat(m_driveC.c_str(), &st) != 0) {
        printf("[SyscallBridge] WARNING: drive_c does not exist yet.\n");
    }

    return true;
}

// ═══════════════════════════════════════════════════════════════
// File System Fast Path — Direct Unix syscalls
// Bypasses Cocoa/NSFileManager/fopen wrappers for minimal overhead.
// ═══════════════════════════════════════════════════════════════

int SyscallBridge::FastOpen(const char* guestPath, int flags) {
    m_totalSyscalls++;

    // Translate Windows path to iOS sandbox path
    std::string nativePath = TranslatePath(guestPath);

    int fd = open(nativePath.c_str(), flags);
    if (fd >= 0) {
        m_fastPathHits++;
    }

    return fd;
}

ssize_t SyscallBridge::FastRead(int fd, void* buffer, size_t count) {
    m_totalSyscalls++;
    return read(fd, buffer, count);
}

ssize_t SyscallBridge::FastWrite(int fd, const void* buffer, size_t count) {
    m_totalSyscalls++;
    return write(fd, buffer, count);
}

int SyscallBridge::FastClose(int fd) {
    m_totalSyscalls++;
    return close(fd);
}

// ═══════════════════════════════════════════════════════════════
// Path Translation — Windows-style to iOS sandbox
// ═══════════════════════════════════════════════════════════════

std::string SyscallBridge::TranslatePath(const char* windowsPath) const {
    if (!windowsPath) return m_driveC;

    std::string path(windowsPath);

    // Replace backslashes with forward slashes
    std::replace(path.begin(), path.end(), '\\', '/');

    // Handle drive letters
    if (path.size() >= 2 && path[1] == ':') {
        char driveLetter = path[0];
        std::string subPath = path.substr(2); // Remove "C:" prefix

        if (driveLetter == 'C' || driveLetter == 'c') {
            return m_driveC + subPath;
        } else if (driveLetter == 'Z' || driveLetter == 'z') {
            // Z: typically maps to Unix root in Wine
            return subPath;
        }
        // Other drives → map to drive_c by default
        return m_driveC + subPath;
    }

    // Relative path → relative to drive_c
    if (path[0] != '/') {
        return m_driveC + "/" + path;
    }

    // Already an absolute Unix path
    return path;
}

// ═══════════════════════════════════════════════════════════════
// Syscall Interception
// ═══════════════════════════════════════════════════════════════

SyscallResult SyscallBridge::InterceptSyscall(int syscallNumber,
                                               uint64_t arg1, uint64_t arg2, uint64_t arg3) {
    m_totalSyscalls++;
    SyscallResult result = {0, 0, false};

    // Common Linux syscall numbers used by Wine/Box64
    switch (syscallNumber) {
        case 2: { // SYS_open
            const char* path = reinterpret_cast<const char*>(arg1);
            int flags = static_cast<int>(arg2);
            result.returnValue = FastOpen(path, flags);
            result.errorCode = (result.returnValue < 0) ? 2 : 0; // ENOENT
            result.handled = true;
            m_interceptedSyscalls++;
            break;
        }
        case 0: { // SYS_read
            int fd = static_cast<int>(arg1);
            void* buf = reinterpret_cast<void*>(arg2);
            size_t count = static_cast<size_t>(arg3);
            result.returnValue = FastRead(fd, buf, count);
            result.handled = true;
            m_interceptedSyscalls++;
            break;
        }
        case 1: { // SYS_write
            int fd = static_cast<int>(arg1);
            const void* buf = reinterpret_cast<const void*>(arg2);
            size_t count = static_cast<size_t>(arg3);
            result.returnValue = FastWrite(fd, buf, count);
            result.handled = true;
            m_interceptedSyscalls++;
            break;
        }
        case 3: { // SYS_close
            int fd = static_cast<int>(arg1);
            result.returnValue = FastClose(fd);
            result.handled = true;
            m_interceptedSyscalls++;
            break;
        }
        case 4: { // SYS_stat
            const char* path = reinterpret_cast<const char*>(arg1);
            struct stat* st = reinterpret_cast<struct stat*>(arg2);
            std::string nativePath = TranslatePath(path);
            result.returnValue = stat(nativePath.c_str(), st);
            result.handled = true;
            m_interceptedSyscalls++;
            break;
        }
        default:
            // Not intercepted — pass through to OS
            result.handled = false;
            break;
    }

    return result;
}

std::string SyscallBridge::GetStats() const {
    return "{\"total_syscalls\":" + std::to_string(m_totalSyscalls) +
           ",\"intercepted\":" + std::to_string(m_interceptedSyscalls) +
           ",\"fast_path_hits\":" + std::to_string(m_fastPathHits) + "}";
}

} // namespace Kernel
} // namespace XeniOS
