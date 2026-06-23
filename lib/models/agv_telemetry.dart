import 'dart:convert';

/// AGV'den gelen anlık telemetri verisi.
///
/// Tüm alanlar opsiyoneldir — firmware henüz belirli bir alanı göndermiyorsa
/// `null` kalır ve UI "—" gösterir.
class AgvTelemetry {
  /// 0–100 arası batarya yüzdesi.
  final double? batteryPct;

  /// Anlık hız (m/s).
  final double? speedMps;

  /// Sürüş modu: `'M'` (manuel) / `'A'` (otonom) gibi tek harf veya tam isim.
  final String? mode;

  /// Sıcaklık (°C) — varsa.
  final double? temperatureC;

  /// Sensör/durum bayrakları (örn. `{"FRONT": true, "REAR": false}`).
  final Map<String, bool> sensors;

  /// Parser'ın tanımadığı ek anahtar/değer çiftleri.
  final Map<String, String> extras;

  /// Bu telemetri kaydının native tarafta üretildiği zaman (ms).
  final int? timestampMs;

  /// Son komuttan bu telemetri varış zamanına kadar geçen süre.
  final int? latencyMs;

  const AgvTelemetry({
    this.batteryPct,
    this.speedMps,
    this.mode,
    this.temperatureC,
    this.sensors = const {},
    this.extras = const {},
    this.timestampMs,
    this.latencyMs,
  });

  static const AgvTelemetry empty = AgvTelemetry();

  /// Yeni satır geldiğinde önceki state üzerine merge eder.
  /// Firmware her satırda tüm alanları göndermese de UI tutarlı kalır.
  AgvTelemetry merge(AgvTelemetry other) {
    return AgvTelemetry(
      batteryPct: other.batteryPct ?? batteryPct,
      speedMps: other.speedMps ?? speedMps,
      mode: other.mode ?? mode,
      temperatureC: other.temperatureC ?? temperatureC,
      sensors: {...sensors, ...other.sensors},
      extras: {...extras, ...other.extras},
      timestampMs: other.timestampMs ?? timestampMs,
      latencyMs: other.latencyMs ?? latencyMs,
    );
  }

  AgvTelemetry copyWith({
    double? batteryPct,
    double? speedMps,
    String? mode,
    double? temperatureC,
    Map<String, bool>? sensors,
    Map<String, String>? extras,
    int? timestampMs,
    int? latencyMs,
  }) {
    return AgvTelemetry(
      batteryPct: batteryPct ?? this.batteryPct,
      speedMps: speedMps ?? this.speedMps,
      mode: mode ?? this.mode,
      temperatureC: temperatureC ?? this.temperatureC,
      sensors: sensors ?? this.sensors,
      extras: extras ?? this.extras,
      timestampMs: timestampMs ?? this.timestampMs,
      latencyMs: latencyMs ?? this.latencyMs,
    );
  }
}

/// AGV'den gelen ham satırları [AgvTelemetry] objesine çevirir.
///
/// Birden fazla format destekler (Arduino tarafı esnek olabilir):
/// - **CSV key:value:** `BAT:75,SPD:0.8,MODE:M,T:25.2`
/// - **CSV key=value:** `BAT=75,SPD=0.8`
/// - **JSON:** `{"bat":75,"spd":0.8,"mode":"M"}`
///
/// Bilinmeyen anahtarlar `extras` map'ine düşer; bilinmeyen format
/// için satır olduğu gibi `extras['raw']` olarak saklanır.
class AgvTelemetryParser {
  AgvTelemetryParser._();

  /// Bilinen anahtarların alias listesi (lower-case).
  static const _batteryKeys = {'bat', 'battery', 'b'};
  static const _speedKeys = {'spd', 'speed', 's'};
  static const _modeKeys = {'mode', 'm'};
  static const _tempKeys = {'t', 'temp', 'temperature'};
  static const _sensorPrefix = 's_';

  /// Bir satırı parse et. Parse edilemezse `null` döner.
  static AgvTelemetry? parseLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return _parseJson(trimmed);
    }
    return _parseKeyValue(trimmed);
  }

  static AgvTelemetry? _parseJson(String line) {
    try {
      final raw = jsonDecode(line);
      if (raw is! Map) return null;
      final map = <String, String>{};
      raw.forEach((k, v) {
        if (k != null && v != null) map[k.toString()] = v.toString();
      });
      return _fromKeyValueMap(map);
    } catch (_) {
      return null;
    }
  }

  static AgvTelemetry _parseKeyValue(String line) {
    final pairs = line.split(RegExp(r'[,;]'));
    final map = <String, String>{};
    for (final pair in pairs) {
      final p = pair.trim();
      if (p.isEmpty) continue;
      final sepIdx = p.indexOf(RegExp(r'[:=]'));
      if (sepIdx <= 0) {
        map['raw_${map.length}'] = p;
        continue;
      }
      final key = p.substring(0, sepIdx).trim();
      final value = p.substring(sepIdx + 1).trim();
      if (key.isNotEmpty) map[key] = value;
    }
    return _fromKeyValueMap(map);
  }

  static AgvTelemetry _fromKeyValueMap(Map<String, String> map) {
    double? battery;
    double? speed;
    String? mode;
    double? temp;
    final sensors = <String, bool>{};
    final extras = <String, String>{};

    map.forEach((rawKey, value) {
      final key = rawKey.toLowerCase();

      if (_batteryKeys.contains(key)) {
        battery = double.tryParse(value)?.clamp(0, 100).toDouble();
      } else if (_speedKeys.contains(key)) {
        speed = double.tryParse(value);
      } else if (_modeKeys.contains(key)) {
        mode = value;
      } else if (_tempKeys.contains(key)) {
        temp = double.tryParse(value);
      } else if (key.startsWith(_sensorPrefix)) {
        sensors[key.substring(_sensorPrefix.length).toUpperCase()] =
            _parseBool(value);
      } else {
        extras[rawKey] = value;
      }
    });

    return AgvTelemetry(
      batteryPct: battery,
      speedMps: speed,
      mode: mode,
      temperatureC: temp,
      sensors: sensors,
      extras: extras,
    );
  }

  static bool _parseBool(String value) {
    final v = value.toLowerCase().trim();
    return v == '1' || v == 'true' || v == 'on' || v == 'yes';
  }
}
