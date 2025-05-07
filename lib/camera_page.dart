// import 'package:audioplayers/audioplayers.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_mjpeg/flutter_mjpeg.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:frontend/main.dart';
// import 'package:frontend/utils/app_style.dart';
// import 'package:frontend/utils/size_config.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:speech_to_text/speech_recognition_error.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:http/http.dart' as http;
// import 'dart:async';
// import 'dart:convert';

// class CameraScreen extends StatefulWidget {
//   const CameraScreen({super.key});

//   @override
//   _CameraScreenState createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen> {
//   late String streamUrl;
//   late AudioPlayer _audioPlayer;
//   late CameraController _cameraController;
//   Future<void>? _initializeControllerFuture;

//   bool _isUsingEsp32Cam = true;

//   late stt.SpeechToText _s;
//   late FlutterTts _flutterTts;
//   bool _isListening = false;
//   bool _isActivated = false;
//   bool _cameraActivationFailed = false;
//   bool _isCameraInitialized = false;
//   bool _isInitializing = false;
//   String message = "Press the button to capture and process OCR.";  //Text from models
//   bool isLoading = false;  //Model loading
//   String? _lastCommand;

//   String _text = ""; // text detected duirng speech recognition

//   //final String djangoUploadUrl = 'http://172.29.13.150:8000/api/upload-image//';  //change this

//   //final String esp32CaptureUrl = 'http://172.29.4.165/capture'; // ESP32 endpoint
//   //final String esp32StreamUrl = "http://172.29.4.165";
//   //final String djangoOCRUrl = 'http://172.29.4.167:8000/api/get-ocr-result/'; // Django OCR endpoint

//   //my ipconfig
//   final String esp32CaptureUrl = "http://192.168.1.10/capture";
//   final String djangoUrl = "http://192.168.1.4:8000/api/upload-image/";

//   @override
//   void initState() {
//     super.initState();
//     _s = stt.SpeechToText();
//     _audioPlayer = AudioPlayer();
//     _flutterTts = FlutterTts();
//     _checkPermissions();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
//     _isUsingEsp32Cam = arguments['useEsp32Cam'] ?? true;

//     if (!_isUsingEsp32Cam) {
//       _initializeMobileCamera();
//       _checkPermissions();
//     } else {
//       //streamUrl = 'http://172.29.13.179:81'
//       streamUrl = "http://192.168.1.10:81/stream";
//     }
//   }

//   void _checkPermissions() async {
//     if (_isCameraInitialized && !_cameraActivationFailed) {
//       print('\x1B[32m $_isCameraInitialized\x1B[0m');
//       if (await Permission.microphone.request().isGranted) {
//         print('\x1B[32m Microphone permission granted\x1B[0m');

//         if (isSpeechRecognitionActiveScreen2 == true) {
//           Future.delayed(Duration(milliseconds: 500), () {
//             _startListening();
//           });
//         }
//       } else {
//         print('\x1B[32m Microphone permission denied\x1B[0m');
//       }
//     } else {
//       print('\x1B[32m Camera is not initialized yet\x1B[0m');
//     }
//    }

//   Future<void> _initializeMobileCamera() async {
//     try {
//       final cameras = await availableCameras();
//       if (cameras.isEmpty) {
//         print("\x1B[32m No cameras found\x1B[0m");
//         setState(() {
//           _cameraActivationFailed = true;
//         });
//         return;
//       }
//       _cameraController = CameraController(
//         cameras[0],
//         ResolutionPreset.high,
//       );
//       _initializeControllerFuture = _cameraController.initialize();

//       await _initializeControllerFuture;
//       print("\x1B[32m Camera initialized!\x1B[0m");
//       setState(() {
//         _isCameraInitialized = true;
//         _cameraActivationFailed = false;
//       });

//       _checkPermissions();

//     } catch (e) {
//       _playFailureSound();
//       setState(() {
//         _cameraActivationFailed = true;
//       });
//       print('\x1B[32m Camera initialization failed: $e\x1B[0m');
//     }
//   }

//   void _toggleCamera() {
//     setState(() {
//       _isUsingEsp32Cam = !_isUsingEsp32Cam;
//     });

//     if (!_isUsingEsp32Cam) {
//       _initializeMobileCamera();
//     } else {
//       if (streamUrl.isEmpty) {
//         _playFailureSound();
//         print('\x1B[32m ESP32-CAM stream failed to activate\x1B[0m');
//       }
//     }
//   }

