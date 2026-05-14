# Manuel Test Checklist — MarcoTest AGV

**Tarih:** 14 Mayıs 2026  
**Build durumu:** `flutter analyze` → hata yok  
**Git baseline (refactor öncesi):** `a03f379` — *autonom manuel*  
**Test edilen sürüm:** Faz 1 + Faz 2 sonrası working tree (commit öncesi)

---

## Kullanım

Her maddeyi fiziksel cihaz + AGV/BT donanımı ile dene. Sonuç sütununa `OK` / `FAIL` / `SKIP` yaz; notları altına ekle.

| # | Senaryo | Adımlar | Beklenen | Sonuç | Notlar |
|---|---------|---------|----------|-------|--------|
| 1 | Uygulama açılışı | Uygulamayı landscape modda başlat | Siyah dashboard, üstte kırmızı **BAĞLANTI YOK** barı | | |
| 2 | BT izinleri | Bluetooth butonuna ilk basış | İzin istenir veya cihaz listesi açılır | | |
| 3 | BT bağlanma | Kayıtlı AGV'yi seç | Üst bar yeşil **BAĞLI**, BT FAB yeşil, snackbar | | |
| 4 | Sürüş joystick | 8 yönde sür, bırak | AGV hareket eder; bırakınca durur | | |
| 5 | Lift joystick | Yukarı / aşağı / bırak | Lift komutları çalışır; bırakınca dur | | |
| 6 | Kamera | Kamera FAB ile aç/kapa | MJPEG akışı veya hata ekranı; tekrar kapanır | | |
| 7 | Otonom / Manuel | Üst orta butona bas | Mod metni ve renk değişir; log kaydı | | |
| 8 | Buzzer | Sol alttaki buzzer ikonu | Toggle çalışır (native log: `B_AC` / `B_KAPA`) | | |
| 9 | Far / Fan | Ayarlar → Donanım switch'leri | Komut gider (native log: `I_AC`, `F_AC` vb.) | | |
| 10 | Bağlantı kopması | AGV'yi kapat veya menzil dışı | ~2 sn içinde üst bar kırmızı; FAB indigo | | |
| 11 | Manuel koparma | BT FAB uzun bas | Bağlantı kesilir, turuncu snackbar | | |
| 12 | Auto-reconnect | Ayarlardan aç → kop → bekle | Exponential backoff ile yeniden bağlanma dener | | |
| 13 | Joystick performans | Sürüş sırasında UI | Gözle görülür takılma / frame drop yok | | |
| 14 | Ayarlar → Joystick ölçek | Slider'ı değiştir | Her iki joystick boyutu anında güncellenir | | |
| 15 | Log ekranı | Ayarlar → Sistem Logları | Komutlar listelenir, temizle çalışır | | |

---

## Regresyon (Faz 1–2 özel)

| # | Senaryo | Beklenen | Sonuç | Notlar |
|---|---------|----------|-------|--------|
| R1 | Bağlı değilken joystick | Komut sessizce düşer (native uyarı log); uygulama çökmez | | Faz 3'te UI kilidi gelecek |
| R2 | `accessory` komutu | `notImplemented` hatası **olmaz** | | |
| R3 | Kopma event'i | `ConnectionStatusBar` anında güncellenir | | |

---

## Özet (test sonrası doldur)

- **Test eden:** _______________  
- **Cihaz / Android sürümü:** _______________  
- **AGV / BT modülü:** _______________  
- **Toplam OK / FAIL / SKIP:** ___ / ___ / ___  
- **Kritik blokör var mı?** Evet / Hayır — açıklama: _______________

---

*Bu checklist Faz 0 (0.1) çıktısıdır. Saha testi operatör tarafından doldurulmalıdır.*
