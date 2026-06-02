//
//  LiveWorkoutView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

import SwiftUI

struct LiveWorkoutView: View {
    let exercise: HomeExercise   // or your HomeExercise type
    @StateObject private var vm = RepCounterViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. Camera feed
                CameraPreviewLayer(session: vm.session)
                    .ignoresSafeArea()

                // 2. Skeleton overlay
                PoseOverlayView(joints: vm.jointPoints, size: geo.size)
                    .ignoresSafeArea()

                // 3. UI overlay
                VStack {
                    // Top bar
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text(exercise.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)

                    Spacer()

                    // Form alert banner
                    if vm.isInBadForm {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text(vm.formFeedback)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.85))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(), value: vm.isInBadForm)
                    }

                    // Bottom HUD
                    HStack(spacing: 0) {
                        statBox(label: "REPS", value: "\(vm.repCount)")
                        Divider().frame(height: 40).background(Color.white.opacity(0.2))
                        statBox(label: "FORM", value: "\(vm.formScore)%",
                                color: vm.formScore >= 80 ? Color(hex: "#00E5FF") : .orange)
                        Divider().frame(height: 40).background(Color.white.opacity(0.2))
                        statBox(label: "TARGET", value: "\(exercise.reps)")
                    }
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding()
                }
            }
        }
        .onAppear { vm.configure(exercise: exercise.name) }
        .onDisappear { vm.stop() }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func statBox(label: String, value: String,
                         color: Color = .white) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
