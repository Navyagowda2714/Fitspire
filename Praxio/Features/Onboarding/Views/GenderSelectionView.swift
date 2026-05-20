//
//  GenderSelectionView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 13/05/2026.
//

import SwiftUI

enum Gender: String, CaseIterable, Codable {
    case male = "Male"
    case female = "Female"
    case other = "Other"

    var icon: String {
        switch self {
        case .male:   return "figure.strengthtraining.traditional"
        case .female: return "figure.yoga"
        case .other:  return "figure.walk"
        }
    }

    var gradient: [Color] {
        switch self {
        case .male:   return [Color(hex: "1D9E75"), Color(hex: "0d7a5b")]
        case .female: return [Color(hex: "7F77DD"), Color(hex: "5a53b0")]
        case .other:  return [Color(hex: "D85A30"), Color(hex: "b03d1a")]
        }
    }
}

struct GenderSelectionView: View {
    @State private var selectedGender: Gender? = nil
    @State private var pulse = false
    @State private var navigateToBodyMap = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "0A0E1A").ignoresSafeArea()

                // Ambient glow behind selected card
                if let g = selectedGender {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [g.gradient[0].opacity(0.35), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 260
                            )
                        )
                        .frame(width: 520, height: 520)
                        .blur(radius: 60)
                        .animation(.easeInOut(duration: 0.5), value: selectedGender)
                }

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Welcome to")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))

                        HStack(spacing: 6) {
                            Text("FitnessAI")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Text("Coach")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "1D9E75"))
                        }

                        Text("Who are you training as?")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.45))
                            .padding(.top, 4)
                    }
                    .padding(.top, 60)

                    Spacer()

                    // Gender Cards
                    VStack(spacing: 16) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            GenderCard(
                                gender: gender,
                                isSelected: selectedGender == gender
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    selectedGender = gender
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Continue Button
                    NavigationLink(destination: BodyMapView(gender: selectedGender ?? .male)) {
                        HStack(spacing: 10) {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            selectedGender != nil
                                ? LinearGradient(
                                    colors: selectedGender!.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .animation(.easeInOut(duration: 0.25), value: selectedGender)
                    }
                    .disabled(selectedGender == nil)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Gender Card
struct GenderCard: View {
    let gender: Gender
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? LinearGradient(colors: gender.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.07), Color.white.opacity(0.07)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: gender.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(gender.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))

                    Text(subtitleFor(gender))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.35))
                }

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? gender.gradient[0] : Color.white.opacity(0.15),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(gender.gradient[0])
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(isSelected ? 0.08 : 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(
                                isSelected ? gender.gradient[0].opacity(0.7) : Color.white.opacity(0.08),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    func subtitleFor(_ g: Gender) -> String {
        switch g {
        case .male:   return "Tailored for male physiology"
        case .female: return "Tailored for female physiology"
        case .other:  return "Custom-fit for you"
        }
    }
}



#Preview {
    GenderSelectionView()
}
