#ifndef MEMORY_OPTIMIZER_H
#define MEMORY_OPTIMIZER_H

#include <stdint.h>
#include <stddef.h>
#include <string>

namespace XeniOS {
namespace Memory {

/// Virtual Address Space (VAS) region descriptor
struct VASRegion {
    void*    base;          // Base address of the region
    size_t   size;          // Size of the region in bytes
    uint32_t guestBase;     // Xbox 360 guest base address
    char     label[32];     // Debug label
    bool     isJIT;         // Marks if region is used for JIT (used for LRU flush)
};

/**
 * MemoryOptimizer — Zero-copy and hardware-accelerated memory operations.
 *
 * 1. Zero-Copy REV Swap: Uses ARM64 hardware REV/REV16 instructions for
 *    Big-Endian ↔ Little-Endian conversion instead of software __builtin_bswap.
 * 2. VAS Isolation: Maintains separate mmap regions for each emulation engine
 *    (Box64, XeniOS) to prevent page table collisions.
 * 3. APFS Fast I/O: Uses mmap instead of fread for game data, enabling
 *    zero-copy reads directly from kernel buffer cache.
 */
class MemoryOptimizer {
public:
    MemoryOptimizer();
    ~MemoryOptimizer();

    /// Initialize optimizer with total RAM budget.
    bool Initialize(size_t totalRamBudget);

    // ─── Zero-Copy Byte Swap (ARM64 REV) ───
    /// Read 32-bit value with hardware byte-reverse (BE→LE).
    static uint32_t ReadSwap32(const void* address);
    /// Read 16-bit value with hardware byte-reverse.
    static uint16_t ReadSwap16(const void* address);
    /// Write 32-bit value with hardware byte-reverse (LE→BE).
    static void WriteSwap32(void* address, uint32_t value);
    /// Read 64-bit with hardware swap.
    static uint64_t ReadSwap64(const void* address);

    // ─── VAS Isolation ───
    /// Create an isolated virtual address space region for an engine.
    /// @param is32BitRestricted If true, ensures allocation is below 4GB boundary
    VASRegion* CreateIsolatedRegion(const char* label, size_t size,
                                    uint32_t guestBase, bool executable,
                                    bool is32BitRestricted = false);
    /// Find a VAS region by label.
    VASRegion* FindRegion(const char* label) const;
    /// Release a VAS region.
    void ReleaseRegion(const char* label);

    // ─── APFS Fast I/O (mmap) ───
    /// Memory-map a file for zero-copy reading. Returns mapped pointer.
    void* MapFile(const std::string& path, size_t& outSize);
    /// Unmap a previously mapped file.
    void UnmapFile(void* mapping, size_t size);
    /// Releases all regions and cleans up resources.
    void Shutdown();

    // ─── Sub-task: Memory Pressure Auto-Flush (LRU) ───
    /// Checks if allocated regions approach VAS limit and flushes least recently used (LRU) data.
    void CheckMemoryPressureAndFlush();

    /// Get statistics.
    std::string GetStats() const;

private:
    static const int MAX_REGIONS = 8;
    VASRegion m_regions[MAX_REGIONS];
    int m_regionCount;
    size_t m_totalBudget;
    size_t m_totalAllocated;
};

} // namespace Memory
} // namespace XeniOS

#endif // MEMORY_OPTIMIZER_H