//   Future<void> _stopListening() async {
//     try {
//       await _s.stop();

//       isSpeechRecognitionActiveScreen2 = false;
//       isSpeechRecognitionActiveScreen1 = true;

//       print("\x1B[32m Stop Speech Recognition in CameraScreen\x1B[0m");
//       print("\x1B[32m Screen 1 : $isSpeechRecognitionActiveScreen1\x1B[0m");
//       print("\x1B[32m Screen 2 : $isSpeechRecognitionActiveScreen2\x1B[0m");

//       _stopCameraAndGoBack();
//       setState(() {});
//     } catch (e) {
//       print("\x1B[32m Stop failure: $e\x1B[0m");
//     }
//   }

//   void onError(SpeechRecognitionError error) {
//     print('\x1B[32m Error during speech recognition: ${error.errorMsg}\x1B[0m');
//     if (error.errorMsg == 'speech timeout' || error.errorMsg == 'microphone is busy') {
//       _startListening();
//     }
//   }

//   void _startListening() async {
//     try {
//       if (isSpeechRecognitionActiveScreen2 == true && _isActivated == false &&
//   _isListening == false && _isInitializing == false) {
//         _isInitializing = true;

//         bool available = await _s.initialize(onStatus: onStatus);

//         if (available) {
//           print("\x1B[32m Start Speech recognition\x1B[0m");

//           setState(() {
//             _isListening = true;
//             _isActivated = false;
//             _text = "Listening for commands...";
//           });

//           _s.listen(onResult: (result) async {
//             final newText = result.recognizedWords;
//             print('\x1B[32m Detected word [2]: $newText\x1B[0m');

//             if (newText.toLowerCase() != _lastCommand) {
//               _lastCommand = newText.toLowerCase();

//               setState(() {
//                 _text = newText;
//               });

//               if (_lastCommand!.contains('capture') && !_isActivated) {
//                   setState(() {
//                     _isActivated = true;
//                     _text = '';
//                   });
//                 await captureAndProcess();
//               } else if (_lastCommand!.contains('stop') && !_isActivated) {
//                   setState(() {
//                       _isActivated = true;
//                       _text = '';
//                   });
//                 await _stopListening();
//               }
//             }
//           });
//         } else {
//           print("\x1B[31m Speech recognition initialization failed\x1B[0m");
//         }

//         _isInitializing = false;
//       }
//     } catch (e) {
//       print('\x1B[31m Error during speech recognition setup: $e\x1B[0m');
//       _isInitializing = false;
//     }
//   }

//   void _restartListening() async {
//     print('\x1B[32m Restarting speech recognition\x1B[0m');
//     await Future.delayed(Duration(milliseconds: 500));

//     setState(() {
//       _isListening = false;
//     });
//     _startListening();
//   }

//   void onStatus(String val) {
//     if(isSpeechRecognitionActiveScreen2){
//       print('\x1B[32m onStatus [2]: $val\x1B[0m');
//       if (val == 'done' && !_isActivated) {
//           _startListening();
//       } else if (val == 'notListening') {
//         setState(() {
//           _isListening = false;
//         });
//       }
//     }
//   }

//   void _playFailureSound() async {
//     if (!_cameraActivationFailed) {
//       _cameraActivationFailed = true;
//       await _audioPlayer.play(AssetSource('sounds/error.mp3'));
//       print("\x1B[32m Camera activation failed\x1B[0m");
//       await _flutterTts.speak('Camera activation failed, returning to landing page');

//       _stopListening();
//     }
//   }

//   void _stopCameraAndGoBack()async{
//     try {
//       print("\x1B[32m Navigating to landing page\x1B[0m");
//       Navigator.of(context).pushReplacementNamed('/').then((_) {
//         setState(() {
//           _isActivated = false;
//           _text = "";
//           _cameraActivationFailed = false;
//         });
//       });
//     } catch (e) {
//       print('\x1B[32m Navigation error: $e\x1B[0m');
//     }
//   }

//   Future<void> captureAndProcess() async {
//     setState(() {
//       isLoading = true;
//       message = "Capturing image and processing...";
//     });

//     try {
//       print('\x1B[32m Capture called\x1B[0m');
//       http.Response response;

