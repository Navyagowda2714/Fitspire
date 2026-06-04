//
//  WorkoutHistoryStore.swift
//  PostureCorrect
//
//  Created by Syed Muhammad Muneeb on 03/06/26.
//

import Foundation
//
//  WorkoutHistoryStore.swift
//  PostureCorrect
//
//  Persistent store for all completed sessions.
//  Saves to a JSON file in the app's Documents directory so data
//  survives app restarts and OS kills. No developer profile needed —
//  the Documents sandbox is available on free provisioning.
//
//  ── How to use ────────────────────────────────────────────────────────────
//  From any ViewModel's stopAndSave():
//      WorkoutHistoryStore.shared.addSession(...)
//
//  From any SwiftUI view:
//      @ObservedObject private var history = WorkoutHistoryStore.shared
//      history.sessions          → all sessions, newest first
//      history.averageFormScore  → Int
//      history.totalReps         → Int
//      history.totalSessions     → Int
//      history.bestScore         → Int
//      history.scores(for:)      → [(date, score)] for chart
//      history.topExercises      → [(name, avgScore)] sorted desc
//  ─────────────────────────────────────────────────────────────────────────

import Foundation
import Combine

// MARK: - Session record (one completed workout)
struct WorkoutSession: Identifiable, Codable {
    let id:           UUID
    let exerciseName: String   // "Squats", "Push-ups", "Plank", "Glute Bridge"
    let icon:         String   // SF Symbol name
    let iconColor:    String   // Color name string
    let formScore:    Int      // 0-100 average posture score
    let goodReps:     Int      // good reps (or good holds for Plank)
    let badReps:      Int
    let totalReps:    Int
    let sessionTime:  String   // "04:32"
    let recordedAt:   Date

    init(
        exerciseName: String,
        icon:         String,
        iconColor:    String,
        formScore:    Int,
        goodReps:     Int,
        badReps:      Int,
        totalReps:    Int,
        sessionTime:  String
    ) {
        self.id           = UUID()
        self.exerciseName = exerciseName
        self.icon         = icon
        self.iconColor    = iconColor
        self.formScore    = formScore
        self.goodReps     = goodReps
        self.badReps      = badReps
        self.totalReps    = totalReps
        self.sessionTime  = sessionTime
        self.recordedAt   = Date()
    }
}

// MARK: - Chart data point
struct FormScorePoint: Identifiable {
    let id   = UUID()
    let date: Date
    let score: Int
}

// MARK: - Top exercise summary
struct ExerciseSummary: Identifiable {
    let id        = UUID()
    let name:      String
    let icon:      String
    let iconColor: String
    let avgScore:  Int
    let sessions:  Int
}

// MARK: - Store
final class WorkoutHistoryStore: ObservableObject {

    static let shared = WorkoutHistoryStore()

    @Published private(set) var sessions: [WorkoutSession] = []

    private let fileName = "workout_history.json"

    private var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    private init() {
        load()
    }

    // MARK: - Write
    func addSession(
        exerciseName: String,
        icon:         String,
        iconColor:    String,
        formScore:    Int,
        goodReps:     Int,
        badReps:      Int,
        totalReps:    Int,
        sessionTime:  String
    ) {
        let session = WorkoutSession(
            exerciseName: exerciseName,
            icon:         icon,
            iconColor:    iconColor,
            formScore:    formScore,
            goodReps:     goodReps,
            badReps:      badReps,
            totalReps:    totalReps,
            sessionTime:  sessionTime
        )
        DispatchQueue.main.async {
            self.sessions.insert(session, at: 0)   // newest first
            self.save()
        }
    }

    // MARK: - Aggregates (all time by default)

    var totalSessions: Int { sessions.count }

    var totalReps: Int { sessions.map(\.totalReps).reduce(0, +) }

    var averageFormScore: Int {
        guard !sessions.isEmpty else { return 0 }
        return sessions.map(\.formScore).reduce(0, +) / sessions.count
    }

