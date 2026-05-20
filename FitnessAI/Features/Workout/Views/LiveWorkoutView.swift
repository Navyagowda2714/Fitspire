//
//  LiveWorkoutView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

//
//  LiveWorkoutView.swift
//  FitnessAI
//
//  ENHANCED for Plank:
//  1. SkeletonOverlayView now receives activeAlerts → joints turn RED when bad
//  2. Prominent banner alert appears when form is incorrect (with injury risk text)
//  3. Plank shows hold-time timer instead of rep count
//  4. Form badge shows CORRECT (green) / INCORRECT (red) at a glance
//

import SwiftUI
import HealthKit

struct LiveWorkoutView: View {
    let exercise: ExerciseType

    @StateObject private var viewModel  = LivePoseViewModel()
    @StateObject private var sessionMgr = WorkoutSessionManager()
    @Environment(\.dismiss) private var dismiss

    @State private var workoutStartTime = Date()
    @State private var showEndConfirm   = false
    @State private var showSavedAlert   = false
    @State private var currentView      = 0
    @State private var bannerVisible    = false
    @State private var lastAlertMessage = ""

    // Ghost race
    @AppStorage("ghostReps_squat")         private var ghostSquat: Int = 0
    @AppStorage("ghostReps_plank")         private var ghostPlank: Int = 0
    @AppStorage("ghostReps_pushUp")        private var ghostPushUp: Int = 0
    @AppStorage("ghostReps_shoulderPress") private var ghostShoulder: Int = 0
    @AppStorage("ghostReps_deadlift")      private var ghostDeadlift: Int = 0

    private var ghostReps: Int {
        switch exercise {
        case .squat:         return ghostSquat
        case .plank:         return ghostPlank
        case .pushUp:        return ghostPushUp
        case .shoulderPress: return ghostShoulder
        case .deadlift:      return ghostDeadlift
        case .lunge, .gluteBridge, .mountainClimber, .highKnees: return 0
        case .general:       return 0
        }
    }
    private func saveGhostReps(_ reps: Int) {
        switch exercise {
        case .squat:         ghostSquat     = reps
        case .plank:         ghostPlank     = reps
        case .pushUp:        ghostPushUp    = reps
        case .shoulderPress: ghostShoulder  = reps
        case .deadlift:      ghostDeadlift  = reps
        case .lunge, .gluteBridge, .mountainClimber, .highKnees: break
        case .general:       break
        }
    }
    private var ghostFraction: Double {
        let target = Double(max(exercise.targetRepCount, 1))
        return min(Double(ghostReps) / target, 1.0)
    }
    private var youFraction: Double { min(viewModel.repProgress, 1.0) }
    private var isAheadOfGhost: Bool { viewModel.repCount >= ghostReps || ghostReps == 0 }

