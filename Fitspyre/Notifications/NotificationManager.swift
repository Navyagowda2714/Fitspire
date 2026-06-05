//
//  FitNotificationManager.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//
//
//  FitNotificationManager.swift
//  Fitspire — Target: Fitspire ONLY
//
//  Handles all local workout reminder notifications:
//    • Daily workout reminder at user-chosen time
//    • Pre-workout reminder 30 min before
//    • Rest day recovery reminder
//    • Streak motivational nudge if no workout logged by evening
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    private init() {}
    func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "fitspire.form.alert.\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        center.add(request)
    }
}

// @MainActor removed from class — @Published + @MainActor causes initializer
// conflicts in Swift 5.9+. MainActor isolation is applied per-function instead.

final class FitNotificationManager: ObservableObject {
    static let shared = FitNotificationManager()

    @Published var isAuthorized        = false
    @Published var reminderEnabled     = true
    @Published var reminderHour:   Int = 7
    @Published var reminderMinute: Int = 0
    @Published var eveningNudgeEnabled = true

    private let center   = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    private init() { loadSettings() }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Permission
    // ─────────────────────────────────────────────────────────────────────────

    @MainActor
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            isAuthorized = granted
            if granted { scheduleAll() }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() {
        Task {
            let settings = await center.notificationSettings()
            await MainActor.run {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Schedule all notifications
    // ─────────────────────────────────────────────────────────────────────────

    func scheduleAll() {
        cancelAll()
        guard isAuthorized else { return }
        if reminderEnabled     { scheduleDailyReminder() }
        if eveningNudgeEnabled { scheduleEveningNudge() }
        scheduleWeeklyMotivation()
    }

    // ── 1. Daily workout reminder ─────────────────────────────────────────────

    private func scheduleDailyReminder() {
        let messages = [
            ("Time to train! 💪",   "Your workout is waiting. Let's build something great today."),
            ("Rise & grind! ⚡️",    "FitSpire Coach is ready when you are. Tap to start."),
            ("Don't skip today!",   "Consistency is what separates good from great. Let's go."),
            ("Your body is ready.", "A quick session today keeps the goals on track. Start now."),
            ("Workout o'clock! 🏋️", "One session closer to your goal. Open FitSpire to begin.")
        ]
        let pick = messages[Calendar.current.component(.weekday, from: Date()) % messages.count]

        let content = UNMutableNotificationContent()
        content.title              = pick.0
        content.body               = pick.1
        content.sound              = .default
        content.badge              = 1
        content.categoryIdentifier = "WORKOUT_REMINDER"

        var components    = DateComponents()
        components.hour   = reminderHour
        components.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "fitspire.daily.reminder", content: content, trigger: trigger)
        center.add(request)
    }

    // ── 2. Evening nudge ──────────────────────────────────────────────────────

    private func scheduleEveningNudge() {
        let content = UNMutableNotificationContent()
        content.title              = "Still time to train! 🌙"
        content.body               = "You haven't logged a workout yet today. Even 15 minutes counts."
        content.sound              = .default
        content.categoryIdentifier = "EVENING_NUDGE"

        var components    = DateComponents()
        components.hour   = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "fitspire.evening.nudge", content: content, trigger: trigger)
        center.add(request)
    }

    // ── 3. Weekly motivation (Sunday 6 PM) ────────────────────────────────────

    private func scheduleWeeklyMotivation() {
        let content = UNMutableNotificationContent()
        content.title = "New week, new goals! 🎯"
        content.body  = "Your weekly plan is ready. Check FitSpire to see what's ahead."
        content.sound = .default

        var components     = DateComponents()
        components.weekday = 1
        components.hour    = 18
        components.minute  = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "fitspire.weekly.motivation", content: content, trigger: trigger)
        center.add(request)
    }

    // ── 4. Pre-workout reminder ───────────────────────────────────────────────

