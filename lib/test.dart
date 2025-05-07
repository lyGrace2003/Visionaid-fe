import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:frontend/utils/app_style.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:frontend/main.dart';
import 'package:permission_handler/permission_handler.dart';

class CaptureTestScreen extends StatefulWidget {
  const CaptureTestScreen({super.key});

  @override
  State<CaptureTestScreen> createState() => _CaptureTestScreenState();
}

class _CaptureTestScreenState extends State<CaptureTestScreen> {
  bool useMobileCamera = true; // default
  bool initialized = false;
  String message = "Press the button to capture and process scene.";
  bool isLoading = false;   //is model still loading
  bool _cameraActivationFailed = false;
  bool _isCameraInitialized = false;
  bool micPerm = false;   //microphone permision
  String _lastCommand = "";
  String _text = "Listening for commands...";
  String lastError = '';
  
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  //final String djangoUrl = "http://172.30.10.69:8000/api/upload-image/";

  final String esp32CaptureUrl = "http://192.168.1.10/capture";
  final String esp32StreamUrl = "http://192.168.1.10:81/stream";
  final String djangoUrl = "http://192.168.1.4:8000/api/upload-image/";

  late AudioPlayer _audioPlayer;
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  //final bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _audioPlayer = AudioPlayer();

    _flutterTts.awaitSpeakCompletion(true);
    _flutterTts.setCompletionHandler(() {
      setState(() {
        message = "Press the button to capture and process scene.";
      });
    });
    _checkPermissions();
  }

    @override
    void didChangeDependencies(){
      super.didChangeDependencies();
      if (!initialized) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('useEsp32Cam')) {
          final bool useEsp32Cam = args['useEsp32Cam'];
          setState(() {
            useMobileCamera = !useEsp32Cam; // If ESP32 is false, use mobile
          });

          print('\x1B[34mReceived useEsp32Cam: $useEsp32Cam => useMobileCamera: $useMobileCamera\x1B[0m');

          if(isSpeechRecognitionActiveScreen2){
            if (!useEsp32Cam) {
              _initializeCamera();
            }else{
              _initializeSpeechRecognizer();
            }
          }
        }
        initialized = true;
      }
    }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      print('\x1B[31m Microphone permission denied\x1B[0m');
      return;
    }

    print('\x1B[32m Microphone permission granted\x1B[0m');
    print("\x1B[32m Screen 1 : $isSpeechRecognitionActiveScreen1\x1B[0m");
    print("\x1B[32m Screen 2 : $isSpeechRecognitionActiveScreen2\x1B[0m");

    if (isSpeechRecognitionActiveScreen2) {
      print("\x1B[34m Microphone Permission granted\x1B[0m");
      micPerm = true;
    }
  }

  // Initialize the speech recognition service
  void _initializeSpeechRecognizer() async {
    if (micPerm){
      print("\x1B[36m Initializing Speech Recognizer...\x1B[0m");
      bool available = await _speech.initialize(
        onStatus: onStatus,
      );
      if (available) {
        print('\x1B[36m Speech recognition is available\x1B[0m');
        _startListening();
      } else {
        print('\x1B[36m Speech recognition is not available\x1B[0m');
      }
    }
  }


  Future<void> _initializeCamera() async {
    try {

      final cameras = await availableCameras();
      _cameraController = CameraController(
        cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back),
        ResolutionPreset.medium,
        enableAudio: false);

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _initializeControllerFuture = Future.value();
        _cameraActivationFailed = false;
        _isCameraInitialized = true;
      });

      print("\x1B[32m Camera initialized\x1B[0m");

      if (_isCameraInitialized || !_cameraActivationFailed) {
          _initializeSpeechRecognizer();
        }

    } catch (e) {
      print("\x1B[31m Camera initialization failed: $e\x1B[0m");

      setState(() {
        _cameraActivationFailed = true;
        _initializeControllerFuture = null;
      });
      _playFailureSound();
    }
  }
  
  Future<void> captureAndProcess() async {
    setState(() {
      isLoading = true;
      message = "Capturing image and processing...";
    });

    try {
      http.Response response;

      if (useMobileCamera) {
        final image = await _cameraController!.takePicture();
        final imagePath = image.path;

        var request = http.MultipartRequest('POST', Uri.parse(djangoUrl));
        var file = await http.MultipartFile.fromPath('image', imagePath);
        request.files.add(file);

        var djangoResponse = await request.send();
        response = await http.Response.fromStream(djangoResponse);
      } else {
        response = await http.post(Uri.parse(esp32CaptureUrl));
      }

      if (response.statusCode != 200) {
        throw Exception("Capture failed: status ${response.statusCode}");
      }

      String responseStr = utf8.decode(response.bodyBytes).trim();
      if (responseStr.startsWith('\ufeff')) {
        responseStr = responseStr.substring(1);
      }

      final result = jsonDecode(responseStr);
      if (result['status'] != 'success') {
        throw Exception("Detection failed: ${result['message']}");
      }

      final sceneDescription = result['scene_description'] ?? "No description available.";


      setState(() {
        message = sceneDescription;
      });

      
      await _flutterTts.speak(sceneDescription);
      _startListening();

    } catch (e) {
      setState(() {
        message = "Error occurred: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onStatus(String val) {
    if(isSpeechRecognitionActiveScreen2){
      print('\x1B[32m onStatus [2]: $val\x1B[0m');
      if (val == 'done') {
          _startListening();
      } else if (val == 'notListening') {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  void _startListening() async {
    try {
      if (!_isListening) {
          print("\x1B[32m Start Speech recognition\x1B[0m");

          setState(() {
            _isListening = true;
            _text = "Listening for commands...";
          });

          final pauseFor = 15; // duration in seconds for pause between commands
          final listenFor = 30; // duration in seconds for how long to listen

          final options = stt.SpeechListenOptions(
            cancelOnError: true,
            partialResults: true,
            listenMode: stt.ListenMode.dictation, // Using dictation mode for continuous speech
            autoPunctuation: true,
            enableHapticFeedback: true,
          );

          await _speech.listen(
          onResult: (result) {
            _handleResultScreen2(result);
          },
            listenFor: Duration(seconds: listenFor),
            pauseFor: Duration(seconds: pauseFor),
            localeId: "en_US",
            listenOptions: options,
          );
        } else {
          print("\x1B[31m Speech recognition initialization failed\x1B[0m");
        }
    } catch (e) {
      print('\x1B[31m Error during speech recognition setup: $e\x1B[0m');
    }
  }

  Future<void> _handleResultScreen2(SpeechRecognitionResult result) async {
    final newText = result.recognizedWords;
    print('\x1B[32m Detected word [2]: $newText\x1B[0m');

    if (newText.toLowerCase() != _lastCommand) {
      _lastCommand = newText.toLowerCase();

      setState(() {
        _text = newText;
      });

      if (_lastCommand.contains('capture')) {
        setState(() {
          _text = '';
          _lastCommand = '';
          _isListening = false;
        });
        if (_speech.isListening) {
          await _speech.stop();
        }
        await captureAndProcess();
      } else if (_lastCommand.contains('stop')) {
        setState(() {
          _text = '';
          _lastCommand = '';
          _isListening = false;
        });
        _stopCameraAndGoBack();
      }else if (!_speech.isListening){
        _startListening();
      }
    }
  } 

  Future<void> _stopListening() async {
    try {
      await _speech.cancel();

      isSpeechRecognitionActiveScreen2 = false;
      isSpeechRecognitionActiveScreen1 = true;

      print("\x1B[32m Stop Speech Recognition in CameraScreen\x1B[0m");
      print("\x1B[32m Screen 1 : $isSpeechRecognitionActiveScreen1\x1B[0m");
      print("\x1B[32m Screen 2 : $isSpeechRecognitionActiveScreen2\x1B[0m");

      setState(() {
        _isListening = false;
      });
    } catch (e) {
      print("\x1B[32m Stop failure: $e\x1B[0m");
    }
  }

  void _playFailureSound() async {
    if (!_cameraActivationFailed) {
      _cameraActivationFailed = true;
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
      print("\x1B[32m Camera activation failed\x1B[0m");
      await _flutterTts.speak('Camera activation failed, returning to landing page');

      _stopCameraAndGoBack();
    }
  }

  void _stopCameraAndGoBack()async{
    try {
      await _stopListening();
      await _cameraController?.dispose();

      print("\x1B[32m Navigating to landing page\x1B[0m"); 
      setState(() {
        _text = "";
        _cameraActivationFailed = false;
        _lastCommand = '';
      });
      print("\x1B[32m mounted = $mounted\x1B[0m"); 
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);  // Navigate only after cleanup
      }
    } catch (e) {
      print('\x1B[32m Navigation error: $e\x1B[0m');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _speech.stop();
    _speech.cancel();
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            _stopCameraAndGoBack();
          },
        ),
        title: Text('Camera Page',style: mBold.copyWith(fontSize: 18, color: mDarkpurple)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16),
            SwitchListTile(
              title: Text("Use Android Camera Instead"),
              value: useMobileCamera,
              onChanged: (val) async {
                setState(() {
                  useMobileCamera = val;
                });

                if (val) {
                  if (_cameraController != null) {
                    await _cameraController?.dispose(); // Dispose the previous controller if it exists
                    _cameraController = null; // Reset the controller
                    _initializeControllerFuture = null; // Reset the initialization future
                  }
                  await _initializeCamera();
                } else {
                   if (_cameraController != null) {
                    await _cameraController?.dispose();
                    _cameraController = null;
                    _initializeControllerFuture = null;
                  }
                }
              },
            ),

            if (useMobileCamera)
              _initializeControllerFuture == null
                  ? Center(child: CircularProgressIndicator())
                  : FutureBuilder<void>(
                      future: _initializeControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            _cameraController != null &&
                            _cameraController!.value.isInitialized) {
                          return AspectRatio(
                            aspectRatio: _cameraController!.value.aspectRatio,
                            child: CameraPreview(_cameraController!),
                          );
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Camera Error: ${snapshot.error}'));
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      },
                    )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Mjpeg(
                    stream: esp32StreamUrl,
                    isLive: true,
                    error: (context, error, stack) {
                      _playFailureSound();
                      return Center(child: Text('Stream Error: $error'));
                    },
                  ),
                ),
              ),

            SizedBox(height: 20),

            if (isLoading) CircularProgressIndicator(),

            SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text("Capture & Process OCR"),
              onPressed: isLoading ? null : captureAndProcess,
            ),

            SizedBox(height: 10),

            // ElevatedButton.icon(
            //   icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
            //   label: Text(_isListening ? "Stop Listening" : "Start Listening"),
            //   onPressed: _speechAvailable
            //       ? () {
            //           _isListening ? _stopListening() : _startListening();
            //         }
            //       : null,
            // ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
