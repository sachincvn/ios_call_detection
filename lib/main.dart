import 'package:flutter/material.dart';
import 'dart:async';

import 'call_model.dart';
import 'call_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final CallService _callService = CallService();
  List<CallInfo> _allCallEvents = []; // To store all detected call events for history
  Map<String, CallInfo> _activeCalls = {}; // To store only currently active calls

  // Timer to update duration for active calls in UI
  Timer? _durationUpdateTimer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch(state){
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.paused:
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _callService.callUpdates.listen((updatedCalls) {
      setState(() {
        _activeCalls.clear();
        for (var call in updatedCalls) {
          _allCallEvents.add(call); // Add to history
          if (!call.hasEnded) {
            _activeCalls[call.uuid] = call; // Keep active calls
          }
        }
        // Remove ended calls from active list
        _activeCalls.removeWhere((key, value) => value.hasEnded);

        // Restart timer if there are active calls
        _durationUpdateTimer?.cancel();
        if (_activeCalls.isNotEmpty) {
          _durationUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              // Trigger rebuild to update durations
            });
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _durationUpdateTimer?.cancel();
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Detection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Call Detection (iOS)'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current Call Status:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_activeCalls.isEmpty)
                const Text('No active calls detected.')
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _activeCalls.values.map((call) {
                    final currentDuration = call.connectedTimestamp != null && !call.hasEnded
                        ? DateTime.now().difference(call.connectedTimestamp!).inSeconds.toDouble()
                        : call.duration;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('UUID: ${call.uuid.substring(0, 8)}...'),
                            Text('Type: ${call.isOutgoing ? 'Outgoing' : 'Incoming'}'),
                            Text('State: ${call.state}'),
                            Text('Duration: ${CallInfo( // Use a temporary instance to format
                              uuid: '', isOutgoing: false, hasConnected: false, hasEnded: false, isOnHold: false,
                              duration: currentDuration,
                            ).formattedDuration}'),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              const Text(
                'Call History:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _allCallEvents.length,
                  itemBuilder: (context, index) {
                    final call = _allCallEvents[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: call.hasEnded ? Colors.grey[200] : Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('UUID: ${call.uuid.substring(0, 8)}...'),
                            Text('Type: ${call.isOutgoing ? 'Outgoing' : 'Incoming'}'),
                            Text('State: ${call.state}'),
                            Text('Connected: ${call.connectedTimestamp?.toLocal().toIso8601String().split('.')[0] ?? 'N/A'}'),
                            Text('Ended: ${call.endedTimestamp?.toLocal().toIso8601String().split('.')[0] ?? 'N/A'}'),
                            Text('Duration: ${call.formattedDuration}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}