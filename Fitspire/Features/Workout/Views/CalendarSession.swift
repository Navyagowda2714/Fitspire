//
//  CalendarSession.swift
//  Fitspire
//
//  Created by Navyashree Byregowda on 03/06/2026.
//

// CalendarSession.swift
// Fitspire — Target: Fitspire ONLY

import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Session data
// ─────────────────────────────────────────────────────────────────────────────
// DayStatus.swift
// Fitspire — Target: Fitspire ONLY

import Foundation

enum DayStatus {
    case completed
    case today
    case rest
    case locked
    case upcoming
}
struct CalendarSession {
    let title:    String
    let duration: String
    let status:   DayStatus
    let calories: Int
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - TrainingView  (Tab 2)
// ─────────────────────────────────────────────────────────────────────────────

struct TrainingView: View {
    @EnvironmentObject var appState: AppState
    @State private var segment = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBG.ignoresSafeArea()
                VStack(spacing: 0) {
                    topBar
                    segmentControl
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 10)
                    if segment == 0 {
                        TrainingWorkoutsView()
                    } else {
                        WeeklyCalendarView()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Training")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(appState.selectedGoal?.rawValue ?? "Home Workout")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appCyan)
            }
            Spacer()
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 17))
                .foregroundStyle(Color.appT2)
                .padding(10)
                .background(Color.appBG2, in: Circle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
    }

    private var segmentControl: some View {
        HStack(spacing: 0) {
            segBtn("Workouts", tag: 0)
            segBtn("Calendar", tag: 1)
        }
        .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appHair, lineWidth: 0.5))
    }

    private func segBtn(_ title: String, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) { segment = tag }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(segment == tag ? Color.appBG : Color.appT3)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if segment == tag {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.appCyan)
                                .padding(3)
                        }
                    }
                )
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - TrainingWorkoutsView
// ─────────────────────────────────────────────────────────────────────────────

struct TrainingWorkoutsView: View {
    @State private var selectedCategory:   HomeExercise.Category? = nil
    @State private var demoExercise:       HomeExercise? = nil
    @State private var cameraExercise:     ExerciseType? = nil
    @State private var cameraHomeExercise: HomeExercise? = nil
    @State private var introExercise:      HomeExercise? = nil

