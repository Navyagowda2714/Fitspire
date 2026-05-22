//
//  QuestionnaireCompleteView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 07/05/2026.
//
//
//  QuestionnaireCompleteView.swift
//  FitnessAI
//
//  FIXES:
//  1. Added Color.appBG background + .preferredColorScheme(.dark) — was showing
//     white/system background in light mode, making text invisible
//  2. equipmentList now uses .displayName ("No Equipment") not .rawValue ("noEquipment")
//  3. personalisationRow text uses explicit .white instead of Color.primary
//     (Color.primary flips to black in light mode)
//  4. CTA background uses Color.appBG instead of .ultraThinMaterial
//     (ultraThinMaterial adapts to system = white in light mode)
//

import SwiftUI

struct QuestionnaireCompleteView: View {
    let plan: GeneratedWorkoutPlan?
    let response: QuestionnaireResponse
    let onContinue: () -> Void
    @State private var animate = false

    var body: some View {
        ZStack {
            // ── FIX 1: Explicit dark background — ultraThinMaterial and Color.primary
            //    both adapt to system appearance, causing white bg in light mode.
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // ── Success header ──────────────────────────────────────
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.appLime.opacity(0.12))
                                    .frame(width: 88, height: 88)
                                    .scaleEffect(animate ? 1.05 : 0.95)
                                    .animation(
                                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                        value: animate
                                    )
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(Color.appGood)
                            }

                            Text("Your plan is ready, \(response.name.components(separatedBy: " ").first ?? "")!")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)            // explicit — not Color.primary
                                .multilineTextAlignment(.center)

                            Text("Personalised specifically for you based on your goals, health profile, and available equipment.")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.appT3)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                        .padding(.bottom, 8)

                        if let plan = plan {

                            // ── Plan stats row ──────────────────────────────────
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Your programme")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.appT3)

                                HStack(spacing: 10) {
                                    PlanStat(value: "\(plan.weeklyFrequency)x", label: "Per week")
                                    PlanStat(value: "\(plan.timelineMonths) mo", label: "Timeline")
                                    PlanStat(
                                        value: "\(plan.workoutDays.filter { !$0.isRestDay }.count)",
                                        label: "Workouts"
                                    )
                                }
                            }

                            // ── Plan type pill ──────────────────────────────────
                            HStack(spacing: 10) {
                                Image(systemName: "house.fill").foregroundStyle(Color.appLime)
                                Text(plan.splitType)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.appLime)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.appLime.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            // ── Personalisation rows ────────────────────────────
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Personalised for you")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.appT3)

                                personalisationRow(
                                    icon: "person.fill",
                                    text: "Exercises chosen for \(response.computedFitnessLevel.rawValue) level"
                                )
                                personalisationRow(
                                    icon: "house.fill",
                                    // ── FIX 2: .displayName not .rawValue
                                    // .rawValue → "noEquipment"   (camelCase internal enum name)
                                    // .displayName → "No Equipment" (human-readable)
                                    text: "Uses only: \(equipmentList)"
                                )
                                if !response.conditions.contains(.none) {
                                    personalisationRow(
                                        icon: "shield.fill",
                                        text: "Avoids movements that aggravate \(conditionList)"
                                    )
                                }
                                personalisationRow(
                                    icon: "clock.fill",
                                    text: "\(response.sessionLength.minutes)-minute sessions, \(response.trainingDays.rawValue) days per week"
                                )
                                if response.parqResult.requiresMedicalClearance {
                                    personalisationRow(
                                        icon: "heart.fill",
                                        text: "Intensity reduced — medical clearance recommended"
                                    )
                                }
                            }
                            .padding(14)
                            .background(Color.appBG2)           // explicit dark card
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            // ── Safety notes ────────────────────────────────────
                            if !plan.safetyNotes.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Important notes")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Color.appT3)

                                    ForEach(plan.safetyNotes, id: \.self) { note in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color.appWarn)
                                                .padding(.top, 2)
                                            Text(note)
                                                .font(.system(size: 12))
                                                .foregroundStyle(Color.appT3)
                                                .lineSpacing(3)
                                        }
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                }

                // ── CTA bar ────────────────────────────────────────────────────
                VStack(spacing: 8) {
                    Button(action: onContinue) {
                        Text("Start my programme")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.appLime)
                            .foregroundStyle(.black)             // black text on lime
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.appLime.opacity(0.35), radius: 14, x: 0, y: 6)
                    }
                    Text("Your camera will be used for real-time form correction during workouts.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appT3)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .padding(.top, 12)
                // ── FIX 4: explicit appBG not .ultraThinMaterial
                // .ultraThinMaterial is white-ish in light mode — caused the
                // CTA area to look completely different from the rest of the screen.
                .background(Color.appBG)
            }
        }
        // ── FIX 1b: Force dark colour scheme regardless of system setting
        // Without this, any system-adaptive colour (Color.primary, materials) flips to
        // light mode colours, making content unreadable on the white background.
        .preferredColorScheme(.dark)
        .onAppear { animate = true }
    }

    // ── FIX 2: Use .displayName everywhere for human-readable equipment names
    private var equipmentList: String {
        let items = response.equipment.map { $0.displayName }   // was .rawValue
        if items.count <= 2 { return items.joined(separator: " + ") }
        return items.prefix(2).joined(separator: ", ") + " +\(items.count - 2) more"
    }

    private var conditionList: String {
        response.conditions
            .filter { $0 != .none }
            .map { $0.rawValue.lowercased() }
            .joined(separator: ", ")
    }

    // ── FIX 3: explicit .white — was Color.primary which flips in light mode
    private func personalisationRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.appLime)
                .frame(width: 16)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.white)        // was Color.primary → black in light mode
                .lineSpacing(3)
        }
    }
}

// MARK: - PlanStat tile
struct PlanStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.appLime)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.appT3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.appLime.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
