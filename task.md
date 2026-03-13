1. CPU & JIT Engine (Dynamic Orchestration)
Hedef: Kodun doğasına göre anlık optimizasyon değişimi.

[x] JIT Hot-Swap (Dynamic BundleRules):

isActive bayrağı ile BundleRule yapısı dinamik hale getirildi.

Fizik motoru veya yoğun matematiksel bloklarda optimizasyon seviyesi çalışma zamanında değiştirilebiliyor.

[x] Instruction Bundling (PPC rlwinm):

ARM64 UBFX / BFC dönüşümü stabil şekilde çalışıyor.

[x] Execution Profiler:

Hangi kuralların (BundleRules) daha sık tetiklendiğini izleyen minimal bir istatistik katmanı ekle.

2. GPU & Graphics Pipeline (Smoothing & Stability)
Hedef: Kristal netliğinde ve stabil bir görüntü çıkışı.

[x] MetalFX Temporal Jitter Smoothing:

SetJitterOffset içerisine EMA (Exponential Moving Average) filtresi entegre edildi.

Alt piksel titremeleri ve MetalFX gürültüsü (noise) minimize edildi.

[x] Tier 2 Argument Buffers:

MTLArgumentEncoder ile bindless texture yönetimi sağlandı.

[x] Adaptive Resolution Scale:

GPU yükü arttığında MetalFX ölçeklendirme çarpanını dinamik olarak düşüren bir kontrolcü ekle.

3. Memory & Kernel (Self-Healing System)
Hedef: Sınırlı bellek alanını (VAS) verimli kullanarak çökmeleri önlemek.

[x] Memory Auto-Flush (LRU tabanlı):

4GB VAS sınırı takip sistemi kuruldu.

Limit aşımında En Az Son Kullanılan (Least Recently Used) JIT bloklarını otomatik temizleyen mekanizma aktif.

[x] ScopedJITWrite (W^X Batching):

RAII guard ile syscall optimizasyonu sağlandı.

[x] Memory Pressure Reporting:

Auto-flush tetiklendiğinde kullanıcıya (veya loglara) performans kaybı yaşanabileceğine dair bir sinyal gönder.