//       if (!_isUsingEsp32Cam) {
//         final image = await _cameraController.takePicture();
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
//         // If using ESP32, send a POST request to capture the image
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
//   void dispose() {
//     if (!_isUsingEsp32Cam) {
//       _cameraController.dispose();
//     }
//     _s.stop();
//     _s.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     SizeConfig().init(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           _isUsingEsp32Cam ? "ESP32-CAM Feed" : "Mobile Camera",
//           style: mBold.copyWith(color: mPurple, fontSize: SizeConfig.blocksHorizontal! * 4),
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(_isUsingEsp32Cam ? Icons.camera : Icons.videocam),
//             onPressed: _toggleCamera,
//           ),
//         ],
//       ),
//       body: Container(
//         padding: const EdgeInsets.only(top: 50.0),
//         child: Column(
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: mPurple, width: 4),
//               ),
//               child: ClipRect(
//                 child: AspectRatio(
//                   aspectRatio: 16 / 9,
//                   child: _isUsingEsp32Cam
//                       ? Mjpeg(
//                           isLive: true,
//                           stream: streamUrl,
//                           error: (context, error, stack) {
//                             _playFailureSound();
//                             return Text('Stream Error: $error');
//                           },
//                         )
//                       : _cameraActivationFailed
//                           ? const Center(child: Text("Camera failed to activate."))
//                           : (_initializeControllerFuture == null
//                               ? const Center(child: CircularProgressIndicator())
//                               : FutureBuilder<void>(
//                                   future: _initializeControllerFuture,
//                                   builder: (context, snapshot) {
//                                     if (snapshot.connectionState == ConnectionState.done) {
//                                       return CameraPreview(_cameraController);
//                                     } else if (snapshot.hasError) {
//                                       return Center(child: Text('Camera Error: ${snapshot.error}'));
//                                     } else {
//                                       return const Center(child: CircularProgressIndicator());
//                                     }
//                                   },
//                                 )),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               message,
//               style: const TextStyle(fontSize: 20, color: Colors.white),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:frontend/main.dart';
import 'package:frontend/utils/app_style.dart';
import 'package:frontend/utils/size_config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'scene_logs_page.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late String streamUrl;
  late AudioPlayer _audioPlayer;
  late CameraController _cameraController;
  Future<void>? _initializeControllerFuture;

  bool _isUsingEsp32Cam = true;

  late stt.SpeechToText _s;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _isActivated = false;
  bool _cameraActivationFailed = false;
  bool _isCameraInitialized = false;
  bool _isInitializing = false;
  String message = "Press the button to capture and process OCR.";
  bool isLoading = false;
  String? _lastCommand;

  String _text = "";

  final String esp32CaptureUrl = "http://192.168.1.10/capture";
  final String djangoUrl = "http://192.168.1.4:8000/api/upload-image/";

  @override
  void initState() {
    super.initState();
    _s = stt.SpeechToText();
    _audioPlayer = AudioPlayer();
    _flutterTts = FlutterTts();
    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    _isUsingEsp32Cam = arguments['useEsp32Cam'] ?? true;

    if (!_isUsingEsp32Cam) {
      _initializeMobileCamera();
      _checkPermissions();
    } else {
      streamUrl = "http://192.168.1.10:81/stream";
    }
  }

  void _checkPermissions() async {
    if (_isCameraInitialized && !_cameraActivationFailed) {
      print('\x1B[32m $_isCameraInitialized\x1B[0m');
      if (await Permission.microphone.request().isGranted) {
        print('\x1B[32m Microphone permission granted\x1B[0m');

        if (isSpeechRecognitionActiveScreen2 == true) {
          Future.delayed(Duration(milliseconds: 500), () {
            _startListening();
          });
        }
      } else {
        print('\x1B[32m Microphone permission denied\x1B[0m');
      }
    } else {
      print('\x1B[32m Camera is not initialized yet\x1B[0m');
    }
  }

  Future<void> _initializeMobileCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print("\x1B[32m No cameras found\x1B[0m");
        setState(() {
          _cameraActivationFailed = true;
        });
        return;
      }
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _cameraController.initialize();

      await _initializeControllerFuture;
      print("\x1B[32m Camera initialized!\x1B[0m");
      setState(() {
        _isCameraInitialized = true;
        _cameraActivationFailed = false;
      });

      _checkPermissions();
    } catch (e) {
      _playFailureSound();
      setState(() {
        _cameraActivationFailed = true;
      });
      print('\x1B[32m Camera initialization failed: $e\x1B[0m');
    }
  }

  void _toggleCamera() {
    setState(() {
      _isUsingEsp32Cam = !_isUsingEsp32Cam;
    });

    if (!_isUsingEsp32Cam) {
      _initializeMobileCamera();
    } else {
      if (streamUrl.isEmpty) {
        _playFailureSound();
        print('\x1B[32m ESP32-CAM stream failed to activate\x1B[0m');
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      await _s.stop();

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

  void onError(SpeechRecognitionError error) {
    print('\x1B[32m Error during speech recognition: ${error.errorMsg}\x1B[0m');
    if (error.errorMsg == 'speech timeout' ||
        error.errorMsg == 'microphone is busy') {
      _startListening();
    }
  }

  void _startListening() async {
    try {
      if (isSpeechRecognitionActiveScreen2 == true &&
          _isActivated == false &&
          _isListening == false &&
          _isInitializing == false) {
        _isInitializing = true;

        bool available = await _s.initialize(onStatus: onStatus);

        if (available) {
          print("\x1B[32m Start Speech recognition\x1B[0m");

          setState(() {
            _isListening = true;
            _isActivated = false;
            _text = "Listening for commands...";
          });

          _s.listen(onResult: (result) async {
            final newText = result.recognizedWords;
            print('\x1B[32m Detected word [2]: $newText\x1B[0m');

            if (newText.toLowerCase() != _lastCommand) {
              _lastCommand = newText.toLowerCase();

              setState(() {
                _text = newText;
              });

              if (_lastCommand!.contains('capture') && !_isActivated) {
                setState(() {
                  _isActivated = true;
                  _text = '';
                });
                await captureAndProcess();
              } else if (_lastCommand!.contains('stop') && !_isActivated) {
                setState(() {
                  _isActivated = true;
                  _text = '';
                });
                await _stopListening();
              }
            }
          });
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

  void _restartListening() async {
    print('\x1B[32m Restarting speech recognition\x1B[0m');
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _isListening = false;
    });
    _startListening();
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

  Future<void> captureAndProcess() async {
    setState(() {
      isLoading = true;
      message = "Capturing image and processing...";
    });

    try {
      print('\x1B[32m Capture called\x1B[0m');
      http.Response response;

      if (!_isUsingEsp32Cam) {
        final image = await _cameraController.takePicture();
        final imagePath = image.path;

        var request = http.MultipartRequest(
          'POST',
          Uri.parse(djangoUrl),
        );

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

  void replayMostRecentSceneLog() async {
    List<Map<String, dynamic>> logs = await getSceneLogsFromDB();
    logs.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    if (logs.isNotEmpty) {
      Map<String, dynamic> recentLog = logs.first;
      // Your replay function here
      replayLog(recentLog);
    }
  }

  void replayLog(Map<String, dynamic> log) async {
    final String sceneDescription =
        log['description'] ?? "No description available.";
    setState(() {
      message = sceneDescription;
    });
    await _flutterTts.speak(sceneDescription);
  }

  @override
  void dispose() {
    if (!_isUsingEsp32Cam) {
      _cameraController.dispose();
    }
    _s.stop();
    _s.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isUsingEsp32Cam ? "ESP32-CAM Feed" : "Mobile Camera",
          style: mBold.copyWith(
              color: mPurple, fontSize: SizeConfig.blocksHorizontal! * 4),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: replayMostRecentSceneLog,
          ),
          IconButton(
            icon: Icon(_isUsingEsp32Cam ? Icons.camera : Icons.videocam),
            onPressed: _toggleCamera,
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.only(top: 50.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: mPurple, width: 4),
              ),
              child: ClipRect(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _isUsingEsp32Cam
                      ? Mjpeg(
                          isLive: true,
                          stream: streamUrl,
                          error: (context, error, stack) {
                            _playFailureSound();
                            return Text('Stream Error: $error');
                          },
                        )
                      : _cameraActivationFailed
                          ? const Center(
                              child: Text("Camera failed to activate."))
                          : (_initializeControllerFuture == null
                              ? const Center(child: CircularProgressIndicator())
                              : FutureBuilder<void>(
                                  future: _initializeControllerFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      return CameraPreview(_cameraController);
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child: Text(
                                              'Camera Error: ${snapshot.error}'));
                                    } else {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    }
                                  },
                                )),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
