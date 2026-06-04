//
//  PushUpViewModel+Store.swift
//  PostureCorrect
//
//  Created by Syed Muhammad Muneeb on 03/06/26.
//

import Foundation
//
//  PushupViewModel+Store.swift
//  PostureCorrect
//
//  Extends PushupViewModel with stopAndSave().
//  In PushupCameraView change:
//      .onDisappear { viewModel.stop() }
//  to:
//      .onDisappear { viewModel.stopAndSave() }
//

import Foundation

extension PushUpViewModel {

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

        let badRepsCount = repHistory.filter { !$0.isGood }.count
        if badRepsCount > 0 {
            feedbackItems.append(PCLastFeedbackItem(
                isGood: false,
                title:  "\(badRepsCount) rep\(badRepsCount == 1 ? "" : "s") with form errors"
            ))
        }

        let ignoredIssues: [PushUpIssue] = [.correct, .ready, .detecting, .notVisible]
        if !ignoredIssues.contains(postureResult.issue) {
            feedbackItems.append(PCLastFeedbackItem(
                isGood: false,
                title:  postureResult.issue.rawValue
                    .replacingOccurrences(of: "❌ ", with: "")
                    .replacingOccurrences(of: "⚠️ ", with: "")
                    .replacingOccurrences(of: "⚠️ ", with: "")
            ))
        }

        if feedbackItems.isEmpty {
            feedbackItems.append(PCLastFeedbackItem(isGood: true, title: "No issues detected"))
        }

        let score = averageScore > 0 ? averageScore : postureResult.postureScore

        LastExerciseStore.shared.record(
            exerciseName:  "Push-ups",
            icon:          "figure.core.training",
            iconColor:     "blue",
            formScore:     score,
            goodReps:      self.goodReps,
            badReps:       self.badReps,
            totalReps:     totalRepsAllTime,
            sessionTime:   sessionTimeString,
            feedbackItems: feedbackItems
        )

        WorkoutHistoryStore.shared.addSession(
            exerciseName: "Push-ups",
            icon:         "figure.core.training",
            iconColor:    "blue",
            formScore:    score,
            goodReps:     self.goodReps,
            badReps:      self.badReps,
            totalReps:    totalRepsAllTime,
            sessionTime:  sessionTimeString
        )
    }
}
