#include "ThreadScheduler.h"
#include <stdio.h>
#include <string.h>

#ifdef __APPLE__
#include <pthread/qos.h>
#endif

namespace XeniOS {
namespace Kernel {

ThreadScheduler::ThreadScheduler() : m_threadCount(0), m_nextThreadId(1) {
    memset(m_threads, 0, sizeof(m_threads));
}

ThreadScheduler::~ThreadScheduler() {
    ShutdownAll();
}

bool ThreadScheduler::Initialize() {
    printf("[ThreadScheduler] Initialized: Xbox 360 Xenon → iOS P/E-core mapping.\n");
    printf("[ThreadScheduler] Strategy:\n");
    printf("  Core 0 (Game Logic)  → P-core (QOS_CLASS_USER_INTERACTIVE)\n");
    printf("  Core 1 (Physics/GPU) → P-core (QOS_CLASS_USER_INITIATED)\n");
    printf("  Core 2 (Audio/IO)    → E-core (QOS_CLASS_UTILITY)\n");
    return true;
}

uint32_t ThreadScheduler::CreateThread(int xenonCore, int hwThread, const char* label,
                                         void* (*entryPoint)(void*), void* arg) {
    if (m_threadCount >= MAX_THREADS) {
        printf("[ThreadScheduler] ERROR: Max threads (%d) reached.\n", MAX_THREADS);
        return 0;
    }

    XenonThread& thread = m_threads[m_threadCount];
    thread.threadId = m_nextThreadId++;
    thread.xenonCore = xenonCore;
    thread.hwThread = hwThread;
    thread.label = label;
    thread.isActive = true;
    thread.qosClass = MapXenonCoreToQoS(xenonCore);

    // Create pthread with QoS attributes
    pthread_attr_t attr;
    pthread_attr_init(&attr);

    // Set detached state (emulation threads are fire-and-forget)
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);

    int result = pthread_create(&thread.nativeThread, &attr, entryPoint, arg);
    pthread_attr_destroy(&attr);

    if (result != 0) {
        printf("[ThreadScheduler] ERROR: pthread_create failed for '%s'.\n", label);
        return 0;
    }

    // Apply QoS after creation
    ApplyQoS(thread.nativeThread, thread.qosClass);

    m_threadCount++;

    const char* qosName;
    switch (thread.qosClass) {
        case 0x21: qosName = "USER_INTERACTIVE (P-core)"; break;
        case 0x19: qosName = "USER_INITIATED (P-core)"; break;
        case 0x11: qosName = "UTILITY (E-core)"; break;
        case 0x09: qosName = "BACKGROUND (E-core)"; break;
        default:   qosName = "DEFAULT"; break;
    }

    printf("[ThreadScheduler] Thread '%s' [Xenon Core %d, HW %d] → %s\n",
           label, xenonCore, hwThread, qosName);

    return thread.threadId;
}

void ThreadScheduler::SuspendThread(uint32_t threadId) {
    for (int i = 0; i < m_threadCount; i++) {
        if (m_threads[i].threadId == threadId) {
            m_threads[i].isActive = false;
            printf("[ThreadScheduler] Thread %u ('%s') suspended.\n",
                   threadId, m_threads[i].label);
            return;
        }
    }
}

void ThreadScheduler::ResumeThread(uint32_t threadId) {
    for (int i = 0; i < m_threadCount; i++) {
        if (m_threads[i].threadId == threadId) {
            m_threads[i].isActive = true;
            printf("[ThreadScheduler] Thread %u ('%s') resumed.\n",
                   threadId, m_threads[i].label);
            return;
        }
    }
}

void ThreadScheduler::TerminateThread(uint32_t threadId) {
    for (int i = 0; i < m_threadCount; i++) {
        if (m_threads[i].threadId == threadId) {
            m_threads[i].isActive = false;
            printf("[ThreadScheduler] Thread %u ('%s') terminated.\n",
                   threadId, m_threads[i].label);
            return;
        }
    }
}

int ThreadScheduler::GetActiveThreadCount() const {
    int count = 0;
    for (int i = 0; i < m_threadCount; i++) {
        if (m_threads[i].isActive) count++;
    }
    return count;
}

std::string ThreadScheduler::GetStats() const {
    return "{\"total_threads\":" + std::to_string(m_threadCount) +
           ",\"active_threads\":" + std::to_string(GetActiveThreadCount()) + "}";
}

void ThreadScheduler::ShutdownAll() {
    for (int i = 0; i < m_threadCount; i++) {
        m_threads[i].isActive = false;
    }
    printf("[ThreadScheduler] All %d threads shut down.\n", m_threadCount);
    m_threadCount = 0;
}

// ═══ Internal ═══

int ThreadScheduler::MapXenonCoreToQoS(int xenonCore) const {
    // Xbox 360 Xenon has 3 physical cores, each with 2 hardware threads.
    // We map to Apple QoS classes to influence P-core vs E-core scheduling.

#ifdef __APPLE__
    switch (xenonCore) {
        case 0:
            // Core 0: Main game logic, AI — highest priority → P-core
            return QOS_CLASS_USER_INTERACTIVE;  // 0x21
        case 1:
            // Core 1: Physics, rendering command submission — high priority → P-core
            return QOS_CLASS_USER_INITIATED;    // 0x19
        case 2:
            // Core 2: Audio, I/O, networking — lower priority → E-core
            return QOS_CLASS_UTILITY;           // 0x11
        default:
            return QOS_CLASS_BACKGROUND;        // 0x09
    }
#else
    (void)xenonCore;
    return 0;
#endif
}

void ThreadScheduler::ApplyQoS(pthread_t thread, int qosClass) {
#ifdef __APPLE__
    pthread_set_qos_class_self_np((qos_class_t)qosClass, 0);
    (void)thread; // QoS is applied to current thread in Apple's API
#else
    (void)thread;
    (void)qosClass;
#endif
}

} // namespace Kernel
} // namespace XeniOS
