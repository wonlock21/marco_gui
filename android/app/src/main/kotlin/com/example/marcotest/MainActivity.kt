package com.example.marcotest

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStream
import java.io.InputStreamReader
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean

/**
 * BU ENUM BİR "ÇEVİRMEN" GİBİ ÇALIŞIR.
 * Sol Taraf (flutterIdx): Flutter joystick'ten gelen matematiksel yön (0, 1, 2...7).
 * Sağ Taraf (agvCommand): Arduino ekibinin istediği özel komutlar ("41", "12" vb.).
 */
enum class Direction(val flutterIdx: Int, val agvCommand: String) {
    STOP(-1, "0"),
    RIGHT(0, "2"),
    UP_RIGHT(1, "12"),
    UP(2, "1"),
    UP_LEFT(3, "41"),
    LEFT(4, "4"),
    DOWN_LEFT(5, "34"),
    DOWN(6, "3"),
    DOWN_RIGHT(7, "23"),
    LIFT_UP(8, "9"),
    LIFT_DOWN(9, "10"),
    LIFT_STOP(10, "11"),
    LIFT_RIGHT(11, "17"),
    LIFT_LEFT(12, "18"),
    LIFT_SIDE_STOP(13, "19");
    companion object {
        fun fromFlutterIdx(idx: Int): Direction =
            values().firstOrNull { it.flutterIdx == idx } ?: STOP
    }
}

@SuppressLint("MissingPermission")
class MainActivity : FlutterActivity() {

    private val CHANNEL = "agv/native"
    private val CONNECTION_CHANNEL = "agv/connection"
    private val TELEMETRY_CHANNEL = "agv/telemetry"
    private val MY_UUID: UUID =
        UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val CONNECT_TIMEOUT_MS = 10_000L
    private val MANUAL_DRIVE_HEARTBEAT_MS = 100L

    private var btSocket: BluetoothSocket? = null
    private var outStream: OutputStream? = null
    private var inStream: InputStream? = null
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var connectionEventSink: EventChannel.EventSink? = null
    private var telemetryEventSink: EventChannel.EventSink? = null
    private var isBtConnected = false
    private var connectedAddress: String? = null

    private var readerThread: Thread? = null
    private val readerRunning = AtomicBoolean(false)

    private val manualDriveHeartbeatHandler = Handler(Looper.getMainLooper())
    @Volatile
    private var lastManualDriveHeartbeatCommand: String? = null
    @Volatile
    private var isManualDriveHeartbeatRunning = false
    private val manualDriveHeartbeatRunnable = object : Runnable {
        override fun run() {
            val command = lastManualDriveHeartbeatCommand
            if (!isManualDriveHeartbeatRunning || command == null || !isBtConnected) {
                stopManualDriveHeartbeat()
                return
            }

            sendBluetoothCommand(command)

            // sendBluetoothCommand IOException durumunda closeConnection çağırarak
            // heartbeat state'ini temizler; bu yüzden yalnız hâlâ aktifse devam et.
            if (
                isManualDriveHeartbeatRunning &&
                lastManualDriveHeartbeatCommand != null &&
                isBtConnected
            ) {
                manualDriveHeartbeatHandler.postDelayed(
                    this,
                    MANUAL_DRIVE_HEARTBEAT_MS,
                )
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CONNECTION_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    connectionEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    connectionEventSink = null
                }
            })

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, TELEMETRY_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    telemetryEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    telemetryEventSink = null
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "joystick" -> {
                        val dirCode = call.argument<Int>("dir") ?: -1
                        val direction = Direction.fromFlutterIdx(dirCode)

                        if (direction == Direction.STOP) {
                            // STOP periyodik gönderilmez: loop önce durur, "0" bir kez gider.
                            stopManualDriveHeartbeat()
                            sendBluetoothCommand(direction.agvCommand)
                        } else if (direction.flutterIdx in 0..7) {
                            // Yeni yön hemen gider; çalışan tek loop sonraki tick'lerde
                            // güncel komutu yaklaşık her 100 ms tekrarlar.
                            sendBluetoothCommand(direction.agvCommand)
                            startOrUpdateManualDriveHeartbeat(direction.agvCommand)
                        } else {
                            // Drive dışı bir indeks yanlışlıkla bu kanala gelirse mevcut
                            // tek-seferlik davranışı koru, heartbeat üretme.
                            sendBluetoothCommand(direction.agvCommand)
                        }
                        result.success(null)
                    }

