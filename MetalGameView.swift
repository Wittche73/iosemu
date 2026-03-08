import SwiftUI
import MetalKit

/// Oyunun render edildiği Metal tabanlı View
struct MetalGameView: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.backgroundColor = .black
        mtkView.isPaused = false
        mtkView.enableSetNeedsDisplay = false
        
        // Layer'ı native tarafa gönder (Basitleştirilmiş simülasyon/bridge)
        if let layer = mtkView.layer as? CAMetalLayer {
            set_metal_layer(UnsafeMutableRawPointer(Unmanaged.passUnretained(layer).toOpaque()))
        }
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {}
}

// C++ Bridge için yeni fonksiyon tanımı (Bridging-Header'a eklenecek)
// void set_metal_layer(void* layer);
