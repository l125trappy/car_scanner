import 'package:car_scanner/plate_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: PlateScannerScreen(camera: cameras.first),

    );
  }
}
