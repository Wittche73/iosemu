#ifndef SHADER_WARMING_SERVICE_H
#define SHADER_WARMING_SERVICE_H

#include <stdint.h>
#include <string>
#include <vector>
#include <unordered_map>
#include <mutex>
#include <atomic>
#include <thread>

namespace XeniOS {
namespace GPU {

/// Shader compilation state
enum class ShaderState {
    Pending,      // Queued for compilation
    Compiling,    // Being compiled on background thread
    Ready,        // Compiled and ready to use
    Failed        // Compilation failed, using placeholder
};

/// A single shader program entry
struct ShaderEntry {
    uint64_t hash;            // Hash of shader source/microcode
    ShaderState state;
    void* nativeHandle;       // Metal shader function pointer (MTLFunction*)
    void* placeholderHandle;  // Fallback shader while compiling
    size_t microcodeSizeBytes;
    uint64_t compilationTimeUs; // Microseconds to compile
};

/// Motion vector data for MetalFX Temporal upscaling
struct MotionVectorData {
    float* vectors;           // Interleaved (dx, dy) pairs per pixel
    uint32_t width;
    uint32_t height;
    uint32_t frameIndex;
};

/**
 * ShaderWarmingService — Asynchronous shader compilation pipeline.
 *
 * 1. Background Compilation: Shader'lar arka plan thread'inde derlenir.
 *    Ana thread donması sıfırdır.
 * 2. Placeholder Fallback: Derlenmemiş shader yerine basit fallback shader
 *    kullanılır (magenta tint ile görselleştirilir).
 * 3. Motion Vector Capture: MetalFX Temporal Upscaling için hareket
 *    vektörlerini Xenos/DirectX katmanından yakalar.
 * 4. Argument Buffers: Draw call sayısını azaltmak için Metal Argument
 *    Buffer'ları ile kaynak gruplama.
 */
class ShaderWarmingService {
public:
    ShaderWarmingService();
    ~ShaderWarmingService();

    /// Initialize the service with a cache directory and Metal device.
    bool Initialize(const std::string& cacheDir, void* metalDevice);

    /// Queue a shader for background compilation.
    void QueueShader(uint64_t hash, const uint8_t* microcode, size_t size);

    /// Get a compiled shader. Returns placeholder if not yet ready.
    void* GetShader(uint64_t hash);

    /// Check if a shader is fully compiled.
    bool IsShaderReady(uint64_t hash) const;

    /// Warm up all queued shaders (blocking, use at load screen).
    void WarmUpAll();

    /// Capture motion vectors from the current frame for MetalFX.
    void CaptureMotionVectors(const float* mvData, uint32_t width,
                              uint32_t height, uint32_t frameIndex);

    /// Get the latest motion vector data for MetalFX Temporal.
    const MotionVectorData* GetMotionVectors() const;

    /// Create a Metal Argument Buffer for resource binding optimization.
    void* CreateArgumentBuffer(const void** resources, uint32_t count);

    /// Get compilation statistics.
    std::string GetStats() const;

    /// Shutdown and release all resources.
    void Shutdown();

private:
    std::string m_cacheDir;
    void* m_metalDevice;
    void* m_placeholderShader;

    std::unordered_map<uint64_t, ShaderEntry> m_shaderCache;
    mutable std::mutex m_cacheMutex;

    // Background compilation
    std::vector<std::thread> m_workerThreads;
    std::atomic<bool> m_isRunning;
    std::atomic<uint32_t> m_pendingCount;
    std::atomic<uint32_t> m_compiledCount;

    // Motion vectors
    MotionVectorData m_motionVectors;
    mutable std::mutex m_mvMutex;

    // Internal
    void CompileWorker();
    void* CompileShader(const uint8_t* microcode, size_t size);
    void CreatePlaceholderShader();
    uint64_t ComputeShaderHash(const uint8_t* data, size_t size) const;
};

} // namespace GPU
} // namespace XeniOS

#endif // SHADER_WARMING_SERVICE_H
