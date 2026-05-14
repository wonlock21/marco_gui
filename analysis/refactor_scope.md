# Refactor Scope — Dokunulan / Dokunulmayan Dosyalar

**Tarih:** 14 Mayıs 2026  
**Amaç:** Faz 0.3 — Faz 1–2 kapsamında hangi dosyaların değiştiğini netleştirmek.

---

## Git referansı

| Referans | Commit / durum | Açıklama |
|----------|----------------|----------|
| Refactor öncesi baseline | `a03f379` (*autonom manuel*) | `origin/main` üzerindeki son commit (Faz 1 öncesi) |
| Faz 1–2 çalışması | Working tree (uncommitted) | `main` branch; kullanıcı kendi commit'lerini yönetiyor |
| Analiz çıktıları | `analysis/` (untracked) | Plan ve raporlar; uygulama runtime'ını etkilemez |

> Ayrı `refactor/phase-1-state` branch'i oluşturulmadı — mevcut git geçmişi ve kullanıcı commit'leri yeterli kabul edildi (Faz 0.2).

---

## Faz 1–2'de değiştirilen / eklenen dosyalar

### Yeni (`lib/`)

| Dosya | Faz |
|-------|-----|
| `lib/services/agv_native_bridge.dart` | 1 |
| `lib/services/connection_controller.dart` | 1 |
| `lib/services/joystick_command_throttler.dart` | 2 |
| `lib/widgets/connection_status_bar.dart` | 1 |
| `lib/accesories.dart` | *(önceden untracked; kapsamda)* |

### Güncellenen (`lib/`)

| Dosya | Faz | Özet değişiklik |
|-------|-----|-----------------|
| `lib/main.dart` | 1 | `ConnectionController.init()` |
| `lib/gamepage.dart` | 1 | `ConnectionStatusBar`, `BluetoothButton` |
| `lib/bluetooth_button.dart` | 1 | Bridge + `ConnectionController` |
| `lib/joystick.dart` | 1→2 | Bridge; Faz 2: `ValueNotifier` |
| `lib/lift_joystick.dart` | 1→2 | Bridge; Faz 2: `ValueNotifier` |
| `lib/agv_settings.dart` | 1 | Bridge, auto-reconnect toggle |
| `lib/autonom_button.dart` | 1 | Bridge |
| `lib/accesories.dart` | 1 | Bridge |
| `lib/log_manager.dart` | 2 | `enabled` flag |
| `lib/background.dart` | — | *(git'te modified; Faz 1–2 dışı küçük değişiklik)* |

### Native

| Dosya | Faz |
|-------|-----|
| `android/.../MainActivity.kt` | 1 — EventChannel, accessory, timeout, lifecycle |

### Analiz (Faz 0)

| Dosya | Açıklama |
|-------|----------|
| `analysis/system_analysis.md` | İlk check-up |
| `analysis/execution_plan.md` | Fazlı plan |
| `analysis/manual_test_checklist.md` | Faz 0.1 |
| `analysis/refactor_scope.md` | Bu dosya (Faz 0.3) |
| `analysis/performance_baseline.md` | Faz 0.4 |

---

## Bilinçli olarak dokunulmayan alanlar

| Alan | Dosyalar / not |
|------|----------------|
| iOS / macOS / Windows / Linux / Web | Platform runner'ları |
| `pubspec.yaml` | Bağımlılık eklenmedi (Faz 3'te `wakelock_plus` planlı) |
| `lib/camera_view.dart` | Faz 4 kapsamı |
| `lib/joystick_settings.dart` | Yalnızca mevcut ölçek UI |
| `lib/background.dart` | Faz 5 UI kapsamı |
| `android/.../AndroidManifest.xml` | Değişmedi |
| Test klasörü | `test/` henüz yok (Faz 7) |

---

## Faz 3+ için beklenen dokunuşlar (henüz yapılmadı)

- `joystick.dart`, `lift_joystick.dart` — bağlantı kilidi overlay
- `gamepage.dart` — E-Stop, wakelock
- `autonom_button.dart` — otonom onay dialogu
- `pubspec.yaml` — `wakelock_plus`
