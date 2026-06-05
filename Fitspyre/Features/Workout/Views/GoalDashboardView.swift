//
//  GoalDashboardView.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 03/06/2026.
//

//
//  GoalDashboardView.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 03/06/2026.
//

import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Supporting types  (week schedule)
// ─────────────────────────────────────────────────────────────────────────────

enum WeekDayStatus {
    case completed, today, rest, locked, upcoming
}

struct WeekDayItem: Identifiable {
    let id = UUID()
    let shortName:    String       // MON, TUE …
    let workoutTitle: String
    let duration:     String       // "" for rest days
    let status:       WeekDayStatus
    let date:         Date         // ← NEW: actual calendar date for the sheet
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - GoalDashboardView
// ─────────────────────────────────────────────────────────────────────────────

struct GoalDashboardView: View {

    @EnvironmentObject var appState: AppState

    @AppStorage("fitspire_streak")        private var streak        = 0
    @AppStorage("fitspire_xp")            private var xp            = 0
    @AppStorage("fitspire_totalWorkouts") private var totalWorkouts = 0

    @State private var demoExercise:       HomeExercise? = nil
    @State private var cameraExercise:     ExerciseType? = nil
    @State private var selectedCategory:   HomeExercise.Category? = nil
    @State private var cameraHomeExercise: HomeExercise? = nil
    @State private var introExercise:      HomeExercise? = nil

