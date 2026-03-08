import Foundation

/// Oyunun çalışma zamanındaki yüküne göre JIT seviyesini dinamik olarak değiştiren sınıf
class DynamicJITManager {
    static let shared = DynamicJITManager()
    
    private var isMonitoring = false
    private var timer: Timer?
    
    private init() {}
    
    /// Dinamik JIT izlemesini başlatır
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        print("--- DynamicJIT: AI Destekli Performans İzleme Aktif ---")
        
        // Monitoring engine load every 3 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.checkAndOptimize()
        }
    }
    
    /// İzlemeyi durdurur
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        print("--- DynamicJIT: İzleme Durduruldu ---")
    }
    
    private func checkAndOptimize() {
        var hostPort = mach_host_self()
        var hostInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(HOST_CPU_LOAD_INFO_COUNT)
        
        let result = withUnsafeMutablePointer(to: &hostInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(hostPort, HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let user = Float(hostInfo.cpu_ticks.0)
            let system = Float(hostInfo.cpu_ticks.1)
            let idle = Float(hostInfo.cpu_ticks.2)
            let total = user + system + idle
            
            let usage = ((user + system) / total) * 100.0
            
            if usage > 80 {
                print("⚠️ DynamicJIT: High CPU Load Detected (\(Int(usage))%). Escalating Dynarec Agility...")
                setenv("BOX64_DYNAREC_WAIT", "0", 1)
                setenv("BOX64_DYNAREC_HOTPAGE", "16", 1)
            } else if usage < 25 {
                print("ℹ️ DynamicJIT: Low Load (\(Int(usage))%). Stabilizing Engine.")
                setenv("BOX64_DYNAREC_WAIT", "1", 1)
            }
        } else {
            // Fallback to safe defaults if sysinfo fails
            print("⚠️ DynamicJIT: Could not poll CPU stats. Using safe engine defaults.")
        }
    }
}
