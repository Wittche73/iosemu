#include "XboxMemory.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>

namespace XeniOS {
namespace Memory {

XboxMemory::XboxMemory()
    : m_physicalRamBase(nullptr), m_ramSize(512 * 1024 * 1024) {
  // Xbox 360 has 512MB of unified GDDR3 RAM
}

XboxMemory::~XboxMemory() {
  if (m_physicalRamBase) {
    munmap(m_physicalRamBase, m_ramSize);
  }
}

bool XboxMemory::Initialize() {
  printf("[XeniOS Memory] Allocating 512MB Unified Memory Architecture...\n");

  // Allocate 512MB contiguous memory block
  m_physicalRamBase = (uint8_t *)mmap(NULL, m_ramSize, PROT_READ | PROT_WRITE,
                                      MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

  if (m_physicalRamBase == MAP_FAILED) {
    printf("[XeniOS Memory] FATAL: Failed to allocate 512MB RAM.\n");
    m_physicalRamBase = nullptr;
    return false;
  }

  printf("[XeniOS Memory] RAM Allocated at: %p (%zu MB)\n",
         m_physicalRamBase, m_ramSize / (1024 * 1024));
  return true;
}

uint32_t XboxMemory::Read32(uint32_t address) {
  if (!m_physicalRamBase || address > m_ramSize - 4)
    return 0;

  // PowerPC is Big-Endian, byte-swap for ARM64 (Little-Endian)
  uint32_t value = *(uint32_t *)(m_physicalRamBase + address);
  return __builtin_bswap32(value);
}

void XboxMemory::Write32(uint32_t address, uint32_t value) {
  if (!m_physicalRamBase || address > m_ramSize - 4)
    return;

  *(uint32_t *)(m_physicalRamBase + address) = __builtin_bswap32(value);
}

void *XboxMemory::TranslateAddress(uint32_t guestAddress) {
  if (!m_physicalRamBase || guestAddress > m_ramSize)
    return nullptr;
  return (void *)(m_physicalRamBase + guestAddress);
}

uint8_t *XboxMemory::GetMemBase() const {
  return m_physicalRamBase;
}

size_t XboxMemory::GetRamSize() const {
  return m_ramSize;
}

} // namespace Memory
} // namespace XeniOS
