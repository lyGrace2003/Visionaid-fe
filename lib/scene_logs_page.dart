import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SceneLogsPage extends StatefulWidget {
  const SceneLogsPage({super.key});

  @override
  State<SceneLogsPage> createState() => _SceneLogsPageState();
}

class _SceneLogsPageState extends State<SceneLogsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> sceneLogs = [];
  List<Map<String, dynamic>> ocrResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchLogs();
  }

  void fetchLogs() async {
    // Example mock DB fetch
    // Replace with your actual DB read
    DateTime now = DateTime.now();
    DateTime fiveDaysAgo = now.subtract(Duration(days: 5));

    // Fetch from your database here
    List<Map<String, dynamic>> allLogs = await getSceneLogsFromDB();

    setState(() {
      sceneLogs = allLogs.where((log) {
        DateTime date = DateTime.parse(log['timestamp']);
        return date.isAfter(fiveDaysAgo);
      }).toList();

      ocrResults = sceneLogs.where((log) => log['type'] == 'ocr').toList();
    });
  }

  void replayLog(Map<String, dynamic> log) {
    // Implement your replay logic here
    print("Replaying log: ${log['path']}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scene Logs"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Scene Logs"),
            Tab(text: "OCR Results"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildLogList(sceneLogs),
          buildLogList(ocrResults),
        ],
      ),
    );
  }

  Widget buildLogList(List<Map<String, dynamic>> logs) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          child: ListTile(
            title: Text("Log at ${log['timestamp']}"),
            subtitle: Text(log['description'] ?? 'No description'),
            trailing: IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () => replayLog(log),
            ),
          ),
        );
      },
    );
  }
}

Future<List<Map<String, dynamic>>> getSceneLogsFromDB() async {
  final response = await http.get(
    Uri.parse(
        'http://192.168.1.28:8000/scene-logs/'), // update to your actual Django IP + port
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data
        .map((log) => {
              'id': log['id'],
              'description': log['description'],
              'timestamp': log['timestamp'],
            })
        .toList();
  } else {
    throw Exception('Failed to load logs from backend');
  }
}
