package com.example.marcotest

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothSocket
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.io.OutputStream
import java.util.UUID

/**
 * BU ENUM BİR "ÇEVİRMEN" GİBİ ÇALIŞIR.
 * Sol Taraf (flutterIdx): Flutter joystick'ten gelen matematiksel yön (0, 1, 2...7).
 * Sağ Taraf (agvCommand): Arduino ekibinin istediği özel komutlar ("41", "12" vb.).
 */
enum class Direction(val flutterIdx: Int, val agvCommand: String) {
    STOP(-1, "0"),       // Durma komutu
    RIGHT(0, "2"),       // Sağ
    UP_RIGHT(1, "12"),   // Sağ Çapraz
    UP(2, "1"),          // İleri
    UP_LEFT(3, "41"),    // Sol Çapraz
    LEFT(4, "4"),        // Sol
    DOWN_LEFT(5, "34"),  // Geri Sol
    DOWN(6, "3"),        // Geri
    DOWN_RIGHT(7, "23"); // Geri Sağ

    companion object {
        // Flutter'dan gelen sayıyı (idx) alıp, yukarıdaki listeden doğru Enum'u bulan fonksiyon.
        fun fromFlutterIdx(idx: Int): Direction = values().firstOrNull { it.flutterIdx == idx } ?: STOP
    }
}

@SuppressLint("MissingPermission")
class MainActivity : FlutterActivity() {

    // Flutter ile iletişim kuracağımız kanalın adı (Telsiz frekansı gibi)
    private val CHANNEL = "agv/native"

    // Bluetooth Seri Port Profili (SPP) için standart UUID.
    // HC-05, HC-06 gibi modüllerle konuşmak için bu numara standarttır, DEĞİŞTİRMEYİN.
    private val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    // Bağlantı değişkenleri
    private var btSocket: BluetoothSocket? = null      // Bağlantı kablosu (Soket)
    private var outStream: OutputStream? = null        // Veri gönderme borusu
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter() // Telefonun BT donanımı

    // Uygulama açıldığında veya Flutter motoru ayağa kalktığında burası çalışır
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Flutter'dan gelen çağrıları dinleyen kulak (MethodChannel)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                // SENARYO 1: Joystick Hareket Etti
                if (call.method == "joystick") {
                    // Flutter'dan gelen yön kodunu al (0-7 arası sayı)
                    val dirCode = call.argument<Int>("dir") ?: -1

                    // 1. Gelen sayıyı bizim Enum sözlüğünden bul
                    val direction = Direction.fromFlutterIdx(dirCode)

                    // 2. Enum'un içindeki Arduino komutunu (örn: "41") Bluetooth'tan gönder
                    sendBluetoothCommand(direction.agvCommand)

                    // İşlem başarılı, Flutter'a "Tamam" de.
                    result.success(null)
                }
                // SENARYO 2: Cihazları Listele 
                else if (call.method == "getPairedDevices") {
                    if (bluetoothAdapter == null) {
                        result.error("NO_BT", "Bluetooth yok", null)
                    } else {
                        // Eşleşmiş cihazları alıp List<Map> olarak Flutter'a atıyoruz
                        val devices = bluetoothAdapter.bondedDevices.map { device ->
                            mapOf("name" to device.name, "address" to device.address)
                        }
                        result.success(devices)
                    }
                }
                // SENARYO 3: Seçilen Cihaza Bağlan 
                else if (call.method == "connect") {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        connectToDevice(address, result)
                    } else {
                        result.error("NO_ADDRESS", "Adres gönderilmedi", null)
                    }
                }
                // SENARYO 4: Bağlantıyı Kes
                else if (call.method == "disconnect") {
                    closeConnection()
                    result.success(true)
                }
                // Bilinmeyen bir komut geldi
                else {
                    result.notImplemented()
                }
            }
    }

    /**
     * Bluetooth cihazına ADRES üzerinden bağlanma fonksiyonu.
     * pendingResult: İşlem bitince Flutter'a cevap vermek için kullanılan geri bildirim kutusu.
     */
    private fun connectToDevice(address: String, pendingResult: MethodChannel.Result) {
        // Telefonun Bluetooth özelliği var mı?
        if (bluetoothAdapter == null) {
            pendingResult.error("NO_BT", "Bluetooth yok", null)
            return
        }

        // Bağlantı işlemi uzun sürer, bu yüzden ANA EKRANI DONDURMAMAK İÇİN
        // ayrı bir iş parçacığında (Thread) çalıştırıyoruz.
        Thread {
            try {
                // Varsa eski bağlantıyı temizle
                closeConnection()

                // MAC adresi üzerinden cihazı bul
                val device = bluetoothAdapter.getRemoteDevice(address)

                // 1. Bağlantı soketi oluştur
                btSocket = device.createRfcommSocketToServiceRecord(MY_UUID)
                // 2. Bağlan (Kapıyı çal)
                btSocket?.connect()
                // 3. Veri gönderme borusunu (Output Stream) ele geçir
                outStream = btSocket?.outputStream

                // ANA EKRANA (UI Thread) GERİ DÖN VE MÜJDEYİ VER
                Handler(Looper.getMainLooper()).post { pendingResult.success(true) }

            } catch (e: Exception) {
                // Bir hata olduysa soketi temizle
                closeConnection()

                // Hatayı Flutter'a bildir
                Handler(Looper.getMainLooper()).post { pendingResult.error("ERROR", e.message, null) }
            }
        }.start() // Thread'i başlat
    }

    /**
     * Veriyi Bluetooth üzerinden gönderen fonksiyon.
     * Format: <KOMUT>  (Örnek: <41>)
     */
    private fun sendBluetoothCommand(commandStr: String) {
        // Eğer boru hattı (Stream) yoksa hiçbir şey yapma
        if (outStream == null) return

        // Arduino'nun anlayacağı format: <41>\n
        // \n (yeni satır) komutun bittiğini gösterir.
        val finalCommand = "$commandStr\n"

        try {
            // Veriyi byte dizisine çevir ve gönder
            outStream?.write(finalCommand.toByteArray())
        } catch (e: IOException) {
            // Gönderirken hata olursa (bağlantı koptuysa)
            closeConnection()
        }
    }

    // Bağlantıyı temizleyen yardımcı fonksiyon
    private fun closeConnection() {
        try {
            outStream?.close()
            btSocket?.close()
            outStream = null
            btSocket = null
        } catch (e: Exception) {}
    }
}