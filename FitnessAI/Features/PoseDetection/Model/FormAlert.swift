//
//  FormAlert.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//


import Foundation

enum AlertSeverity: String, Codable {
    case warning = "Warning"
    case danger  = "Danger"

    var color: String {
        switch self {
        case .warning: return "BA7517"
        case .danger:  return "D85A30"
        }
    }
}

enum ExerciseType: String, CaseIterable, Codable {
    case squat         = "Squat"
    case plank         = "Plank"
    case pushUp        = "Push-up"
    case shoulderPress = "Shoulder Press"
    case deadlift      = "Deadlift"
    case general       = "General"
}

struct FormAlert: Identifiable {
    let id = UUID()
    let severity: AlertSeverity
    let message: String
    let correction: String
    let affectedJoint: String
    let exercise: ExerciseType
    let timestamp: Date

    init(
        severity: AlertSeverity,
        message: String,
        correction: String,
        affectedJoint: String,
        exercise: ExerciseType
    ) {
        self.severity     = severity
        self.message      = message
        self.correction   = correction
        self.affectedJoint = affectedJoint
        self.exercise     = exercise
        self.timestamp    = Date()
    }
}

struct WatchAlertPayload: Codable {
    let title: String
    let message: String
    let severity: String
    let timestamp: Date
}
