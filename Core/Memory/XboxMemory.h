#ifndef XBOX_MEMORY_H
#define XBOX_MEMORY_H

#include <stddef.h>
#include <stdint.h>

namespace XeniOS {
namespace Memory {

/**
 * Xbox 360 memory subsystem — 512MB unified GDDR3 RAM.
 * Backed by Xenia static libraries at link time.
 */
class XboxMemory {
public:
  XboxMemory();
  ~XboxMemory();

  bool Initialize();

  uint32_t Read32(uint32_t address);
  void Write32(uint32_t address, uint32_t value);
  void *TranslateAddress(uint32_t guestAddress);

  uint8_t *GetMemBase() const;
  size_t GetRamSize() const;

private:
  uint8_t *m_physicalRamBase;
  size_t m_ramSize;
};

} // namespace Memory
} // namespace XeniOS

#endif // XBOX_MEMORY_H
