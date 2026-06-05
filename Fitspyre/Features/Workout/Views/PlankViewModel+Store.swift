//
//  PlankViewModel+Store.swift
//  PostureCorrect
//
//  Created by Syed Muhammad Muneeb on 03/06/26.
//

//
//  PlankViewModel+Store.swift
//  PostureCorrect
//
//  Extends PlankViewModel with stopAndSave().
//  In PlankCameraView change:
//      .onDisappear { viewModel.stop() }
//  to:
//      .onDisappear { viewModel.stopAndSave() }
//
//  Plank is hold-based, not rep-based. goodReps/badReps map to
//  good holds / bad holds; totalReps maps to total holds completed.
//

import Foundation

extension PlankViewModel {

    func stopAndSave() {
        stop()
        saveToStore()
    }

    func saveToStore() {
        var feedbackItems: [PCLastFeedbackItem] = []

        let goodHolds = holdHistory.filter { $0.isGood }.count
        let badHolds  = holdHistory.filter { !$0.isGood }.count

        if goodHolds > 0 {
            feedbackItems.append(PCLastFeedbackItem(
                isGood: true,
                title:  "\(goodHolds) hold\(goodHolds == 1 ? "" : "s") with good form"
            ))
        }

        if badHolds > 0 {
            feedbackItems.append(PCLastFeedbackItem(
                isGood: false,
                title:  "\(badHolds) hold\(badHolds == 1 ? "" : "s") with form errors"
            ))
        }

        let ignoredIssues: [PlankIssue] = [.correct, .ready, .detecting, .notVisible]
        if !ignoredIssues.contains(plankResult.issue) {
            feedbackItems.append(PCLastFeedbackItem(
                isGood: false,
                title:  plankResult.issue.rawValue
                    .replacingOccurrences(of: "❌ ", with: "")
            ))
        }

        if !holdHistory.isEmpty && bestSeconds > 0 {
            feedbackItems.append(PCLastFeedbackItem(
                isGood: true,
                title:  "Best hold: \(formattedBestTime)"
            ))
        }

        if feedbackItems.isEmpty {
            feedbackItems.append(PCLastFeedbackItem(isGood: true, title: "No issues detected"))
        }

        let score = averageFormScore > 0 ? averageFormScore : plankResult.postureScore

        LastExerciseStore.shared.record(
            exerciseName:  "Plank",
            icon:          "figure.core.training",
            iconColor:     "purple",
            formScore:     score,
            goodReps:      goodHolds,
            badReps:       badHolds,
            totalReps:     holdHistory.count,
            sessionTime:   sessionTimeString,
            feedbackItems: feedbackItems
        )

        WorkoutHistoryStore.shared.addSession(
            exerciseName: "Plank",
            icon:         "figure.core.training",
            iconColor:    "purple",
            formScore:    score,
            goodReps:     goodHolds,
            badReps:      badHolds,
            totalReps:    holdHistory.count,
            sessionTime:  sessionTimeString
        )
    }
}
