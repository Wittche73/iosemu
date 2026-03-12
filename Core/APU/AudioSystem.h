#ifndef AUDIO_SYSTEM_H
#define AUDIO_SYSTEM_H

#include <stddef.h>

namespace XeniOS {
namespace APU {

/**
 * Xbox XMA Audio and XAudio2 Emulation Subsystem.
 */
class AudioSystem {
public:
    AudioSystem();
    ~AudioSystem();

    // Initializes the audio renderer (e.g. CoreAudio on iOS)
    bool Initialize();

    // Processes an XMA audio buffer
    void SubmitAudioBuffer(void* data, size_t size);

private:
    float m_masterVolume;
};

} // namespace APU
} // namespace XeniOS

#endif // AUDIO_SYSTEM_H
