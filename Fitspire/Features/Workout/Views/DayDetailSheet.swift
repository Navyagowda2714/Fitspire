//
//  DayDetailSheet.swift
//  Fitspire
//
//  Created by Navyashree Byregowda on 04/06/2026.
//


import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DayPlan  (what exercises are mapped to each day)
// Replace the sample data below with your real WorkoutPlan SwiftData model
// ─────────────────────────────────────────────────────────────────────────────

struct DayExerciseEntry: Identifiable {
    let id          = UUID()
    let exercise:     HomeExercise
    let isCompleted:  Bool
    let score:        Int?     // 0–100, nil if not yet done
    let setsCompleted: Int?
}

struct DayPlan: Identifiable {
    let id        = UUID()
    let date:       Date
    let status:     DayStatus
    let entries:    [DayExerciseEntry]
    let totalCalories: Int
    let durationMin:   Int
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DayPlanStore  (sample data — wire to SwiftData later)
// ─────────────────────────────────────────────────────────────────────────────

struct DayPlanStore {

    static func plan(for date: Date) -> DayPlan {
        let cal     = Calendar.current
        let today   = Date()
        let diff    = cal.dateComponents([.day], from: cal.startOfDay(for: today),
                                         to: cal.startOfDay(for: date)).day ?? 0
        let all     = HomeExerciseLibrary.bodyweight

        func ex(_ name: String) -> HomeExercise? { all.first { $0.name == name } }

        switch diff {
        case ..<0:    // past — mark completed with sample scores
            let picks: [(String, Int)] = [
                ("Push-Up", 88), ("Plank Hold", 76), ("Squat", 92)
            ]
            let entries = picks.compactMap { (name, score) -> DayExerciseEntry? in
                guard let e = ex(name) else { return nil }
                return DayExerciseEntry(exercise: e, isCompleted: true,
                                        score: score, setsCompleted: e.sets)
            }
            return DayPlan(date: date, status: .completed,
                           entries: entries, totalCalories: 210, durationMin: 28)

        case 0:       // today
            let picks = ["Push-Up", "Mountain Climber", "Plank Hold"]
            let entries = picks.enumerated().compactMap { i, name -> DayExerciseEntry? in
                guard let e = ex(name) else { return nil }
                let done = i == 0   // first one done as example
                return DayExerciseEntry(exercise: e, isCompleted: done,
                                        score: done ? 84 : nil, setsCompleted: done ? e.sets : nil)
            }
            return DayPlan(date: date, status: .today,
                           entries: entries, totalCalories: 180, durationMin: 25)

        case 1...5:   // upcoming planned
            let weekPlans: [[String]] = [
                ["Tricep Dip", "Superman Hold", "Squat"],
                ["Burpee", "Mountain Climber"],
                ["Push-Up", "Plank Hold", "Squat", "Tricep Dip"],
                ["Superman Hold", "Burpee"],
                ["Mountain Climber", "Push-Up", "Plank Hold"]
            ]
            let picks = weekPlans[min(diff - 1, 4)]
            let entries = picks.compactMap { name -> DayExerciseEntry? in
                guard let e = ex(name) else { return nil }
                return DayExerciseEntry(exercise: e, isCompleted: false,
                                        score: nil, setsCompleted: nil)
            }
            return DayPlan(date: date, status: .upcoming,
                           entries: entries, totalCalories: 0, durationMin: 0)

        default:      // locked future
            return DayPlan(date: date, status: .locked,
                           entries: [], totalCalories: 0, durationMin: 0)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DayDetailSheet
// ─────────────────────────────────────────────────────────────────────────────

struct DayDetailSheet: View {
    let date:    Date
    let session: CalendarSession?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: HomeExercise? = nil

    private var plan: DayPlan { DayPlanStore.plan(for: date) }

    private var dateTitle: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Header ─────────────────────────────────────
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        // ── Content by status ──────────────────────────
                        switch plan.status {
                        case .completed, .today:
                            completedSection
                        case .upcoming:
                            plannedSection
                        case .rest:
                            restSection
                        case .locked:
                            lockedSection
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBG)
        // Tap exercise → open demo
        .fullScreenCover(item: $selectedExercise) { ex in
            HomeExerciseDemoView(exercise: ex, onStartCamera: {})
        }
    }

    // ── Header ────────────────────────────────────────────────────────────────

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateTitle)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    if let s = session {
                        Text(s.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(statusColor)
                    }
                }
                Spacer()
                // Status badge
                Text(statusBadgeLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(statusColor.opacity(0.15), in: Capsule())
            }

            // Stats row for completed days
            if plan.status == .completed || plan.status == .today {
                if let s = session, !s.duration.isEmpty {
                    HStack(spacing: 12) {
                        statChip(icon: "clock.fill",    value: s.duration,          color: Color.appCyan)
                        statChip(icon: "flame.fill",    value: "\(plan.totalCalories) kcal", color: Color(hex: "D85A30"))
                        statChip(icon: "checkmark.circle.fill",
                                 value: "\(plan.entries.filter(\.isCompleted).count)/\(plan.entries.count) done",
                                 color: Color(hex: "1D9E75"))
                    }
                }
            } else if plan.status == .upcoming && !plan.entries.isEmpty {
                HStack(spacing: 12) {
                    statChip(icon: "dumbbell.fill",
                             value: "\(plan.entries.count) exercises",
                             color: Color(hex: "F5A623"))
                    statChip(icon: "clock.fill",
                             value: estimatedDuration,
                             color: Color.appCyan)
                }
            }
        }
        .padding(.bottom, 20)
    }

