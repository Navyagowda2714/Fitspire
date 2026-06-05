//
//  FormAlert.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 01/05/2026.
//
//
//
//  FormAlert.swift
//  Fitspyre
//
//  ENHANCED: Added injuryRisk computed property so LiveWorkoutView can display
//  what injury results from each incorrect form alert, inline during the workout.
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
    case squat           = "Squat"
    case plank           = "Plank"
    case pushUp          = "Push-up"
    case shoulderPress   = "Shoulder Press"
    case deadlift        = "Deadlift"
    case lunge           = "Lunge"
    case gluteBridge     = "Glute Bridge"
    case mountainClimber = "Mountain Climber"
    case highKnees       = "High Knees"
    case general         = "General"
}

struct FormAlert: Identifiable, Equatable {
    let id          = UUID()
    let severity:     AlertSeverity
    let message:      String
    let correction:   String
    let affectedJoint: String
    let exercise:     ExerciseType
    let timestamp:    Date

    init(
        severity:      AlertSeverity,
        message:       String,
        correction:    String,
        affectedJoint: String,
        exercise:      ExerciseType
    ) {
        self.severity      = severity
        self.message       = message
        self.correction    = correction
        self.affectedJoint = affectedJoint
        self.exercise      = exercise
        self.timestamp     = Date()
    }

    // MARK: - Injury risk (shown live during workout — NEW)
    /// Returns a short, plain-language description of the injury this form fault can cause.
    var injuryRisk: String {
        switch (exercise, affectedJoint, severity) {
        // Plank-specific
        case (.plank, "Hips", .danger):
            return "Lumbar disc herniation, chronic lower back strain"
        case (.plank, "Hips", .warning):
            return "Increased lumbar load — correct before it worsens"
        case (.plank, "Neck", .danger):
            return "Cervical spine compression, upper trapezius strain"
        case (.plank, "Neck", .warning):
            return "Neck tension — tuck chin and look at floor"
        // Squat
        case (.squat, "Left Knee", _), (.squat, "Right Knee", _):
            return "ACL/MCL stress, patellofemoral pain syndrome"
        case (.squat, "Spine", .danger):
            return "Lumbar disc herniation under load"
        case (.squat, "Spine", .warning):
            return "Elevated spinal compression — reduce load"
        // Push-up
        case (.pushUp, "Elbows", .danger):
            return "Rotator cuff impingement, elbow tendinopathy"
        case (.pushUp, "Hips", .danger):
            return "Lumbar hyperextension, lower back strain"
        // Shoulder press
        case (.shoulderPress, "Lower Back", .danger):
            return "L4-L5 disc compression, lumbar strain"
        case (.shoulderPress, "Shoulders", _):
            return "Rotator cuff imbalance, AC joint irritation"
        // Deadlift
        case (.deadlift, "Spine", .danger):
            return "Serious disc herniation risk — stop immediately"
        case (.deadlift, "Knees", _):
            return "Patellar tendon overload, knee joint stress"
        // Generic fallback
        default:
            return severity == .danger
                ? "High injury risk — correct immediately"
                : "Caution: form deviation detected"
        }
    }
}

struct WatchAlertPayload: Codable {
    let title:     String
    let message:   String
    let severity:  String
    let timestamp: Date
}
