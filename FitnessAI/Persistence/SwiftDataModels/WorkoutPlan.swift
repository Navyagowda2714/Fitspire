//
//  WorkoutPlan.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

import Foundation
import SwiftData

@Model
final class WorkoutPlan {
    var id: UUID
    var goal: String
    var splitType: String
    var weeklyFrequency: Int
    var timelineMonths: Int
    var progressionNote: String
    var createdAt: Date

    init(
        goal: String,
        splitType: String,
        weeklyFrequency: Int,
        timelineMonths: Int,
        progressionNote: String
    ) {
        self.id               = UUID()
        self.goal             = goal
        self.splitType        = splitType
        self.weeklyFrequency  = weeklyFrequency
        self.timelineMonths   = timelineMonths
        self.progressionNote  = progressionNote
        self.createdAt        = Date()
    }
}