    // ── Completed / Today section ─────────────────────────────────────────────

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel(plan.status == .today ? "TODAY'S EXERCISES" : "EXERCISES COMPLETED")

            ForEach(plan.entries) { entry in
                CompletedExerciseRow(entry: entry)
                    .padding(.horizontal, 20)
                    .onTapGesture { selectedExercise = entry.exercise }
            }

            if plan.entries.isEmpty {
                emptyHint("No exercise data recorded yet.")
            }
        }
    }

    // ── Planned section ───────────────────────────────────────────────────────

    private var plannedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("PLANNED EXERCISES")

            ForEach(plan.entries) { entry in
                PlannedExerciseRow(exercise: entry.exercise)
                    .padding(.horizontal, 20)
                    .onTapGesture { selectedExercise = entry.exercise }
            }

            if plan.entries.isEmpty {
                emptyHint("No exercises planned for this day yet.")
            }

            // Tip
            tipCard("Tap any exercise to see form cues and start AI coaching.")
                .padding(.horizontal, 20)
                .padding(.top, 6)
        }
    }

    // ── Rest section ──────────────────────────────────────────────────────────

    private var restSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("RECOVERY DAY")
            VStack(spacing: 10) {
                recoveryTip(icon: "drop.fill",       color: Color.appCyan,
                            title: "Hydrate",        sub: "Aim for 2–3 litres of water")
                recoveryTip(icon: "figure.cooldown", color: Color(hex: "7F77DD"),
                            title: "Stretch",        sub: "10–15 min light mobility work")
                recoveryTip(icon: "moon.fill",       color: Color(hex: "1D9E75"),
                            title: "Sleep",          sub: "7–9 hrs for optimal muscle repair")
                recoveryTip(icon: "fork.knife",      color: Color(hex: "F5A623"),
                            title: "Eat well",       sub: "Prioritise protein and whole foods")
            }
            .padding(.horizontal, 20)
        }
    }

    // ── Locked section ────────────────────────────────────────────────────────

    private var lockedSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.appT4)
                .padding(.top, 30)
            Text("Not unlocked yet")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.appT2)
            Text("Complete your upcoming sessions to unlock this day's workout.")
                .font(.system(size: 13))
                .foregroundStyle(Color.appT4)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private var statusColor: Color {
        switch plan.status {
        case .completed: return Color(hex: "1D9E75")
        case .today:     return Color.appCyan
        case .rest:      return Color(hex: "7F77DD")
        case .upcoming:  return Color(hex: "F5A623")
        case .locked:    return Color.appT4
        }
    }

    private var statusBadgeLabel: String {
        switch plan.status {
        case .completed: return "Completed"
        case .today:     return "Today"
        case .rest:      return "Rest Day"
        case .upcoming:  return "Planned"
        case .locked:    return "Locked"
        }
    }

    private var estimatedDuration: String {
        let total = plan.entries.reduce(0) { $0 + ($1.exercise.sets * $1.exercise.restSeconds / 60 + 3) }
        return "\(total) min est."
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color.appT4)
            .tracking(1.8)
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
    }

    private func statChip(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.appT2)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(color.opacity(0.1), in: Capsule())
    }

    private func tipCard(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Color(hex: "F5A623"))
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Color.appT3)
        }
        .padding(12)
        .background(Color(hex: "F5A623").opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "F5A623").opacity(0.2), lineWidth: 1))
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(Color.appT4)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
    }

    private func recoveryTip(icon: String, color: Color, title: String, sub: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                Text(sub).font(.system(size: 12)).foregroundStyle(Color.appT3)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 14))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - CompletedExerciseRow
