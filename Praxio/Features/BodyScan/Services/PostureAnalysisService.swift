//
//  PostureAnalysisService.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

import Foundation
import Vision
import CoreGraphics

final class PostureAnalysisService {

    func analyse(body: DetectedBody) -> PostureAnalysis {
        let joints = body.joints

        let spineDeviation   = calculateSpineDeviation(joints: joints)
        let shoulderImbal    = calculateShoulderImbalance(joints: joints)
        let hipImbal         = calculateHipImbalance(joints: joints)

        let postureScore     = calculatePostureScore(
            spineDeviation: spineDeviation,
            shoulderImbalance: shoulderImbal
        )
        let symmetryScore    = calculateSymmetryScore(
            shoulderImbalance: shoulderImbal,
            hipImbalance: hipImbal
        )
        let mobilityScore    = calculateMobilityScore(joints: joints)

        let notes            = generateNotes(
            spineDeviation: spineDeviation,
            shoulderImbalance: shoulderImbal,
            hipImbalance: hipImbal,
            postureScore: postureScore
        )
        let intensity        = recommendIntensity(
            postureScore: postureScore,
            symmetryScore: symmetryScore
        )

        return PostureAnalysis(
            postureScore: postureScore,
            symmetryScore: symmetryScore,
            mobilityScore: mobilityScore,
            spineDeviation: spineDeviation,
            shoulderImbalance: shoulderImbal,
            hipImbalance: hipImbal,
            notes: notes,
            recommendedIntensity: intensity
        )
    }

    // MARK: - Calculations

    private func calculateSpineDeviation(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> Double {
        guard
            let neck = joints[.neck],
            let root = joints[.root]
        else { return 0 }

        return AngleCalculator.verticalDeviation(
            point: neck,
            referenceX: root.x
        ) * 100
    }

    private func calculateShoulderImbalance(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> Double {
        guard
            let left  = joints[.leftShoulder],
            let right = joints[.rightShoulder]
        else { return 0 }

        return AngleCalculator.horizontalDifference(
            pointA: left,
            pointB: right
        ) * 100
    }

    private func calculateHipImbalance(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> Double {
        guard
            let left  = joints[.leftHip],
            let right = joints[.rightHip]
        else { return 0 }

        return AngleCalculator.horizontalDifference(
            pointA: left,
            pointB: right
        ) * 100
    }

    private func calculatePostureScore(
        spineDeviation: Double,
        shoulderImbalance: Double
    ) -> Double {
        var score = 100.0
        score -= min(spineDeviation * 3, 25)
        score -= min(shoulderImbalance * 3, 25)
        return max(score, 0).rounded()
    }

    private func calculateSymmetryScore(
        shoulderImbalance: Double,
        hipImbalance: Double
    ) -> Double {
        var score = 100.0
        score -= min(shoulderImbalance * 4, 30)
        score -= min(hipImbalance * 4, 30)
        return max(score, 0).rounded()
    }

    private func calculateMobilityScore(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> Double {
        var score    = 100.0
        var detected = 0

        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftElbow,    .rightElbow,
            .leftHip,      .rightHip,
            .leftKnee,     .rightKnee
        ]

        for joint in keyJoints {
            if joints[joint] != nil { detected += 1 }
        }

        let detectionRate = Double(detected) / Double(keyJoints.count)
        score = detectionRate * 100

        return max(score, 0).rounded()
    }

    // MARK: - Notes

    private func generateNotes(
        spineDeviation: Double,
        shoulderImbalance: Double,
        hipImbalance: Double,
        postureScore: Double
    ) -> [PostureNote] {
        var notes: [PostureNote] = []

        if spineDeviation > 8 {
            notes.append(PostureNote(
                severity: .moderate,
                message: "Forward head posture detected. Neck stretches recommended before training.",
                area: .neck
            ))
        } else if spineDeviation > 4 {
            notes.append(PostureNote(
                severity: .mild,
                message: "Slight spinal deviation. Focus on core engagement during lifts.",
                area: .spine
            ))
        }

        if shoulderImbalance > 6 {
            notes.append(PostureNote(
                severity: .moderate,
                message: "Shoulder imbalance detected. Unilateral exercises recommended.",
                area: .shoulders
            ))
        } else if shoulderImbalance > 3 {
            notes.append(PostureNote(
                severity: .mild,
                message: "Minor shoulder elevation difference. Monitor during pressing movements.",
                area: .shoulders
            ))
        }

        if hipImbalance > 5 {
            notes.append(PostureNote(
                severity: .moderate,
                message: "Hip imbalance detected. Single-leg work and mobility recommended.",
                area: .hips
            ))
        }

        if postureScore >= 85 {
            notes.append(PostureNote(
                severity: .good,
                message: "Good baseline posture. Maintain consistent training and mobility work.",
                area: .overall
            ))
        }

        if notes.isEmpty {
            notes.append(PostureNote(
                severity: .good,
                message: "Posture scan complete. No significant issues detected.",
                area: .overall
            ))
        }

        return notes
    }

    // MARK: - Intensity recommendation

    private func recommendIntensity(
        postureScore: Double,
        symmetryScore: Double
    ) -> TrainingIntensity {
        let combined = (postureScore + symmetryScore) / 2

        switch combined {
        case 85...100: return .high
        case 70..<85:  return .standard
        case 55..<70:  return .moderate
        default:       return .light
        }
    }
}
