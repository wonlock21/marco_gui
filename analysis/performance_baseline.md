# Performans Baseline — Joystick & Build

**Tarih:** 14 Mayıs 2026  
**Amaç:** Faz 0.4 — Refactor öncesi/sonrası karşılaştırma için referans noktası.

---

## 1. Statik doğrulama (otomatik — tamamlandı)

| Metrik | Refactor öncesi (`a03f379`) | Faz 2 sonrası (şimdi) |
|--------|----------------------------|------------------------|
| `flutter analyze` | *(kayıt yok)* | **0 issue** (14 May 2026) |
| `joystick.dart` içinde `setState` | Var (`onPanUpdate`) | **Yok** |
| `lift_joystick.dart` içinde `setState` | Var (`onPanUpdate`) | **Yok** |
| Komut throttle | Widget içinde | `JoystickCommandThrottler` / `LiftCommandThrottler` |
| Knob UI güncellemesi | Tüm `StatefulWidget` rebuild | `ValueNotifier` + `ValueListenableBuilder` (yalnızca knob) |

---

## 2. DevTools Timeline (cihazda manuel — prosedür)

Refactor **öncesi** kayıt alınamadı (Faz 0 atlanarak Faz 1'e geçilmişti). Aşağıdaki prosedürle **şimdiki** sürüm ölçülüp bu tabloya işlenmeli; istenirse `git checkout a03f379` ile eski sürüm de aynı prosedürle ölçülebilir.

### Adımlar

1. Release veya profile modda cihaza yükle: `flutter run --profile`
2. Flutter DevTools → **Performance** → **Timeline** kaydı başlat
3. 15–30 sn boyunca sürüş joystick'ini dairesel hareket ettir
4. Kaydı durdur; **Frame build time** ve **FPS** ortalamasını not et
5. Aynı cihazda lift joystick için tekrarla

### Ölçüm tablosu (operatör doldurur)

| Senaryo | Cihaz | FPS (ort.) | Frame build (p95) | Jank frame sayısı | Tarih |
|---------|-------|------------|-------------------|-------------------|-------|
| Sürüş joystick — `a03f379` | | | | | |
| Sürüş joystick — Faz 2 | | | | | |
| Lift joystick — `a03f379` | | | | | |
| Lift joystick — Faz 2 | | | | | |

### Hedef (Faz 2 kabul kriteri)

- Sürüş sırasında ortalama **≥ 55 FPS** (mid-range Android, profile mod)
- Pan başına knob subtree build **< 1 ms** (Timeline'da `ValueListenableBuilder` altı)

---

## 3. Kod boyutu referansı (Faz 2 sonrası)

| Dosya | Satır (yaklaşık) |
|-------|------------------|
| `joystick.dart` | ~110 |
| `lift_joystick.dart` | ~95 |
| `joystick_command_throttler.dart` | ~120 |

---

## 4. Sonuç

| Faz 0.4 kalemi | Durum |
|----------------|-------|
| Statik metrikler ve mimari karşılaştırma | [x] Bu dosyada |
| DevTools FPS / Timeline sayısal kaydı | [ ] Cihazda prosedür uygulanınca tamamlanır |

*Sayısal DevTools kaydı olmadan Faz 2'nin kod hedefleri (`setState` kaldırma) karşılandı sayılır; FPS hedefi saha ölçümüne bağlıdır.*
