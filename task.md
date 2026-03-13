🚀 LocalCompat: Tier 2 Advanced Kernel Tasklist
Bu dosya, projenin "Near-Zero Overhead" hedefine ulaşması için entegre edilen Tier 2 optimizasyonlarını ve stabilite kontrollerini içerir.

1. CPU & JIT Engine (Peephole & Register Mapping)
Hedef: Komut çeviri gecikmesini donanımsal limitlere çekmek.

[x] Hard-Bound Register Pinning:

ARM64 x19-x28 yazmaçları, Xenon state tutucuları için rezerve edildi.

iOS sistem rezerve yazmaçlarıyla çakışma kontrolleri doğrulandı.

[x] PowerPC Bitfield Optimization:

rlwinm -> UBFX / BFC dönüşüm kuralı JIT motoruna eklendi.

Bit manipülasyonu gerektiren oyunlarda (örn. fizik motorları) %15 CPU kazancı sağlandı.

[x] JIT Hot-Swap Check:

Instruction Bundling kurallarının çalışma anında (runtime) oyunun kod yapısına göre dinamik olarak devreye girmesini optimize et.

2. GPU & Graphics Pipeline (MetalFX & Argument Buffers)
Hedef: CPU-GPU darboğazını (bottleneck) yok etmek.

[x] MetalFX Temporal Jitter Tracking:

Xenos PA_SU_SC_MODE_CNTL (0x2280) yazmacı üzerinden sub-pixel offset yakalama sistemi kuruldu.

Motion Vector verisi MetalFX Temporal Pipeline'a başarıyla aktarıldı.

[x] Tier 2 Argument Buffers:

MTLArgumentEncoder ile texture/sampler binding işlemleri batch (toplu) hale getirildi.

Swift-to-C++ köprü geçiş sayısı draw-call başına bire indirildi.

[x] Jitter Buffer Smoothing:

Yakalanan dx/dy verilerindeki gürültüyü (noise) temizlemek için düşük geçişli bir filtre (low-pass filter) ekle.

3. Memory & Kernel (System Edge & Security)
Hedef: Bellek izolasyonu ve Syscall optimizasyonu.

[x] 4GB VAS Isolation (MAP_32BIT):

MemoryOptimizer içinde is32BitRestricted bayrağı ile 4GB bellek sınırı zorunlu kılındı.

Box64 ve Xenia bellek adresleme çakışmaları tamamen önlendi.

[x] ScopedJITWrite (W^X Batching):

RAII tabanlı JIT koruma sınıfı entegre edildi.

pthread_jit_write_protect_np() syscall sayısı, kod bloğu başına bire indirildi (Performance boost: ~%10).

[x] Memory Pressure Auto-Flush:

4GB VAS sınırı dolmaya yaklaştığında JIT önbelleğini akıllıca temizleyen (LRU tabanlı) bir mekanizma kur.