import Foundation
import CallKit
import Flutter

// Define a struct to send call details to Flutter
struct CallInfo: Codable {
    let uuid: String
    let isOutgoing: Bool
    let hasConnected: Bool
    let hasEnded: Bool
    let isOnHold: Bool
    let connectedTimestamp: Double? // Timestamp when call connected
    let endedTimestamp: Double?     // Timestamp when call ended
    let duration: Double?           // Calculated duration if ended

    // Convert CXCall to CallInfo
    init(call: CXCall, connectedTimestamp: Double?, endedTimestamp: Double?, duration: Double?) {
        self.uuid = call.uuid.uuidString
        self.isOutgoing = call.isOutgoing
        self.hasConnected = call.hasConnected
        self.hasEnded = call.hasEnded
        self.isOnHold = call.isOnHold
        self.connectedTimestamp = connectedTimestamp
        self.endedTimestamp = endedTimestamp
        self.duration = duration
    }

    func toDictionary() -> [String: Any] {
        return [
            "uuid": uuid,
            "isOutgoing": isOutgoing,
            "hasConnected": hasConnected,
            "hasEnded": hasEnded,
            "isOnHold": isOnHold,
            "connectedTimestamp": connectedTimestamp ?? NSNull(),
            "endedTimestamp": endedTimestamp ?? NSNull(),
            "duration": duration ?? NSNull()
        ]
    }
}

class CallManager: NSObject, CXCallObserverDelegate {
    private let callObserver = CXCallObserver()
    private var eventSink: FlutterEventSink?
    private var activeCalls: [UUID: CXCall] = [:] // Store active calls
    private var callTimestamps: [UUID: (connected: Date?, ended: Date?)] = [:] // Store timestamps

    override init() {
        super.init()
        callObserver.setDelegate(self, queue: nil) // Use main queue
        print("[CallManager] Initialized CallObserver delegate.")
    }

    func setEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
        print("[CallManager] Event sink set.")
    }

    // MARK: - CXCallObserverDelegate

    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        print("[CallManager] Call state changed for UUID: \(call.uuid.uuidString)")
        print("[CallManager] isOutgoing: \(call.isOutgoing), hasConnected: \(call.hasConnected), hasEnded: \(call.hasEnded)")

        // Update timestamps
        if call.hasConnected && callTimestamps[call.uuid]?.connected == nil {
            callTimestamps[call.uuid, default: (nil, nil)].connected = Date()
            print("[CallManager] Call connected timestamp recorded for \(call.uuid.uuidString)")
        }

        if call.hasEnded {
            if callTimestamps[call.uuid]?.ended == nil {
                callTimestamps[call.uuid, default: (nil, nil)].ended = Date()
                print("[CallManager] Call ended timestamp recorded for \(call.uuid.uuidString)")
            }
            activeCalls.removeValue(forKey: call.uuid) // Remove ended call
        } else {
            activeCalls[call.uuid] = call // Keep track of active calls
        }

        // Calculate duration if call has ended
        var duration: Double? = nil
        if let connectedDate = callTimestamps[call.uuid]?.connected,
           let endedDate = callTimestamps[call.uuid]?.ended,
           call.hasEnded {
            duration = endedDate.timeIntervalSince(connectedDate)
            print("[CallManager] Call duration calculated: \(duration ?? 0.0) seconds for \(call.uuid.uuidString)")
        }

        // Send update to Flutter
        let callInfo = CallInfo(
            call: call,
            connectedTimestamp: callTimestamps[call.uuid]?.connected?.timeIntervalSince1970,
            endedTimestamp: callTimestamps[call.uuid]?.ended?.timeIntervalSince1970,
            duration: duration
        )

        DispatchQueue.main.async {
            self.eventSink?(callInfo.toDictionary())
            print("[CallManager] Sent call update to Flutter: \(callInfo.toDictionary())")
        }

        // Clean up timestamps for ended calls after dispatching
        if call.hasEnded {
            callTimestamps.removeValue(forKey: call.uuid)
        }
    }

    // This function can be called from Flutter to get initial active calls (if any)
    func getActiveCallInfo() -> [[String: Any]] {
        var infos: [[String: Any]] = []
        for (uuid, call) in activeCalls {
            var duration: Double? = nil
            if let connectedDate = callTimestamps[uuid]?.connected,
               let endedDate = callTimestamps[uuid]?.ended,
               call.hasEnded {
                duration = endedDate.timeIntervalSince(connectedDate)
            } else if let connectedDate = callTimestamps[uuid]?.connected {
                // If call is still active, show duration from connect to now
                duration = Date().timeIntervalSince(connectedDate)
            }

            let callInfo = CallInfo(
                call: call,
                connectedTimestamp: callTimestamps[uuid]?.connected?.timeIntervalSince1970,
                endedTimestamp: callTimestamps[uuid]?.ended?.timeIntervalSince1970,
                duration: duration
            )
            infos.append(callInfo.toDictionary())
        }
        return infos
    }
}