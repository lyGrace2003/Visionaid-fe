// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_mjpeg/flutter_mjpeg.dart';
// import 'dart:convert';
// import 'package:camera/camera.dart';

// class CaptureTestScreen extends StatefulWidget {
//   const CaptureTestScreen({super.key});

//   @override
//   _CaptureTestScreenState createState() => _CaptureTestScreenState();
// }

// class _CaptureTestScreenState extends State<CaptureTestScreen> {
//   String message = "Press the button to capture and process OCR.";
//   bool isLoading = false;
//   bool useMobileCamera = false;
//   CameraController? _cameraController;
//   Future<void>? _initializeControllerFuture;
//   Map<int, String> labelMap = {};

//   //final String esp32CaptureUrl = 'http://172.29.4.165/capture'; // ESP32 endpoint
//   //final String esp32StreamUrl = "http://172.29.4.165";
//   //final String djangoOCRUrl = 'http://172.29.4.167:8000/api/get-ocr-result/'; // Django OCR endpoint

//   //my ipconfig
//   final String esp32CaptureUrl = "http://192.168.1.10/capture";
//   final String esp32StreamUrl = "http://192.168.1.10:81/stream";
//   final String djangoUrl = "http://192.168.1.4:8000/api/upload-image/";

//   @override
//   void initState() {
//     super.initState();
//     if (useMobileCamera) {
//       _initializeCamera();
//     }
//   }

//   Future<void> _initializeCamera() async {
//     final cameras = await availableCameras();
//     final camera = cameras.first;

//     _cameraController = CameraController(
//       camera,
//       ResolutionPreset.medium,
//       enableAudio: false,
//     );

//     _initializeControllerFuture = _cameraController!.initialize();
//     setState(() {});
//   }

//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     super.dispose();
//   }

//   Future<void> captureAndProcess() async {
//     setState(() {
//       isLoading = true;
//       message = "Capturing image and processing...";
//     });

//     try {
//       http.Response response;

//       if (useMobileCamera) {
//         final image = await _cameraController!.takePicture();
//         final imagePath = image.path;

//         // Create a multipart request for sending the image to Django
//         var request = http.MultipartRequest(
//           'POST',
//           Uri.parse(djangoUrl),
//         );

//         var file = await http.MultipartFile.fromPath('image', imagePath);
//         request.files.add(file);

//         // Send the request
//         var djangoResponse = await request.send();

//         // Wait for the server response
//         response = await http.Response.fromStream(djangoResponse);
//       } else {
//         response = await http.post(Uri.parse(esp32CaptureUrl));
//       }

//       if (response.statusCode != 200) {
//         throw Exception("Capture failed: status ${response.statusCode}");
//       }

//       // Decode the response body and remove BOM (if present)
//       String responseStr = utf8.decode(response.bodyBytes).trim();
//       if (responseStr.startsWith('\ufeff')) {
//         responseStr = responseStr.substring(1); // Remove BOM if present
//       }

//       final result = jsonDecode(responseStr);
//       if (result['status'] != 'success') {
//         throw Exception("Detection failed: ${result['message']}");
//       }

//       // Get the scene description from the response
//       final sceneDescription = result['scene_description'] ?? "No description available.";

//       setState(() {
//         message = sceneDescription;
//       });
//     } catch (e) {
//       setState(() {
//         message = "Error occurred: $e";
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("VisionAid: ESP32 OCR")),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             SizedBox(height: 16),
//             SwitchListTile(
//               title: Text("Use Android Camera Instead"),
//               value: useMobileCamera,
//               onChanged: (val) async {
//                 setState(() {
//                   useMobileCamera = val;
//                 });

//                 if (val) {
//                   await _initializeCamera();
//                 } else {
//                   await _cameraController?.dispose();
//                   _cameraController = null;
//                   _initializeControllerFuture = null;
//                 }
//               },
//             ),

//             if (useMobileCamera)
//               _initializeControllerFuture == null
//                   ? Center(child: CircularProgressIndicator())
//                   : FutureBuilder<void>(
//                       future: _initializeControllerFuture,
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState == ConnectionState.done &&
//                             _cameraController != null &&
//                             _cameraController!.value.isInitialized) {
//                           return AspectRatio(
//                             aspectRatio: _cameraController!.value.aspectRatio,
//                             child: CameraPreview(_cameraController!),
//                           );
//                         } else if (snapshot.hasError) {
//                           return Center(child: Text('Camera Error: ${snapshot.error}'));
//                         } else {
//                           return Center(child: CircularProgressIndicator());
//                         }
//                       },
//                     )
//             else
//               AspectRatio(
//                 aspectRatio: 16 / 9,
//                 child: Container(
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.blue, width: 2),
//                   ),
//                   child: Mjpeg(
//                     stream: esp32StreamUrl,
//                     isLive: true,
//                     error: (context, error, stack) =>
//                         Center(child: Text('Stream Error: $error')),
//                   ),
//                 ),
//               ),

