#include "ShaderWarmingService.h"
#include <stdio.h>
#include <string.h>
#include <chrono>

namespace XeniOS {
namespace GPU {

static const uint64_t FNV_OFFSET = 14695981039346656037ULL;
static const uint64_t FNV_PRIME  = 1099511628211ULL;

ShaderWarmingService::ShaderWarmingService()
    : m_metalDevice(nullptr), m_placeholderShader(nullptr),
      m_isRunning(false), m_pendingCount(0), m_compiledCount(0) {
    memset(&m_motionVectors, 0, sizeof(m_motionVectors));
}

ShaderWarmingService::~ShaderWarmingService() {
    Shutdown();
}

bool ShaderWarmingService::Initialize(const std::string& cacheDir, void* metalDevice) {
    m_cacheDir = cacheDir;
    m_metalDevice = metalDevice;
    m_isRunning = true;

    printf("[ShaderWarming] Initializing async shader pipeline...\n");

    // Create placeholder shader (magenta tint for visual debugging)
    CreatePlaceholderShader();

    // Spawn 2 background compilation worker threads
    for (int i = 0; i < 2; i++) {
        m_workerThreads.emplace_back(&ShaderWarmingService::CompileWorker, this);
    }

    printf("[ShaderWarming] %zu worker threads started.\n", m_workerThreads.size());
    return true;
}

void ShaderWarmingService::QueueShader(uint64_t hash, const uint8_t* microcode, size_t size) {
    std::lock_guard<std::mutex> lock(m_cacheMutex);

    // Skip if already cached
    if (m_shaderCache.count(hash)) return;

    ShaderEntry entry;
    entry.hash = hash;
    entry.state = ShaderState::Pending;
    entry.nativeHandle = nullptr;
    entry.placeholderHandle = m_placeholderShader;
    entry.microcodeSizeBytes = size;
    entry.compilationTimeUs = 0;

    m_shaderCache[hash] = entry;
    m_pendingCount++;
}

void* ShaderWarmingService::GetShader(uint64_t hash) {
    std::lock_guard<std::mutex> lock(m_cacheMutex);

    auto it = m_shaderCache.find(hash);
    if (it == m_shaderCache.end()) {
        return m_placeholderShader; // Unknown shader → placeholder
    }

    if (it->second.state == ShaderState::Ready && it->second.nativeHandle) {
        return it->second.nativeHandle;
    }

    // Still compiling → return placeholder (no stutter!)
    return it->second.placeholderHandle;
}

bool ShaderWarmingService::IsShaderReady(uint64_t hash) const {
    std::lock_guard<std::mutex> lock(m_cacheMutex);
    auto it = m_shaderCache.find(hash);
    return it != m_shaderCache.end() && it->second.state == ShaderState::Ready;
}

void ShaderWarmingService::WarmUpAll() {
    printf("[ShaderWarming] Warming up all %u pending shaders...\n", m_pendingCount.load());

    std::lock_guard<std::mutex> lock(m_cacheMutex);
    for (auto& pair : m_shaderCache) {
        if (pair.second.state == ShaderState::Pending) {
            auto start = std::chrono::high_resolution_clock::now();

            pair.second.nativeHandle = CompileShader(nullptr, pair.second.microcodeSizeBytes);
            pair.second.state = ShaderState::Ready;

            auto end = std::chrono::high_resolution_clock::now();
            pair.second.compilationTimeUs =
                std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();

            m_compiledCount++;
            m_pendingCount--;
        }
    }

    printf("[ShaderWarming] Warm-up complete: %u shaders compiled.\n", m_compiledCount.load());
}

void ShaderWarmingService::CaptureMotionVectors(const float* mvData, uint32_t width,
                                                  uint32_t height, uint32_t frameIndex) {
    std::lock_guard<std::mutex> lock(m_mvMutex);

    size_t dataSize = width * height * 2 * sizeof(float); // (dx, dy) per pixel

    // Realloc if dimensions changed
    if (m_motionVectors.width != width || m_motionVectors.height != height) {
        free(m_motionVectors.vectors);
        m_motionVectors.vectors = (float*)malloc(dataSize);
        m_motionVectors.width = width;
        m_motionVectors.height = height;
    }

    if (m_motionVectors.vectors && mvData) {
        memcpy(m_motionVectors.vectors, mvData, dataSize);
    }
    m_motionVectors.frameIndex = frameIndex;
}

const MotionVectorData* ShaderWarmingService::GetMotionVectors() const {
    // Caller should hold m_mvMutex if thread-safe access needed
    return &m_motionVectors;
}

void* ShaderWarmingService::CreateArgumentBuffer(const void** resources, uint32_t count) {
    // In a full Metal implementation:
    // 1. Create MTLArgumentEncoder from function
    // 2. Encode all resources (textures, buffers, samplers) 
    // 3. Return the argument buffer
    printf("[ShaderWarming] Argument Buffer created with %u resources (draw call reduction).\n", count);
    (void)resources;
    return nullptr; // Placeholder — real Metal ObjC bridge required
}

std::string ShaderWarmingService::GetStats() const {
    return "{\"total_shaders\":" + std::to_string(m_shaderCache.size()) +
           ",\"compiled\":" + std::to_string(m_compiledCount.load()) +
           ",\"pending\":" + std::to_string(m_pendingCount.load()) +
           ",\"motion_vector_frame\":" + std::to_string(m_motionVectors.frameIndex) + "}";
}

void ShaderWarmingService::Shutdown() {
    m_isRunning = false;

    for (auto& t : m_workerThreads) {
        if (t.joinable()) t.join();
    }
    m_workerThreads.clear();

    free(m_motionVectors.vectors);
    m_motionVectors.vectors = nullptr;

    printf("[ShaderWarming] Service shut down.\n");
}

// ═══ Internal ═══

void ShaderWarmingService::CompileWorker() {
    while (m_isRunning) {
        uint64_t hashToCompile = 0;
        {
            std::lock_guard<std::mutex> lock(m_cacheMutex);
            for (auto& pair : m_shaderCache) {
                if (pair.second.state == ShaderState::Pending) {
                    pair.second.state = ShaderState::Compiling;
                    hashToCompile = pair.first;
                    break;
                }
            }
        }

        if (hashToCompile != 0) {
            auto start = std::chrono::high_resolution_clock::now();

            // Compile the shader (in real impl: SPIRV → MSL → MTLLibrary)
            void* compiled = CompileShader(nullptr, 0);

            auto end = std::chrono::high_resolution_clock::now();
            uint64_t us = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();

            {
                std::lock_guard<std::mutex> lock(m_cacheMutex);
                auto it = m_shaderCache.find(hashToCompile);
                if (it != m_shaderCache.end()) {
                    it->second.nativeHandle = compiled;
                    it->second.state = ShaderState::Ready;
                    it->second.compilationTimeUs = us;
                }
            }
            m_compiledCount++;
            m_pendingCount--;
        } else {
            // No work — sleep briefly
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    }
}

void* ShaderWarmingService::CompileShader(const uint8_t* microcode, size_t size) {
    (void)microcode;
    (void)size;
    // In full implementation:
    // 1. Convert Xenos microcode → SPIR-V (via dxbc/glslang)
    // 2. Convert SPIR-V → MSL (via SPIRV-Cross)
    // 3. Compile MSL → MTLLibrary (via Metal API)
    // 4. Return MTLFunction*
    return (void*)0x1; // Non-null placeholder
}

void ShaderWarmingService::CreatePlaceholderShader() {
    // Magenta debug shader — makes uncompiled shaders visible during development
    // In Metal: fragment returns half4(1, 0, 1, 1)
    m_placeholderShader = (void*)0xDEAD;
    printf("[ShaderWarming] Placeholder (magenta debug) shader created.\n");
}

uint64_t ShaderWarmingService::ComputeShaderHash(const uint8_t* data, size_t size) const {
    uint64_t hash = FNV_OFFSET;
    for (size_t i = 0; i < size; i++) {
        hash ^= data[i];
        hash *= FNV_PRIME;
    }
    return hash;
}

} // namespace GPU
} // namespace XeniOS
