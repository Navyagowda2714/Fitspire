//
//  ContentView.swift
//  FitspyreWatch Watch App
//
//  Three states cycle during a session:
//    1. Idle / ready      — connection + waiting
//    2. Live rep counter  — progress ring + form score (default while training)
//    3. Form alert        — posture fault, fix, red flash (overrides for a few seconds)
//

import SwiftUI
import WatchConnectivity
import WatchKit

// Fitspyre palette (kept local to the watch target)
private extension Color {
    static let fCyan = Color(red: 0,    green: 0.90, blue: 1.0)
    static let fGood = Color(red: 0.19, green: 0.82, blue: 0.35)
    static let fWarn = Color(red: 1.0,  green: 0.69, blue: 0.13)
    static let fMove = Color(red: 0.98, green: 0.07, blue: 0.31)
    static let fBG3  = Color(red: 0.10, green: 0.14, blue: 0.20)
}

struct ContentView: View {
    @StateObject private var connector = WatchSessionManager.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 10) {
                connectionBar

                Spacer(minLength: 0)

                if let alert = connector.latestAlert {
                    AlertCard(alert: alert)
                } else if let rep = connector.repStatus {
                    RepCard(rep: rep)
                } else {
                    IdleCard()
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
        // Red border flash on a new alert
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.fMove.opacity(connector.showFlash ? 0.85 : 0), lineWidth: 4)
                .animation(.easeOut(duration: 0.6), value: connector.showFlash)
                .ignoresSafeArea()
        )
    }

    private var connectionBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(connector.isConnected ? Color.fGood : Color.gray)
                .frame(width: 7, height: 7)
            Text(connector.isConnected ? "Connected" : "Waiting…")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
        }
    }
}

// MARK: - Idle

private struct IdleCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.strengthtraining.functional")
                .font(.system(size: 34))
                .foregroundColor(.white.opacity(0.32))
            Text("Exercise to begin")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.55))
            Text("Open a workout on your iPhone")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.32))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Rep counter

private struct RepCard: View {
    let rep: RepStatus

    private var scoreColor: Color {
        if rep.formScore >= 85 { return .fGood }
        if rep.formScore >= 65 { return .fWarn }
        return .fMove
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(rep.exercise.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.fCyan)
                .tracking(1)

            ZStack {
                Circle()
                    .stroke(Color.fBG3, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(rep.progress))
                    .stroke(Color.fCyan, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.25), value: rep.progress)
                VStack(spacing: 0) {
                    Text("\(rep.repsInSet)")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(rep.targetReps > 0 ? "/ \(rep.targetReps) reps" : "reps")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 96, height: 96)

            Text("Set \(rep.currentSet) of \(max(rep.totalSets, rep.currentSet))")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))

            // Form score bar
            VStack(spacing: 3) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.fBG3)
                        Capsule().fill(scoreColor)
                            .frame(width: geo.size.width * CGFloat(rep.formScore) / 100)
                    }
                }
                .frame(height: 7)
                HStack {
                    Text(rep.feedback)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(scoreColor)
                        .lineLimit(1)
                    Spacer()
                    Text("\(rep.formScore)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(scoreColor)
                }
            }
        }
    }
}

// MARK: - Form alert

private struct AlertCard: View {
    let alert: FormAlert

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.fMove)

            Text(alert.exercise.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.fWarn)
                .tracking(0.5)

            Text(alert.issue)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            if !alert.fix.isEmpty {
                Text(alert.fix)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.fGood)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(Color.fGood.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
            }

            Text(alert.timeAgo)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