                    "getPairedDevices" -> {
                        if (bluetoothAdapter == null) {
                            result.error("NO_BT", "Bluetooth yok", null)
                        } else {
                            val devices = bluetoothAdapter.bondedDevices.map { device ->
                                mapOf("name" to device.name, "address" to device.address)
                            }
                            result.success(devices)
                        }
                    }

                    "connect" -> {
                        val address = call.argument<String>("address")
                        if (address != null) {
                            connectToDevice(address, result)
                        } else {
                            result.error("NO_ADDRESS", "Adres gönderilmedi", null)
                        }
                    }

                    "disconnect" -> {
                        closeConnection(notify = true, reason = "user_disconnect")
                        result.success(true)
                    }

                    "lift" -> {
                        val action = call.argument<Int>("action") ?: 10
                        val direction = Direction.fromFlutterIdx(action)
                        sendBluetoothCommand(direction.agvCommand)
                        android.util.Log.d(
                            "Lift",
                            "Lift komutu: $direction → ${direction.agvCommand} (flutterIdx=$action)",
                        )
                        result.success(null)
                    }

                    "setMode" -> {
                        val isAuto = call.argument<Boolean>("isAuto") ?: false
                        if (isAuto) {
                            stopManualDriveHeartbeat()
                        }
                        val commandToSend = if (isAuto) "otonom" else "manuel"
                        sendBluetoothCommand(commandToSend)
                        result.success(null)
                    }

