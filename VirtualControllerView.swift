import SwiftUI

/// Oyunlar için ekran üzeri sanal kontrolcü (Overlay)
struct VirtualControllerView: View {
    @State private var joystickOffset: CGSize = .zero
    @State private var isJoystickActive: Bool = false
    
    // Tuş Kodları (XInput benzeri eşleşme için)
    private let kButtonA = 0x41 // 'A' key
    private let kButtonB = 0x42 // 'B' key
    private let kButtonX = 0x58 // 'X' key
    private let kButtonY = 0x59 // 'Y' key
    
    var body: some View {
        ZStack {
            // Sol Taraf: Joystick
            VStack {
                Spacer()
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 150, height: 150)
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                            .background(BlurView(style: .systemThinMaterialDark))
                            .clipShape(Circle())
                        
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 70, height: 70)
                            .offset(joystickOffset)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let limit: CGFloat = 40
                                        let translation = value.translation
                                        let x = max(-limit, min(limit, translation.width))
                                        let y = max(-limit, min(limit, translation.height))
                                        self.joystickOffset = CGSize(width: x, height: y)
                                        self.isJoystickActive = true
                                        
                                        // Normalize ve InputManager'a ilet (-1.0 ile 1.0 arası)
                                        InputManager.shared.handleJoystickAxis(axis: 0, value: Float(x / limit))
                                        InputManager.shared.handleJoystickAxis(axis: 1, value: Float(-y / limit))
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring()) {
                                            self.joystickOffset = .zero
                                            self.isJoystickActive = false
                                        }
                                        InputManager.shared.handleJoystickAxis(axis: 0, value: 0)
                                        InputManager.shared.handleJoystickAxis(axis: 1, value: 0)
                                    }
                            )
                    }
                    .padding(40)
                    Spacer()
                }
            }
            
            // Sağ Taraf: Aksiyon Butonları
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            ControlButton(label: "Y", color: .yellow) { pressed in
                                InputManager.shared.handleKeyPress(keyCode: kButtonY, isPressed: pressed)
                            }
                        }
                        HStack(spacing: 20) {
                            ControlButton(label: "X", color: .blue) { pressed in
                                InputManager.shared.handleKeyPress(keyCode: kButtonX, isPressed: pressed)
                            }
                            ControlButton(label: "B", color: .red) { pressed in
                                InputManager.shared.handleKeyPress(keyCode: kButtonB, isPressed: pressed)
                            }
                        }
                        HStack(spacing: 20) {
                            ControlButton(label: "A", color: .green) { pressed in
                                InputManager.shared.handleKeyPress(keyCode: kButtonA, isPressed: pressed)
                            }
                        }
                    }
                    .padding(40)
                }
            }
            
            // Üst Taraf: Menü ve Diğerleri
            VStack {
                HStack {
                    Button(action: {}) {
                        Text("MENU")
                            .font(.caption.bold())
                            .padding(8)
                            .background(BlurView(style: .systemThinMaterialDark))
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

/// Özel Buton Bileşeni
struct ControlButton: View {
    let label: String
    let color: Color
    let action: (Bool) -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Text(label)
            .font(.title2.bold())
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(
                ZStack {
                    Circle()
                        .fill(isPressed ? color.opacity(0.8) : Color.white.opacity(0.1))
                    Circle()
                        .stroke(isPressed ? color : Color.white.opacity(0.3), lineWidth: 2)
                    BlurView(style: .systemThinMaterialDark)
                        .clipShape(Circle())
                }
            )
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            action(true)
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        action(false)
                    }
            )
    }
}

/// SwiftUI için UIViewRepresentable Blur
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
