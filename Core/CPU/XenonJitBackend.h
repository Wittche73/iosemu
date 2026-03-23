#ifndef XENON_JIT_BACKEND_H
#define XENON_JIT_BACKEND_H

#include <stdint.h>

namespace XeniOS {
namespace CPU {

class XenonJitBackend {
public:
  XenonJitBackend();
  ~XenonJitBackend();

  bool Initialize();
  int Execute(uint32_t entryAddress);
  void Stop();

private:
  bool m_isRunning;
};

} // namespace CPU
} // namespace XeniOS

#endif // XENON_JIT_BACKEND_H
