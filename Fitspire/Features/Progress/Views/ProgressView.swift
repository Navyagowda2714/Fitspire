//
//  ProgressView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 03/05/2026.
//
//  Updated: Integrated workout progress stats (form score, reps, sessions,
//  chart, top exercises) from PostureCorrect. All HealthKit data is unchanged.
//

import SwiftUI
import HealthKit
import Charts

struct FitProgressView: View {
    // ── HealthKit (unchanged) ──────────────────────────────────────────────
    @StateObject private var healthKit = HealthKitManager.shared
    @State private var hasRequestedPermission = false

    // ── Workout history (new) ──────────────────────────────────────────────
    @ObservedObject private var history = WorkoutHistoryStore.shared
    @State private var selectedPeriod: StatPeriod = .week

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    if !healthKit.isAuthorized {
                        healthKitPrompt
                    } else {
                        statsSection
                    }

                    // ── Workout progress stats (always visible) ────────────
                    workoutProgressSection

                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            healthKit.checkAuthorizationStatus()
            if healthKit.isAuthorized {
                Task { await loadData() }
            }
        }
    }

    // MARK: - HealthKit prompt (unchanged)

    private var healthKitPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.appMove)

            Text("Connect Apple Health")
                .font(.system(size: 20, weight: .medium))

            Text("Allow FitnessAI to read and save your workout data to Apple Health.")
                .font(.system(size: 14))
                .foregroundStyle(Color.appT3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Task {
                    let granted = await healthKit.requestAuthorization()
                    if granted {
                        await loadData()
                    }
                }
            } label: {
                Text("Connect Apple Health")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.appMove)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 60)
    }

    // MARK: - Stats section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header row — matches workoutProgressSection style
            HStack {
                Text("Health Data")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appT3)
                    .padding(.leading, 24)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2.weight(.semibold))
                    Text("Today")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(Color(hex: "D85A30"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: "D85A30").opacity(0.12))
                .clipShape(Capsule())
                .padding(.trailing, 24)
            }

            // Original 3-column card row
            HStack(spacing: 12) {
                HealthStatCard(
                    icon: "flame.fill",
                    value: "\(Int(healthKit.activeCalories))",
                    label: "Active kcal",
                    color: "D85A30"
                )
                HealthStatCard(
                    icon: "figure.walk",
                    value: "\(healthKit.steps)",
                    label: "Steps",
                    color: "1D9E75"
                )
                HealthStatCard(
                    icon: "heart.fill",
                    value: healthKit.heartRate > 0
                        ? "\(Int(healthKit.heartRate))"
                        : "—",
                    label: "BPM",
                    color: "D85A30"
                )
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Workout progress section (new)

    private var workoutProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Period picker
            HStack {
                Text("Workout Stats")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appT3)
                    .padding(.leading, 24)

                Spacer()

                Menu {
                    ForEach(StatPeriod.allCases) { period in
                        Button(period.rawValue) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedPeriod = period
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPeriod.rawValue)
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.appBG2)
                    .clipShape(Capsule())
                }
                .padding(.trailing, 24)
            }

            // 2×2 stat grid
            let avgScore  = history.averageFormScore(in: selectedPeriod)
            let totalReps = history.totalReps(in: selectedPeriod)
            let sessions  = history.totalSessions(in: selectedPeriod)
            let best      = history.bestScore(in: selectedPeriod)
            let bestEx    = history.bestScoreExercise(in: selectedPeriod)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                PCStatTile(
                    label: "Avg Form Score",
                    value: sessions > 0 ? "\(avgScore)" : "—",
                    unit: sessions > 0 ? "/100" : "",
                    valueColor: scoreColor(avgScore, hasSessions: sessions > 0),
                    trend: sessions > 0 ? formTrend(avgScore) : "No sessions yet"
                )
                PCStatTile(
                    label: "Total Reps",
                    value: "\(totalReps)", unit: "",
                    valueColor: .primary,
                    trend: "\(sessions) session\(sessions == 1 ? "" : "s")"
                )
                PCStatTile(
                    label: "Sessions",
                    value: "\(sessions)", unit: "",
                    valueColor: .primary,
                    trend: selectedPeriod == .week ? "This week" : "Keep going"
                )
                PCStatTile(
                    label: "Best Score",
                    value: best > 0 ? "\(best)" : "—",
                    unit: best > 0 ? "/100" : "",
                    valueColor: .orange,
                    trend: best > 0 ? bestEx : "Complete a session"
                )
            }
            .padding(.horizontal, 24)

            // Form score chart
            PCFormScoreChart(history: history, period: selectedPeriod)

            // Top exercises
            PCTopExercisesSection(history: history, period: selectedPeriod)
        }
    }

    // MARK: - Form Score Chart
    // Uses Swift Charts (iOS 16+). Falls back gracefully when no data.
    // ─────────────────────────────────────────────────────────────────────────────

    struct PCFormScoreChart: View {
        @ObservedObject var history: WorkoutHistoryStore
        let period: StatPeriod

        private var points: [FormScorePoint] { history.chartPoints(for: period) }

        // For the weekly bar chart we use day-of-week labels
        private let weekDayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Form score")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal)

                Group {
                    if points.isEmpty {
                        // Empty state
                        VStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                            Text("No sessions in this period yet")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .padding(.vertical, 16)
                    } else if period == .week {
                        // Weekly view — bar chart with day labels
                        PCWeeklyBarChart(weeklyScores: history.weeklyScores())
                    } else {
                        // Month / All time — line chart
                        Chart(points) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Score", point.score)
                            )
                            .foregroundStyle(Color.green)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Score", point.score)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green.opacity(0.3), .clear],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Score", point.score)
                            )
                            .foregroundStyle(Color.green)
                            .symbolSize(30)
                        }
                        .chartYScale(domain: 0...100)
                        .chartYAxis {
                            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                                AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                                AxisValueLabel()
                                    .foregroundStyle(Color.secondary)
                                    .font(.caption2)
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel(format: period == .month ? .dateTime.day().month() : .dateTime.month().year())
                                    .foregroundStyle(Color.secondary)
                                    .font(.caption2)
                            }
                        }
                        .frame(height: 120)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 14)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal)
            }
        }
    }
    
    struct PCWeeklyBarChart: View {
        let weeklyScores: [Int?]   // 7 values, index 0 = 6 days ago, 6 = today
        private let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        // Compute today's weekday index (0=Mon … 6=Sun)
        private var todayWeekdayOffset: Int {
            let wd = Calendar.current.component(.weekday, from: Date())
            return (wd + 5) % 7   // Sunday=1→6, Monday=2→0, …
        }

        // Map rolling-7-day index (0=6 days ago) to label index
        private func labelIndex(for offset: Int) -> Int {
            return (todayWeekdayOffset - (6 - offset) + 7) % 7
        }

        var body: some View {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { idx in
                    let score = weeklyScores[idx]
                    let isToday = (idx == 6)
                    let heightFraction = score.map { CGFloat($0) / 100.0 } ?? 0
                    let label = labels[labelIndex(for: idx)]

                    VStack(spacing: 4) {
                        if let s = score {
                            Text("\(s)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(isToday ? .green : .secondary)
                        }
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(score != nil
                                  ? (isToday ? Color.green : Color.green.opacity(0.4))
                                  : Color.white.opacity(0.07))
                            .frame(height: max(6, heightFraction * 70))
                        Text(label)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(isToday ? .green : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .frame(height: 110)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // MARK: - Top Exercises Section
    // ─────────────────────────────────────────────────────────────────────────────

    struct PCTopExercisesSection: View {
        @ObservedObject var history: WorkoutHistoryStore
        let period: StatPeriod

        private var summaries: [ExerciseSummary] { history.topExercises(in: period) }

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                Text("Top exercises")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                if summaries.isEmpty {
                    HStack {
                        Image(systemName: "dumbbell")
                            .foregroundStyle(.secondary)
                        Text("No sessions yet — start a workout!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal)
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
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal)
                }
            }
        }
    }

    struct PCExerciseScoreRow: View {
        let rank:      Int
        let name:      String
        let icon:      String
        let iconColor: Color
        let score:     Int
        let sessions:  Int

        private var scoreColor: Color {
            if score >= 80 { return .green }
            if score >= 55 { return .yellow }
            return .red
        }

        var body: some View {
            HStack(spacing: 12) {
                // Rank badge
                Text("\(rank)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                // Exercise icon
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .glassEffect(.regular.tint(iconColor.opacity(0.15)),
                                 in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.subheadline)
                    Text("\(sessions) session\(sessions == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Score + bar
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(score)")
                        .font(.subheadline.bold())
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
    // MARK: - Stat Tile
    // ─────────────────────────────────────────────────────────────────────────────

    struct PCStatTile: View {
        let label:      String
        let value:      String
        let unit:       String
        let valueColor: Color
        let trend:      String
        var trendColor: Color = .green

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(valueColor)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(trend)
                    .font(.caption2)
                    .foregroundStyle(trendColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    
    // MARK: - Helpers

    private func scoreColor(_ score: Int, hasSessions: Bool) -> Color {
        guard hasSessions else { return .primary }
        if score >= 80 { return .green }
        if score >= 55 { return .yellow }
        return .red
    }

    private func formTrend(_ score: Int) -> String {
        if score >= 80 { return "Excellent form" }
        if score >= 55 { return "Good — keep improving" }
        return "Focus on form"
    }

    private func loadData() async {
        await healthKit.loadTodayStats()
    }
}

// MARK: - Supporting views (unchanged)

struct HealthStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: String

    var body: some View {
        VStack(spacing: 10) {
            // Tinted icon badge — mirrors PCExerciseScoreRow icon style
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(hex: color))
                .frame(width: 36, height: 36)
                .glassEffect(.regular.tint(Color(hex: color).opacity(0.18)),
                             in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Value — same rounded bold font as PCStatTile
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)

            // Label — same caption style as PCStatTile
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Shared colour helper (used by Coach + Progress)
// ─────────────────────────────────────────────────────────────────────────────

func colorFromName(_ name: String) -> Color {
    switch name {
    case "blue":   return .blue
    case "green":  return .green
    case "orange": return .orange
    case "red":    return .red
    case "purple": return .purple
    case "yellow": return .yellow
    case "pink":   return .pink
    case "teal":   return .teal
    case "cyan":   return .cyan
    case "mint":   return .mint
    case "indigo": return .indigo
    default:       return .orange
    }
}
