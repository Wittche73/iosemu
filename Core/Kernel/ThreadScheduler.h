#ifndef THREAD_SCHEDULER_H
#define THREAD_SCHEDULER_H

#include <stdint.h>
#include <pthread.h>
#include <string>

namespace XeniOS {
namespace Kernel {

/// Xbox 360 Xenon thread descriptor
struct XenonThread {
    uint32_t threadId;      // Xbox thread ID
    int      xenonCore;     // Xbox Xenon core (0, 1, 2)
    int      hwThread;      // Hardware thread within core (0 or 1)
    pthread_t nativeThread; // iOS pthread handle
    int      qosClass;     // Apple QoS class assigned
    bool     isActive;
    const char* label;      // "gpu_thread", "audio_thread", etc.
};

/**
 * ThreadScheduler — Xbox 3-core (6-thread) → iPhone P/E-core distribution.
 *
 * Xbox 360 Xenon CPU:
 *   Core 0 (HW thread 0,1): Usually main game logic + AI
 *   Core 1 (HW thread 2,3): Physics + rendering submission
 *   Core 2 (HW thread 4,5): Audio + I/O + network
 *
 * iPhone ARM64 Strategy:
 *   P-cores (Performance): Game logic, physics, rendering — QOS_CLASS_USER_INTERACTIVE
 *   E-cores (Efficiency):  Audio, I/O, network — QOS_CLASS_UTILITY / BACKGROUND
 *
 * This scheduler maps Xenon threads to appropriate iOS QoS classes for
 * optimal P/E-core distribution.
 */
class ThreadScheduler {
public:
    ThreadScheduler();
    ~ThreadScheduler();

    /// Initialize the scheduler.
    bool Initialize();

    /// Create a mapped thread with QoS affinity.
    uint32_t CreateThread(int xenonCore, int hwThread, const char* label,
                          void* (*entryPoint)(void*), void* arg);

    /// Suspend a thread by Xbox thread ID.
    void SuspendThread(uint32_t threadId);

    /// Resume a thread.
    void ResumeThread(uint32_t threadId);

    /// Terminate a thread.
    void TerminateThread(uint32_t threadId);

    /// Get the number of active threads.
    int GetActiveThreadCount() const;

    /// Get statistics.
    std::string GetStats() const;

    /// Shutdown all threads.
    void ShutdownAll();

private:
    static const int MAX_THREADS = 8; // 6 Xenon + 2 extra
    XenonThread m_threads[MAX_THREADS];
    int m_threadCount;
    uint32_t m_nextThreadId;

    int MapXenonCoreToQoS(int xenonCore) const;
    void ApplyQoS(pthread_t thread, int qosClass);
};

} // namespace Kernel
} // namespace XeniOS

#endif // THREAD_SCHEDULER_H
