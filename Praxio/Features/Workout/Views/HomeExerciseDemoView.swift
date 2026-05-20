//
//  HomeExerciseDemoView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 17/05/2026.
//


import SwiftUI

struct HomeExerciseDemoView: View {
    let exercise: HomeExercise
    var onStartCamera: (() -> Void)?
    var onStartTimer:  (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: Tab = .howTo

    // Gender from onboarding (stored in UserDefaults via QuestionnaireResponse)
    private var isFemale: Bool {
        let g = UserDefaults.standard.string(forKey: "userGender") ?? "Female"
        return g.lowercased() != "male"
    }

    enum Tab: String, CaseIterable {
        case howTo    = "How To"
        case targets  = "Targets"
        case mistakes = "Mistakes"
    }

    var hasPoseDetection: Bool { exercise.poseType != nil }

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Top bar ─────────────────────────────────────────────────
                HStack {
                    Button { dismiss() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold))
                            Text("Back").font(.system(size: 15))
                        }.foregroundStyle(Color.appT2)
                    }
                    Spacer()
                    if hasPoseDetection {
                        HStack(spacing: 5) {
                            Image(systemName: "brain.head.profile").font(.system(size: 11))
                            Text("AI Form Check").font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color.appCyan)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.appCyan.opacity(0.12)).clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.appCyan.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24).padding(.top, 56).padding(.bottom, 8)

                // ── Animation card ────────────────────────────────────────────
                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(Color.appBG2)

                    VStack(spacing: 12) {
                        // Smart animation: Lottie → ExerciseAnimationView → GenericIcon
                        ExerciseDemoAnimation(exercise: exercise)
                            .frame(height: 170).padding(.horizontal, 16)

                        // Title row
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name)
                                    .font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                                Text(exercise.targetMuscles)
                                    .font(.system(size: 12)).foregroundStyle(Color.appT3)
                            }
                            Spacer()
                            Text(exercise.difficulty.rawValue)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color(hex: exercise.difficulty.color))
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Color(hex: exercise.difficulty.color).opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(16)
                }
                .frame(height: 270)
                .padding(.horizontal, 24)
                .padding(.bottom, 4)

                // ── Stats pills ──────────────────────────────────────────────
                ScrollView(Axis.Set.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        statPill(icon: "repeat",     text: "\(exercise.sets) sets")
                        statPill(icon: "timer",      text: exercise.repsOrTime)
                        statPill(icon: "clock",      text: "\(exercise.restSeconds)s rest")
                        statPill(icon: "flame.fill", text: "~\(exercise.calories) kcal/set")
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 8)

                // ── Tab bar ──────────────────────────────────────────────────
                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.rawValue) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                        } label: {
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

                // ── Tab content ──────────────────────────────────────────────
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch selectedTab {
                        case .howTo:    howToTab
                        case .targets:  targetsTab
                        case .mistakes: mistakesTab
                        }
                    }
                    .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 140)
                }
            }
        }
        // ── CTA bar ─────────────────────────────────────────────────────────
        .overlay(alignment: .bottom) {
            VStack(spacing: 10) {
                if hasPoseDetection {
                    Button { onStartCamera?() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                            Text("Start with AI Form Check")
                        }
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(.black)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(Color.appLime).clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.appLime.opacity(0.4), radius: 14, y: 4)
                    }
                    Button { onStartTimer?() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "timer").font(.system(size: 13))
                            Text("Start without camera").font(.system(size: 14))
                        }
                        .foregroundStyle(Color.appT2)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Color.appBG2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appHair2, lineWidth: 1))
                    }
                } else {
                    Button { onStartTimer?() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                            Text("Start Guided Workout")
                        }
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(.black)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(Color.appLime).clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.appLime.opacity(0.4), radius: 14, y: 4)
                    }
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 36).padding(.top, 12)
            .background(LinearGradient(colors: [Color.appBG.opacity(0), Color.appBG],
                                        startPoint: .top, endPoint: .bottom))
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - How To tab (unchanged)
    private var howToTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            tabHeader("STEP-BY-STEP FORM", color: Color.appGood, icon: "checkmark.shield.fill")

            VStack(spacing: 8) {
                ForEach(Array(exercise.formCues.enumerated()), id: \.offset) { i, cue in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle().fill(Color.appGood.opacity(0.15)).frame(width: 28, height: 28)
                            Text("\(i+1)").font(.system(size: 13, weight: .black))
                                .foregroundStyle(Color.appGood)
                        }
                        Text(cue).font(.system(size: 14)).foregroundStyle(Color.appT2)
                            .lineSpacing(3).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12).background(Color.appBG2)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appGood.opacity(0.2), lineWidth: 1))
                }
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill").font(.system(size: 13))
                    .foregroundStyle(Color.appWarn).padding(.top, 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Coach tip").font(.system(size: 12, weight: .bold)).foregroundStyle(Color.appWarn)
                    Text(exercise.tips).font(.system(size: 13)).foregroundStyle(Color.appT2).lineSpacing(3)
                }
            }
            .padding(12).background(Color.appWarn.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appWarn.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - Targets tab — NOW with MuscleMapView
    private var targetsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            tabHeader("MUSCLES TARGETED", color: Color.appLime, icon: "figure.strengthtraining.traditional")

            // ── Gender-aware muscle map ─────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(isFemale ? "Female body" : "Male body")
                        .font(.system(size: 12)).foregroundStyle(Color.appT3)
                    Spacer()
                    Text("Tap Front / Back to switch views")
                        .font(.system(size: 10)).foregroundStyle(Color.appT4)
                }

                AnatomicalMuscleMapView(exercise: exercise, isFemale: isFemale)
                    .padding(14).background(Color.appBG2)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // ── Primary muscles ─────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 8) {
                Text("PRIMARY").font(.system(size: 10, weight: .bold)).kerning(1.2)
                    .foregroundStyle(Color.appLime)
                ScrollView(Axis.Set.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                            Text(muscle).font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.appLime)
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(Color.appLime.opacity(0.12)).clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.appLime.opacity(0.3), lineWidth: 1))
                        }
                    }
                }
            }

            // ── Session stats ───────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 8) {
                tabHeader("SESSION PLAN", color: Color.appCyan, icon: "calendar")
                HStack(spacing: 10) {
                    sessionStat(value: "\(exercise.sets)", label: "Sets")
                    sessionStat(value: exercise.repsOrTime, label: "Reps / Hold")
                    sessionStat(value: "\(exercise.restSeconds)s", label: "Rest")
                }
            }

            // No equipment banner
            if exercise.isBodyweight {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.appGood)
                    Text("No equipment required — do this anywhere")
                        .font(.system(size: 13)).foregroundStyle(Color.appT2)
                }
                .padding(12).background(Color.appGood.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appGood.opacity(0.2), lineWidth: 1))
            }
        }
    }

    // MARK: - Mistakes tab (unchanged)
    private var mistakesTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            tabHeader("COMMON MISTAKES", color: Color.appMove, icon: "exclamationmark.triangle.fill")

            Text("Each mistake below has a real injury risk. Red joints in the AI form check flag these live.")
                .font(.system(size: 13)).foregroundStyle(Color.appT3).lineSpacing(3)

            VStack(spacing: 12) {
                ForEach(exercise.mistakes) { item in
                    mistakeCard(item)
                }
            }
        }
    }

    @ViewBuilder
    private func mistakeCard(_ item: HomeExercise.MistakeInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "xmark.circle.fill").font(.system(size: 17))
                    .foregroundStyle(Color.appMove)
                Text(item.mistake).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                Spacer()
                Text(item.severity).font(.system(size: 10, weight: .bold))
                    .foregroundStyle(severityColor(item.severity))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(severityColor(item.severity).opacity(0.15)).clipShape(Capsule())
            }
            Divider().background(Color.appHair)
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle").font(.system(size: 11))
                    .foregroundStyle(Color.appT3).padding(.top, 1)
                Text(item.whyItHappens).font(.system(size: 12)).foregroundStyle(Color.appT3).lineSpacing(2)
            }
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
            .padding(8).background(Color.appMove.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 8))
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 11))
                    .foregroundStyle(Color.appGood).padding(.top, 1)
                Text(item.fix).font(.system(size: 12)).foregroundStyle(Color.appGood.opacity(0.9)).lineSpacing(2)
            }
        }
        .padding(14).background(Color.appBG2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appMove.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Helpers
    private func tabHeader(_ text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(color)
            Text(text).font(.system(size: 11, weight: .bold)).kerning(1.4).foregroundStyle(color)
        }
    }

    private func statPill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(Color.appLime)
            Text(text).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.appT2)
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(Color.appBG2).clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appHair, lineWidth: 0.5))
    }

    private func sessionStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .bold)).foregroundStyle(Color.appCyan)
            Text(label).font(.system(size: 11)).foregroundStyle(Color.appT3)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Color.appCyan.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func severityColor(_ s: String) -> Color {
        switch s {
        case "High": return Color.appMove
        case "Moderate": return Color.appWarn
        default: return Color.appT3
        }
    }
}

// MARK: - Inline animation selector (routes to ExerciseAnimationSwiftUI or video)
// Defined here so HomeExerciseDemoView compiles even if ExerciseAnimationSwiftUI.swift
// has not yet been added to the Xcode project.

struct ExerciseDemoAnimation: View {
    let exercise: HomeExercise
    @State private var hasVideo = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color(hex: "0B1520"), Color(hex: "0E1B2A")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            if hasVideo, let name = exercise.videoFileName {
                ExerciseVideoPlayerView(videoName: name)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                // ExerciseMotionView is in ExerciseAnimationSwiftUI.swift
                // If that file is added to the project, full animations play.
                // Otherwise this safe fallback shows the exercise icon.
                ZStack {
                    Circle()
                        .fill(Color.appLime.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: exercise.icon)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.appLime, Color.appCyan],
                                           startPoint: .top, endPoint: .bottom)
                        )
                }
            }
        }
        .onAppear {
            if let name = exercise.videoFileName,
               Bundle.main.url(forResource: name, withExtension: "mp4") != nil {
                hasVideo = true
            }
        }
    }
}
