import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:frontend/main.dart';
import 'package:frontend/utils/app_style.dart';
import 'package:frontend/utils/size_config.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isActivated = false; 
  bool _isInitializing  = false;
  String _text = "Listening for commands...";
  String? _lastCommand;
  bool useEsp = false;

  @override
  void initState(){
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

    _flutterTts.awaitSpeakCompletion(true);
    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("\x1B[32m didChangeDependencies called\x1B[0m");
    if (isSpeechRecognitionActiveScreen1 == true) {
      _startListening();
    }
  }

  void _checkPermissions() async {
    if (await Permission.microphone.request().isGranted) {
      print('\x1B[32m Microphone permission granted\x1B[0m');
      Future.delayed(Duration(milliseconds: 500), () {
        _startListening();
      });
    } else {
      print('\x1B[32m Microphone permission denied\x1B[0m');
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();
      await Future.delayed(Duration(milliseconds: 300));

      isSpeechRecognitionActiveScreen1 = false;
      isSpeechRecognitionActiveScreen2 = true;

      print("\x1B[32m Stop Speech Recognition\x1B[0m");
      print("\x1B[32m Screen 1: $isSpeechRecognitionActiveScreen1\x1B[0m");
      print("\x1B[32m Screen 2: $isSpeechRecognitionActiveScreen2\x1B[0m");

      setState(() {
        _isListening = false;
      });
    } catch (e) {
      print("Stop failure: $e");
    }
  }


  void _startListening() async {
  if (isSpeechRecognitionActiveScreen1 == true && _isActivated == false && 
  _isListening == false && _isInitializing == false) {
    _isInitializing  = true;
    bool available = await _speech.initialize(onStatus: onStatus);
    
    try {
      print("\x1B[32m Start Speech recognition\x1B[0m");
      
      if (available) {
        setState(() {
          _isListening = true;
          _isActivated = false;
          _text = "Listening for commands...";
        });
        _speech.listen(onResult: (result) async{
          final newText = result.recognizedWords;
          print('\x1B[32m Detected word [1]: $newText\x1B[0m');
          if (newText.toLowerCase() != _lastCommand) {
              _lastCommand = newText.toLowerCase();

              setState(() {
                _text = newText;
              });
              if (_lastCommand!.contains('describe') && !_isActivated) {
                print('\x1B[32m Activating CameraScreen\x1B[0m');
                setState(() {
                    _isActivated = true;
                    _text = '';
                    _lastCommand = '';
                  });
                await _flutterTts.speak(
                  'Command detected. Do you prefer the mobile camera or external camera?'
                );
                _listenForCameraPreference();
              }  
          } 
        });
      } else {
        print('\x1B[32m Speech recognition not available.\x1B[0m');
        _flutterTts.speak('Speech recognition not available.');
      }
    } catch (e) {
      print('\x1B[32m Error initializing speech recognition: $e\x1B[0m');
    } finally {
      _isInitializing = false;
    }
  }
}

  void _listenForCameraPreference() async {
    // Stop any ongoing speech recognition
    if (_speech.isListening) {
      await _speech.stop();
    }
    setState(() {
      _isListening = true;
    });

    _speech.listen(
      onResult: (result) async {
        String preference = result.recognizedWords.toLowerCase();
        print('\x1B[32m User preference: $preference\x1B[0m');

        if (preference.contains('mobile')) {
          await _speech.stop();
          useEsp = false;
          _navigateToCameraScreen(useEsp);
        } else if (preference.contains('external')) {
          await _speech.stop();
          useEsp = true;
          _navigateToCameraScreen(useEsp);
        } else if (result.finalResult) {
          // If final result but no match, restart listening
          print('\x1B[33m Unrecognized input, listening again...\x1B[0m');
          await _speech.stop();
          Future.delayed(Duration(milliseconds: 300), () {
            _listenForCameraPreference();
          });
        }
      },
    );
  }



  void onStatus(String val) {
    if (isSpeechRecognitionActiveScreen1) {
      print('\x1B[32m onStatus [1]: $val\x1B[0m');
      if (val == 'done' && !_isActivated) {
        _startListening();
      } else if (val == 'notListening') {
        setState(() {
          _isListening = false; 
        });
      }
    }
  }

  void _navigateToCameraScreen(bool useEsp32Cam) async {
    try {
      await _stopListening();
      // Stop listening before navigating
      print('\x1B[32m Navigating to Camera Screen with ESP32-CAM: $useEsp32Cam\x1B[0m');
      navigatorKey.currentState?.pushNamed(
        '/camera',
        arguments: {'useEsp32Cam': useEsp32Cam},
      ).then((_) {
        setState(() {
          _lastCommand = ""; 
          _text = "Listening for commands...";
          _isActivated = false;
        });
      });
    } catch (e) {
      print('\x1B[32m Navigation error: $e\x1B[0m');
    }
  }


  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              child: Text(
                "VisionAid",
                style:  mBold.copyWith(color: mPurple, fontSize: SizeConfig.blocksHorizontal! * 10),
              ),
            ),
            SizedBox(height: SizeConfig.blocksVertical! * 4),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 25.0),
              padding: const EdgeInsets.only(top: 15.0),
              child: Text(
                _text,
                style: mRegular.copyWith(color: mDarkpurple, fontSize: SizeConfig.blocksHorizontal! * 3
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
