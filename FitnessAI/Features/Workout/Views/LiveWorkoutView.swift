//
//  LiveWorkoutView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//


import SwiftUI
import HealthKit

struct LiveWorkoutView: View {
    let exercise: ExerciseType
    @StateObject private var viewModel  = LivePoseViewModel()
    @StateObject private var sessionMgr = WorkoutSessionManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showEndConfirm   = false
    @State private var workoutStartTime = Date()
    @State private var showSavedAlert   = false

    var body: some View {
        ZStack {
            CameraPreviewView(cameraManager: viewModel.cameraManager)
                .ignoresSafeArea()

            if let body = viewModel.detectedBody {
                GeometryReader { geo in
                    SkeletonOverlayView(
                        detectedBody: body,
                        size: geo.size
                    )
                }
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                topBar
                Spacer()
                alertsSection
                statsRow
                endButton
            }
        }
        .onAppear {
            workoutStartTime = Date()
            viewModel.startSession(exercise: exercise)
        }
        .onDisappear {
            viewModel.endSession()
        }
        .alert("End workout?", isPresented: $showEndConfirm) {
            Button("End and save", role: .destructive) {
                Task { await endAndSave() }
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text("Form score: \(viewModel.currentFormScore)/100. Save to Apple Health?")
        }
        .alert("Workout saved", isPresented: $showSavedAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your workout has been saved to Apple Health.")
        }
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Text(viewModel.formattedTime)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // Camera flip button
            Button {
                viewModel.cameraManager.switchCamera()
            } label: {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: "1D9E75"))
                    .frame(width: 8, height: 8)
                Text("Live")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
    }

    private var alertsSection: some View {
        Group {
            if !viewModel.activeAlerts.isEmpty {
                VStack(spacing: 6) {
                    ForEach(viewModel.activeAlerts.prefix(2)) { alert in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName:
                                alert.severity == .danger
                                ? "exclamationmark.triangle.fill"
                                : "exclamationmark.circle.fill"
                            )
                            .font(.system(size: 14))
                            .foregroundStyle(
                                alert.severity == .danger
                                ? Color(hex: "D85A30")
                                : Color(hex: "BA7517")
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(alert.message)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white)
                                Text(alert.correction)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private var statsRow: some View {
        VStack(spacing: 8) {
            // Rep progress bar
            VStack(spacing: 4) {
                HStack {
                    Text("\(viewModel.repCount) / \(exercise.targetRepCount) reps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(viewModel.repPhase == .down ? "↓ Down" : "↑ Up")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "1D9E75"))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "1D9E75"))
                            .frame(
                                width: geo.size.width * viewModel.repProgress,
                                height: 6
                            )
                            .animation(.easeOut(duration: 0.1), value: viewModel.repProgress)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)

            HStack(spacing: 8) {
                workoutStatPill(label: "Reps",  value: "\(viewModel.repCount)")
                workoutStatPill(
                    label: "Form",
                    value: "\(viewModel.currentFormScore)",
                    color: formScoreColor
                )
                workoutStatPill(label: "Time",  value: viewModel.formattedTime)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private var endButton: some View {
        Button {
            showEndConfirm = true
        } label: {
            Text("End workout")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "D85A30").opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }

    // MARK: - Helpers

    private func workoutStatPill(
        label: String,
        value: String,
        color: Color = Color.primary
    ) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func endAndSave() async {
        viewModel.endSession()
        let estimatedCalories = Double(viewModel.elapsedSeconds / 60) * 7.0
        let saved = await sessionMgr.saveWorkout(
            activityType: sessionMgr.activityType(for: exercise),
            startDate: workoutStartTime,
            endDate: Date(),
            calories: estimatedCalories,
            formScore: viewModel.currentFormScore
        )
        if saved {
            showSavedAlert = true
        } else {
            dismiss()
        }
    }

    var formScoreColor: Color {
        switch viewModel.currentFormScore {
        case 80...100: return Color(hex: "1D9E75")
        case 60...79:  return Color(hex: "7F77DD")
        default:       return Color(hex: "D85A30")
        }
    }
}
