#ifndef XBOX_MEMORY_H
#define XBOX_MEMORY_H

#include <stddef.h>
#include <stdint.h>
#include <memory>

// Forward declare Xenia's Memory class
namespace xe {
class Memory;
}

namespace XeniOS {
namespace Memory {

/**
 * Wrapper around xe::Memory — the real Xbox 360 memory subsystem.
 * Manages 512MB unified GDDR3 with virtual/physical heaps.
 */
class XboxMemory {
public:
  XboxMemory();
  ~XboxMemory();

  // Initializes the real Xenia memory system
  bool Initialize();

  // Read/Write operations enforcing Big-Endian conversion
  uint32_t Read32(uint32_t address);
  void Write32(uint32_t address, uint32_t value);

  // Translate Xbox virtual address to host pointer
  void *TranslateAddress(uint32_t guestAddress);

  // Get the underlying xe::Memory instance
  xe::Memory *GetXeMemory() const { return m_xeMemory.get(); }

private:
  std::unique_ptr<xe::Memory> m_xeMemory;
};

} // namespace Memory
} // namespace XeniOS

#endif // XBOX_MEMORY_H
