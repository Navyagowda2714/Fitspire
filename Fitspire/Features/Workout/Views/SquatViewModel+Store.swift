//
//  SquatViewModel+Store.swift
//  PostureCorrect
//
//  Extends SquatViewModel with stopAndSave() — call this from
//  SquatCameraView.onDisappear instead of stop().
//
//  Writes to both:
//    • LastExerciseStore  — powers the Coach tab (in-memory + UserDefaults)
//    • WorkoutHistoryStore — powers the Progress tab (persisted to disk)
//
//  No changes to SquatView.swift required.
//

import Foundation

extension SquatViewModel {

    func stopAndSave() {
        stop()
        saveToStore()
    }

    func saveToStore() {
        var feedbackItems: [PCLastFeedbackItem] = []

        let goodCount = repHistory.filter { $0.isGood }.count
        if goodCount > 0 {
            feedbackItems.append(PCLastFeedbackItem(
                isGood: true,
                title:  "\(goodCount) rep\(goodCount == 1 ? "" : "s") with perfect form"
            ))
        }

        let badReps = repHistory.filter { !$0.isGood }
        if !badReps.isEmpty {
            feedbackItems.append(PCLastFeedbackItem(
                isGood: false,
                title:  "\(badReps.count) rep\(badReps.count == 1 ? "" : "s") with form errors"
            ))
        }

        let ignoredIssues: [SquatIssue] = [.correct, .ready, .detecting, .notVisible]
        if !ignoredIssues.contains(postureResult.issue) {
            feedbackItems.append(PCLastFeedbackItem(
                isGood: false,
                title:  postureResult.issue.rawValue
                    .replacingOccurrences(of: "❌ ", with: "")
                    .replacingOccurrences(of: "⚠️ ", with: "")
            ))
        }

        if feedbackItems.isEmpty {
            feedbackItems.append(PCLastFeedbackItem(isGood: true, title: "No issues detected"))
        }

        let score = averageScore > 0 ? averageScore : postureResult.postureScore

        LastExerciseStore.shared.record(
            exerciseName:  "Squats",
            icon:          "figure.strengthtraining.functional",
            iconColor:     "orange",
            formScore:     score,
            goodReps:      self.goodReps,
            badReps:       self.badReps,
            totalReps:     totalRepsAllTime,
            sessionTime:   sessionTimeString,
            feedbackItems: feedbackItems
        )

        WorkoutHistoryStore.shared.addSession(
            exerciseName: "Squats",
            icon:         "figure.strengthtraining.functional",
            iconColor:    "orange",
            formScore:    score,
            goodReps:     self.goodReps,
            badReps:      self.badReps,
            totalReps:    totalRepsAllTime,
            sessionTime:  sessionTimeString
        )
    }
}
