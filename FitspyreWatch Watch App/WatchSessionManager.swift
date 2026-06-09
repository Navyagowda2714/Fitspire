//
//  WatchSessionManager.swift
//  FitspyreWatch Watch App
//
//  Receives form alerts and live rep updates from the iPhone.
//

import Foundation
import WatchConnectivity
import WatchKit
import Combine

// MARK: - Incoming models

struct FormAlert: Identifiable, Equatable {
    let id         = UUID()
    let exercise:  String
    let issue:     String
    let fix:       String
    let receivedAt: Date

    var timeAgo: String {
        let secs = Int(-receivedAt.timeIntervalSinceNow)
        if secs < 3  { return "now" }
        if secs < 60 { return "\(secs)s ago" }
        return "\(secs / 60)m ago"
    }
}

struct RepStatus: Equatable {
    var exercise:   String
    var repsInSet:  Int
    var targetReps: Int
    var currentSet: Int
    var totalSets:  Int
    var formScore:  Int
    var feedback:   String
    var updatedAt:  Date = Date()

    var progress: Double {
        guard targetReps > 0 else { return 0 }
        return min(1, Double(repsInSet) / Double(targetReps))
    }
}

// MARK: - Session manager

final class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {

    static let shared = WatchSessionManager()

    @Published var latestAlert: FormAlert?
    @Published var repStatus:   RepStatus?
    @Published var isConnected = false
    @Published var showFlash   = false

    private var alertClearWork: DispatchWorkItem?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = (state == .activated)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncoming(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        handleIncoming(userInfo)
    }

    // MARK: - Routing

    private func handleIncoming(_ message: [String: Any]) {
        let kind = WatchPayloadKind(rawValue: message["kind"] as? String ?? "")

        switch kind {
        case .repUpdate:
            handleRepUpdate(message)
        case .formAlert, .none:
            // .none covers older payloads that only carried exercise + issue.
            handleFormAlert(message)
        }
    }

    private func handleFormAlert(_ message: [String: Any]) {
        guard
            let exercise = message["exercise"] as? String,
            let issue    = message["issue"]    as? String
        else { return }
        let fix = message["fix"] as? String ?? ""

        DispatchQueue.main.async {
            self.latestAlert = FormAlert(exercise: exercise, issue: issue,
                                         fix: fix, receivedAt: Date())
            self.fireHaptic(for: issue)
            self.flash()
            self.scheduleAlertClear()
        }
    }

    private func handleRepUpdate(_ message: [String: Any]) {
        guard let exercise = message["exercise"] as? String else { return }
        DispatchQueue.main.async {
            self.repStatus = RepStatus(
                exercise:   exercise,
                repsInSet:  message["repsInSet"]  as? Int ?? 0,
                targetReps: message["targetReps"] as? Int ?? 0,
                currentSet: message["currentSet"] as? Int ?? 1,
                totalSets:  message["totalSets"]  as? Int ?? 1,
                formScore:  message["formScore"]  as? Int ?? 100,
                feedback:   message["feedback"]   as? String ?? "Good form!"
            )
            // A light tick on each rep keeps the user in rhythm.
            WKInterfaceDevice.current().play(.click)
        }
    }

    // MARK: - Feedback

    private func fireHaptic(for issue: String) {
        let lower = issue.lowercased()
        let hapticType: WKHapticType
        if lower.contains("back") || lower.contains("straight") || lower.contains("spine") {
            hapticType = .notification        // strongest — spine faults are critical
        } else if lower.contains("knee") || lower.contains("hip") {
            hapticType = .retry
        } else {
            hapticType = .failure
        }
        WKInterfaceDevice.current().play(hapticType)
    }

    private func flash() {
        showFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.showFlash = false
        }
    }

    /// Auto-clear an alert after a few seconds so the rep counter returns.
    private func scheduleAlertClear() {
        alertClearWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.latestAlert = nil }
        alertClearWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: work)
    }
}

// Mirror of the iOS enum so the watch can decode `kind`.
enum WatchPayloadKind: String {
    case formAlert
    case repUpdate
}
