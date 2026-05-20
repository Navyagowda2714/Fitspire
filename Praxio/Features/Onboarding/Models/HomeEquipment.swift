//
//  HomeEquipment.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 08/05/2026.
//


import Foundation

enum HomeEquipment: String, Codable, CaseIterable, Identifiable {
    case dumbbells
    case resistanceBands
    case kettlebell
    case pullUpBar
    case bench
    case jumpRope
    case ankleWeights
    case noEquipment
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .dumbbells: return "Dumbbells"
        case .resistanceBands: return "Resistance Bands"
        case .kettlebell: return "Kettlebell"
        case .pullUpBar: return "Pull-Up Bar"
        case .bench: return "Bench"
        case .jumpRope: return "Jump Rope"
        case .ankleWeights: return "Ankle Weights"
        case .noEquipment: return "No Equipment"
        }
    }
}
