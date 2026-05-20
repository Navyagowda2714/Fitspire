//
//  PostureAnalysis.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

import Foundation

struct PostureAnalysis {
    let postureScore: Double
    let symmetryScore: Double
    let mobilityScore: Double
    let spineDeviation: Double
    let shoulderImbalance: Double
    let hipImbalance: Double
    let notes: [PostureNote]
    let recommendedIntensity: TrainingIntensity
    let date: Date

    init(
        postureScore: Double,
        symmetryScore: Double,
        mobilityScore: Double,
        spineDeviation: Double,
        shoulderImbalance: Double,
        hipImbalance: Double,
        notes: [PostureNote],
        recommendedIntensity: TrainingIntensity
    ) {
        self.postureScore = postureScore
        self.symmetryScore = symmetryScore
        self.mobilityScore = mobilityScore
        self.spineDeviation = spineDeviation
        self.shoulderImbalance = shoulderImbalance
        self.hipImbalance = hipImbalance
        self.notes = notes
        self.recommendedIntensity = recommendedIntensity
        self.date = Date()
    }
}

struct PostureNote: Identifiable {
    let id = UUID()
    let severity: NoteSeverity
    let message: String
    let area: BodyArea
}

enum NoteSeverity {
    case good
    case mild
    case moderate
    case attention
}

enum BodyArea: String {
    case spine       = "Spine"
    case shoulders   = "Shoulders"
    case hips        = "Hips"
    case knees       = "Knees"
    case neck        = "Neck"
    case overall     = "Overall"
}

enum TrainingIntensity: String {
    case light      = "Light"
    case moderate   = "Moderate"
    case standard   = "Standard"
    case high       = "High"

    var description: String {
        switch self {
        case .light:    return "Start with lighter loads and focus on form"
        case .moderate: return "Moderate intensity with form focus"
        case .standard: return "Standard training intensity"
        case .high:     return "Full intensity training recommended"
        }
    }
}

