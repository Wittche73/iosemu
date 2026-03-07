# LocalCompat MVP

`LocalCompat`, iOS cihazlarda yerel calisan bir Windows oyun uyumluluk katmani icin MVP iskeletidir.

## Kapsam

- oyun ice aktarma ve kutuphane yonetimi
- oyun basina izole prefix yasam dongusu
- JIT kontrolu ve runtime baslatma kapisi
- log toplama ve hata goruntuleme
- dokunmatik/gamepad profili depolama
- UIKit tabanli ekran iskeleti

## Moduller

- `CompatCore`: domain modelleri, depolama, import, prefix, runtime orkestrasyonu
- `CompatUIKit`: kutuphane, detay, log ve import akislari icin UIKit bilesenleri
- `CompatCoreTests`: depolama ve orkestrasyon davranis testleri

## Temel API

- `importGame(from:suggestedName:)`
- `createPrefix(for:)`
- `launchGame(id:)`
- `stopGame(id:)`
- `fetchLogs(for:)`
- `updateInputProfile(for:profile:)`

## Not

Bu repo, Box64/Wine dusuk seviye bilesenlerini dogrudan getirmez. `RuntimeBridge`, gercek native entegrasyon icin dar bir sinir sunar.
