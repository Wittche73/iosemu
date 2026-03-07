import SwiftUI

struct SettingsDashboard: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var jitEnabled = JITManager.shared.isJITAvailable()
    @State private var dxvkHud = "compiler"
    @State private var audioLatency: Double = 0.005
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sistem Durumu").font(.headline)) {
                    HStack {
                        Label("JIT Durumu", systemImage: "bolt.fill")
                        Spacer()
                        Text(jitEnabled ? "Aktif" : "Pasif")
                            .foregroundColor(jitEnabled ? .green : .red)
                            .fontWeight(.bold)
                    }
                }
                
                Section(header: Text("Grafik Ayarları (DXVK)").font(.headline)) {
                    Picker("DXVK HUD", selection: $dxvkHud) {
                        Text("Kapalı").tag("0")
                        Text("Sadece FPS").tag("fps")
                        Text("Detaylı (Compiler)").tag("compiler")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Toggle("Vulkan Katmanını Zorla", isOn: .constant(true))
                }
                
                Section(header: Text("Ses Ayarları").font(.headline)) {
                    Slider(value: $audioLatency, in: 0.001...0.020, step: 0.001) {
                        Text("Gecikme: \(Int(audioLatency * 1000))ms")
                    }
                    Text("Hedef Gecikme: \(Int(audioLatency * 1000))ms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Performans Ayarları")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
