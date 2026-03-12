#ifndef XBOX_KERNEL_H
#define XBOX_KERNEL_H

#include <stdint.h>
#include <memory>
#include <string>

// Forward declarations
namespace xe {
class Memory;
namespace kernel {
class KernelState;
class XModule;
} // namespace kernel
} // namespace xe

namespace XeniOS {
namespace Memory {
class XboxMemory;
}

namespace Kernel {

/**
 * Wrapper around xe::kernel::KernelState — the real Xbox 360 kernel HLE.
 */
class XboxKernel {
public:
  XboxKernel();
  ~XboxKernel();

  // Boot the kernel with the given memory subsystem
  bool InitializeOS();
  bool InitializeOS(XeniOS::Memory::XboxMemory *memory);

  // Loads a .xex module
  bool LoadModule(const std::string &modulePath);

  // HLE syscall dispatch
  void HandleSyscall(uint32_t syscallId);

  xe::kernel::KernelState *GetKernelState() const {
    return m_kernelState.get();
  }

private:
  std::unique_ptr<xe::kernel::KernelState> m_kernelState;
};

} // namespace Kernel
} // namespace XeniOS

#endif // XBOX_KERNEL_H
