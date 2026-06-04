//
//  GluteBridgeViewModel+Store.swift
//  PostureCorrect
//
//  Created by Syed Muhammad Muneeb on 03/06/26.
//

import Foundation
//
//  GluteBridgeViewModel+Store.swift
//  PostureCorrect
//
//  Extends GluteBridgeViewModel with stopAndSave().
//  In GluteBridgeCameraView change:
//      .onDisappear { viewModel.stop() }
//  to:
//      .onDisappear { viewModel.stopAndSave() }
//

import Foundation

extension GluteBridgeViewModel {

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

        let ignoredIssues: [GluteBridgeIssue] = [.correct, .ready, .detecting, .notVisible]
        if !ignoredIssues.contains(bridgeResult.issue) {
            feedbackItems.append(PCLastFeedbackItem(
                isGood: false,
                title:  bridgeResult.issue.rawValue
                    .replacingOccurrences(of: "❌ ", with: "")
            ))
        }

        if feedbackItems.isEmpty {
            feedbackItems.append(PCLastFeedbackItem(isGood: true, title: "No issues detected"))
        }

        let score = averageScore > 0 ? averageScore : bridgeResult.postureScore

        LastExerciseStore.shared.record(
            exerciseName:  "Glute Bridge",
            icon:          "figure.gymnastics",
            iconColor:     "pink",
            formScore:     score,
            goodReps:      self.goodReps,
            badReps:       self.badReps,
            totalReps:     totalRepsAllTime,
            sessionTime:   sessionTimeString,
            feedbackItems: feedbackItems
        )

        WorkoutHistoryStore.shared.addSession(
            exerciseName: "Glute Bridge",
            icon:         "figure.gymnastics",
            iconColor:    "pink",
            formScore:    score,
            goodReps:     self.goodReps,
            badReps:      self.badReps,
            totalReps:    totalRepsAllTime,
            sessionTime:  sessionTimeString
        )
    }
}
