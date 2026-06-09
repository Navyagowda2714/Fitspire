//
//  ProgressView.swift
//  Fitspyre
//
//  NOTE: struct is named FitProgressView to avoid clash with SwiftUI's ProgressView.
//  Crashes fixed:
//    1. glassEffect → replaced with plain background (iOS 17+ safe)
//    2. HealthKit Simulator guard added
//    3. WorkoutHistoryStore bundled in WorkoutHistoryStore.swift
//

import SwiftUI
import HealthKit
import Charts

struct FitProgressView: View {

    // ── HealthKit ─────────────────────────────────────────────────────────────
    @StateObject private var healthKit = HealthKitManager.shared
    @State private var isLoading = false

    // ── Workout history ───────────────────────────────────────────────────────
    @ObservedObject private var history = WorkoutHistoryStore.shared
    @State private var selectedPeriod: StatPeriod = .week

    @AppStorage("fitspire_streak")        private var streak        = 0
    @AppStorage("fitspire_xp")            private var xp            = 0
    @AppStorage("fitspire_totalWorkouts") private var totalWorkouts = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {

                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Progress")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text(healthKit.isAuthorized ? "Live from Apple Health" : "Connect to get started")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.appT3)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 56)

                        // Streak / momentum hero — always visible
                        streakHeroCard
                            .padding(.horizontal, 24)

                        // HealthKit section
                        if !HKHealthStore.isHealthDataAvailable() {
                            simulatorBanner
                        } else if !healthKit.isAuthorized {
                            healthKitPrompt
                        } else {
                            statsSection
                        }

                        // Workout progress — always visible
                        workoutProgressSection

                        Spacer(minLength: 80)
                    }
                }

                if isLoading {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    SwiftUI.ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.appCyan)
                        .scaleEffect(1.4)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            guard HKHealthStore.isHealthDataAvailable() else { return }
            healthKit.checkAuthorizationStatus()
            if healthKit.isAuthorized {
                Task { await loadData() }
            }
        }
    }

    // ── Simulator banner ──────────────────────────────────────────────────────

    private var simulatorBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 36))
                .foregroundStyle(Color.appCyan.opacity(0.6))
            Text("HealthKit unavailable on Simulator")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.appT2)
            Text("Run on a real iPhone to see live health data.")
                .font(.system(size: 12))
                .foregroundStyle(Color.appT3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appHair, lineWidth: 0.5))
        .padding(.horizontal, 24)
    }

    // ── HealthKit prompt ──────────────────────────────────────────────────────

    private var healthKitPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.appMove)
                .padding(.top, 20)

            Text("Connect Apple Health")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("Allow Fitspyre to read and save your workout data to Apple Health.")
                .font(.system(size: 14))
                .foregroundStyle(Color.appT3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Task {
                    isLoading = true
                    let granted = await healthKit.requestAuthorization()
                    isLoading = false
                    if granted { await loadData() }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                    Text("Connect Apple Health")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.appMove)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
        }
    }

    // ── Health stats ──────────────────────────────────────────────────────────

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("HEALTH DATA")
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill").font(.caption2.weight(.semibold))
                    Text("Today").font(.subheadline.weight(.medium))
                }
                .foregroundStyle(Color(hex: "D85A30"))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color(hex: "D85A30").opacity(0.12), in: Capsule())
                .padding(.trailing, 24)
            }

            HStack(spacing: 10) {
                HealthStatCard(icon: "flame.fill",
                               value: "\(Int(healthKit.activeCalories))",
                               label: "Active kcal", color: "D85A30")
                HealthStatCard(icon: "figure.walk",
                               value: "\(healthKit.steps)",
                               label: "Steps", color: "1D9E75")
                HealthStatCard(icon: "heart.fill",
                               value: healthKit.heartRate > 0 ? "\(Int(healthKit.heartRate))" : "—",
                               label: "BPM", color: "D85A30")
            }
            .padding(.horizontal, 24)
        }
    }

    // ── Workout progress section ──────────────────────────────────────────────

    private var streakHeroCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "D85A30").opacity(0.16))
                    .frame(width: 58, height: 58)
                Image(systemName: "flame.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color(hex: "D85A30"))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("\(streak)-day streak")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(streak > 0 ? "Keep the fire going — train today" : "Start today to begin a streak")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appT3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(xp)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.appCyan)
                Text("XP")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.appT4)
                    .tracking(1.2)
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: [Color(hex: "1E1206"), Color.appBG2],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                RoundedRectangle(cornerRadius: 18)
                    .stroke(LinearGradient(colors: [Color(hex: "D85A30").opacity(0.4), Color.clear],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1)
            }
        )
    }

    private var workoutProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Period picker
            HStack {
                sectionLabel("WORKOUT STATS")
                Spacer()
                Menu {
                    ForEach(StatPeriod.allCases) { period in
                        Button(period.rawValue) {
                            withAnimation(.spring(response: 0.3)) { selectedPeriod = period }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPeriod.rawValue)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appT2)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.appT3)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Color.appBG2, in: Capsule())
                    .overlay(Capsule().stroke(Color.appHair, lineWidth: 0.5))
                }
                .padding(.trailing, 24)
            }

            // 2×2 stat grid
            let avgScore  = history.averageFormScore(in: selectedPeriod)
            let totalReps = history.totalReps(in: selectedPeriod)
            let sessions  = history.totalSessions(in: selectedPeriod)
            let best      = history.bestScore(in: selectedPeriod)
            let bestEx    = history.bestScoreExercise(in: selectedPeriod)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PCStatTile(
                    label: "Avg Form Score",
                    value: sessions > 0 ? "\(avgScore)" : "—",
                    unit:  sessions > 0 ? "/100" : "",
                    valueColor: scoreColor(avgScore, hasSessions: sessions > 0),
                    trend: sessions > 0 ? formTrend(avgScore) : "No sessions yet"
                )
                PCStatTile(
                    label: "Total Reps",
                    value: "\(totalReps)", unit: "",
                    valueColor: .white,
                    trend: "\(sessions) session\(sessions == 1 ? "" : "s")"
                )
                PCStatTile(
                    label: "Sessions",
                    value: "\(sessions)", unit: "",
                    valueColor: .white,
                    trend: selectedPeriod == .week ? "This week" : "Keep going"
                )
                PCStatTile(
                    label: "Best Score",
                    value: best > 0 ? "\(best)" : "—",
                    unit:  best > 0 ? "/100" : "",
                    valueColor: Color(hex: "F5A623"),
                    trend: best > 0 ? bestEx : "Complete a session"
                )
            }
            .padding(.horizontal, 24)

            // Chart
            PCFormScoreChart(history: history, period: selectedPeriod)

            // Top exercises
            PCTopExercisesSection(history: history, period: selectedPeriod)
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color.appT4)
            .tracking(1.8)
            .padding(.leading, 24)
    }

    private func scoreColor(_ score: Int, hasSessions: Bool) -> Color {
        guard hasSessions else { return Color.appT2 }
        if score >= 80 { return Color(hex: "1D9E75") }
        if score >= 55 { return Color(hex: "F5A623") }
        return Color(hex: "D85A30")
    }

    private func formTrend(_ score: Int) -> String {
        if score >= 80 { return "Excellent form 🔥" }
        if score >= 55 { return "Good — keep improving" }
        return "Focus on form"
    }

    private func loadData() async {
        isLoading = true
        await healthKit.loadTodayStats()
        isLoading = false
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PCFormScoreChart
// ─────────────────────────────────────────────────────────────────────────────

struct PCFormScoreChart: View {
    @ObservedObject var history: WorkoutHistoryStore
    let period: StatPeriod

    private var points: [FormScorePoint] { history.chartPoints(for: period) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Form Score")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appT2)
                .padding(.leading, 24)

            if points.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.appT4)
                    Text("No sessions in this period yet")
                        .font(.subheadline)
                        .foregroundStyle(Color.appT3)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appHair, lineWidth: 0.5))
                .padding(.horizontal, 24)
            } else if period == .week {
                PCWeeklyBarChart(weeklyScores: history.weeklyScores())
                    .padding(.horizontal, 24)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(Color(hex: "1D9E75"))
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "1D9E75").opacity(0.3), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(Color(hex: "1D9E75"))
                    .symbolSize(30)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100]) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel().foregroundStyle(Color.appT3).font(.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel(
                            format: period == .month
                                ? .dateTime.day().month()
                                : .dateTime.month().year()
                        )
                        .foregroundStyle(Color.appT3)
                        .font(.caption2)
                    }
                }
                .frame(height: 130)
                .padding(.horizontal, 24)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PCWeeklyBarChart
