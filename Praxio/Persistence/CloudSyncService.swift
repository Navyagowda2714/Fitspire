//
//  ShareSheet.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 06/05/2026.
//

import Foundation
import CloudKit

final class CloudSyncService {
    static let shared = CloudSyncService()
    private let container = CKContainer.default()

    private init() {}

    var isSyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: "cloudSyncEnabled")
    }

    func checkAccountStatus() async -> CKAccountStatus {
        do {
            return try await container.accountStatus()
        } catch {
            return .couldNotDetermine
        }
    }

    func syncEnabled() -> Bool {
        return isSyncEnabled
    }
}