                    "accessory" -> {
                        val cmd = call.argument<String>("cmd") ?: ""
                        if (cmd.isNotEmpty()) {
                            sendBluetoothCommand(cmd)
                        }
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun startOrUpdateManualDriveHeartbeat(command: String) {
        lastManualDriveHeartbeatCommand = command
        if (!isBtConnected || isManualDriveHeartbeatRunning) return

        isManualDriveHeartbeatRunning = true
        manualDriveHeartbeatHandler.postDelayed(
            manualDriveHeartbeatRunnable,
            MANUAL_DRIVE_HEARTBEAT_MS,
        )
    }

    private fun stopManualDriveHeartbeat() {
        isManualDriveHeartbeatRunning = false
        lastManualDriveHeartbeatCommand = null
        manualDriveHeartbeatHandler.removeCallbacks(manualDriveHeartbeatRunnable)
    }

    override fun onDestroy() {
        closeConnection(notify = false)
        super.onDestroy()
    }

    private fun emitConnectionEvent(event: String, extras: Map<String, Any?> = emptyMap()) {
        val payload = mutableMapOf<String, Any?>("event" to event)
        payload.putAll(extras)
        Handler(Looper.getMainLooper()).post {
            connectionEventSink?.success(payload)
        }
    }

    private fun connectToDevice(address: String, pendingResult: MethodChannel.Result) {
        if (bluetoothAdapter == null) {
            pendingResult.error("NO_BT", "Bluetooth yok", null)
            return
        }

        Thread {
            try {
                closeConnection(notify = false)
                val device = bluetoothAdapter.getRemoteDevice(address)
                val socket = connectWithFallback(device)

                btSocket = socket
                outStream = socket.outputStream
                inStream = socket.inputStream
                isBtConnected = true
                connectedAddress = address

                startInputReader()

                Handler(Looper.getMainLooper()).post {
                    emitConnectionEvent("connected", mapOf("address" to address))
                    pendingResult.success(true)
                }
            } catch (e: Exception) {
                closeConnection(notify = false)
                val message = e.message ?: "Bağlantı hatası"
                Handler(Looper.getMainLooper()).post {
                    emitConnectionEvent("error", mapOf("message" to message))
                    pendingResult.error("ERROR", message, null)
                }
            }
        }.start()
    }

    @Throws(IOException::class)
    private fun connectWithFallback(device: BluetoothDevice): BluetoothSocket {
        var socket = device.createRfcommSocketToServiceRecord(MY_UUID)

        val connectThread = Thread {
            try {
                socket.connect()
            } catch (_: IOException) {
                // Timeout veya fallback thread içinde ele alınır.
            }
        }
        connectThread.start()
        connectThread.join(CONNECT_TIMEOUT_MS)

        if (connectThread.isAlive) {
            connectThread.interrupt()
            try {
                socket.close()
            } catch (_: Exception) {
            }
            throw IOException("Bağlantı zaman aşımı (${CONNECT_TIMEOUT_MS / 1000} sn)")
        }

        if (socket.isConnected) {
            return socket
        }

        try {
            socket.close()
        } catch (_: Exception) {
        }

        // Bazı cihazlarda SPP fallback (reflection channel 1)
        val method = device.javaClass.getMethod(
            "createRfcommSocket",
            Int::class.javaPrimitiveType,
        )
        socket = method.invoke(device, 1) as BluetoothSocket

        val fallbackThread = Thread {
            try {
                socket.connect()
            } catch (_: IOException) {
            }
        }
        fallbackThread.start()
        fallbackThread.join(CONNECT_TIMEOUT_MS)

        if (fallbackThread.isAlive) {
            fallbackThread.interrupt()
            try {
                socket.close()
            } catch (_: Exception) {
            }
            throw IOException("Bağlantı zaman aşımı (fallback)")
        }

        if (!socket.isConnected) {
            try {
                socket.close()
            } catch (_: Exception) {
            }
            throw IOException("Bluetooth cihazına bağlanılamadı")
        }

        return socket
    }

    private fun sendBluetoothCommand(commandStr: String) {
        if (outStream == null || btSocket == null || !isBtConnected) {
            android.util.Log.w(
                "Bluetooth",
                "Bluetooth bağlı değil, komut gönderilemedi: $commandStr",
            )
            return
        }

        val finalCommand = "$commandStr\n"

        try {
            outStream?.write(finalCommand.toByteArray())
            outStream?.flush()
            android.util.Log.d("Bluetooth", "Komut gönderildi: $commandStr")
        } catch (e: IOException) {
            android.util.Log.e("Bluetooth", "Gönderme hatası: ${e.message}")
            closeConnection(notify = true, reason = "io_error: ${e.message}")
        }
    }

    private fun closeConnection(notify: Boolean = true, reason: String = "connection_closed") {
        val wasConnected = isBtConnected
        val address = connectedAddress

        stopManualDriveHeartbeat()
        stopInputReader()

        try {
            inStream?.close()
        } catch (_: Exception) {
        }
        try {
            outStream?.close()
        } catch (_: Exception) {
        }
        try {
            btSocket?.close()
        } catch (_: Exception) {
        }

        inStream = null
        outStream = null
        btSocket = null
        isBtConnected = false
        connectedAddress = null

        if (notify && wasConnected) {
            emitConnectionEvent(
                "disconnected",
                mapOf("reason" to reason, "address" to address),
            )
        }
    }

    private fun emitTelemetry(line: String) {
        val payload = mapOf<String, Any?>(
            "line" to line,
            "timestamp" to System.currentTimeMillis(),
        )
        Handler(Looper.getMainLooper()).post {
            telemetryEventSink?.success(payload)
        }
    }

    /**
     * AGV'den gelen veriyi satır bazlı okur ve EventChannel ile Flutter'a iletir.
     * Her bağlantı için yeni bir thread başlatılır. IOException oluşursa
     * bağlantı koparılır ve UI'ya `disconnected` event'i yollanır.
     */
    private fun startInputReader() {
        stopInputReader()
        val stream = inStream ?: return

        readerRunning.set(true)
        readerThread = Thread {
            try {
                val reader = BufferedReader(InputStreamReader(stream, Charsets.UTF_8))
                while (readerRunning.get() && !Thread.currentThread().isInterrupted) {
                    val line = try {
                        reader.readLine()
                    } catch (e: IOException) {
                        if (readerRunning.get()) {
                            android.util.Log.e("Bluetooth", "Okuma hatası: ${e.message}")
                            Handler(Looper.getMainLooper()).post {
                                closeConnection(
                                    notify = true,
                                    reason = "read_error: ${e.message}",
                                )
                            }
                        }
                        null
                    } ?: break

                    val trimmed = line.trim()
                    if (trimmed.isNotEmpty()) {
                        emitTelemetry(trimmed)
                    }
                }
            } catch (t: Throwable) {
                android.util.Log.e("Bluetooth", "Reader thread exception: ${t.message}")
            }
        }.also { it.isDaemon = true; it.start() }
    }

    private fun stopInputReader() {
        readerRunning.set(false)
        readerThread?.interrupt()
        readerThread = null
    }
}