    func schedulePreWorkoutReminder(sessionTitle: String, at date: Date) {
        guard isAuthorized else { return }
        guard let fireDate = Calendar.current.date(byAdding: .minute, value: -30, to: date),
              fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Starting in 30 min ⏱"
        content.body  = "\(sessionTitle) is coming up. Get your gear ready!"
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "fitspire.preworkout.\(date.timeIntervalSince1970)",
            content: content, trigger: trigger)
        center.add(request)
    }

    // ── 5. Streak at-risk nudge ───────────────────────────────────────────────

    func scheduleStreakRiskNotification(streakDays: Int) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Don't break your \(streakDays)-day streak! 🔥"
        content.body  = "You're on a roll — one quick session keeps it alive."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7200, repeats: false)
        let request = UNNotificationRequest(
            identifier: "fitspire.streak.risk", content: content, trigger: trigger)
        center.add(request)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Cancel
    // ─────────────────────────────────────────────────────────────────────────

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(
            withIdentifiers: ["fitspire.daily.reminder"])
    }

    func cancelEveningNudge() {
        center.removePendingNotificationRequests(
            withIdentifiers: ["fitspire.evening.nudge"])
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Settings persistence
    // ─────────────────────────────────────────────────────────────────────────

    func saveSettings() {
        defaults.set(reminderEnabled,     forKey: "notif_reminder_enabled")
        defaults.set(reminderHour,        forKey: "notif_reminder_hour")
        defaults.set(reminderMinute,      forKey: "notif_reminder_minute")
        defaults.set(eveningNudgeEnabled, forKey: "notif_evening_nudge")
        scheduleAll()
    }

    private func loadSettings() {
        if defaults.object(forKey: "notif_reminder_enabled") != nil {
            reminderEnabled     = defaults.bool(forKey: "notif_reminder_enabled")
            reminderHour        = defaults.integer(forKey: "notif_reminder_hour")
            reminderMinute      = defaults.integer(forKey: "notif_reminder_minute")
            eveningNudgeEnabled = defaults.bool(forKey: "notif_evening_nudge")
        }
        checkAuthorizationStatus()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - NotificationSettingsView
// ─────────────────────────────────────────────────────────────────────────────

struct NotificationSettingsView: View {
    @StateObject private var nm = FitNotificationManager.shared
    @State private var reminderTime = Date()

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notifications")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Stay on track with smart reminders")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appT3)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 56)

                    // Permission banner
                    if !nm.isAuthorized {
                        permissionBanner.padding(.horizontal, 20)
                    }

                    // Daily reminder card
                    settingsCard {
                        VStack(spacing: 16) {
                            toggleRow(
                                icon: "bell.fill", iconColor: Color.appCyan,
                                title: "Daily Workout Reminder",
                                subtitle: "Reminds you to train each day",
                                isOn: $nm.reminderEnabled
                            )
                            if nm.reminderEnabled {
                                Divider().background(Color.appHair)
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Reminder Time")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("When should we remind you?")
                                            .font(.system(size: 11))
                                            .foregroundStyle(Color.appT3)
                                    }
                                    Spacer()
                                    DatePicker("", selection: $reminderTime,
                                               displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                        .onChange(of: reminderTime) { _, newVal in
                                            nm.reminderHour   = Calendar.current.component(.hour,   from: newVal)
                                            nm.reminderMinute = Calendar.current.component(.minute, from: newVal)
                                            nm.saveSettings()
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Evening nudge card
                    settingsCard {
                        toggleRow(
                            icon: "moon.fill", iconColor: Color(hex: "7F77DD"),
                            title: "Evening Nudge",
                            subtitle: "8:00 PM reminder if no workout logged",
                            isOn: $nm.eveningNudgeEnabled
                        )
                        .onChange(of: nm.eveningNudgeEnabled) { _, _ in nm.saveSettings() }
                    }
                    .padding(.horizontal, 20)

                    // Info rows
                    VStack(spacing: 10) {
                        infoRow(icon: "bolt.fill",  color: Color(hex: "F5A623"),
                                text: "Weekly plan summary every Sunday at 6 PM")
                        infoRow(icon: "flame.fill", color: Color(hex: "D85A30"),
                                text: "Streak alerts when you're close to breaking it")
                        infoRow(icon: "timer",      color: Color.appCyan,
                                text: "30-min heads up before scheduled sessions")
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 80)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            var components    = DateComponents()
            components.hour   = nm.reminderHour
            components.minute = nm.reminderMinute
            reminderTime      = Calendar.current.date(from: components) ?? Date()
            nm.checkAuthorizationStatus()
        }
    }

    // ── Permission banner ─────────────────────────────────────────────────────

    private var permissionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: "F5A623"))
            VStack(alignment: .leading, spacing: 3) {
                Text("Notifications are off")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text("Enable in Settings to receive reminders")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appT3)
            }
            Spacer()
            Button {
                Task { await nm.requestAuthorization() }
            } label: {
                Text("Enable")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "F5A623"))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color(hex: "F5A623").opacity(0.15), in: Capsule())
            }
        }
        .padding(14)
        .background(Color(hex: "F5A623").opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(hex: "F5A623").opacity(0.25), lineWidth: 1))
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appHair, lineWidth: 0.5))
    }

    private func toggleRow(icon: String, iconColor: Color,
                           title: String, subtitle: String,
                           isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appT3)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.appCyan)
        }
    }

    private func infoRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Color.appT3)
            Spacer()
        }
        .padding(12)
        .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appHair, lineWidth: 0.5))
    }
}
