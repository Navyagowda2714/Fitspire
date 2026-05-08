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
//  Created by Navyashree Byregowda on 07/05/2026.
//

import SwiftUI

struct QuestionnaireCompleteView: View {
    let plan: GeneratedWorkoutPlan?
    let response: QuestionnaireResponse
    let onContinue: () -> Void
    @State private var animate = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Success header
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
                        // Plan overview
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your programme")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.appT3)

                            HStack(spacing: 10) {
                                PlanStat(
                                    value: "\(plan.weeklyFrequency)x",
                                    label: "Per week"
                                )
                                PlanStat(
                                    value: "\(plan.timelineMonths) mo",
                                    label: "Timeline"
                                )
                                PlanStat(
                                    value: "\(plan.workoutDays.filter { !$0.isRestDay }.count)",
                                    label: "Workouts"
                                )
                            }
                        }

                        // Plan type
                        HStack(spacing: 10) {
                            Image(systemName: "house.fill")
                                .foregroundStyle(Color.appLime)
                            Text(plan.splitType)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.appLime)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.appLime.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // What was personalised
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
                        .background(Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Safety notes
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

            // CTA
            VStack(spacing: 8) {
                Button(action: onContinue) {
                    Text("Start my programme")
                        .font(.system(size: 17, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.appLime)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.appLime.opacity(0.3),
                                radius: 12, x: 0, y: 6)
                }
                Text("Your camera will be used for real-time form correction during workouts.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appT3)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .padding(.top, 8)
            .background(.ultraThinMaterial)
        }
        .onAppear { animate = true }
    }

    private var equipmentList: String {
        let items = response.equipment.map { $0.rawValue }
        if items.count <= 2 { return items.joined(separator: " + ") }
        return items.prefix(2).joined(separator: ", ") + " +\(items.count - 2) more"
    }

    private var conditionList: String {
        response.conditions
            .filter { $0 != .none }
            .map { $0.rawValue.lowercased() }
            .joined(separator: ", ")
    }

    private func personalisationRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.appLime)
                .frame(width: 16)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.primary)
                .lineSpacing(3)
        }
    }
}

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
