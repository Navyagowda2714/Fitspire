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
//  Created by Navyashree Byregowda on 05/05/2026.
//

import SwiftUI

struct ExerciseDemoView: View {
    let exercise: ExerciseType
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss

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
                            Text("Back")
                                .font(.system(size: 16))
                        }
                        .foregroundStyle(Color.appT2)
                        .padding(.vertical, 8)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)

                // Animation area
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.appBG2)
                        .padding(.horizontal, 24)
                    VStack(spacing: 20) {
                        ExerciseAnimationView(exercise: exercise)
                            .frame(height: 200)
                            .padding(.horizontal, 40)
                        Text("Watch the demonstration")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appT3)
                    }
                }
                .frame(height: 280)
                .padding(.top, 12)

                // Scrollable info
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.rawValue)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                            Text(exercise.targetMuscles)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.appT3)
                        }
                        .padding(.top, 20)

                        HStack(spacing: 10) {
                            InfoPill(icon: "repeat",    text: exercise.targetReps)
                            InfoPill(icon: "timer",     text: exercise.restTime)
                            InfoPill(icon: "star.fill", text: exercise.difficulty)
                        }

                        formPointsSection
                        mistakesSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }
        }
        .overlay(alignment: .bottom) {
            Button(action: onStart) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                    Text("Start with form check")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.appLime)
                .clipShape(Capsule())
                .shadow(color: Color.appLime.opacity(0.4), radius: 14, y: 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 16)
            .background(
                LinearGradient(
                    colors: [Color.appBG.opacity(0), Color.appBG],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    // MARK: - Form cues
    private var formPointsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FORM CUES")
                .font(.system(size: 11, weight: .bold))
                .kerning(1.4)
                .foregroundStyle(Color.appLime)

            VStack(spacing: 8) {
                ForEach(exercise.formPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.appGood)
                        Text(point)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appT2)
                            .lineSpacing(2)
                    }
                }
            }
            .padding(14)
            .background(Color.appBG2)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.appHair, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Common mistakes
    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMMON MISTAKES")
                .font(.system(size: 11, weight: .bold))
                .kerning(1.4)
                .foregroundStyle(Color.appMove)

            VStack(spacing: 8) {
                ForEach(exercise.commonMistakes, id: \.self) { mistake in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.appMove)
                        Text(mistake)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appT2)
                            .lineSpacing(2)
                    }
                }
            }
            .padding(14)
            .background(Color.appBG2)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.appHair, lineWidth: 0.5)
            )
        }
    }
}

// MARK: - InfoPill
struct InfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.appLime)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.appT2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.appBG2)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appHair, lineWidth: 0.5))
    }
}