// ─────────────────────────────────────────────────────────────────────────────

struct PCWeeklyBarChart: View {
    let weeklyScores: [Int?]
    private let labels = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    private var todayOffset: Int {
        (Calendar.current.component(.weekday, from: Date()) + 5) % 7
    }
    private func labelIndex(for offset: Int) -> Int {
        (todayOffset - (6 - offset) + 7) % 7
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<7, id: \.self) { idx in
                let score   = weeklyScores[idx]
                let isToday = idx == 6
                let height  = score.map { CGFloat($0) / 100.0 * 70 } ?? 6

                VStack(spacing: 4) {
                    if let s = score {
                        Text("\(s)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(isToday ? Color(hex: "1D9E75") : Color.appT3)
                    }
                    RoundedRectangle(cornerRadius: 5)
                        .fill(score != nil
                              ? (isToday ? Color(hex: "1D9E75") : Color(hex: "1D9E75").opacity(0.4))
                              : Color.white.opacity(0.07))
                        .frame(height: max(6, height))
                    Text(labels[labelIndex(for: idx)])
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(isToday ? Color(hex: "1D9E75") : Color.appT4)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 110)
        .padding(16)
        .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appHair, lineWidth: 0.5))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PCTopExercisesSection
// ─────────────────────────────────────────────────────────────────────────────

struct PCTopExercisesSection: View {
    @ObservedObject var history: WorkoutHistoryStore
    let period: StatPeriod

