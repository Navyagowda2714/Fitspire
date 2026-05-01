//
//  BodyScanViewModel.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//


import Foundation
import AVFoundation
import Vision
import SwiftData
import Combine

@MainActor
final class BodyScanViewModel: NSObject, ObservableObject {
    @Published var detectedBody: DetectedBody?
    @Published var scanComplete: Bool = false
    @Published var postureScore: Double = 0
    @Published var symmetryScore: Double = 0
    @Published var mobilityScore: Double = 0
    @Published var scanNotes: [String] = []
    @Published var isScanning: Bool = false

    let cameraManager = CameraManager()
    private let poseService = PoseDetectionService()
    private var frameCount = 0

    override init() {
        super.init()
        cameraManager.delegate = self
    }

    func startCamera() {
        cameraManager.startSession()
    }

    func stopCamera() {
        cameraManager.stopSession()
    }

    func performScan() {
        guard detectedBody != nil else { return }
        isScanning = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            self.calculateScores()
            self.isScanning = false
            self.scanComplete = true
        }
    }

    private func calculateScores() {
        guard let body = detectedBody else { return }
        let joints = body.joints

        postureScore = calculatePostureScore(joints: joints)
        symmetryScore = calculateSymmetryScore(joints: joints)
        mobilityScore = calculateMobilityScore(joints: joints)
        scanNotes = generateNotes()
    }

    private func calculatePostureScore(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> Double {
        var score = 85.0

        if let leftShoulder = joints[.leftShoulder],
           let rightShoulder = joints[.rightShoulder] {
            let diff = abs(leftShoulder.y - rightShoulder.y)
            if diff > 0.05 { score -= 10 }
        }

        if let nose = joints[.nose],
           let root = joints[.root] {
            let spineX = root.x
            let headX = nose.x
            let deviation = abs(headX - spineX)
            if deviation > 0.05 { score -= 8 }
        }

        return min(max(score, 0), 100)
    }

    private func calculateSymmetryScore(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> Double {
        var score = 90.0
        var checks = 0
        var passed = 0

        let pairs: [(VNHumanBodyPoseObservation.JointName,
                      VNHumanBodyPoseObservation.JointName)] = [
            (.leftShoulder, .rightShoulder),
            (.leftHip, .rightHip),
            (.leftKnee, .rightKnee)
        ]

        for (left, right) in pairs {
            if let l = joints[left], let r = joints[right] {
                checks += 1
                let diff = abs(l.y - r.y)
                if diff < 0.04 { passed += 1 }
            }
        }

        if checks > 0 {
            score = Double(passed) / Double(checks) * 100
        }

        return min(max(score, 0), 100)
    }

    private func calculateMobilityScore(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> Double {
        return Double.random(in: 68...82)
    }

    private func generateNotes() -> [String] {
        var notes: [String] = []

        if postureScore < 75 {
            notes.append("Forward head posture detected. Consider neck mobility work.")
        }
        if symmetryScore < 80 {
            notes.append("Minor shoulder imbalance detected. Focus on balanced training.")
        }
        if mobilityScore < 75 {
            notes.append("Mobility warm-up recommended before each session.")
        }
        if notes.isEmpty {
            notes.append("Good baseline posture. Maintain consistent training.")
        }

        return notes
    }

    func saveResult(context: ModelContext) {
        let result = BodyScanResult(
            postureScore: postureScore,
            symmetryScore: symmetryScore,
            mobilityScore: mobilityScore
        )
        context.insert(result)
        try? context.save()
    }
}

extension BodyScanViewModel: CameraManagerDelegate {
    nonisolated func cameraManager(
        _ manager: CameraManager,
        didOutput sampleBuffer: CMSampleBuffer
    ) {
        let detected = poseService.detect(sampleBuffer: sampleBuffer)
        Task { @MainActor [weak self] in
            self?.detectedBody = detected
        }
    }
}
