//
//  SafetyRuleEngine.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation
import Vision

final class SafetyRuleEngine: Sendable {
    private let formRuleEngine = FormRuleEngine()

    func evaluate(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
        exercise: ExerciseType
    ) -> [FormAlert] {
        return formRuleEngine.evaluate(
            joints: joints,
            exercise: exercise
        )
    }

    func hasDangerAlert(_ alerts: [FormAlert]) -> Bool {
        alerts.contains { $0.severity == .danger }
    }

    func mostSevereAlert(_ alerts: [FormAlert]) -> FormAlert? {
        alerts.first { $0.severity == .danger } ?? alerts.first
    }

    func toWatchPayload(_ alert: FormAlert) -> WatchAlertPayload {
        WatchAlertPayload(
            title: alert.affectedJoint,
            message: alert.correction,
            severity: alert.severity.rawValue,
            timestamp: alert.timestamp
        )
    }
}

