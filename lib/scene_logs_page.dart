import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:frontend/utils/app_style.dart';
// import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';

class SceneLogsPage extends StatefulWidget {
  const SceneLogsPage({super.key});

  @override
  State<SceneLogsPage> createState() => _SceneLogsPageState();
}

class _SceneLogsPageState extends State<SceneLogsPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> sceneLogs = [];
  late FlutterTts flutterTts;
  final String djangoSceneUrl = "http://192.168.1.4:8000/api/scene-logs/";

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    fetchLogs();
  }

  void fetchLogs() async {
    List<Map<String, dynamic>> allLogs = await getSceneLogsFromDB();

    setState(() {
      sceneLogs = allLogs;
      });
  }

  void replayLog(Map<String, dynamic> log) async{
    String? description = log['scene_description'];
    if (description != null && description.isNotEmpty) {
      await flutterTts.speak(description);
    } else {
      print("No scene description to speak.");
    }
  }

  Future<List<Map<String, dynamic>>> getSceneLogsFromDB() async {
    final response = await http.get(
      Uri.parse(djangoSceneUrl), // update to your actual Django IP + port
  );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((log) => {
                'id': log['id'],
                'scene_description': log['scene_description'],
                'created_at': log['created_at'],
              })
          .toList();
    } else {
      throw Exception('Failed to load logs from backend');
    }
  }
  
  String formatDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('MMMM d, y').format(dateTime);
  }

    void _stopCameraAndGoBack()async{
      try {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);  // Navigate only after cleanup
      } catch (e) {
        print('\x1B[32m Navigation error: $e\x1B[0m');
      }
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
        title: Text("Scene Logs", style: mBold.copyWith(color: mPurple)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: buildLogList(sceneLogs),
      ),
    );
  }

  Widget buildLogList(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              formatDate(log['created_at']),
              style: const TextStyle(fontWeight: FontWeight.w400, color: mDarkpurple),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                log['scene_description'] ?? 'No description',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () => replayLog(log),
              tooltip: 'Replay',
            ),
          ),
        );
      },
    );
  }
}

