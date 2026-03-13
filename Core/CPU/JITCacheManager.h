#ifndef JIT_CACHE_MANAGER_H
#define JIT_CACHE_MANAGER_H

#include <stdint.h>
#include <stddef.h>
#include <string>
#include <unordered_map>
#include <vector>

namespace XeniOS {
namespace CPU {

// ─── Register Mapping: PPC r0-r31 → ARM64 x0-x28 ───
// Xbox 360 Xenon PPC has 32 GPRs, ARM64 has 31 (x0-x30).
// We pin the hottest PPC registers to ARM64 hardware registers.
struct RegisterMapping {
    int ppcReg;       // PPC register index (0-31)
    int arm64Reg;     // ARM64 register index (x0-x28, -1 = spilled to stack)
    bool isDirty;     // Modified since last sync
};

// ─── Instruction Bundling Table Entry ───
// Maps simple x86/PPC instruction pairs to optimized ARM64 equivalents.
struct BundleRule {
    uint32_t pattern1;    // First instruction pattern/opcode
    uint32_t pattern2;    // Second instruction pattern/opcode (0 = single instruction)
    uint32_t emitARM64;   // Fused ARM64 equivalent opcode
    std::string description; // Description for debugging
    bool isActive;        // Sub-task: Dynamic Hot-Swap constraint
    uint32_t useCount;    // Sub-task: Execution Profiler usage counter
};

// ─── AOT Cache Block ───
struct CachedBlock {
    uint32_t guestAddress;    // Original PPC/x86 address
    uint64_t hash;            // Fnv1a hash of source bytes
    size_t   nativeSize;      // Size of compiled ARM64 code
    void*    nativeCode;      // Pointer to mmap'd code
    uint64_t hitCount;        // Execution count for hot-path analysis
};

/**
 * JITCacheManager — AOT (Ahead-of-Time) disk cache with peephole optimization.
 *
 * 1. AOT Cache: Saves compiled JIT blocks to disk (.bin files), reloads on
 *    next launch via mmap for zero startup latency.
 * 2. Register Mapping: Pins Xenon PPC r0-r31 to ARM64 x0-x28 with minimal spills.
 * 3. Instruction Bundling: Fuses common instruction pairs into single ARM64 ops.
 */
class JITCacheManager {
public:
    JITCacheManager();
    ~JITCacheManager();

    /// Initialize the cache directory and reload any previously cached blocks.
    bool Initialize(const std::string& cacheDirectory);

    /// Look up a cached block by guest address. Returns nullptr if not cached.
    CachedBlock* LookupBlock(uint32_t guestAddress);

    /// Insert a newly compiled block into the cache and persist to disk.
    bool CacheBlock(uint32_t guestAddress, const uint8_t* sourceBytes,
                    size_t sourceSize, const uint8_t* nativeBytes,
                    size_t nativeSize);

    /// Invalidate a cached block (e.g., self-modifying code detected).
    void InvalidateBlock(uint32_t guestAddress);

    /// Flush entire cache to disk and free memory.
    void FlushAll();

    /// Get the optimal ARM64 register for a PPC register.
    int MapRegister(int ppcRegister) const;

    /// Try to bundle two instructions into one. Returns fused opcode or 0.
    uint32_t TryBundle(uint32_t opcode1, uint32_t opcode2) const;

    /// Get current cache capacity stats
    std::string GetStats() const;
    
    /// Get execution profiler stats for Bundle rules
    std::string GetBundleStats() const;

private:
    std::string m_cacheDir;
    std::unordered_map<uint32_t, CachedBlock> m_blockCache;
    std::vector<RegisterMapping> m_registerMap;
    // Peephole bundle table
    std::vector<BundleRule> m_bundleTable;

    // Internal helpers
    uint64_t ComputeHash(const uint8_t* data, size_t size) const;
    bool LoadFromDisk(const std::string& path, CachedBlock& block);
    bool SaveToDisk(const std::string& path, const CachedBlock& block);
    void InitializeRegisterMap();
    void InitializeBundleTable();
};

} // namespace CPU
} // namespace XeniOS

#endif // JIT_CACHE_MANAGER_H