    var bestScore: Int { sessions.map(\.formScore).max() ?? 0 }

    var bestScoreExercise: String {
        sessions.max(by: { $0.formScore < $1.formScore })?.exerciseName ?? "—"
    }

    // MARK: - Period-filtered aggregates

    func sessions(in period: StatPeriod) -> [WorkoutSession] {
        let cutoff = period.startDate
        return sessions.filter { $0.recordedAt >= cutoff }
    }

    func averageFormScore(in period: StatPeriod) -> Int {
        let s = sessions(in: period)
        guard !s.isEmpty else { return 0 }
        return s.map(\.formScore).reduce(0, +) / s.count
    }

    func totalReps(in period: StatPeriod) -> Int {
        sessions(in: period).map(\.totalReps).reduce(0, +)
    }

    func totalSessions(in period: StatPeriod) -> Int {
        sessions(in: period).count
    }

    func bestScore(in period: StatPeriod) -> Int {
        sessions(in: period).map(\.formScore).max() ?? 0
    }

    func bestScoreExercise(in period: StatPeriod) -> String {
        sessions(in: period)
            .max(by: { $0.formScore < $1.formScore })?.exerciseName ?? "—"
    }

    // MARK: - Chart data

    /// Returns one (date, avgScore) point per day for the given period.
    /// Days with no sessions are omitted.
    func chartPoints(for period: StatPeriod) -> [FormScorePoint] {
        let cal = Calendar.current
        let filtered = sessions(in: period)

        // Group by calendar day
        var byDay: [Date: [Int]] = [:]
        for s in filtered {
            let day = cal.startOfDay(for: s.recordedAt)
            byDay[day, default: []].append(s.formScore)
        }

        return byDay
            .map { day, scores in
                FormScorePoint(date: day,
                               score: scores.reduce(0, +) / scores.count)
            }
            .sorted { $0.date < $1.date }
    }

    /// Weekly bar chart helper — returns scores for each of the last 7 days
    /// (index 0 = 6 days ago, index 6 = today). nil if no session that day.
    func weeklyScores() -> [Int?] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).map { offset -> Int? in
            guard let day = cal.date(byAdding: .day, value: -(6 - offset), to: today) else { return nil }
            let dayEnd = cal.date(byAdding: .day, value: 1, to: day)!
            let daySessions = sessions.filter { $0.recordedAt >= day && $0.recordedAt < dayEnd }
            guard !daySessions.isEmpty else { return nil }
            return daySessions.map(\.formScore).reduce(0, +) / daySessions.count
        }
    }

    // MARK: - Top exercises

    func topExercises(in period: StatPeriod = .allTime) -> [ExerciseSummary] {
        let s = sessions(in: period)
        var groups: [String: [WorkoutSession]] = [:]
        for session in s {
            groups[session.exerciseName, default: []].append(session)
        }
        return groups
            .map { name, group in
                ExerciseSummary(
                    name:      name,
                    icon:      group[0].icon,
                    iconColor: group[0].iconColor,
                    avgScore:  group.map(\.formScore).reduce(0, +) / group.count,
                    sessions:  group.count
                )
            }
            .sorted { $0.avgScore > $1.avgScore }
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("WorkoutHistoryStore save error: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            sessions = try JSONDecoder().decode([WorkoutSession].self, from: data)
        } catch {
            print("WorkoutHistoryStore load error: \(error)")
        }
    }
}

// MARK: - Period enum
enum StatPeriod: String, CaseIterable, Identifiable {
    case week    = "This Week"
    case month   = "This Month"
    case allTime = "All Time"

    var id: String { rawValue }

    var startDate: Date {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .week:    return cal.date(byAdding: .day,   value: -7,  to: now)!
        case .month:   return cal.date(byAdding: .month, value: -1,  to: now)!
        case .allTime: return Date(timeIntervalSince1970: 0)
        }
    }
}
