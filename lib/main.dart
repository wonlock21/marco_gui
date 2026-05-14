import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'gamepage.dart';
import 'services/connection_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ConnectionController.instance.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. ScreenUtilInit İLE SAR
    return ScreenUtilInit(
      // Referans Tasarım Boyutu (iPhone 13/14 Pro Landscape yaklaşık boyutu)
      // Genişlik: 844, Yükseklik: 390
      designSize: const Size(844, 390),
      minTextAdapt: true,
      splitScreenMode: true,
      // Builder içinde MaterialApp döndür
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Lift Ant Controller',
          theme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
          ),
          home: const GamePage(),
        );
      },
    );
  }
}