//             SizedBox(height: 20),

//             if (isLoading) CircularProgressIndicator(),

//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Text(
//                 message,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 18),
//               ),
//             ),

//             ElevatedButton.icon(
//               icon: Icon(Icons.camera_alt),
//               label: Text("Capture & Process OCR"),
//               onPressed: isLoading ? null : captureAndProcess,
//             ),

//             SizedBox(height: 30),
//           ],
//         ),
//       ),
//     );
//    }
//   }

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'dart:convert';
import 'package:camera/camera.dart';
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
  bool isLoading = false;
  bool _cameraActivationFailed = false;
  bool _isCameraInitialized = false;
  bool _isInitializing = false;
  bool _isActivated = false;
  String _lastCommand = "";
  String _text = "";

  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;

  final String esp32CaptureUrl = "http://192.168.1.10/capture";
  final String esp32StreamUrl = "http://192.168.1.10:81/stream";
  final String djangoUrl = "http://192.168.1.28:8000/api/upload-image/";

  // final String djangoUrl = "http://172.30.10.69:8000/api/upload-image/";

  late AudioPlayer _audioPlayer;
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  final bool _speechAvailable = false;
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
    // if (useMobileCamera) {
    //   _initializeCamera();
    // }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('useEsp32Cam')) {
        final bool useEsp32Cam = args['useEsp32Cam'];
        setState(() {
          useMobileCamera = !useEsp32Cam; // If ESP32 is false, use mobile
        });

        print(
            '\x1B[34mReceived useEsp32Cam: $useEsp32Cam => useMobileCamera: $useMobileCamera\x1B[0m');

        if (!useEsp32Cam) {
          if (isSpeechRecognitionActiveScreen2) {
            _initializeCamera();
          }
        }
      }
      initialized = true;
    }
  }

  Future<void> _checkPermissions() async {
    if (!_isCameraInitialized || _cameraActivationFailed) {
      print('\x1B[33m Camera is not ready or activation failed\x1B[0m');
      return; // Return early if camera is not ready or initialization failed
    }

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      print('\x1B[31m Microphone permission denied\x1B[0m');
      return;
    }

    print('\x1B[32m Microphone permission granted\x1B[0m');

    if (isSpeechRecognitionActiveScreen2) {
      print("\x1B[34m Speech recognition active on TestCamera screen\x1B[0m");

      await Future.delayed(Duration(milliseconds: 500));
      _startListening();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        _initializeControllerFuture = Future.value();
        _cameraActivationFailed = false;
        _isCameraInitialized = true;
      });

      print("Camera initialized");
      print("\x1B[32m Screen 1 : $isSpeechRecognitionActiveScreen1\x1B[0m");
      print("\x1B[32m Screen 2 : $isSpeechRecognitionActiveScreen2\x1B[0m");

      if (isSpeechRecognitionActiveScreen2) {
        await _checkPermissions();
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

      final sceneDescription =
          result['scene_description'] ?? "No description available.";

      setState(() {
        message = sceneDescription;
      });

      await _flutterTts.speak(sceneDescription);
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
    if (isSpeechRecognitionActiveScreen2) {
      print('\x1B[32m onStatus [2]: $val\x1B[0m');
      if (val == 'done' && !_isActivated) {
        _startListening();
      } else if (val == 'notListening') {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  // void _startListening() async {
  //   try {
  //     if (isSpeechRecognitionActiveScreen2 == true && _isActivated == false &&
  // _isListening == false && _isInitializing == false) {

  //       _isInitializing = true;

  //       bool available = await _speech.initialize(onStatus: onStatus);
  //       print("\x1B[32m Availabe = $available\x1B[0m");
  //       if (available) {
  //         print("\x1B[32m Start Speech recognition\x1B[0m");

  //         setState(() {
  //           _isListening = true;
  //           _isActivated = false;
  //           _text = "Listening for commands...";
  //         });

  //         await _speech.listen(
  //           onResult: (result) async {
  //             final newText = result.recognizedWords;
  //             print('\x1B[32m Detected word [2]: $newText\x1B[0m');

  //             if (newText.toLowerCase() != _lastCommand) {
  //               _lastCommand = newText.toLowerCase();

  //               setState(() {
  //                 _text = newText;
  //               });

  //               if (_lastCommand!.contains('capture') && !_isActivated) {
  //                 setState(() {
  //                   _isActivated = true;
  //                   _text = '';
  //                 });
  //                 await captureAndProcess();
  //               } else if (_lastCommand!.contains('stop') && !_isActivated) {
  //                 setState(() {
  //                   _isActivated = true;
  //                   _text = '';
  //                 });
  //                 await _stopListening();
  //               }
  //             }
  //           },
  //         );

  //       } else {
  //         print("\x1B[31m Speech recognition initialization failed\x1B[0m");
  //       }

  //       _isInitializing = false;
  //     }
  //   } catch (e) {
  //     print('\x1B[31m Error during speech recognition setup: $e\x1B[0m');
  //     _isInitializing = false;
  //   }
  // }

  void _startListening() async {
    try {
      if (isSpeechRecognitionActiveScreen2 == true &&
          _isActivated == false &&
          _isListening == false &&
          _isInitializing == false) {
        _isInitializing = true;

        bool available = await _speech.initialize(onStatus: onStatus);
        print("\x1B[32m Available = $available\x1B[0m");

        if (available) {
          print("\x1B[32m Start Speech recognition\x1B[0m");

          setState(() {
            _isListening = true;
            _isActivated = false;
            _text = "Listening for commands...";
          });

          final pauseFor = 5; // duration in seconds for pause between commands
          final listenFor = 30; // duration in seconds for how long to listen

          final options = stt.SpeechListenOptions(
            cancelOnError: true,
            partialResults: true,
            listenMode: stt.ListenMode
                .dictation, // Using dictation mode for continuous speech
            autoPunctuation: true,
            enableHapticFeedback: true,
          );

          await _speech.listen(
            onResult: (result) async {
              final newText = result.recognizedWords;
              print('\x1B[32m Detected word [2]: $newText\x1B[0m');

              if (newText.toLowerCase() != _lastCommand) {
                _lastCommand = newText.toLowerCase();

                setState(() {
                  _text = newText;
                });

                if (_lastCommand.contains('capture') && !_isActivated) {
                  setState(() {
                    _isActivated = true;
                    _text = '';
                  });
                  await captureAndProcess();
                } else if (_lastCommand.contains('stop') && !_isActivated) {
                  setState(() {
                    _isActivated = true;
                    _text = '';
                  });
                  await _stopListening();
                }
              }
            },
            listenFor: Duration(seconds: listenFor),
            pauseFor: Duration(seconds: pauseFor),
            localeId: "en_US",
            listenOptions: options,
          );
        } else {
          print("\x1B[31m Speech recognition initialization failed\x1B[0m");
        }

        _isInitializing = false;
      }
    } catch (e) {
      print('\x1B[31m Error during speech recognition setup: $e\x1B[0m');
      _isInitializing = false;
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();

      isSpeechRecognitionActiveScreen2 = false;
      isSpeechRecognitionActiveScreen1 = true;

      print("\x1B[32m Stop Speech Recognition in CameraScreen\x1B[0m");
      print("\x1B[32m Screen 1 : $isSpeechRecognitionActiveScreen1\x1B[0m");
      print("\x1B[32m Screen 2 : $isSpeechRecognitionActiveScreen2\x1B[0m");

      _stopCameraAndGoBack();
      setState(() {});
    } catch (e) {
      print("\x1B[32m Stop failure: $e\x1B[0m");
    }
  }

  void _playFailureSound() async {
    if (!_cameraActivationFailed) {
      _cameraActivationFailed = true;
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
      print("\x1B[32m Camera activation failed\x1B[0m");
      await _flutterTts
          .speak('Camera activation failed, returning to landing page');

      _stopListening();
    }
  }

  void _stopCameraAndGoBack() async {
    try {
      print("\x1B[32m Navigating to landing page\x1B[0m");
      Navigator.of(context).pushReplacementNamed('/').then((_) {
        setState(() {
          _isActivated = false;
          _text = "";
          _cameraActivationFailed = false;
        });
      });
    } catch (e) {
      print('\x1B[32m Navigation error: $e\x1B[0m');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            await _stopListening();
          },
        ),
        title: Text('Camera Page', style: TextStyle(fontSize: 10)),
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
                    await _cameraController
                        ?.dispose(); // Dispose the previous controller if it exists
                    _cameraController = null; // Reset the controller
                    _initializeControllerFuture =
                        null; // Reset the initialization future
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
                          return Center(
                              child: Text('Camera Error: ${snapshot.error}'));
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text("Capture & Process OCR"),
              onPressed: isLoading ? null : captureAndProcess,
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
              label: Text(_isListening ? "Stop Listening" : "Start Listening"),
              onPressed: _speechAvailable
                  ? () {
                      _isListening ? _stopListening() : _startListening();
                    }
                  : null,
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
