#ifndef XBOX_KERNEL_H
#define XBOX_KERNEL_H

#include <stdint.h>
#include <string>

namespace XeniOS {
namespace Kernel {

class XboxKernel {
public:
  XboxKernel();
  ~XboxKernel();

  bool InitializeOS();
  bool LoadModule(const std::string &modulePath);
  void HandleSyscall(uint32_t syscallId);
};

} // namespace Kernel
} // namespace XeniOS

#endif // XBOX_KERNEL_H