    private var userName: String {
        appState.userProfile?.name ?? "Athlete"
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    private let quotes = [
        "Consistency beats intensity.",
        "One rep closer.",
        "Your only limit is you.",
        "Train hard, recover smart.",
        "Show up. Every day."
    ]
    private var dailyQuote: String {
        quotes[Calendar.current.component(.day, from: Date()) % quotes.count]
    }

    private var weekDays: [WeekDayItem] {
        let cal     = Calendar.current
        let today   = Date()
        let weekday = cal.component(.weekday, from: today) - 1  // 0=Sun
        guard let startOfWeek = cal.date(byAdding: .day, value: -weekday, to: today) else { return [] }

        let names = ["SUN","MON","TUE","WED","THU","FRI","SAT"]
        let rawPlan: [(String, String, WeekDayStatus)] = [
            ("Rest",              "",       .rest),
            ("HIIT Cardio",       "25 min", .completed),
            ("Full Body Circuit", "30 min", .upcoming),
            ("Rest",              "",       .rest),
            ("Cardio Blast",      "20 min", .locked),
            ("Upper Body",        "30 min", .locked),
            ("Active Recovery",   "15 min", .locked),
        ]

        return (0..<7).compactMap { i in
            guard let date = cal.date(byAdding: .day, value: i, to: startOfWeek) else { return nil }
            let isToday = cal.isDateInToday(date)
            let raw = rawPlan[i]
            return WeekDayItem(
                shortName:    names[i],
                workoutTitle: raw.0,
                duration:     raw.1,
                status:       isToday ? .today : raw.2,
                date:         date              // ← pass real date
            )
        }
    }

    private var todayItem: WeekDayItem? {
        weekDays.first { $0.status == .today }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        headerSection
                            .padding(.top, 56)
                            .padding(.horizontal, 20)

                        statsRow
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        Text("\"\(dailyQuote)\"")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appT3)
                            .italic()
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        todayQuestCard
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        weeklyPathSection
                            .padding(.top, 28)

                        Spacer(minLength: 110)
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $demoExercise) { ex in
                HomeExerciseDemoView(
                    exercise: ex,
                    onStartCamera: ex.poseType != nil ? {
                        cameraHomeExercise = ex
                        demoExercise = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            introExercise = ex
                        }
                    } : {}
                )
            }
            .fullScreenCover(item: $introExercise) { ex in
                AIFormCheckIntroView(exercise: ex) {
                    let poseType = ex.poseType!
                    introExercise = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        cameraExercise = poseType
                    }
                }
            }
            .fullScreenCover(item: $cameraExercise) { poseType in
                if let homeEx = cameraHomeExercise {
                    ExerciseLiveView(exercise: homeEx)
                } else {
                    ExerciseLiveView(
                        exercise: HomeExerciseLibrary.bodyweight.first(where: { $0.poseType == poseType })
                            ?? HomeExerciseLibrary.bodyweight[0]
                    )
                }
            }
        }
    }

    // ── Header ────────────────────────────────────────────────────────────────

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(greeting),")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.appT2)
                Text(userName)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.appCyan)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "7F77DD"), Color(hex: "1D9E75")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Text(String(userName.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    // ── Stats ─────────────────────────────────────────────────────────────────

    private var statsRow: some View {
        HStack(spacing: 10) {
            statPill(icon: "flame.fill",  value: "\(streak)d",      label: "STREAK",   accent: Color(hex: "D85A30"))
            statPill(icon: "bolt.fill",   value: "\(xp)",            label: "XP",       accent: Color.appCyan)
            statPill(icon: "trophy.fill", value: "\(totalWorkouts)", label: "WORKOUTS", accent: Color(hex: "1D9E75"))
        }
    }

    private func statPill(icon: String, value: String, label: String, accent: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accent)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.appT4)
                    .tracking(1.2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.appHair, lineWidth: 0.5)
        )
    }

    // ── Today's Quest ─────────────────────────────────────────────────────────

    private var todayQuestCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY'S QUEST")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.appCyan)
                .tracking(2)

            if let item = todayItem, item.workoutTitle != "Rest" {
                Text(item.workoutTitle)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(item.duration.isEmpty
                     ? (appState.selectedGoal?.rawValue ?? "Stay active")
                     : "\(item.duration) · Stay focused")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appT3)
            } else {
                Text("Rest & recover")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Hydrate, stretch, sleep")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appT3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "0D1E2E"), Color.appBG2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Color.appCyan.opacity(0.4), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }

    // ── Weekly Path ───────────────────────────────────────────────────────────

    private var weeklyPathSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("This week's path")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                NavigationLink(destination: WeeklyCalendarView()) {
                    Text("Weekly plan →")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "D85A30"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            ZigzagWeekView(days: weekDays)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ZigzagWeekView
// ─────────────────────────────────────────────────────────────────────────────

struct ZigzagWeekView: View {
    let days: [WeekDayItem]

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geo in
                Path { p in
                    let x = geo.size.width / 2
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
                .foregroundStyle(Color.appHair2)
            }

            VStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    ZigzagNode(day: day, onLeft: index.isMultiple(of: 2))
                        .frame(height: 110)
                }
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ZigzagNode  (tappable — opens DayDetailSheet)
// ─────────────────────────────────────────────────────────────────────────────

struct ZigzagNode: View {
    let day:    WeekDayItem
    let onLeft: Bool

    @State private var showDetail = false   // ← drives the sheet

    private var fill: Color {
        switch day.status {
        case .completed: return Color(hex: "1D9E75")
        case .today:     return Color.appCyan
        case .rest:      return Color(hex: "7F77DD")
        case .upcoming:  return Color.appBG3
        case .locked:    return Color.appBG2
        }
    }

    private var icon: String {
        switch day.status {
        case .completed: return "checkmark"
        case .today:     return "bolt.fill"
        case .rest:      return "moon.fill"
        case .upcoming:  return "star"
        case .locked:    return "lock.fill"
        }
    }

    private var iconTint: Color {
        switch day.status {
        case .today:  return Color.appBG
        case .locked: return Color.appT4
        default:      return .white
        }
    }

    // Convert WeekDayStatus → DayStatus for DayDetailSheet
    private var dayStatus: DayStatus {
        switch day.status {
        case .completed: return .completed
        case .today:     return .today
        case .rest:      return .rest
        case .locked:    return .locked
        case .upcoming:  return .upcoming
        }
    }

    // Build a CalendarSession from the WeekDayItem for DayDetailSheet
    private var calSession: CalendarSession? {
        CalendarSession(
            title:    day.workoutTitle.isEmpty ? "Rest & Recover" : day.workoutTitle,
            duration: day.duration,
            status:   dayStatus,
            calories: 0
        )
    }

    var body: some View {
        HStack(spacing: 0) {
            if onLeft {
                nodeContent
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 8)
                Spacer().frame(width: UIScreen.main.bounds.width / 2)
            } else {
                Spacer().frame(width: UIScreen.main.bounds.width / 2)
                nodeContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
            }
        }
        // Tap anywhere on the node row to open detail
        .contentShape(Rectangle())
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            DayDetailSheet(date: day.date, session: calSession)
        }
    }

    private var nodeContent: some View {
        VStack(spacing: 6) {
            ZStack {
                if day.status == .today {
                    Circle()
                        .stroke(Color.appCyan.opacity(0.35), lineWidth: 3)
                        .frame(width: 64, height: 64)
                }
                Circle()
                    .fill(fill)
                    .frame(width: 56, height: 56)
                    .shadow(color: fill.opacity(0.45), radius: 8, y: 4)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(iconTint)
            }
            Text(day.shortName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(day.status == .today ? Color.appCyan : Color.appT3)
                .tracking(1.5)
            Text(day.duration.isEmpty
                 ? day.workoutTitle
                 : "\(day.workoutTitle) · \(day.duration)")
                .font(.system(size: 10))
                .foregroundStyle(Color.appT4)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 145)
    }
}
