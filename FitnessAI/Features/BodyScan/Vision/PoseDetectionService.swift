//
//  PoseDetectionService.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//


import Vision
import CoreImage

struct DetectedBody {
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let confidence: Float
}

final class PoseDetectionService: Sendable {
    private let requestHandler = VNSequenceRequestHandler()
    private let confidenceThreshold: Float = 0.4

    func detect(sampleBuffer: CMSampleBuffer) -> DetectedBody? {
        let request = VNDetectHumanBodyPoseRequest()

        try? requestHandler.perform(
            [request],
            on: sampleBuffer,
            orientationHandler: nil
        )

        guard
            let observation = request.results?.first
        else { return nil }

        var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]

        let allJoints: [VNHumanBodyPoseObservation.JointName] = [
            .nose,
            .leftEye, .rightEye,
            .leftEar, .rightEar,
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle,
            .root, .neck
        ]

        for jointName in allJoints {
            if let point = try? observation.recognizedPoint(jointName),
               point.confidence > confidenceThreshold {
                joints[jointName] = CGPoint(x: point.location.x,
                                            y: 1 - point.location.y)
            }
        }

        guard !joints.isEmpty else { return nil }

        return DetectedBody(
            joints: joints,
            confidence: observation.confidence
        )
    }
}

extension VNSequenceRequestHandler {
    func perform(
        _ requests: [VNRequest],
        on sampleBuffer: CMSampleBuffer,
        orientationHandler: (() -> CGImagePropertyOrientation)?
    ) throws {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        try perform(requests, on: pixelBuffer)
    }
}
