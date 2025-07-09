import 'dart:async';

import 'package:flutter/services.dart';

import 'call_model.dart';

class CallService {
  static const MethodChannel _methodChannel =
  MethodChannel('com.your_app_name.call_detection/call_methods');
  static const EventChannel _eventChannel =
  EventChannel('com.your_app_name.call_detection/call_events');

  // Stream controller to broadcast call updates
  final StreamController<List<CallInfo>> _callUpdatesController =
  StreamController<List<CallInfo>>.broadcast();
  Stream<List<CallInfo>> get callUpdates => _callUpdatesController.stream;

  // Internal map to keep track of calls by their UUID
  final Map<String, CallInfo> _currentCalls = {};

  CallService() {
    _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      print('[Flutter] Received call event: $event');
      if (event is Map) {
        final callInfo = CallInfo.fromJson(event);
        _updateCallState(callInfo);
      }
    }, onError: (dynamic error) {
      print('[Flutter] Received error from call stream: $error');
    });
    _initiateCallMonitoring();
  }

  // This will be called once on service initialization to get any existing calls
  Future<void> _initiateCallMonitoring() async {
    try {
      final List<dynamic>? initialCalls =
      await _methodChannel.invokeMethod('getInitialActiveCalls');
      if (initialCalls != null) {
        print('[Flutter] Initial active calls: $initialCalls');
        for (var callMap in initialCalls) {
          final callInfo = CallInfo.fromJson(callMap);
          _updateCallState(callInfo);
        }
      }
    } on PlatformException catch (e) {
      print("Failed to get initial active calls: '${e.message}'.");
    }
  }

  void _updateCallState(CallInfo newCall) {
    _currentCalls[newCall.uuid] = newCall;

    // Remove ended calls from the active list, but keep them in the stream history
    if (newCall.hasEnded) {
      // We keep ended calls in the map for a moment, but the list sent
      // to stream should probably exclude them if you only want 'active' ones.
      // For this example, we'll send all calls, then filter on the UI side if needed.
    }

    _callUpdatesController.add(_currentCalls.values.toList());
  }

  void dispose() {
    _callUpdatesController.close();
  }
}