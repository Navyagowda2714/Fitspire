//
//  RepCounterViewModel.swift
//  Fitspire
//
//  Created by Navyashree Byregowda on 01/06/2026.
//

/*
import Foundation
import AVFoundation
import Vision
import Combine

@MainActor
final class RepCounterViewModel: NSObject, ObservableObject {

    // MARK: - Published
    @Published var repCount: Int = 0
    @Published var formScore: Int = 100          // 0–100
    @Published var formFeedback: String = ""
    @Published var isInBadForm: Bool = false
    @Published var jointPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]

    // MARK: - Camera
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "com.fitspire.camera", qos: .userInitiated)

    // MARK: - Rep state machine
    private var exerciseName: String = ""
    private var repState: RepState = .up
    private var angleHistory: [Double] = []
    private var lastRepTime: Date = .distantPast

    enum RepState { case up, down }

    // MARK: - Setup
    func configure(exercise: String) {
        self.exerciseName = exercise
        repCount = 0
        formScore = 100
        setupCamera()
    }

    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        session.commitConfiguration()

        Task.detached { [weak self] in await self?.session.startRunning() }
    }

    func stop() {
        Task.detached { [weak self] in self?.session.stopRunning() }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension RepCounterViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput,
                                   didOutput sampleBuffer: CMSampleBuffer,
                                   from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        detectPose(in: pixelBuffer)
    }

    private nonisolated func detectPose(in pixelBuffer: CVPixelBuffer) {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .leftMirrored)
        try? handler.perform([request])
        guard let obs = request.results?.first else { return }
        Task { @MainActor [weak self] in
            self?.processObservation(obs)
        }
    }
}

// MARK: - Pose Processing
extension RepCounterViewModel {
    private func processObservation(_ obs: VNHumanBodyPoseObservation) {
        // Extract joints
        let joints = extractJoints(obs)
        self.jointPoints = joints

        // Exercise-specific logic
        switch exerciseName.lowercased() {
        case "push-up", "pushup":   processPushUp(joints)
        case "squat":               processSquat(joints)
        case "lunge":               processLunge(joints)
        case "plank":               processPlank(joints)
        default:                    processGeneric(joints)
        }
    }

    private func extractJoints(_ obs: VNHumanBodyPoseObservation) -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
        var dict: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        let names: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle,
            .neck, .root
        ]
        for name in names {
            if let pt = try? obs.recognizedPoint(name), pt.confidence > 0.4 {
                dict[name] = CGPoint(x: pt.x, y: 1 - pt.y) // flip Y for screen coords
            }
        }
        return dict
    }

    // MARK: Push-Up
    private func processPushUp(_ j: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        guard let ls = j[.leftShoulder], let le = j[.leftElbow], let lw = j[.leftWrist] else { return }
        let angle = angleBetween(a: ls, b: le, c: lw)
        countRep(angle: angle, downThreshold: 90, upThreshold: 160)

        // Form: check body alignment hip-shoulder
        if let lh = j[.leftHip] {
            let hipDrop = abs(lh.y - ls.y)
            if hipDrop > 0.12 {
                postFormAlert("Keep hips level — don't sag", score: 60)
            } else {
                clearFormAlert()
            }
        }
    }

    // MARK: Squat
    private func processSquat(_ j: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        guard let lh = j[.leftHip], let lk = j[.leftKnee], let la = j[.leftAnkle] else { return }
        let angle = angleBetween(a: lh, b: lk, c: la)
        countRep(angle: angle, downThreshold: 100, upThreshold: 160)

        // Form: knee-over-toe check
        if let _ = j[.leftWrist] {} // placeholder
        if lk.x < la.x - 0.05 {
            postFormAlert("Knees caving in — push them out", score: 65)
        } else {
            clearFormAlert()
        }
    }

    // MARK: Lunge
    private func processLunge(_ j: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        guard let lh = j[.leftHip], let lk = j[.leftKnee], let la = j[.leftAnkle] else { return }
        let angle = angleBetween(a: lh, b: lk, c: la)
        countRep(angle: angle, downThreshold: 100, upThreshold: 155)

        if let neck = j[.neck], let root = j[.root] {
            let lean = abs(neck.x - root.x)
            if lean > 0.08 {
                postFormAlert("Keep torso upright", score: 70)
            } else { clearFormAlert() }
        }
    }

    // MARK: Plank
    private func processPlank(_ j: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        guard let ls = j[.leftShoulder], let lh = j[.leftHip], let la = j[.leftAnkle] else { return }
        let yVariance = abs(lh.y - ((ls.y + la.y) / 2))
        if yVariance > 0.08 {
            postFormAlert("Hips too high or low — hold the line", score: 55)
        } else {
            formScore = 100
            formFeedback = "Great form!"
            isInBadForm = false
        }
    }

    // MARK: Generic fallback
    private func processGeneric(_ j: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        guard let ls = j[.leftShoulder], let le = j[.leftElbow], let lw = j[.leftWrist] else { return }
        let angle = angleBetween(a: ls, b: le, c: lw)
        countRep(angle: angle, downThreshold: 90, upThreshold: 160)
    }

    // MARK: Rep state machine
    private func countRep(angle: Double, downThreshold: Double, upThreshold: Double) {
        angleHistory.append(angle)
        if angleHistory.count > 5 { angleHistory.removeFirst() }
        let smoothed = angleHistory.reduce(0, +) / Double(angleHistory.count)

        switch repState {
        case .up where smoothed < downThreshold:
            repState = .down
        case .down where smoothed > upThreshold:
            let now = Date()
            if now.timeIntervalSince(lastRepTime) > 0.5 { // debounce
                repCount += 1
                lastRepTime = now
                repState = .up
                // Notify Watch
                let stats = WatchRepUpdate(repCount: repCount,
                                           formScore: formScore,
                                           feedback: formFeedback)
                WatchConnectivityManager.shared.sendRepUpdate(stats)
            }
        default: break
        }
    }

    // MARK: Form helpers
    private func postFormAlert(_ message: String, score: Int) {
        formFeedback = message
        formScore = score
        isInBadForm = true
        WatchConnectivityManager.shared.sendPostureAlert(message)
    }

    private func clearFormAlert() {
        if isInBadForm {
            formFeedback = "Good form!"
            formScore = 100
            isInBadForm = false
        }
    }

    // MARK: Geometry
    private nonisolated func angleBetween(a: CGPoint, b: CGPoint, c: CGPoint) -> Double {
        let ab = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let cb = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = ab.dx * cb.dx + ab.dy * cb.dy
        let cross = ab.dx * cb.dy - ab.dy * cb.dx
        return abs(atan2(cross, dot) * 180 / .pi)
    }
}
*/
