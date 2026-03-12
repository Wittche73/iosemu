#ifndef XENON_JIT_BACKEND_H
#define XENON_JIT_BACKEND_H

#include <stdint.h>
#include <string>

// Forward declarations
namespace xe {
class Memory;
namespace cpu {
class Processor;
} // namespace cpu
} // namespace xe

namespace XeniOS {
namespace Memory {
class XboxMemory;
}

namespace CPU {

/**
 * Wrapper around xe::cpu::Processor — the real Xenon PowerPC JIT backend.
 * Translates PPC instructions to ARM64 via Xenia's backend.
 */
class XenonJitBackend {
public:
  XenonJitBackend();
  ~XenonJitBackend();

  // Initializes the real Xenia CPU processor
  bool Initialize();
  bool Initialize(XeniOS::Memory::XboxMemory *memory);

  // Executes from the given guest address
  int Execute(uint32_t entryAddress);

  // Stops the CPU
  void Stop();

private:
  bool m_isRunning;
};

} // namespace CPU
} // namespace XeniOS

#endif // XENON_JIT_BACKEND_H
