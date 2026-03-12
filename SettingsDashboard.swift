import SwiftUI

struct SettingsDashboard: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var jitEnabled = JITManager.shared.isJITAvailable()
    @State private var dxvkHud = "compiler"
    @State private var relativeMouse = false
    @State private var jitAggressiveness = 1 // 0: Safe, 1: Fast, 2: Aggressive
    @State private var selectedEngine = UserDefaults.standard.string(forKey: "selectedEmulatorEngine") ?? "box64"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Emülatör Motoru").font(.headline)) {
                    Picker("Ana Motor", selection: $selectedEngine) {
                        Text("Box64 (Önerilen)").tag("box64")
                        Text("FEX-Emu (Fallback)").tag("fex")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedEngine) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "selectedEmulatorEngine")
                    }
                    
                    Text("Box64 çoğu oyun için daha uyumludur. Bazı özel durumlarda FEX-Emu daha iyi performans verebilir.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Sistem ve JIT").font(.headline)) {
                    HStack {
                        Label("JIT Durumu", systemImage: "bolt.fill")
                        Spacer()
                        Text(jitEnabled ? "Aktif" : "Pasif")
                            .foregroundColor(jitEnabled ? .green : .red)
                            .fontWeight(.bold)
                    }
                    
                    Picker("JIT Agresifliği", selection: $jitAggressiveness) {
                        Text("Güvenli").tag(0)
                        Text("Hızlı").tag(1)
                        Text("Agresif").tag(2)
                    }
                    .onChange(of: jitAggressiveness) { newValue in
                        PerformanceManager.shared.setJITLevel(newValue)
                    }
                }
                
                Section(header: Text("Girdi (Input)").font(.headline)) {
                    Toggle("Relative Mouse (FPS Modu)", isOn: $relativeMouse)
                        .onChange(of: relativeMouse) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "relativeMouseMode")
                        }
                    
                    Text("FPS oyunlarında kamerayı kontrol etmek için bu modu açın.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Grafik (DXVK/Metal)").font(.headline)) {
                    Picker("DXVK HUD", selection: $dxvkHud) {
                        Text("Kapalı").tag("0")
                        Text("Sadece FPS").tag("fps")
                        Text("Detaylı").tag("compiler")
                        Text("Full").tag("full")
                    }
                    .onChange(of: dxvkHud) { newValue in
                        setenv("DXVK_HUD", newValue, 1)
                    }
                    
                    Toggle("MetalFX Upscaling", isOn: .constant(true))
                }
                
                Section(header: Text("Bağımlılıklar (Winetricks)").font(.headline)) {
                    Button(action: {
                        // Basit test: d3dx9 yükle (Aktif prefix varsayılıyor veya seçilmesi gerekiyor)
                        print("🛠 Winetricks: d3dx9 kurulumu tetiklendi.")
                    }) {
                        Label("DirectX 9 Kütüphanelerini Kur", systemImage: "shippingbox.fill")
                    }
                    
                    Button(action: {
                        print("🛠 Winetricks: vcrun2015 kurulumu tetiklendi.")
                    }) {
                        Label("VC++ 2015 Redistributable Kur", systemImage: "shippingbox.fill")
                    }
                    
                    Text("Oyun düzgün açılmıyorsa bu paketleri kurun.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Konsol Ayarları")
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
