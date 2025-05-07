import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SpeechRecognitionTest(),
    );
  }
}

class SpeechRecognitionTest extends StatefulWidget {
  const SpeechRecognitionTest({super.key});

  @override
  _SpeechRecognitionTestState createState() => _SpeechRecognitionTestState();
}

class _SpeechRecognitionTestState extends State<SpeechRecognitionTest> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = "";
  Map<String, String> testPhrases = {
    "1": "start",
    "2": "capture",
    "3": "describe",
    "4": "exit",
  };
  Map<String, bool> accuracyResults = {};

  // Function to calculate accuracy (match the full recognized phrase)
  bool calculateAccuracy(String recognizedPhrase) {
    String lowerRecognizedPhrase = recognizedPhrase.trim().toLowerCase();

    // Check for an exact match
    for (var entry in testPhrases.entries) {
      String testPhrase = entry.value.toLowerCase();
      if (lowerRecognizedPhrase == testPhrase) {
        return true; // Exact match
      }
    }
    return false; // No match
  }

  // Start listening
  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
              // Compare and calculate accuracy for exact phrase match
              accuracyResults = {
                for (var entry in testPhrases.entries)
                  entry.key: calculateAccuracy(result.recognizedWords),
              };
            });
          },
          listenFor: Duration(seconds: 10), // Add this to specify maximum listening duration
          pauseFor: Duration(seconds: 5), // Allow a pause for 5 seconds before stopping
          partialResults: true, // Capture partial results to show as you speak
          onSoundLevelChange: (double level) {
            print("Sound level: $level");
          },
        );
      }
    }
  }

  // Stop listening
  void _stopListening() {
    if (_isListening) {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
      // Update the accuracy results after stopping the listening
      setState(() {
        accuracyResults = {
          for (var entry in testPhrases.entries)
            entry.key: calculateAccuracy(_text),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Speech Recognition Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Please say one of the following commands:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...testPhrases.entries.map((entry) {
              return Text('${entry.key}: ${entry.value}');
            }),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? 'Stop Listening' : 'Start Listening'),
            ),
            SizedBox(height: 20),
            Text(
              "You said: $_text",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              "Accuracy Results:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...accuracyResults.entries.map((entry) {
              return Text(
                "Test phrase ${entry.key} matched: ${entry.value ? 'Yes' : 'No'}",
                style: TextStyle(fontSize: 16),
              );
            }),
          ],
        ),
      ),
    );
  }
}
