//
//  LiveWorkoutView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//


import SwiftUI

struct LiveWorkoutView: View {
    let exercise: ExerciseType
    @StateObject private var viewModel   = LivePoseViewModel()
    @StateObject private var sessionMgr  = WorkoutSessionManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showEndConfirm    = false
    @State private var workoutStartTime  = Date()
    @State private var showSavedAlert    = false

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
                // Top bar
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

                Spacer()

                // Form alerts
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

                // Stats row
                HStack(spacing: 8) {
                    StatPill(label: "Reps",  value: "\(viewModel.repCount)")
                    StatPill(
                        label: "Form",
                        value: "\(viewModel.currentFormScore)",
                        color: formScoreColor
                    )
                    StatPill(label: "Time",  value: viewModel.formattedTime)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // End button
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
            Button("Continue", role: .cancel) { }
        } message: {
            Text("Your form score was \(viewModel.currentFormScore)/100. Save to Apple Health?")
        }
        .alert("Workout saved", isPresented: $showSavedAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your workout has been saved to Apple Health.")
        }
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
