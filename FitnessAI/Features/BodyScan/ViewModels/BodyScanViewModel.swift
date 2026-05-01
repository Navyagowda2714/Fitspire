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
    @Published var isScanning: Bool = false
    @Published var postureAnalysis: PostureAnalysis?

    let cameraManager = CameraManager()
    private let poseService = PoseDetectionService()
    private let analysisService = PostureAnalysisService()

    var postureScore: Double { postureAnalysis?.postureScore ?? 0 }
    var symmetryScore: Double { postureAnalysis?.symmetryScore ?? 0 }
    var mobilityScore: Double { postureAnalysis?.mobilityScore ?? 0 }
    var scanNotes: [String] {
        postureAnalysis?.notes.map { $0.message } ?? []
    }
    var recommendedIntensity: String {
        postureAnalysis?.recommendedIntensity.rawValue ?? "Standard"
    }

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
        guard let body = detectedBody else { return }
        isScanning = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            self.postureAnalysis = self.analysisService.analyse(body: body)
            self.isScanning = false
            self.scanComplete = true
        }
    }

    func saveResult(context: ModelContext) {
        guard let analysis = postureAnalysis else { return }

        let result = BodyScanResult(
            postureScore: analysis.postureScore,
            symmetryScore: analysis.symmetryScore,
            mobilityScore: analysis.mobilityScore
        )
        result.notes = analysis.notes.map { $0.message }
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