    // MARK: - Body
    var body: some View {
        ZStack {
            CameraPreviewView(cameraManager: viewModel.cameraManager).ignoresSafeArea()

            // ── Skeleton overlay — NOW passes activeAlerts for red/green joints ──
            if let body = viewModel.detectedBody {
                GeometryReader { geo in
                    SkeletonOverlayView(
                        detectedBody: body,
                        size: geo.size,
                        activeAlerts: viewModel.activeAlerts   // ← CHANGED
                    )
                }.ignoresSafeArea()
            }

            if currentView != 2 {
                Color.black.opacity(0.45).ignoresSafeArea()
            }

            VStack(spacing: 0) {
                topBar

                // ── FORM ALERT BANNER (appears when form goes red) ──
                formAlertBanner

                Spacer()
                raceProgressBar
                swipeableContent
                viewDots
                bottomControls
            }
        }
        .onAppear {
            workoutStartTime = Date()
            viewModel.startSession(exercise: exercise)
        }
        .onDisappear { viewModel.endSession() }
        // Watch activeAlerts to trigger the banner
        .onChange(of: viewModel.activeAlerts) { _, alerts in
            if let first = alerts.first {
                lastAlertMessage = first.message
                withAnimation(.spring(response: 0.3)) { bannerVisible = true }
                // Auto-dismiss after 3 seconds if form improves
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if viewModel.activeAlerts.isEmpty {
                        withAnimation { bannerVisible = false }
                    }
                }
            } else {
                withAnimation(.easeOut(duration: 0.4)) { bannerVisible = false }
            }
        }
        .alert("End workout?", isPresented: $showEndConfirm) {
            Button("End and save", role: .destructive) { Task { await endAndSave() } }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Form score: \(viewModel.currentFormScore)/100. Save to Apple Health?")
        }
        .alert("Workout saved", isPresented: $showSavedAlert) {
            Button("OK") { dismiss() }
        } message: {
            let beatGhost = viewModel.repCount > ghostReps && ghostReps > 0
            Text(beatGhost
                ? "New personal best! +\(viewModel.repCount - ghostReps) reps ahead of your ghost. 🔥"
                : "Your workout has been saved to Apple Health.")
        }
    }

    // MARK: - Form alert banner (NEW)
    @ViewBuilder
    private var formAlertBanner: some View {
        if bannerVisible, let alert = viewModel.activeAlerts.first {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: alert.severity == .danger
                          ? "exclamationmark.triangle.fill"
                          : "exclamationmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(alert.severity == .danger ? Color.appMove : Color.appWarn)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(alert.message)
                            .font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        Text(alert.correction)
                            .font(.system(size: 12)).foregroundStyle(Color.white.opacity(0.85)).lineSpacing(2)

                        // Injury risk inline (NEW)
                        if alert.severity == .danger {
                            HStack(spacing: 6) {
                                Image(systemName: "bandage.fill").font(.system(size: 10))
                                    .foregroundStyle(Color(red: 1, green: 0.6, blue: 0.6))
                                Text(alert.injuryRisk)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color(red: 1, green: 0.6, blue: 0.6))
                            }
                            .padding(.top, 2)
                        }
                    }
                    Spacer()
                    Button { withAnimation { bannerVisible = false } } label: {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                .padding(14)
                .background(alert.severity == .danger
                            ? Color.appMove.opacity(0.85)
                            : Color.appWarn.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.3), radius: 12, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.rawValue)
                    .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                Text(viewModel.formattedTime)
                    .font(.system(size: 13)).foregroundStyle(Color.appT3)
            }
            Spacer()

            // Form status badge (NEW — green CORRECT / red INCORRECT)
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.activeAlerts.isEmpty ? Color.appGood : Color.appMove)
                    .frame(width: 8, height: 8)
                Text(viewModel.activeAlerts.isEmpty ? "Correct" : "Fix Form")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(viewModel.activeAlerts.isEmpty ? Color.appGood : Color.appMove)
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(.ultraThinMaterial).clipShape(Capsule())

            Button { viewModel.cameraManager.switchCamera() } label: {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 18)).foregroundStyle(.white.opacity(0.8))
                    .padding(10).background(.ultraThinMaterial).clipShape(Circle())
            }
        }
        .padding(.horizontal, 20).padding(.top, 56)
    }

    // MARK: - Race progress bar
    private var raceProgressBar: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.15)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(viewModel.activeAlerts.isEmpty ? Color.appLime : Color.appMove)  // ← turns red when bad form
                        .frame(width: geo.size.width * CGFloat(youFraction), height: 6)
                        .animation(.easeOut(duration: 0.15), value: youFraction)
                    if ghostReps > 0 {
                        Circle().fill(Color.appMove).frame(width: 12, height: 12)
                            .offset(x: geo.size.width * CGFloat(ghostFraction) - 6, y: -3)
                    }
                    Circle().fill(viewModel.activeAlerts.isEmpty ? Color.appLime : Color.appMove)
                        .frame(width: 14, height: 14)
                        .shadow(color: Color.appLime.opacity(0.6), radius: 4)
                        .offset(x: geo.size.width * CGFloat(youFraction) - 7, y: -4)
                        .animation(.easeOut(duration: 0.15), value: youFraction)
                }
            }.frame(height: 14)
            if ghostReps > 0 {
                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(Color.appMove).frame(width: 7, height: 7)
                        Text("GHOST \(ghostReps)").font(.system(size: 9, weight: .bold)).foregroundStyle(Color.appMove)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text("YOU \(viewModel.repCount)").font(.system(size: 9, weight: .bold)).foregroundStyle(Color.appLime)
                        Circle().fill(Color.appLime).frame(width: 7, height: 7)
                    }
                }
            }
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
    }

    // MARK: - 3 swipeable content views
    private var swipeableContent: some View {
        TabView(selection: $currentView) {
            repCountView.tag(0)
            formView.tag(1)
            cameraOnlyView.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 260)
    }

    // View 1 — Rep count / plank hold timer
    private var repCountView: some View {
        VStack(spacing: 0) {
            if exercise == .plank {
                // PLANK: show elapsed hold time prominently
                Text("HOLD TIME")
                    .font(.system(size: 12, weight: .bold)).kerning(1.4)
                    .foregroundStyle(viewModel.activeAlerts.isEmpty ? Color.appLime : Color.appMove)
                    .padding(.bottom, 4)

                Text(viewModel.formattedTime)
                    .font(.system(size: 80, weight: .heavy, design: .monospaced))
                    .foregroundStyle(viewModel.activeAlerts.isEmpty ? Color.appLime : Color.appMove)
                    .monospacedDigit()
                    .animation(.easeInOut(duration: 0.2), value: viewModel.activeAlerts.isEmpty)

                Text(viewModel.activeAlerts.isEmpty ? "Form looks good — keep holding!" : "Fix your form!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(viewModel.activeAlerts.isEmpty ? Color.appT3 : Color.appMove)
                    .padding(.top, 8)

            } else {
                Text(viewModel.repPhase == .down ? "↓  DOWN" : "↑  UP")
                    .font(.system(size: 12, weight: .bold)).kerning(1.4)
                    .foregroundStyle(viewModel.repPhase == .down ? Color.appStand : Color.appLime)
                    .padding(.bottom, 4)

                Text("\(viewModel.repCount)")
                    .font(.system(size: 96, weight: .heavy))
                    .foregroundStyle(Color.appLime).monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.repCount)

                Text("of \(exercise.targetRepCount) reps")
                    .font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.appT3).padding(.top, 2)

                HStack(spacing: 5) {
                    ForEach(0..<exercise.targetRepCount, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(i < viewModel.repCount ? Color.appLime : Color.white.opacity(0.15))
                            .frame(height: 5)
                    }
                }.padding(.horizontal, 24).padding(.top, 14)
            }
        }
    }

    // View 2 — Form score + coach alerts (with injury risk)
    private var formView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.12), lineWidth: 8).frame(width: 90, height: 90)
                Circle().trim(from: 0, to: CGFloat(viewModel.currentFormScore) / 100)
                    .stroke(formScoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 90, height: 90).rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.4), value: viewModel.currentFormScore)
                VStack(spacing: 2) {
                    Text("\(viewModel.currentFormScore)")
                        .font(.system(size: 28, weight: .heavy)).foregroundStyle(formScoreColor)
                    Text("FORM").font(.system(size: 9, weight: .bold)).kerning(0.8).foregroundStyle(Color.appT3)
                }
            }

            if viewModel.activeAlerts.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.appGood)
                    Text("Form looks good — keep it up")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(Color.appT2)
                }
                .padding(12).background(Color.appGood.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 6) {
                    ForEach(viewModel.activeAlerts.prefix(2)) { alert in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: alert.severity == .danger
                                      ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(alert.severity == .danger ? Color.appMove : Color.appWarn)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(alert.message)
                                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                                    Text(alert.correction)
                                        .font(.system(size: 11)).foregroundStyle(Color.appT2)
                                }
                            }
                            // Injury risk shown inline (NEW)
                            if alert.severity == .danger {
                                HStack(spacing: 6) {
                                    Image(systemName: "bandage.fill").font(.system(size: 10))
                                    Text("Risk: \(alert.injuryRisk)")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundStyle(Color(red: 1, green: 0.55, blue: 0.55))
                                .padding(.leading, 24)
                            }
                        }
                        .padding(12).background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }.padding(.horizontal, 20)
            }
        }
    }

    // View 3 — Pure camera
    private var cameraOnlyView: some View {
        VStack {
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.activeAlerts.isEmpty ? Color.appGood : Color.appMove)
                    .frame(width: 7, height: 7)
                Text(viewModel.activeAlerts.isEmpty ? "FORM OK — HOLD STEADY" : "FORM ISSUE — CHECK SKELETON")
                    .font(.system(size: 10, weight: .bold)).kerning(1.0).foregroundStyle(.white)
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(.ultraThinMaterial).clipShape(Capsule())
            .padding(.bottom, 12)
        }
    }

    // MARK: - View dots
    private var viewDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(i == currentView ? Color.appLime : Color.white.opacity(0.25))
                    .frame(width: i == currentView ? 18 : 6, height: 4)
                    .animation(.easeInOut(duration: 0.2), value: currentView)
            }
        }.padding(.bottom, 12)
    }

    // MARK: - Bottom controls
    private var bottomControls: some View {
        HStack(spacing: 10) {
            Button { showEndConfirm = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill").font(.system(size: 14))
                    Text("End")
                }
                .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                .frame(width: 90, height: 52)
                .background(Color.white.opacity(0.12)).clipShape(Capsule())
                .overlay(Capsule().stroke(Color.appMove.opacity(0.5), lineWidth: 0.5))
            }
            if ghostReps > 0 {
                HStack(spacing: 6) {
                    Image(systemName: isAheadOfGhost ? "arrow.up" : "arrow.down")
                        .font(.system(size: 13, weight: .bold))
                    let diff = abs(viewModel.repCount - ghostReps)
                    Text(isAheadOfGhost ? "+\(diff) ahead" : "\(diff) behind")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(isAheadOfGhost ? Color.appLime : Color.appMove)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background((isAheadOfGhost ? Color.appLime : Color.appMove).opacity(0.12))
                .clipShape(Capsule())
            } else {
                Text("First session — set your baseline!")
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(Color.appT3)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Color.appBG2).clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 40)
    }

    // MARK: - Save logic
    private func endAndSave() async {
        viewModel.endSession()
        saveGhostReps(viewModel.repCount)
        let estimatedCalories = Double(viewModel.elapsedSeconds / 60) * 7.0
        let saved = await sessionMgr.saveWorkout(
            activityType: sessionMgr.activityType(for: exercise),
            startDate: workoutStartTime,
            endDate: Date(),
            calories: estimatedCalories,
            formScore: viewModel.currentFormScore
        )
        if saved { showSavedAlert = true } else { dismiss() }
    }

    private var formScoreColor: Color {
        switch viewModel.currentFormScore {
        case 80...100: return Color.appGood
        case 60...79:  return Color.appLime
        default:       return Color.appMove
        }
    }
}
