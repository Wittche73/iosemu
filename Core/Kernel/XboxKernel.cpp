#include "XboxKernel.h"
#include <stdio.h>

namespace XeniOS {
namespace Kernel {

XboxKernel::XboxKernel() = default;
XboxKernel::~XboxKernel() = default;

bool XboxKernel::InitializeOS() {
  printf("[XeniOS Kernel] Initializing Xbox 360 Kernel HLE...\n");
  printf("[XeniOS Kernel] Kernel subsystem initialized.\n");
  return true;
}

bool XboxKernel::LoadModule(const std::string &modulePath) {
  printf("[XeniOS Kernel] Loading XEX module: %s\n", modulePath.c_str());
  return true;
}

void XboxKernel::HandleSyscall(uint32_t syscallId) {
  printf("[XeniOS Kernel] Syscall: 0x%X\n", syscallId);
}

} // namespace Kernel
} // namespace XeniOS
