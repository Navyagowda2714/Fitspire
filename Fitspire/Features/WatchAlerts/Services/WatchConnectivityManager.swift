//
//  WatchConnectivityManager.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 03/05/2026.
//


import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isWatchReachable: Bool = false
    @Published var lastSentAlert: WatchAlertPayload?

    private override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    var isWatchConnected: Bool {
        guard WCSession.isSupported() else { return false }
        return WCSession.default.isReachable
    }

    func sendAlert(_ payload: WatchAlertPayload) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }

        let message: [String: Any] = [
            "title":     payload.title,
            "message":   payload.message,
            "severity":  payload.severity,
            "timestamp": payload.timestamp.timeIntervalSince1970
        ]

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                message,
                replyHandler: nil
            ) { error in
                print("Watch error: \(error.localizedDescription)")
            }
        } else {
            try? WCSession.default.updateApplicationContext(message)
        }

        lastSentAlert = payload
    }

    func sendWorkoutStatus(
        exercise: String,
        formScore: Int,
        isActive: Bool
    ) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }

        let context: [String: Any] = [
            "exercise":  exercise,
            "formScore": formScore,
            "isActive":  isActive
        ]
        try? WCSession.default.updateApplicationContext(context)
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor [weak self] in
            self?.isWatchReachable = session.isReachable
        }
    }
}
struct WatchRepUpdate: Codable {
    var repCount: Int
    var formScore: Int
    var feedback: String
}

// Add to WatchConnectivityManager
func sendRepUpdate(_ update: WatchRepUpdate) {
    guard WCSession.default.activationState == .activated,
          WCSession.default.isReachable else { return }
    let data = (try? JSONEncoder().encode(update)) ?? Data()
    WCSession.default.sendMessage(["repUpdate": data], replyHandler: nil)
}

func sendPostureAlert(_ message: String) {
    guard WCSession.default.activationState == .activated else { return }
    WCSession.default.sendMessage(["postureAlert": message], replyHandler: nil)
}


// MARK: - Rep counter + posture alert helpers
extension WatchConnectivityManager {
    func sendRepUpdate(_ update: WatchRepUpdate) {
        guard WCSession.default.activationState == .activated,
              WCSession.default.isReachable else { return }
        let data = (try? JSONEncoder().encode(update)) ?? Data()
        WCSession.default.sendMessage(["repUpdate": data], replyHandler: nil)
    }

    func sendPostureAlert(_ message: String) {
        guard WCSession.default.activationState == .activated else { return }
        let msg: [String: Any] = ["postureAlert": message]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(msg, replyHandler: nil)
        } else {
            WCSession.default.transferUserInfo(msg)
        }
    }
}
