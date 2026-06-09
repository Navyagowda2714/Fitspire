//
//  WatchConnectivityManager.swift
//  Fitspyre (iOS target)
//
//  Sends two kinds of payloads to the paired Apple Watch:
//    • Form alerts  — a posture fault + a short fix the user can act on
//    • Rep updates  — live rep count, set progress and form score
//
//  Both fall back to transferUserInfo when the watch app is in the background.
//

import Foundation
import WatchConnectivity
import Combine

// Message "kind" so the watch can tell payloads apart.
enum WatchPayloadKind: String {
    case formAlert
    case repUpdate
}

final class WatchConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {

    static let shared = WatchConnectivityManager()

    @Published var isWatchReachable = false

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Public API

    /// Send a posture/form fault to the watch. `fix` is a short corrective cue
    /// (e.g. "Chest up, brace your core") shown under the issue.
    func sendFormAlert(exercise: String, issue: String, fix: String = "") {
        let payload: [String: Any] = [
            "kind":      WatchPayloadKind.formAlert.rawValue,
            "exercise":  exercise,
            "issue":     issue,
            "fix":       fix.isEmpty ? Self.defaultFix(for: issue) : fix,
            "timestamp": Date().timeIntervalSince1970
        ]
        deliver(payload)
    }

    /// Send a live rep update to the watch.
    func sendRepUpdate(exercise: String,
                       repsInSet: Int,
                       targetReps: Int,
                       currentSet: Int,
                       totalSets: Int,
                       formScore: Int,
                       feedback: String) {
        let payload: [String: Any] = [
            "kind":       WatchPayloadKind.repUpdate.rawValue,
            "exercise":   exercise,
            "repsInSet":  repsInSet,
            "targetReps": targetReps,
            "currentSet": currentSet,
            "totalSets":  totalSets,
            "formScore":  formScore,
            "feedback":   feedback,
            "timestamp":  Date().timeIntervalSince1970
        ]
        deliver(payload)
    }

    // MARK: - Delivery

    private func deliver(_ payload: [String: Any]) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isPaired,
              WCSession.default.isWatchAppInstalled else { return }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { _ in
                // Reachable check can race; fall back to queued delivery.
                WCSession.default.transferUserInfo(payload)
            }
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }

    /// Reasonable default corrective cue based on keywords in the issue text.
    private static func defaultFix(for issue: String) -> String {
        let s = issue.lowercased()
        if s.contains("back") || s.contains("spine") || s.contains("round") {
            return "Chest up, brace your core"
        } else if s.contains("knee") {
            return "Track knees over your toes"
        } else if s.contains("hip") {
            return "Keep hips level and square"
        } else if s.contains("depth") || s.contains("lower") {
            return "Go a little deeper, controlled"
        } else if s.contains("elbow") {
            return "Tuck elbows ~45°"
        } else if s.contains("neck") || s.contains("head") {
            return "Keep your neck neutral"
        }
        return "Reset and slow it down"
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
