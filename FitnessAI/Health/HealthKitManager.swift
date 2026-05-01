//
//  HealthKitManager.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import Foundation
import HealthKit
import Combine

final class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()
}
