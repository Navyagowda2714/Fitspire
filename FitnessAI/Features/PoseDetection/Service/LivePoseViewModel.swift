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
    @Published var repProgress: Double = 0
    @Published var repPhase: RepPhase = .up

    private var lastAngle: Double = 0
    private var inDownPhase: Bool = false

    enum RepPhase {
        case up, down
    }

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
    func countRep(joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        guard currentExercise != .plank else { return }

        switch currentExercise {
        case .squat, .deadlift:
            countLegRep(joints: joints)
        case .pushUp:
            countPushUpRep(joints: joints)
        case .shoulderPress:
            countPressRep(joints: joints)
        default:
            break
        }
    }

    private func countLegRep(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) {
        guard
            let hip   = joints[.leftHip],
            let knee  = joints[.leftKnee],
            let ankle = joints[.leftAnkle]
        else { return }

        let angle = AngleCalculator.angle(
            pointA: hip,
            pointB: knee,
            pointC: ankle
        )

        repProgress = max(0, min(1, (180 - angle) / 90))

        if angle < 100 && !inDownPhase {
            inDownPhase = true
            repPhase = .down
        } else if angle > 150 && inDownPhase {
            inDownPhase = false
            repPhase = .up
            repCount += 1
        }
    }

    private func countPushUpRep(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) {
        guard
            let shoulder = joints[.leftShoulder],
            let elbow    = joints[.leftElbow],
            let wrist    = joints[.leftWrist]
        else { return }

        let angle = AngleCalculator.angle(
            pointA: shoulder,
            pointB: elbow,
            pointC: wrist
        )

        repProgress = max(0, min(1, (180 - angle) / 100))

        if angle < 90 && !inDownPhase {
            inDownPhase = true
            repPhase = .down
        } else if angle > 150 && inDownPhase {
            inDownPhase = false
            repPhase = .up
            repCount += 1
        }
    }

    private func countPressRep(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) {
        guard
            let shoulder = joints[.leftShoulder],
            let elbow    = joints[.leftElbow],
            let wrist    = joints[.leftWrist]
        else { return }

        let angle = AngleCalculator.angle(
            pointA: shoulder,
            pointB: elbow,
            pointC: wrist
        )

        repProgress = max(0, min(1, angle / 160))

        if angle < 90 && !inDownPhase {
            inDownPhase = true
            repPhase = .down
        } else if angle > 155 && inDownPhase {
            inDownPhase = false
            repPhase = .up
            repCount += 1
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
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectHumanBodyPoseRequest()
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])

        guard let observation = request.results?.first else { return }

        var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        let allJoints: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .leftEye, .rightEye, .leftEar, .rightEar,
            .leftShoulder, .rightShoulder, .leftElbow, .rightElbow,
            .leftWrist, .rightWrist, .leftHip, .rightHip,
            .leftKnee, .rightKnee, .leftAnkle, .rightAnkle, .root, .neck
        ]
        for jointName in allJoints {
            if let point = try? observation.recognizedPoint(jointName),
               point.confidence > 0.4 {
                joints[jointName] = CGPoint(x: point.location.x, y: 1 - point.location.y)
            }
        }

        guard !joints.isEmpty else { return }
        let body = DetectedBody(joints: joints, confidence: observation.confidence)
        let localSafetyEngine = SafetyRuleEngine()

        Task { @MainActor [weak self] in
            guard let self else { return }
            let alerts = localSafetyEngine.evaluate(
                joints: body.joints,
                exercise: self.currentExercise
            )
            self.detectedBody = body
            self.processAlerts(alerts)
            self.countRep(joints: body.joints)   // ← add this line
        }
    }
}
