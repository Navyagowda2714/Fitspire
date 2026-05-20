//
//  BodyScanResult.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

import Foundation
import SwiftData

@Model
final class BodyScanResult {
    var id: UUID
    var postureScore: Double
    var symmetryScore: Double
    var mobilityScore: Double
    var notes: [String]
    var createdAt: Date

    init(
        postureScore: Double,
        symmetryScore: Double,
        mobilityScore: Double
    ) {
        self.id = UUID()
        self.postureScore = postureScore
        self.symmetryScore = symmetryScore
        self.mobilityScore = mobilityScore
        self.notes = []
        self.createdAt = Date()
    }
}