// ─────────────────────────────────────────────────────────────────────────────

struct CompletedExerciseRow: View {
    let entry: DayExerciseEntry

    private var scoreColor: Color {
        guard let s = entry.score else { return Color.appT4 }
        if s >= 85 { return Color(hex: "1D9E75") }
        if s >= 65 { return Color(hex: "F5A623") }
        return Color(hex: "D85A30")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Exercise icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(entry.isCompleted
                          ? Color(hex: "1D9E75").opacity(0.15)
                          : Color.appBG3)
                    .frame(width: 46, height: 46)
                Image(systemName: entry.isCompleted ? "checkmark.circle.fill" : entry.exercise.icon)
                    .font(.system(size: entry.isCompleted ? 22 : 18))
                    .foregroundStyle(entry.isCompleted ? Color(hex: "1D9E75") : Color.appT3)
            }

            // Name + sets
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.exercise.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    if entry.exercise.poseType != nil {
                        Text("AI")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.appCyan)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.appCyan.opacity(0.12), in: Capsule())
                    }
                }
                Text(entry.isCompleted
                     ? "\(entry.setsCompleted ?? entry.exercise.sets) sets · \(entry.exercise.repsOrTime)"
                     : "\(entry.exercise.sets) sets · \(entry.exercise.repsOrTime)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appT3)
            }

            Spacer()

            // Score ring
            if let score = entry.score {
                ZStack {
                    Circle()
                        .stroke(scoreColor.opacity(0.2), lineWidth: 3)
                        .frame(width: 42, height: 42)
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 42, height: 42)
                    Text("\(score)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(scoreColor)
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appT4)
            }
        }
        .padding(12)
        .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(entry.isCompleted
                        ? Color(hex: "1D9E75").opacity(0.2)
                        : Color.appHair, lineWidth: 1)
        )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PlannedExerciseRow
// ─────────────────────────────────────────────────────────────────────────────

struct PlannedExerciseRow: View {
    let exercise: HomeExercise

    private var diffColor: Color {
        switch exercise.difficulty {
        case .beginner:     return Color(hex: "1D9E75")
        case .intermediate: return Color(hex: "F5A623")
        case .advanced:     return Color(hex: "D85A30")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appCyan.opacity(0.1))
                    .frame(width: 46, height: 46)
                Image(systemName: exercise.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.appCyan)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    if exercise.poseType != nil {
                        Text("AI")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.appCyan)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.appCyan.opacity(0.12), in: Capsule())
                    }
                }
                Text("\(exercise.sets) sets · \(exercise.repsOrTime)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appT3)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(exercise.difficulty.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(diffColor)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(diffColor.opacity(0.12), in: Capsule())
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appT4)
            }
        }
        .padding(12)
        .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appHair, lineWidth: 1))
    }
}
