import 'package:flutter/material.dart';
import 'package:frontend/home_page.dart';
import 'package:frontend/test.dart';

// Global Variables
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool isSpeechRecognitionActiveScreen1 = true;
bool isSpeechRecognitionActiveScreen2 = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) =>  MyHomePage(),
        //MyHomePage()
        '/camera': (context) => CaptureTestScreen(),
        //CameraScreen()
      },
    );
  }
}