    private var exercises: [HomeExercise] {
        guard let cat = selectedCategory else { return HomeExerciseLibrary.bodyweight }
        return HomeExerciseLibrary.bodyweight.filter { $0.category == cat }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                aiBanner.padding(.horizontal, 20).padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterPill("All (\(HomeExerciseLibrary.bodyweight.count))",
                                   selected: selectedCategory == nil) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = nil }
                        }
                        ForEach(HomeExercise.Category.allCases, id: \.rawValue) { cat in
                            let count = HomeExerciseLibrary.bodyweight.filter { $0.category == cat }.count
                            if count > 0 {
                                filterPill("\(cat.rawValue) (\(count))",
                                           selected: selectedCategory == cat) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedCategory = selectedCategory == cat ? nil : cat
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                VStack(spacing: 10) {
                    ForEach(exercises) { exercise in
                        ExerciseCard(exercise: exercise) { demoExercise = exercise }
                            .padding(.horizontal, 20)
                    }
                }

                Spacer(minLength: 110)
            }
        }
        .fullScreenCover(item: $demoExercise) { ex in
            HomeExerciseDemoView(
                exercise: ex,
                onStartCamera: ex.poseType != nil ? {
                    cameraHomeExercise = ex
                    demoExercise = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { introExercise = ex }
                } : {}
            )
        }
        .fullScreenCover(item: $introExercise) { ex in
            AIFormCheckIntroView(exercise: ex) {
                let poseType = ex.poseType!
                introExercise = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { cameraExercise = poseType }
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

    private var aiBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.appCyan)
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Form Coach Active")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text("Tap any exercise to start live detection")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appT3)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.appCyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appCyan.opacity(0.2), lineWidth: 1))
    }

    private func filterPill(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: selected ? .bold : .medium))
                .foregroundStyle(selected ? .black : Color.appT2)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(selected ? Color.appLime : Color.appBG2)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(selected ? Color.appLime : Color.appHair2, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - WeeklyCalendarView
// ─────────────────────────────────────────────────────────────────────────────

struct WeeklyCalendarView: View {
    @State private var selectedDate: Date = Date()
    @State private var displayMonth: Date = Date()
    private let calendar = Calendar.current

    private var sessions: [String: CalendarSession] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = Date()
        var d: [String: CalendarSession] = [:]

        // Past sessions — completed
        let pastData: [(String, Int, DayStatus, Int)] = [
            ("HIIT Cardio", 25, DayStatus.completed, 180),
            ("Push Ups",    20, DayStatus.completed, 120),
            ("Plank Hold",  15, DayStatus.completed,  90),
            ("Squats",      30, DayStatus.completed, 200),
            ("Full Body",   35, DayStatus.completed, 240)
        ]
        for (i, (title, dur, status, cal)) in pastData.enumerated() {
            if let date = calendar.date(byAdding: .day, value: -(i + 1), to: today) {
                d[fmt.string(from: date)] = CalendarSession(
                    title: title, duration: "\(dur) min", status: status, calories: cal)
            }
        }

        // Today — rest
        d[fmt.string(from: today)] = CalendarSession(
            title: "Rest & Recover", duration: "", status: DayStatus.rest, calories: 0)

        // Future sessions — upcoming
        let futureData: [(String, Int, DayStatus, Int)] = [
            ("Cardio Blast",    20, DayStatus.upcoming, 0),
            ("Upper Body",      30, DayStatus.upcoming, 0),
            ("Core Burn",       25, DayStatus.upcoming, 0),
            ("Leg Day",         35, DayStatus.upcoming, 0),
            ("Active Recovery", 15, DayStatus.upcoming, 0)
        ]
        for (i, (title, dur, status, cal)) in futureData.enumerated() {
            if let date = calendar.date(byAdding: .day, value: i + 1, to: today) {
                d[fmt.string(from: date)] = CalendarSession(
                    title: title, duration: "\(dur) min", status: status, calories: cal)
            }
        }
        return d
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                monthNav
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                calendarGrid
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                Rectangle()
                    .fill(Color.appHair)
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                weekList.padding(.top, 16)
                Spacer(minLength: 110)
            }
        }
    }

    // ── Month navigator ───────────────────────────────────────────────────────

    private var monthNav: some View {
        HStack {
            navArrow("chevron.left") {
                withAnimation {
                    displayMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth
                }
            }
            Spacer()
            Text(monthString(displayMonth))
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            navArrow("chevron.right") {
                withAnimation {
                    displayMonth = calendar.date(byAdding: .month, value: 1, to: displayMonth) ?? displayMonth
                }
            }
        }
    }

    private func navArrow(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.appT2)
                .frame(width: 36, height: 36)
                .background(Color.appBG2, in: Circle())
        }
    }

    // ── Calendar grid ─────────────────────────────────────────────────────────

    private var calendarGrid: some View {
        let days    = daysInMonth(displayMonth)
        let offset  = firstWeekdayOffset(displayMonth)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        let headers = ["S","M","T","W","T","F","S"]
        return VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(headers.indices, id: \.self) { i in
                    Text(headers[i])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.appT4)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<offset, id: \.self) { _ in Color.clear.frame(height: 42) }
                ForEach(days, id: \.self) { date in
                    DayCell(
                        date:       date,
                        isToday:    calendar.isDateInToday(date),
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        dotStatus:  sessions[dateKey(date)]?.status
                    )
                    .onTapGesture { withAnimation { selectedDate = date } }
                }
            }
        }
    }

    // ── This week list ────────────────────────────────────────────────────────

    private var weekList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THIS WEEK")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.appT4)
                .tracking(1.8)
                .padding(.horizontal, 20)
            ForEach(thisWeekDates(), id: \.self) { date in
                CalendarRowCard(
                    date:       date,
                    session:    sessions[dateKey(date)],
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                )
                .padding(.horizontal, 20)
                .onTapGesture { withAnimation { selectedDate = date } }
            }
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func monthString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: d)
    }
    private func dateKey(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: d)
    }
    private func daysInMonth(_ d: Date) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: d),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: d))
        else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
    }
    private func firstWeekdayOffset(_ d: Date) -> Int {
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: d))
        else { return 0 }
        return (calendar.component(.weekday, from: start) - 1 + 7) % 7
    }
    private func thisWeekDates() -> [Date] {
        let wd = calendar.component(.weekday, from: Date()) - 1
        guard let start = calendar.date(byAdding: .day, value: -wd, to: Date()) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - DayCell
// ─────────────────────────────────────────────────────────────────────────────

struct DayCell: View {
    let date:       Date
    let isToday:    Bool
    let isSelected: Bool
    let dotStatus:  DayStatus?

    private var dot: Color? {
        switch dotStatus {
        case .completed: return Color(hex: "1D9E75")
        case .today:     return Color.appCyan
        case .rest:      return Color(hex: "7F77DD")
        case .upcoming:  return Color(hex: "F5A623")
        default:         return nil
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if isSelected {
                    Circle().fill(Color.appCyan).frame(width: 34, height: 34)
                } else if isToday {
                    Circle().stroke(Color.appCyan, lineWidth: 1.5).frame(width: 34, height: 34)
                }
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 13, weight: isSelected || isToday ? .bold : .regular))
                    .foregroundStyle(
                        isSelected ? Color.appBG : (isToday ? Color.appCyan : Color.appT2)
                    )
            }
            Circle()
                .fill(dot ?? Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(height: 46)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - CalendarRowCard
// ─────────────────────────────────────────────────────────────────────────────

struct CalendarRowCard: View {
    let date:       Date
    let session:    CalendarSession?
    let isSelected: Bool
    @State private var showDetail = false   // ← NEW

    private var dayLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEE d"; return f.string(from: date)
    }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    private var accent: Color {
        switch session?.status {
        case .completed: return Color(hex: "1D9E75")
        case .rest:      return Color(hex: "7F77DD")
        case .upcoming:  return Color(hex: "F5A623")
        default:         return Color.appCyan
        }
    }

    private var statusLabel: String {
        switch session?.status {
        case .completed: return "Done"
        case .rest:      return "Rest"
        case .upcoming:  return "Planned"
        case .today:     return "Today"
        default:         return "—"
        }
    }

    var body: some View {
        Button { showDetail = true } label: {   // ← WRAPPED
            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(dayLabel.components(separatedBy: " ").first ?? "")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isToday ? Color.appCyan : Color.appT4)
                        .tracking(1)
                    Text(dayLabel.components(separatedBy: " ").last ?? "")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isToday ? Color.appCyan : Color.appT2)
                }
                .frame(width: 38)

                if let s = session {
                    Rectangle()
                        .fill(accent)
                        .frame(width: 3)
                        .clipShape(Capsule())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(s.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        if !s.duration.isEmpty {
                            HStack(spacing: 6) {
                                Text(s.duration)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.appT3)
                                if s.calories > 0 {
                                    Text("· ~\(s.calories) kcal")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.appT4)
                                }
                            }
                        }
                    }
                    Spacer()
                    Text(statusLabel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(accent.opacity(0.14), in: Capsule())
                } else {
                    Text("No session")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appT4)
                    Spacer()
                }
            }
            .padding(14)
            .background(isSelected ? Color.appBG3 : Color.appBG2,
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.appCyan.opacity(0.3) : Color.appHair, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {          // ← NEW sheet
            DayDetailSheet(date: date, session: session)
        }
    }
}
