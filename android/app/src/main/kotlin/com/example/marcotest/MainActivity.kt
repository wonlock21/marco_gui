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
import java.io.IOException
import java.io.OutputStream
import java.util.UUID

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
    DOWN_RIGHT(7, "23");

    companion object {
        fun fromFlutterIdx(idx: Int): Direction =
            values().firstOrNull { it.flutterIdx == idx } ?: STOP
    }
}

@SuppressLint("MissingPermission")
class MainActivity : FlutterActivity() {

    private val CHANNEL = "agv/native"
    private val CONNECTION_CHANNEL = "agv/connection"
    private val MY_UUID: UUID =
        UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
    private val CONNECT_TIMEOUT_MS = 10_000L

    private var btSocket: BluetoothSocket? = null
    private var outStream: OutputStream? = null
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var connectionEventSink: EventChannel.EventSink? = null
    private var isBtConnected = false
    private var connectedAddress: String? = null

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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "joystick" -> {
                        val dirCode = call.argument<Int>("dir") ?: -1
                        val direction = Direction.fromFlutterIdx(dirCode)
                        sendBluetoothCommand(direction.agvCommand)
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
                        val action = call.argument<Int>("action") ?: 0
                        val commandToSend = when (action) {
                            1 -> "9"
                            -1 -> "7"
                            else -> "8"
                        }
                        sendBluetoothCommand(commandToSend)
                        result.success(null)
                    }

                    "setMode" -> {
                        val isAuto = call.argument<Boolean>("isAuto") ?: false
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
                isBtConnected = true
                connectedAddress = address

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

        try {
            outStream?.close()
        } catch (_: Exception) {
        }
        try {
            btSocket?.close()
        } catch (_: Exception) {
        }

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
}
