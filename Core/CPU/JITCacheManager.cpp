#include "JITCacheManager.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <fstream>

namespace XeniOS {
namespace CPU {

// ─── FNV-1a 64-bit Hash ───
static const uint64_t FNV_OFFSET_BASIS = 14695981039346656037ULL;
static const uint64_t FNV_PRIME = 1099511628211ULL;

JITCacheManager::JITCacheManager() {}

JITCacheManager::~JITCacheManager() {
    FlushAll();
}

bool JITCacheManager::Initialize(const std::string& cacheDirectory) {
    m_cacheDir = cacheDirectory;

    // Create cache directory if not exists
    mkdir(m_cacheDir.c_str(), 0755);

    printf("[JITCache] Initializing AOT Cache at: %s\n", m_cacheDir.c_str());

    // Reload previously cached blocks from disk
    DIR* dir = opendir(m_cacheDir.c_str());
    if (dir) {
        struct dirent* entry;
        int loaded = 0;
        while ((entry = readdir(dir)) != nullptr) {
            std::string name(entry->d_name);
            if (name.size() > 4 && name.substr(name.size() - 4) == ".bin") {
                CachedBlock block;
                std::string path = m_cacheDir + "/" + name;
                if (LoadFromDisk(path, block)) {
                    m_blockCache[block.guestAddress] = block;
                    loaded++;
                }
            }
        }
        closedir(dir);
        printf("[JITCache] Preloaded %d cached blocks from disk.\n", loaded);
    }

    // Initialize optimization tables
    InitializeRegisterMap();
    InitializeBundleTable();

    printf("[JITCache] Initialized: %zu register mappings, %zu bundle patterns.\n",
           m_registerMap.size(), m_bundleTable.size());
    return true;
}

CachedBlock* JITCacheManager::LookupBlock(uint32_t guestAddress) {
    auto it = m_blockCache.find(guestAddress);
    if (it != m_blockCache.end()) {
        it->second.hitCount++;
        return &it->second;
    }
    return nullptr;
}

bool JITCacheManager::CacheBlock(uint32_t guestAddress,
                                  const uint8_t* sourceBytes, size_t sourceSize,
                                  const uint8_t* nativeBytes, size_t nativeSize) {
    CachedBlock block;
    block.guestAddress = guestAddress;
    block.hash = ComputeHash(sourceBytes, sourceSize);
    block.nativeSize = nativeSize;
    block.hitCount = 0;

    // Allocate executable memory (MAP_JIT for iOS W^X compliance)
#ifdef __APPLE__
    block.nativeCode = mmap(NULL, nativeSize, PROT_READ | PROT_WRITE,
                            MAP_PRIVATE | MAP_ANONYMOUS | MAP_JIT, -1, 0);
#else
    block.nativeCode = mmap(NULL, nativeSize, PROT_READ | PROT_WRITE | PROT_EXEC,
                            MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
#endif

    if (block.nativeCode == MAP_FAILED) {
        printf("[JITCache] ERROR: mmap failed for block at 0x%08X\n", guestAddress);
        return false;
    }

    // Copy native code into JIT page
#ifdef __APPLE__
    // Temporarily allow writes on iOS
    extern void pthread_jit_write_protect_np(int);
    pthread_jit_write_protect_np(0);
#endif

    memcpy(block.nativeCode, nativeBytes, nativeSize);

#ifdef __APPLE__
    // Re-enable execute protection
    mprotect(block.nativeCode, nativeSize, PROT_READ | PROT_EXEC);
    pthread_jit_write_protect_np(1);
#else
    mprotect(block.nativeCode, nativeSize, PROT_READ | PROT_EXEC);
#endif

    m_blockCache[guestAddress] = block;

    // Persist to disk for next launch
    char filename[64];
    snprintf(filename, sizeof(filename), "block_0x%08X.bin", guestAddress);
    std::string path = m_cacheDir + "/" + filename;
    SaveToDisk(path, block);

    return true;
}

void JITCacheManager::InvalidateBlock(uint32_t guestAddress) {
    auto it = m_blockCache.find(guestAddress);
    if (it != m_blockCache.end()) {
        if (it->second.nativeCode) {
            munmap(it->second.nativeCode, it->second.nativeSize);
        }
        m_blockCache.erase(it);
        printf("[JITCache] Invalidated block at 0x%08X\n", guestAddress);
    }
}

void JITCacheManager::FlushAll() {
    for (auto& pair : m_blockCache) {
        if (pair.second.nativeCode) {
            munmap(pair.second.nativeCode, pair.second.nativeSize);
            pair.second.nativeCode = nullptr;
        }
    }
    m_blockCache.clear();
    printf("[JITCache] All blocks flushed.\n");
}

int JITCacheManager::MapRegister(int ppcRegister) const {
    if (ppcRegister < 0 || ppcRegister >= (int)m_registerMap.size()) {
        return -1; // Spill to stack
    }
    return m_registerMap[ppcRegister].arm64Reg;
}

uint32_t JITCacheManager::TryBundle(uint32_t opcode1, uint32_t opcode2) const {
    for (const auto& pattern : m_bundleTable) {
        if (pattern.opcode1 == opcode1 && pattern.opcode2 == opcode2) {
            return pattern.arm64Opcode;
        }
    }
    return 0; // No bundle found
}

std::string JITCacheManager::GetStats() const {
    uint64_t totalHits = 0;
    for (const auto& pair : m_blockCache) {
        totalHits += pair.second.hitCount;
    }
    return "{\"cached_blocks\":" + std::to_string(m_blockCache.size()) +
           ",\"total_hits\":" + std::to_string(totalHits) +
           ",\"register_mappings\":" + std::to_string(m_registerMap.size()) +
           ",\"bundle_patterns\":" + std::to_string(m_bundleTable.size()) + "}";
}

// ═══════════════════════════════════════════════════════════════
// Internal Helpers
// ═══════════════════════════════════════════════════════════════

uint64_t JITCacheManager::ComputeHash(const uint8_t* data, size_t size) const {
    uint64_t hash = FNV_OFFSET_BASIS;
    for (size_t i = 0; i < size; i++) {
        hash ^= data[i];
        hash *= FNV_PRIME;
    }
    return hash;
}

bool JITCacheManager::LoadFromDisk(const std::string& path, CachedBlock& block) {
    std::ifstream file(path, std::ios::binary);
    if (!file.is_open()) return false;

    // Header: guestAddress(4) + hash(8) + nativeSize(8)
    file.read(reinterpret_cast<char*>(&block.guestAddress), sizeof(uint32_t));
    file.read(reinterpret_cast<char*>(&block.hash), sizeof(uint64_t));
    file.read(reinterpret_cast<char*>(&block.nativeSize), sizeof(size_t));

    if (block.nativeSize == 0 || block.nativeSize > 1024 * 1024) {
        return false; // Sanity check: max 1MB per block
    }

    // Read native code
    std::vector<uint8_t> code(block.nativeSize);
    file.read(reinterpret_cast<char*>(code.data()), block.nativeSize);
    if (!file) return false;

    // Map into executable memory
#ifdef __APPLE__
    block.nativeCode = mmap(NULL, block.nativeSize, PROT_READ | PROT_WRITE,
                            MAP_PRIVATE | MAP_ANONYMOUS | MAP_JIT, -1, 0);
#else
    block.nativeCode = mmap(NULL, block.nativeSize, PROT_READ | PROT_WRITE | PROT_EXEC,
                            MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
#endif
    if (block.nativeCode == MAP_FAILED) return false;

#ifdef __APPLE__
    extern void pthread_jit_write_protect_np(int);
    pthread_jit_write_protect_np(0);
#endif
    memcpy(block.nativeCode, code.data(), block.nativeSize);
#ifdef __APPLE__
    mprotect(block.nativeCode, block.nativeSize, PROT_READ | PROT_EXEC);
    pthread_jit_write_protect_np(1);
#else
    mprotect(block.nativeCode, block.nativeSize, PROT_READ | PROT_EXEC);
#endif

    block.hitCount = 0;
    return true;
}

bool JITCacheManager::SaveToDisk(const std::string& path, const CachedBlock& block) {
    std::ofstream file(path, std::ios::binary);
    if (!file.is_open()) return false;

    file.write(reinterpret_cast<const char*>(&block.guestAddress), sizeof(uint32_t));
    file.write(reinterpret_cast<const char*>(&block.hash), sizeof(uint64_t));
    file.write(reinterpret_cast<const char*>(&block.nativeSize), sizeof(size_t));

    // Need to temporarily make readable for save (it's PROT_READ | PROT_EXEC)
    file.write(reinterpret_cast<const char*>(block.nativeCode), block.nativeSize);

    return file.good();
}

void JITCacheManager::InitializeRegisterMap() {
    m_registerMap.clear();

    // ═══ Xenon PPC (r0-r31) → ARM64 (x0-x28) Mapping ═══
    // Strategy: Pin hottest PPC GPRs to ARM64 hardware regs.
    // r0 is special in PPC (often 0 in address calculations).
    // r1 = stack pointer, r2 = TOC, r3-r10 = function args/return.
    // r13 = thread-local storage.

    const int SPILL = -1; // Register spilled to stack frame

    // PPC r0 → ARM64 x19 (callee-saved, specialized)
    // PPC r1 (SP) → ARM64 x20 (stack pointer)
    // PPC r2 (TOC) → ARM64 x21
    // PPC r3-r10 (args/ret) → ARM64 x0-x7 (native ABI match)
    // PPC r11-r12 → ARM64 x8-x9
    // PPC r13 (TLS) → ARM64 x22 (dedicated thread-local)
    // PPC r14-r31 → ARM64 x10-x18, x23-x28 (hard-pinned callee-saved)

    int arm64Map[32] = {
        19,  // r0  → x19 (callee-saved)
        20,  // r1  → x20 (stack)
        21,  // r2  → x21 (TOC)
         0,  // r3  → x0  (1st arg)
         1,  // r4  → x1
         2,  // r5  → x2
         3,  // r6  → x3
         4,  // r7  → x4
         5,  // r8  → x5
         6,  // r9  → x6
         7,  // r10 → x7
         8,  // r11 → x8
         9,  // r12 → x9
        22,  // r13 → x22 (TLS - pinned hard)
        10,  // r14 → x10
        11,  // r15 → x11
        12,  // r16 → x12
        13,  // r17 → x13
        14,  // r18 → x14
        15,  // r19 → x15
        16,  // r20 → x16
        17,  // r21 → x17
        23,  // r22 → x23 (skipped x18 Apple reserved system register)
        24,  // r23 → x24
        25,  // r24 → x25
        26,  // r25 → x26
        27,  // r26 → x27
        28,  // r27 → x28 (last callee-saved)
        SPILL, // r28 → stack
        SPILL, // r29 → stack
        SPILL, // r30 → stack
        SPILL  // r31 → stack
    };

    for (int i = 0; i < 32; i++) {
        RegisterMapping mapping;
        mapping.ppcReg = i;
        mapping.arm64Reg = arm64Map[i];
        mapping.isDirty = false;
        m_registerMap.push_back(mapping);
    }
}

void JITCacheManager::InitializeBundleTable() {
    m_bundleTable.clear();

    // ═══ Peephole Optimization: Common PPC instruction pairs → ARM64 ═══
    // Basic rules initialized as active=true. Advanced ones can be toggled via Hot-Swap check.

    // ADD + CMP → ADDS (set flags in single op)
    m_bundleTable.push_back({0x7C000214, 0x7C000000, 0x2B000000, "add+cmp → adds"});

    // LOAD + BSWAP32 → LDR + REV (ARM64 has native REV)
    m_bundleTable.push_back({0x80000000, 0x7C00062C, 0xDAC00C00, "lwz+bswap → ldr+rev"});

    // OR rD,rS,rS (PPC move) → MOV (ARM64 native)
    m_bundleTable.push_back({0x7C000378, 0x00000000, 0xAA0003E0, "or(move) → mov"});

    // ADDI + STWU (stack push) → STP pre-indexed
    m_bundleTable.push_back({0x38000000, 0x94000000, 0xA9BF0000, "addi+stwu → stp pre", true});

    // RLWINM (rotate-left-word-immediate-and-mask) → UBFX/BFC (bitfield extract/clear)
    // Transforms complex PowerPC bitwise mask and rotate to a single ARM64 hardware bitfield op.
    m_bundleTable.push_back({0x54000000, 0x00000000, 0x53000000, "rlwinm → ubfx/bfc", true});

    // MULLI + ADD → MADD (multiply-add in single cycle)
    m_bundleTable.push_back({0x1C000000, 0x7C000214, 0x1B000000, "mulli+add → madd", true});

    // LWZ + LWZ (sequential loads) → LDP (load pair)
    m_bundleTable.push_back({0x80000000, 0x80000004, 0xA9400000, "lwz+lwz → ldp"});

    // STW + STW (sequential stores) → STP (store pair)
    m_bundleTable.push_back({0x90000000, 0x90000004, 0xA9000000, "stw+stw → stp"});

    printf("[JITCache] Bundle table: %zu peephole patterns registered.\n", m_bundleTable.size());
}

} // namespace CPU
} // namespace XeniOS
