//
//  LivePoseViewModel.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//


import Foundation
import Vision
import Combine
import SwiftData

@MainActor
final class LivePoseViewModel: NSObject, ObservableObject {
    @Published var detectedBody: DetectedBody?
    @Published var activeAlerts: [FormAlert] = []
    @Published var currentFormScore: Int = 100
    @Published var isSessionActive: Bool = false
    @Published var repCount: Int = 0
    @Published var currentExercise: ExerciseType = .squat
    @Published var elapsedSeconds: Int = 0

    let cameraManager = CameraManager()
    private let poseService     = PoseDetectionService()
    private let safetyEngine    = SafetyRuleEngine()
    private var timer: Timer?
    private var alertHistory: [FormAlert] = []

    override init() {
        super.init()
        cameraManager.delegate = self
    }

    func startSession(exercise: ExerciseType) {
        currentExercise  = exercise
        isSessionActive  = true
        elapsedSeconds   = 0
        repCount         = 0
        activeAlerts     = []
        alertHistory     = []
        currentFormScore = 100
        cameraManager.startSession()
        startTimer()
    }

    func endSession() {
        isSessionActive = false
        cameraManager.stopSession()
        stopTimer()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.elapsedSeconds += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func processAlerts(_ alerts: [FormAlert]) {
        activeAlerts = alerts

        if !alerts.isEmpty {
            alertHistory.append(contentsOf: alerts)
            let deductions = alerts.reduce(0) { sum, alert in
                sum + (alert.severity == .danger ? 5 : 2)
            }
            currentFormScore = max(0, currentFormScore - deductions)
        } else {
            currentFormScore = min(100, currentFormScore + 1)
        }
    }

    var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds  = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var dangerAlerts: [FormAlert] {
        activeAlerts.filter { $0.severity == .danger }
    }

    var shouldSendWatchAlert: Bool {
        safetyEngine.hasDangerAlert(activeAlerts)
    }

    var watchPayload: WatchAlertPayload? {
        guard let alert = safetyEngine.mostSevereAlert(activeAlerts) else {
            return nil
        }
        return safetyEngine.toWatchPayload(alert)
    }
}

extension LivePoseViewModel: CameraManagerDelegate {
    nonisolated func cameraManager(
        _ manager: CameraManager,
        didOutput sampleBuffer: CMSampleBuffer
    ) {
        guard let body = poseService.detect(sampleBuffer: sampleBuffer) else {
            return
        }
        let alerts = safetyEngine.evaluate(
            joints: body.joints,
            exercise: currentExercise
        )
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.detectedBody = body
            self.processAlerts(alerts)
        }
    }
}
