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
//    UP_RIGHT(1, "12"),   // Sağ Çapraz
    UP(2, "1"),          // İleri
//    UP_LEFT(3, "41"),    // Sol Çapraz
    LEFT(4, "4"),        // Sol
//    DOWN_LEFT(5, "34"),  // Geri Sol
    DOWN(6, "3");        // Geri
//    DOWN_RIGHT(7, "23"); // Geri Sağ

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
    private val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    // Bağlantı değişkenleri
    private var btSocket: BluetoothSocket? = null       // Bağlantı kablosu (Soket)
    private var outStream: OutputStream? = null         // Veri gönderme borusu
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter() // Telefonun BT donanımı

    // Uygulama açıldığında veya Flutter motoru ayağa kalktığında burası çalışır
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Flutter'dan gelen çağrıları dinleyen kulak (MethodChannel)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                // SENARYO 1: Joystick Hareket Etti (SÜRÜŞ)
                if (call.method == "joystick") {
                    val dirCode = call.argument<Int>("dir") ?: -1
                    val direction = Direction.fromFlutterIdx(dirCode)
                    sendBluetoothCommand(direction.agvCommand)
                    result.success(null)
                }
                
                // SENARYO 5: Lift (Asansör) Kontrolü (YENİ EKLENDİ)
                else if (call.method == "lift") {
                    // Flutter'dan gelen aksiyonu al: 1 (Yukarı), -1 (Aşağı), 0 (Dur)
                    val action = call.argument<Int>("action") ?: 0
                    
                    val commandToSend = when (action) {
                        1 -> "8"      // Yukarı (Arduino kodu)
                        -1 -> "9"     // Aşağı (Arduino kodu)
                        else -> "0"   // Dur (Arduino kodu)
                    }
                    
                    sendBluetoothCommand(commandToSend)
                    result.success(null)
                }

                // SENARYO 2: Cihazları Listele 
                else if (call.method == "getPairedDevices") {
                    if (bluetoothAdapter == null) {
                        result.error("NO_BT", "Bluetooth yok", null)
                    } else {
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
     */
    private fun connectToDevice(address: String, pendingResult: MethodChannel.Result) {
        if (bluetoothAdapter == null) {
            pendingResult.error("NO_BT", "Bluetooth yok", null)
            return
        }

        Thread {
            try {
                closeConnection()
                val device = bluetoothAdapter.getRemoteDevice(address)
                btSocket = device.createRfcommSocketToServiceRecord(MY_UUID)
                btSocket?.connect()
                outStream = btSocket?.outputStream
                Handler(Looper.getMainLooper()).post { pendingResult.success(true) }

            } catch (e: Exception) {
                closeConnection()
                Handler(Looper.getMainLooper()).post { pendingResult.error("ERROR", e.message, null) }
            }
        }.start()
    }

    /**
     * Veriyi Bluetooth üzerinden gönderen fonksiyon.
     * Format: <KOMUT> 
     */
    private fun sendBluetoothCommand(commandStr: String) {
        // Bağlantı kontrolü
        if (outStream == null || btSocket == null) {
            android.util.Log.w("Bluetooth", "Bluetooth bağlı değil, komut gönderilemedi: $commandStr")
            return
        }

        // Arduino protokolüne uygun olarak veriyi paketliyoruz
        val finalCommand = "$commandStr\n"

        try {
            outStream?.write(finalCommand.toByteArray())
            android.util.Log.d("Bluetooth", "Komut gönderildi: $commandStr")
        } catch (e: IOException) {
            android.util.Log.e("Bluetooth", "Gönderme hatası: ${e.message}")
            closeConnection()
        }
    }

    private fun closeConnection() {
        try {
            outStream?.close()
            btSocket?.close()
            outStream = null
            btSocket = null
        } catch (e: Exception) {}
    }
}