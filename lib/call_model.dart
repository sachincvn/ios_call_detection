class CallInfo {
  final String uuid;
  final bool isOutgoing;
  final bool hasConnected;
  final bool hasEnded;
  final bool isOnHold;
  final DateTime? connectedTimestamp;
  final DateTime? endedTimestamp;
  final double? duration; // Duration in seconds

  CallInfo({
    required this.uuid,
    required this.isOutgoing,
    required this.hasConnected,
    required this.hasEnded,
    required this.isOnHold,
    this.connectedTimestamp,
    this.endedTimestamp,
    this.duration,
  });

  factory CallInfo.fromJson(Map<dynamic, dynamic> json) {
    return CallInfo(
      uuid: json['uuid'] as String,
      isOutgoing: json['isOutgoing'] as bool,
      hasConnected: json['hasConnected'] as bool,
      hasEnded: json['hasEnded'] as bool,
      isOnHold: json['isOnHold'] as bool,
      connectedTimestamp: json['connectedTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
          (json['connectedTimestamp'] * 1000).toInt())
          : null,
      endedTimestamp: json['endedTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
          (json['endedTimestamp'] * 1000).toInt())
          : null,
      duration: (json['duration'] as num?)?.toDouble(),
    );
  }

  String get state {
    if (hasEnded) return 'Ended';
    if (hasConnected) return 'Connected';
    if (isOutgoing) return 'Outgoing';
    return 'Ringing/Unknown';
  }

  String get formattedDuration {
    if (duration == null) return 'N/A';
    int minutes = (duration! / 60).floor();
    int seconds = (duration! % 60).toInt();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'CallInfo(uuid: $uuid, isOutgoing: $isOutgoing, hasConnected: $hasConnected, hasEnded: $hasEnded, isOnHold: $isOnHold, '
        'connectedTimestamp: $connectedTimestamp, endedTimestamp: $endedTimestamp, duration: $duration)';
  }
}