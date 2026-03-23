#include "MemoryOptimizer.h"
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <mutex> // Added for std::mutex and std::lock_guard

namespace XeniOS {
namespace Memory {

MemoryOptimizer::MemoryOptimizer()
    : m_regionCount(0), m_totalBudget(0), m_totalAllocated(0), m_pressureCallback(nullptr) {
    memset(m_regions, 0, sizeof(m_regions));
}

MemoryOptimizer::~MemoryOptimizer() {
    // The destructor should call Shutdown to clean up resources.
    Shutdown();
}

void MemoryOptimizer::SetPressureCallback(MemoryPressureCallback callback) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_pressureCallback = callback;
}

void MemoryOptimizer::Shutdown() {
    for (int i = 0; i < m_regionCount; ++i) {
        if (m_regions[i].base && m_regions[i].size > 0) {
            munmap(m_regions[i].base, m_regions[i].size);
            m_regions[i].base = nullptr;
        }
    }
    m_regionCount = 0;
}

// ═══════════════════════════════════════════════════════════════

void MemoryOptimizer::CheckMemoryPressureAndFlush() {
    // We assume 4GB (0xFFFFFFFF) as typical tight VAS boundary for 32-bit emu components.
    // If we have mapped multiple regions totaling > 3.5GB (say 85% of 4GB), trigger LRU flush.
    const size_t THRESHOLD = (size_t)(3.5 * 1024 * 1024 * 1024ull); 
    size_t totalAllocated = 0;
    
    for (int i = 0; i < m_regionCount; i++) {
        totalAllocated += m_regions[i].size;
    }

    if (totalAllocated >= THRESHOLD) {
        printf("[MemOptimizer] Memory pressure HIGH (%zu bytes). Triggering LRU flush...\n", totalAllocated);
        // Simple demonstration of LRU logic: We look for a region labelled "XeniaJIT" or "Box64Dynarec" 
        // that hasn't been used recently (in a full implementation we'd track last_access_timestamp).
        // For now, we simulate freeing an arbitrary old region if we hit the limit.
        for (int i = 0; i < m_regionCount; i++) {
            if (m_regions[i].isJIT) { // Assuming `isJIT` is a new member in VASRegion
                // Fake mmap flush / madvise DONTNEED
                #ifdef __APPLE__
                madvise(m_regions[i].base, m_regions[i].size, MADV_FREE);
                #else
                madvise(m_regions[i].base, m_regions[i].size, MADV_DONTNEED);
                #endif
                printf("[MemOptimizer] Flushed JIT Region '%s' (%zu bytes) to relieve pressure.\n", 
                        m_regions[i].label, m_regions[i].size);
                
                // Invoke callback to alert higher layers (Swift UI)
                if (m_pressureCallback) {
                    m_pressureCallback(m_regions[i].size);
                }

                break; // Only flush one large block per check
            }
        }
    }
}

bool MemoryOptimizer::Initialize(size_t totalRamBudget) {
    m_totalBudget = totalRamBudget;
    printf("[MemOptimizer] Initialized with %zu MB budget.\n",
           totalRamBudget / (1024 * 1024));
    return true;
}

// ═══════════════════════════════════════════════════════════════
// Zero-Copy Byte Swap — ARM64 REV Hardware Instructions
// On ARM64, the REV instruction reverses the byte order in a
// register in a single cycle — no software loop needed.
// ═══════════════════════════════════════════════════════════════

uint32_t MemoryOptimizer::ReadSwap32(const void* address) {
    uint32_t value;
    memcpy(&value, address, sizeof(uint32_t));
#if defined(__aarch64__) || defined(__arm64__)
    // ARM64 REV instruction: single-cycle hardware byte swap
    __asm__ volatile("rev %w0, %w0" : "+r"(value));
#else
    value = __builtin_bswap32(value);
#endif
    return value;
}

uint16_t MemoryOptimizer::ReadSwap16(const void* address) {
    uint16_t value;
    memcpy(&value, address, sizeof(uint16_t));
#if defined(__aarch64__) || defined(__arm64__)
    __asm__ volatile("rev16 %w0, %w0" : "+r"(value));
#else
    value = __builtin_bswap16(value);
#endif
    return value;
}

void MemoryOptimizer::WriteSwap32(void* address, uint32_t value) {
#if defined(__aarch64__) || defined(__arm64__)
    __asm__ volatile("rev %w0, %w0" : "+r"(value));
#else
    value = __builtin_bswap32(value);
#endif
    memcpy(address, &value, sizeof(uint32_t));
}

uint64_t MemoryOptimizer::ReadSwap64(const void* address) {
    uint64_t value;
    memcpy(&value, address, sizeof(uint64_t));
#if defined(__aarch64__) || defined(__arm64__)
    __asm__ volatile("rev %0, %0" : "+r"(value));
#else
    value = __builtin_bswap64(value);
#endif
    return value;
}

// ═══════════════════════════════════════════════════════════════
// VAS Isolation — Separate mmap regions per emulation engine
// ═══════════════════════════════════════════════════════════════

VASRegion* MemoryOptimizer::CreateIsolatedRegion(const char* label, size_t size,
                                                   uint32_t guestBase, bool executable,
                                                   bool is32BitRestricted) {
    if (m_regionCount >= MAX_REGIONS) {
        printf("[MemOptimizer] ERROR: Max VAS regions (%d) reached.\n", MAX_REGIONS);
        return nullptr;
    }

    if (m_totalAllocated + size > m_totalBudget) {
        printf("[MemOptimizer] WARNING: Allocation of %zu bytes exceeds budget.\n", size);
    }

    int prot = PROT_READ | PROT_WRITE;
    int flags = MAP_PRIVATE | MAP_ANONYMOUS;

#ifdef __APPLE__
    if (executable) {
        flags |= MAP_JIT;
    }
#else
    if (executable) {
        prot |= PROT_EXEC;
    }
#endif

#if defined(MAP_32BIT)
    if (is32BitRestricted) {
        flags |= MAP_32BIT;
    }
#endif

    void* base = mmap(NULL, size, prot, flags, -1, 0);
    if (base == MAP_FAILED) {
        printf("[MemOptimizer] ERROR: mmap failed for region '%s' (%zu bytes).\n", label, size);
        return nullptr;
    }

    // On macOS/iOS ARM64, MAP_32BIT might not be strictly supported by mmap hardware.
    // If it allocated above 4GB while restricted, warn heavily.
    if (is32BitRestricted && (uintptr_t)base > 0xFFFFFFFFull) {
        printf("[MemOptimizer] WARNING: 'is32BitRestricted' failed, address %p is above 4GB bound!\n", base);
    }

    VASRegion& region = m_regions[m_regionCount];
    region.base = base;
    region.size = size;
    region.guestBase = guestBase;
    region.isJIT = executable;
    strncpy(region.label, label, sizeof(region.label) - 1);
    region.label[sizeof(region.label) - 1] = '\0'; // ensure null termination

    m_totalAllocated += size;
    m_regionCount++;

    printf("[MemOptimizer] VAS Region '%s': %p, %zu MB, guest=0x%08X%s\n",
           label, base, size / (1024 * 1024), guestBase,
           executable ? " [JIT]" : "");

    return &region;
}

VASRegion* MemoryOptimizer::FindRegion(const char* label) const {
    for (int i = 0; i < m_regionCount; i++) {
        if (strcmp(m_regions[i].label, label) == 0) {
            return const_cast<VASRegion*>(&m_regions[i]);
        }
    }
    return nullptr;
}

void MemoryOptimizer::ReleaseRegion(const char* label) {
    for (int i = 0; i < m_regionCount; ++i) {
        if (strcmp(m_regions[i].label, label) == 0) {
            if (m_regions[i].base) {
                munmap(m_regions[i].base, m_regions[i].size);
                m_totalAllocated -= m_regions[i].size;
                printf("[MemOptimizer] Released VAS region '%s'.\n", label);
            }
            // Shift remaining regions
            for (int j = i; j < m_regionCount - 1; j++) {
                m_regions[j] = m_regions[j + 1];
            }
            m_regionCount--;
            return;
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// APFS Fast I/O — mmap instead of fread for zero-copy reads
// ═══════════════════════════════════════════════════════════════

void* MemoryOptimizer::MapFile(const std::string& path, size_t& outSize) {
    int fd = open(path.c_str(), O_RDONLY);
    if (fd < 0) {
        printf("[MemOptimizer] ERROR: Cannot open file: %s\n", path.c_str());
        outSize = 0;
        return nullptr;
    }

    struct stat st;
    if (fstat(fd, &st) != 0) {
        close(fd);
        outSize = 0;
        return nullptr;
    }

    outSize = st.st_size;

    void* mapping = mmap(NULL, outSize, PROT_READ, MAP_PRIVATE, fd, 0);
    close(fd);

    if (mapping == MAP_FAILED) {
        printf("[MemOptimizer] ERROR: mmap failed for file: %s\n", path.c_str());
        outSize = 0;
        return nullptr;
    }

    // Advise kernel for sequential read pattern (APFS optimization)
    madvise(mapping, outSize, MADV_SEQUENTIAL);

    printf("[MemOptimizer] Mapped file: %s (%zu KB, zero-copy)\n",
           path.c_str(), outSize / 1024);
    return mapping;
}

void MemoryOptimizer::UnmapFile(void* mapping, size_t size) {
    if (mapping) {
        munmap(mapping, size);
    }
}

std::string MemoryOptimizer::GetStats() const {
    return "{\"regions\":" + std::to_string(m_regionCount) +
           ",\"allocated_mb\":" + std::to_string(m_totalAllocated / (1024 * 1024)) +
           ",\"budget_mb\":" + std::to_string(m_totalBudget / (1024 * 1024)) + "}";
}

} // namespace Memory
} // namespace XeniOS
