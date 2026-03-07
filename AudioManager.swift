import Foundation
#if os(iOS)
import AVFoundation
#endif

/// Ses sistemini (OpenAL/SDL_Audio) yöneten sınıf
class AudioManager {
    static let shared = AudioManager()
    
    private init() {}
    
    /// iOS ses oturumunu (Audio Session) oyun için yapılandırır
    func setupAudioSession() -> Bool {
        print("--- AudioManager: iOS Ses Oturumu Yapılandırılıyor ---")
        
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .gameChat, options: [])
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
            print("✅ AudioManager: Ses oturumu aktif hale getirildi (iOS Low Latency).")
            return true
        } catch {
            print("❌ AudioManager: Ses oturumu hatası: \(error)")
            return false
        }
        #else
        print("ℹ️ AudioManager: Linux/Simulator ortamı, AVAudioSession atlandı.")
        return true
        #endif
    }
    
    /// C++ tarafındaki ses motorunu ilklendirir
    func initializeAudioEngine() -> Bool {
        if init_audio() {
            print("✅ AudioManager: OpenAL/SDL ses motoru ilklendirildi.")
            return true
        } else {
            print("❌ AudioManager: Ses motoru ilklendirme hatası!")
            return false
        }
    }
}