    private var summaries: [ExerciseSummary] { history.topExercises(in: period) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top Exercises")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appT2)
                .padding(.leading, 24)

            if summaries.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(Color.appT4)
                    Text("No sessions yet — start a workout!")
                        .font(.subheadline)
                        .foregroundStyle(Color.appT3)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appHair, lineWidth: 0.5))
                .padding(.horizontal, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(summaries.enumerated()), id: \.element.id) { idx, summary in
                        PCExerciseScoreRow(
                            rank:      idx + 1,
                            name:      summary.name,
                            icon:      summary.icon,
                            iconColor: colorFromName(summary.iconColor),
                            score:     summary.avgScore,
                            sessions:  summary.sessions
                        )
                        if idx < summaries.count - 1 {
                            Divider()
                                .background(Color.appHair)
                                .padding(.leading, 60)
                        }
                    }
                }
                .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appHair, lineWidth: 0.5))
                .padding(.horizontal, 24)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PCExerciseScoreRow
// ─────────────────────────────────────────────────────────────────────────────

struct PCExerciseScoreRow: View {
    let rank:      Int
    let name:      String
    let icon:      String
    let iconColor: Color
    let score:     Int
    let sessions:  Int

    private var scoreColor: Color {
        if score >= 80 { return Color(hex: "1D9E75") }
        if score >= 55 { return Color(hex: "F5A623") }
        return Color(hex: "D85A30")
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.caption.bold())
                .foregroundStyle(Color.appT4)
                .frame(width: 16)

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(sessions) session\(sessions == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(Color.appT3)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(scoreColor)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(scoreColor)
                            .frame(width: geo.size.width * CGFloat(score) / 100, height: 4)
                    }
                }
                .frame(width: 60, height: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PCStatTile
// ─────────────────────────────────────────────────────────────────────────────

struct PCStatTile: View {
    let label:      String
    let value:      String
    let unit:       String
    let valueColor: Color
    let trend:      String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.appT3)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(Color.appT4)
                }
            }

            Text(trend)
                .font(.caption2)
                .foregroundStyle(Color(hex: "1D9E75"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appHair, lineWidth: 0.5))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HealthStatCard
// ─────────────────────────────────────────────────────────────────────────────

struct HealthStatCard: View {
    let icon:  String
    let value: String
    let label: String
    let color: String

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: color).opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: color))
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.appT3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appHair, lineWidth: 0.5))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HKWorkoutActivityType extension
// ─────────────────────────────────────────────────────────────────────────────

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .traditionalStrengthTraining: return "Strength Training"
        case .coreTraining:                return "Core Training"
        case .running:                     return "Running"
        case .cycling:                     return "Cycling"
        case .walking:                     return "Walking"
        case .yoga:                        return "Yoga"
        default:                           return "Workout"
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Color name helper
// ─────────────────────────────────────────────────────────────────────────────

func colorFromName(_ name: String) -> Color {
    switch name {
    case "blue":   return .blue
    case "green":  return Color(hex: "1D9E75")
    case "orange": return Color(hex: "F5A623")
    case "red":    return Color(hex: "D85A30")
    case "purple": return Color(hex: "7F77DD")
    case "yellow": return .yellow
    case "pink":   return .pink
    case "teal":   return .teal
    case "cyan":   return Color(hex: "00E5FF")
    case "mint":   return .mint
    case "indigo": return .indigo
    default:       return Color(hex: "F5A623")
    }
}
