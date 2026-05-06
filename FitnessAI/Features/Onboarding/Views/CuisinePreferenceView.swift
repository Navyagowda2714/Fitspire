//
//  CuisinePreferenceView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 05/05/2026.
//


import SwiftUI

struct CuisinePreferenceView: View {
    @Binding var liked: [CuisinePreference]
    @Binding var disliked: [CuisinePreference]
    let onContinue: () -> Void

    private let regions = ["Asian", "Western", "Middle East & African", "Americas"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Cuisine preferences")
                        .font(.system(size: 28, weight: .medium))
                    Text("Tap once to love it, twice to avoid it, three times to clear.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)

                HStack(spacing: 16) {
                    Label("Love", systemImage: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "1D9E75"))
                    Label("Avoid", systemImage: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "D85A30"))
                    Label("Neutral", systemImage: "circle")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                ForEach(regions, id: \.self) { region in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(region)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 8
                        ) {
                            ForEach(
                                CuisinePreference.allCases.filter { $0.region == region },
                                id: \.self
                            ) { cuisine in
                                CuisineChip(
                                    cuisine: cuisine,
                                    state: chipState(for: cuisine)
                                ) {
                                    toggleCuisine(cuisine)
                                }
                            }
                        }
                    }
                }

                Button {
                    onContinue()
                } label: {
                    Text("Save preferences")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "7F77DD"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }

    private func chipState(for cuisine: CuisinePreference) -> CuisineChipState {
        if liked.contains(cuisine) { return .liked }
        if disliked.contains(cuisine) { return .disliked }
        return .neutral
    }

    private func toggleCuisine(_ cuisine: CuisinePreference) {
        if liked.contains(cuisine) {
            liked.removeAll { $0 == cuisine }
            disliked.append(cuisine)
        } else if disliked.contains(cuisine) {
            disliked.removeAll { $0 == cuisine }
        } else {
            liked.append(cuisine)
        }
    }
}

enum CuisineChipState {
    case neutral, liked, disliked
}

struct CuisineChip: View {
    let cuisine: CuisinePreference
    let state: CuisineChipState
    let onTap: () -> Void

    var bgColor: Color {
        switch state {
        case .neutral:  return Color(.systemGray6)
        case .liked:    return Color(hex: "E1F5EE")
        case .disliked: return Color(hex: "FAECE7")
        }
    }

    var textColor: Color {
        switch state {
        case .neutral:  return Color.secondary
        case .liked:    return Color(hex: "0F6E56")
        case .disliked: return Color(hex: "993C1D")
        }
    }

    var icon: String {
        switch state {
        case .neutral:  return ""
        case .liked:    return "♥ "
        case .disliked: return "✕ "
        }
    }

    var body: some View {
        Button(action: onTap) {
            Text(icon + cuisine.rawValue)
                .font(.system(size: 12, weight: state == .neutral ? .regular : .medium))
                .foregroundStyle(textColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(bgColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: state)
    }
}
