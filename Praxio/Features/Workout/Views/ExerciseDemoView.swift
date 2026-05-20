//
//  ExerciseDemoView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 05/05/2026.
//
//
//  ExerciseDemoView.swift
//  FitnessAI
//
//  ENHANCED: Added plank-specific injury risk section.
//  Each incorrect posture now shows what injury it can lead to.
//  The demo page was also restructured to show:
//    ✅ Correct posture points (green)
//    ❌ Common mistakes (red) + injury consequences
//

import SwiftUI

struct ExerciseDemoView: View {
    let exercise: ExerciseType
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DemoTab = .howTo

    enum DemoTab: String, CaseIterable {
        case howTo    = "How To"
        case targets  = "Targets"
        case mistakes = "Mistakes"
    }

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 0) {

                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back").font(.system(size: 16))
                        }
                        .foregroundStyle(Color.appT2).padding(.vertical, 8)
                    }
                    Spacer()
                    // Duration pill
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill").font(.system(size: 11))
                            .foregroundStyle(Color.appCyan)
                        Text(exercise.targetReps).font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appT2)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.appBG2).clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.appHair, lineWidth: 0.5))
                }
                .padding(.horizontal, 24).padding(.top, 56)

                // Animation card
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.appBG2).padding(.horizontal, 24)
                    VStack(spacing: 16) {
                        ExerciseAnimationView(exercise: exercise)
                            .frame(height: 180).padding(.horizontal, 40)

                        // Exercise title + difficulty badge inline
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.rawValue)
                                    .font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                Text(exercise.targetMuscles)
                                    .font(.system(size: 12)).foregroundStyle(Color.appT3)
                            }
                            Spacer()
                            Text(exercise.difficulty)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(difficultyColor)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(difficultyColor.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(16)
                }
                .frame(height: 280).padding(.top, 12)

                // Segmented tab bar
                HStack(spacing: 0) {
                    ForEach(DemoTab.allCases, id: \.rawValue) { tab in
                        Button { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } } label: {
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: selectedTab == tab ? .bold : .regular))
                                .foregroundStyle(selectedTab == tab ? Color.appCyan : Color.appT3)
                                .frame(maxWidth: .infinity).frame(height: 40)
                                .overlay(alignment: .bottom) {
                                    if selectedTab == tab {
                                        Rectangle().fill(Color.appCyan).frame(height: 2)
                                    }
                                }
                        }.buttonStyle(.plain)
                    }
                }
                .background(Color.appBG2)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.appHair).frame(height: 0.5)
                }
                .padding(.top, 16)

                // Tab content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch selectedTab {
                        case .howTo:    howToTab
                        case .targets:  targetsTab
                        case .mistakes: mistakesTab
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }
        }
        .overlay(alignment: .bottom) {
            Button(action: onStart) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                    Text("Start with live form check")
                }
                .font(.system(size: 16, weight: .bold)).foregroundStyle(.black)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(Color.appLime).clipShape(Capsule())
                .shadow(color: Color.appLime.opacity(0.4), radius: 14, y: 4)
            }
            .padding(.horizontal, 24).padding(.bottom, 32).padding(.top, 16)
            .background(LinearGradient(colors: [Color.appBG.opacity(0), Color.appBG],
                                        startPoint: .top, endPoint: .bottom))
        }
    }

    // MARK: - How To Tab (correct form = green)
    private var howToTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(label: "CORRECT FORM", color: Color.appGood,
                          icon: "checkmark.shield.fill")

            VStack(spacing: 8) {
                ForEach(Array(exercise.formPoints.enumerated()), id: \.offset) { i, point in
                    HStack(alignment: .top, spacing: 12) {
                        // Step number bubble (green)
                        ZStack {
                            Circle().fill(Color.appGood.opacity(0.15)).frame(width: 26, height: 26)
                            Text("\(i + 1)").font(.system(size: 12, weight: .black))
                                .foregroundStyle(Color.appGood)
                        }
                        Text(point)
                            .font(.system(size: 14)).foregroundStyle(Color.appT2).lineSpacing(3)
                        Spacer()
                    }
                    .padding(12).background(Color.appBG2)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.appGood.opacity(0.25), lineWidth: 1))
                }
            }

            // Plank-specific breathing tip
            if exercise == .plank {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lungs.fill").font(.system(size: 14))
                        .foregroundStyle(Color.appCyan)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Breathing cue").font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Inhale for 3 seconds, exhale for 3. Never hold your breath — it spikes blood pressure and causes early failure.")
                            .font(.system(size: 12)).foregroundStyle(Color.appT3).lineSpacing(3)
                    }
                }
                .padding(12).background(Color.appCyan.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appCyan.opacity(0.3), lineWidth: 1))
            }
        }
    }

    // MARK: - Targets Tab
    private var targetsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(label: "MUSCLES WORKED", color: Color.appLime, icon: "figure.strengthtraining.traditional")

            // Primary / secondary breakdown for plank
            if exercise == .plank {
                muscleGroup(label: "PRIMARY", muscles: ["Rectus Abdominis", "Transverse Abdominis"], color: Color.appLime)
                muscleGroup(label: "SECONDARY", muscles: ["Erector Spinae", "Anterior Deltoids", "Serratus Anterior"], color: Color.appCyan)
                muscleGroup(label: "STABILISERS", muscles: ["Glutes", "Quads", "Rhomboids"], color: Color.appT3)

                // What plank improves
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(label: "WHY DO PLANKS?", color: Color.appWarn, icon: "star.fill")

                    let benefits: [(String, String)] = [
                        ("Spinal stability", "Strengthens the muscles that protect your spine against compression"),
                        ("Posture improvement", "Activates deep core stabilisers that keep you upright all day"),
                        ("Injury prevention", "A strong isometric core reduces injury risk across ALL other exercises"),
                        ("Zero equipment", "No gym required — 30 seconds anywhere gives real results")
                    ]
                    ForEach(benefits, id: \.0) { title, desc in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "bolt.fill").font(.system(size: 12))
                                .foregroundStyle(Color.appWarn).padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                                Text(desc).font(.system(size: 12)).foregroundStyle(Color.appT3).lineSpacing(2)
                            }
                        }
                        .padding(10).background(Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else {
                // Generic target display for other exercises
                HStack(spacing: 8) {
                    ForEach(exercise.targetMuscles.components(separatedBy: " · "), id: \.self) { muscle in
                        Text(muscle).font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appLime)
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(Color.appLime.opacity(0.12)).clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.appLime.opacity(0.3), lineWidth: 1))
                    }
                }
            }

            // Stats row
            HStack(spacing: 10) {
                InfoPill(icon: "repeat",    text: exercise.targetReps)
                InfoPill(icon: "timer",     text: exercise.restTime)
                InfoPill(icon: "star.fill", text: exercise.difficulty)
            }
        }
    }

    // MARK: - Mistakes Tab (incorrect form = red + injury risk)
    private var mistakesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(label: "COMMON MISTAKES", color: Color.appMove, icon: "exclamationmark.triangle.fill")

            Text("Incorrect form isn't just inefficient — these mistakes can lead to real injury. Watch for the RED joints in your live form check.")
                .font(.system(size: 13)).foregroundStyle(Color.appT3).lineSpacing(3)

            VStack(spacing: 12) {
                ForEach(plankMistakesWithInjury, id: \.mistake) { item in
                    plankMistakeCard(item)
                }
            }

            // Danger zone notice
            HStack(spacing: 10) {
                Image(systemName: "eye.fill").font(.system(size: 14))
                    .foregroundStyle(Color.appMove)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Live form monitoring").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                    Text("During your plank, the skeleton overlay goes RED on any joint that violates form. You'll also hear an audio cue and see a banner alert so you can self-correct immediately.")
                        .font(.system(size: 12)).foregroundStyle(Color.appT3).lineSpacing(3)
                }
            }
            .padding(12).background(Color.appMove.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appMove.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - Plank mistake + injury data
    struct PlankMistakeInfo {
        let mistake: String
        let whyItHappens: String
        let injuryRisk: String
        let injurySeverity: String     // "Low", "Moderate", "High"
        let correction: String
    }

    private var plankMistakesWithInjury: [PlankMistakeInfo] {
        if exercise == .plank {
            return [
                PlankMistakeInfo(
                    mistake: "Hips sagging toward the floor",
                    whyItHappens: "Core fatigue causes the lower back to hyperextend under load",
                    injuryRisk: "Lumbar disc herniation, chronic lower back strain, SI joint irritation",
                    injurySeverity: "High",
                    correction: "Squeeze your glutes and abs simultaneously. Drop to your knees if you can't maintain a neutral spine."
                ),
                PlankMistakeInfo(
                    mistake: "Hips raised too high (piking)",
                    whyItHappens: "Avoiding core work by shifting load to the shoulders",
                    injuryRisk: "Reduced core activation, anterior shoulder impingement, wrist strain",
                    injurySeverity: "Moderate",
                    correction: "Lower your hips until your body is a straight plank from heel to head."
                ),
                PlankMistakeInfo(
                    mistake: "Neck extended or looking forward",
                    whyItHappens: "Trying to watch a screen or mirror instead of maintaining neutral spine",
                    injuryRisk: "Cervical spine compression, upper trapezius overuse, headaches",
                    injurySeverity: "Moderate",
                    correction: "Tuck your chin slightly and keep your gaze at a spot on the floor between your elbows."
                ),
                PlankMistakeInfo(
                    mistake: "Holding your breath",
                    whyItHappens: "Bracing incorrectly — confusing breath-holding with core activation",
                    injuryRisk: "Sharp blood pressure spike, dizziness, fainting risk",
                    injurySeverity: "High",
                    correction: "Practice 3-second inhale through nose, 3-second exhale through mouth while maintaining tension."
                ),
                PlankMistakeInfo(
                    mistake: "Elbows too far forward of shoulders",
                    whyItHappens: "Drifting forward as fatigue sets in",
                    injuryRisk: "Rotator cuff stress, elbow joint pain, shoulder impingement",
                    injurySeverity: "Low",
                    correction: "Stack elbows directly below your shoulders. Use a mirror or camera to verify."
                )
            ]
        } else {
            // Generic fallback for non-plank exercises
            return exercise.commonMistakes.map { mistake in
                PlankMistakeInfo(
                    mistake: mistake,
                    whyItHappens: "Loss of focus or muscle fatigue",
                    injuryRisk: "Increased stress on surrounding joints",
                    injurySeverity: "Moderate",
                    correction: "Reduce load or reps and focus on form quality."
                )
            }
        }
    }

    @ViewBuilder
    private func plankMistakeCard(_ item: PlankMistakeInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 18))
                    .foregroundStyle(Color.appMove)
                Text(item.mistake).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                Spacer()
                // Severity badge
                Text(item.injurySeverity).font(.system(size: 10, weight: .bold))
                    .foregroundStyle(severityColor(item.injurySeverity))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(severityColor(item.injurySeverity).opacity(0.15))
                    .clipShape(Capsule())
            }

            Divider().background(Color.appHair)

            // Why it happens
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill").font(.system(size: 11))
                    .foregroundStyle(Color.appT3).padding(.top, 1)
                Text(item.whyItHappens).font(.system(size: 12)).foregroundStyle(Color.appT3).lineSpacing(2)
            }

            // Injury risk (highlighted)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "bandage.fill").font(.system(size: 11))
                    .foregroundStyle(Color.appMove).padding(.top, 1)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Injury risk").font(.system(size: 10, weight: .bold)).kerning(0.5)
                        .foregroundStyle(Color.appMove)
                    Text(item.injuryRisk).font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(red: 1, green: 0.6, blue: 0.6)).lineSpacing(2)
                }
            }
            .padding(8).background(Color.appMove.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Correction (green)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 11))
                    .foregroundStyle(Color.appGood).padding(.top, 1)
                Text(item.correction).font(.system(size: 12)).foregroundStyle(Color.appGood.opacity(0.9)).lineSpacing(2)
            }
        }
        .padding(14).background(Color.appBG2)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color.appMove.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Helpers

    private func sectionHeader(label: String, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(color)
            Text(label).font(.system(size: 11, weight: .bold)).kerning(1.4).foregroundStyle(color)
        }
    }

    private func muscleGroup(label: String, muscles: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 10, weight: .bold)).kerning(1.2).foregroundStyle(color)
            HStack(spacing: 8) {
                ForEach(muscles, id: \.self) { muscle in
                    Text(muscle).font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(color.opacity(0.12)).clipShape(Capsule())
                        .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
                }
            }
        }
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity {
        case "High":     return Color.appMove
        case "Moderate": return Color.appWarn
        default:         return Color.appT3
        }
    }

    private var difficultyColor: Color {
        switch exercise.difficulty {
        case "Beginner":     return Color(hex: "1D9E75")
        case "Intermediate": return Color(hex: "F5A623")
        default:             return Color(hex: "D85A30")
        }
    }
}

// MARK: - InfoPill (reused from before)
struct InfoPill: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(Color.appLime)
            Text(text).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.appT2)
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(Color.appBG2).clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appHair, lineWidth: 0.5))
    }
}
