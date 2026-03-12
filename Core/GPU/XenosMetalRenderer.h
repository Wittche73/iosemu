#ifndef XENOS_METAL_RENDERER_H
#define XENOS_METAL_RENDERER_H

#include <stdint.h>

// Forward declare to avoid circular include
namespace XeniOS { namespace GPU { class ShaderWarmingService; } }

namespace XeniOS {
namespace GPU {

/**
 * Xenos (ATI) GPU → Apple Metal translation renderer.
 * Integrates ShaderWarmingService for async shader compilation
 * and MetalFX motion vector capture.
 */
class XenosMetalRenderer {
public:
    XenosMetalRenderer();
    ~XenosMetalRenderer();

    // Attach the renderer to a given metal view/layer pointer
    bool Initialize(void* metalLayer);

    // Write to a GPU register
    void WriteRegister(uint32_t regKey, uint32_t value);

    // Triggers the execution of the current command buffer
    void ExecuteCommandBuffer(uint32_t physicalAddress, uint32_t size);

    // Swaps the front and back render buffers to present the frame
    void PresentFrame();

    // Get the shader warming service
    ShaderWarmingService* GetShaderService() const { return m_shaderService; }

private:
    void* m_metalDevice;
    void* m_commandQueue;
    ShaderWarmingService* m_shaderService;

    // Platform specific setup to bridge C++ with Objective-C Metal APIs
    bool SetupMetalPipeline();
};

} // namespace GPU
} // namespace XeniOS

#endif // XENOS_METAL_RENDERER_H
