//
//  GuidedTimerView.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 17/05/2026.
//


import SwiftUI

struct GuidedTimerView: View {
    let exercise: HomeExercise
    @Environment(\.dismiss) private var dismiss

    @State private var currentSet      = 1
    @State private var phase: Phase    = .prepare
    @State private var timeRemaining   = 5
    @State private var timer: Timer?
    @State private var showComplete    = false

    enum Phase {
        case prepare, active, rest, done

        var label: String {
            switch self {
            case .prepare: return "GET READY"
            case .active:  return "GO!"
            case .rest:    return "REST"
            case .done:    return "DONE!"
            }
        }
        var color: Color {
            switch self {
            case .prepare: return Color.appWarn
            case .active:  return Color.appLime
            case .rest:    return Color.appCyan
            case .done:    return Color.appGood
            }
        }
    }

    // Parse duration from repsOrTime (e.g. "30 sec" → 30, "15 reps" → 40 sec estimate)
    private var activeDuration: Int {
        let s = exercise.repsOrTime
        if s.contains("sec") {
            return Int(s.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .joined()) ?? 30
        }
        // reps → estimate ~3 sec per rep
        let reps = Int(s.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined().prefix(3)) ?? 10
        return reps * 3
    }

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { stopTimer(); dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark").font(.system(size: 15, weight: .semibold))
                            Text("End").font(.system(size: 15))
                        }.foregroundStyle(Color.appT2)
                    }
                    Spacer()
                    Text("\(exercise.name)")
                        .font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    Spacer()
                    // Set counter
                    Text("Set \(currentSet)/\(exercise.sets)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.appLime)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.appLime.opacity(0.12)).clipShape(Capsule())
                }
                .padding(.horizontal, 24).padding(.top, 56)

                Spacer()

                // Big timer ring
                ZStack {
                    Circle().stroke(Color.appHair2, lineWidth: 10).frame(width: 220, height: 220)

                    let max = phase == .prepare ? 5 : phase == .active ? activeDuration : exercise.restSeconds
                    let fraction = max > 0 ? CGFloat(timeRemaining) / CGFloat(max) : 0

                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(phase.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timeRemaining)

                    VStack(spacing: 6) {
                        Text(phase.label)
                            .font(.system(size: 14, weight: .bold)).kerning(1.5)
                            .foregroundStyle(phase.color)
                        Text("\(timeRemaining)")
                            .font(.system(size: 72, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.white).monospacedDigit()
                        Text(phase == .active && !exercise.repsOrTime.contains("sec")
                             ? exercise.repsOrTime : "seconds")
                            .font(.system(size: 13)).foregroundStyle(Color.appT3)
                    }
                }

                Spacer()

                // Current form cue
                if phase == .active, let cue = exercise.formCues.first {
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb.fill").font(.system(size: 13))
                            .foregroundStyle(Color.appWarn)
                        Text(cue).font(.system(size: 13)).foregroundStyle(Color.appT2)
                            .lineSpacing(3)
                    }
                    .padding(14).background(Color.appWarn.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appWarn.opacity(0.25), lineWidth: 1))
                    .padding(.horizontal, 24)
                }

                // Set dots
                HStack(spacing: 10) {
                    ForEach(1...exercise.sets, id: \.self) { i in
                        Circle()
                            .fill(i < currentSet ? Color.appGood :
                                  i == currentSet ? Color.appLime : Color.appHair2)
                            .frame(width: 14, height: 14)
                    }
                }
                .padding(.top, 24).padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { startPhase(.prepare) }
        .alert("Workout Complete! 🎉", isPresented: $showComplete) {
            Button("Done") { dismiss() }
        } message: {
            Text("You completed all \(exercise.sets) sets of \(exercise.name). Great work!")
        }
    }

    private func startPhase(_ p: Phase) {
        phase = p
        switch p {
        case .prepare: timeRemaining = 5
        case .active:  timeRemaining = activeDuration
        case .rest:    timeRemaining = exercise.restSeconds
        case .done:    showComplete = true; return
        }
        startCountdown()
    }

    private func startCountdown() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 1 {
                timeRemaining -= 1
            } else {
                stopTimer()
                advance()
            }
        }
    }

    private func advance() {
        switch phase {
        case .prepare:
            startPhase(.active)
        case .active:
            if currentSet < exercise.sets {
                startPhase(.rest)
            } else {
                startPhase(.done)
            }
        case .rest:
            currentSet += 1
            startPhase(.active)
        case .done:
            break
        }
    }

    private func stopTimer() {
        timer?.invalidate(); timer = nil
    }
}
