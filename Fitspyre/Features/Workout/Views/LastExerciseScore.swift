//
//  LastExerciseStore.swift
//  PostureCorrect
//
//  Single source of truth for the "last exercise" data that the Coach tab
//  displays. Persists to UserDefaults so the Coach tab still shows your
//  last session after an app restart — no developer profile needed.
//
//  Drop this file in and delete the old LastExerciseStore.swift.
//

import Foundation
import Combine

// MARK: - Feedback entry (one row in Coach tab Recent Feedback)
struct PCLastFeedbackItem: Identifiable, Codable {
    let id:        UUID
    let isGood:    Bool
    let title:     String
    let timestamp: Date

    init(isGood: Bool, title: String, timestamp: Date = Date()) {
        self.id        = UUID()
        self.isGood    = isGood
        self.title     = title
        self.timestamp = timestamp
    }
}

// MARK: - Last-exercise snapshot
struct PCLastExercise: Codable {
    let exerciseName:  String
    let icon:          String
    let iconColor:     String
    let formScore:     Int
    let goodReps:      Int
    let badReps:       Int
    let totalReps:     Int
    let sessionTime:   String
    let feedbackItems: [PCLastFeedbackItem]
    let recordedAt:    Date
}

// MARK: - Store
final class LastExerciseStore: ObservableObject {

    static let shared = LastExerciseStore()

    @Published var last: PCLastExercise? = nil

    private let udKey = "pc_last_exercise_v1"

    private init() {
        load()
    }

    /// Call this from any ViewModel's stopAndSave() to persist results.
    func record(
        exerciseName:  String,
        icon:          String,
        iconColor:     String,
        formScore:     Int,
        goodReps:      Int,
        badReps:       Int,
        totalReps:     Int,
        sessionTime:   String,
        feedbackItems: [PCLastFeedbackItem]
    ) {
        let snapshot = PCLastExercise(
            exerciseName:  exerciseName,
            icon:          icon,
            iconColor:     iconColor,
            formScore:     formScore,
            goodReps:      goodReps,
            badReps:       badReps,
            totalReps:     totalReps,
            sessionTime:   sessionTime,
            feedbackItems: feedbackItems,
            recordedAt:    Date()
        )
        DispatchQueue.main.async {
            self.last = snapshot
            self.save(snapshot)
        }
    }

    // MARK: - Persistence (UserDefaults — no entitlements needed)

    private func save(_ snapshot: PCLastExercise) {
        do {
            let data = try JSONEncoder().encode(snapshot)
            UserDefaults.standard.set(data, forKey: udKey)
        } catch {
            print("LastExerciseStore save error: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: udKey) else { return }
        do {
            last = try JSONDecoder().decode(PCLastExercise.self, from: data)
        } catch {
            print("LastExerciseStore load error: \(error)")
        }
    }
}
