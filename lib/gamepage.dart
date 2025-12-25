import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'background.dart';
import 'joystick.dart';
import 'camera_view.dart';
import 'bluetooth_button.dart';
import 'log_manager.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool isCameraOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // -----------------------------------------------------------
          // KATMAN 1: ZEMİN (Arka Plan / Kamera)
          // -----------------------------------------------------------
          if (isCameraOn)
            Positioned.fill(
              child: CameraView(
                streamUrl: 'http://192.168.1.100:81/stream',
              ), //kendi ipni gir
            )
          else
            const BackgroundColor(), //eğer kamera kısmında değilsek klasik arka planı ayarla
          // -----------------------------------------------------------
          // KATMAN 2: KONTROLLER
          // -----------------------------------------------------------

          // 1. Joystick
          Positioned(
            right: 30.w, //joystick konumu ayarlı screenutil ile yapıldı
            bottom: 15.h,
            child: Joystick(
              isCameraOn: isCameraOn,
            ), //isCameraOn joystick kamera açıkken de gözüksün diye var, arka planı saydamlaştırıyorum onun sayesinde
          ),

          // 2. Bluetooth Butonu
          Positioned(
            right: 30.w, //bt konumu ayarlı screenutil ile yapıldı
            top: 10.h,
            child: SafeArea(
              child: BluetoothButton(onConnectionChanged: (status) {}),
            ),
          ),

          // 3. Kamera Aç/Kapa Butonu
          Positioned(
            left: 30.w, //kamera buton konumu ayarlı
            top: 10.h,
            child: SafeArea(
              child: FloatingActionButton.small(
                //.small ile buton boyutu küçültüldü
                heroTag: "btn_camera",
                onPressed: () => setState(
                  () => isCameraOn = !isCameraOn,
                ), //butona basıldığında ekranı kamera görüntüsüne çeviriyor.
                backgroundColor: isCameraOn ? Colors.redAccent : Colors.white,
                child: Icon(
                  isCameraOn ? Icons.videocam_off : Icons.videocam,
                  color: isCameraOn ? Colors.white : Colors.black,
                  size: 20.r,
                ),
              ),
            ),
          ),

          // 4.LOG BUTONU
          Positioned(
            top: 50.h,
            left: 30.w,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: "btn_logs",
                backgroundColor: Colors.black54,
                child: const Icon(Icons.terminal, color: Colors.greenAccent),
                onPressed: () {
                  LogManager.show(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
