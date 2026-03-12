#include "XboxMemory.h"
#include <stdio.h>

#include "xenia/memory.h"
#include "xenia/base/byte_swap.h"

namespace XeniOS {
namespace Memory {

XboxMemory::XboxMemory() : m_xeMemory(std::make_unique<xe::Memory>()) {}

XboxMemory::~XboxMemory() = default;

bool XboxMemory::Initialize() {
  printf("[XeniOS Memory] Initializing real xe::Memory subsystem...\n");

  if (!m_xeMemory->Initialize()) {
    printf("[XeniOS Memory] FATAL: xe::Memory::Initialize() failed.\n");
    return false;
  }

  printf("[XeniOS Memory] xe::Memory initialized. Virtual base: %p, Physical "
         "base: %p\n",
         m_xeMemory->virtual_membase(), m_xeMemory->physical_membase());
  return true;
}

uint32_t XboxMemory::Read32(uint32_t address) {
  auto ptr = m_xeMemory->TranslateVirtual<uint32_t *>(address);
  if (!ptr)
    return 0;
  return xe::byte_swap(*ptr); // Big-Endian -> Little-Endian
}

void XboxMemory::Write32(uint32_t address, uint32_t value) {
  auto ptr = m_xeMemory->TranslateVirtual<uint32_t *>(address);
  if (!ptr)
    return;
  *ptr = xe::byte_swap(value); // Little-Endian -> Big-Endian
}

void *XboxMemory::TranslateAddress(uint32_t guestAddress) {
  return m_xeMemory->TranslateVirtual(guestAddress);
}

} // namespace Memory
} // namespace XeniOS
