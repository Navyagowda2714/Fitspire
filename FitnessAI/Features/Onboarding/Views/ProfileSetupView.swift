//
//  ProfileSetupView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import SwiftUI
import SwiftData

struct ProfileSetupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading, spacing: 6) {
                    Text("Your profile")
                        .font(.system(size: 28, weight: .medium))
                    Text("Used to personalise your workout and nutrition plan.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)

                // Name
                InputField(label: "Full name", placeholder: "Alex Johnson", text: $viewModel.name)

                // Age and gender row
                HStack(spacing: 12) {
                    InputField(label: "Age", placeholder: "28", text: $viewModel.age)
                        .keyboardType(.numberPad)
                }

                // Height and weight row
                HStack(spacing: 12) {
                    InputField(label: "Height (cm)", placeholder: "178", text: $viewModel.heightCM)
                        .keyboardType(.decimalPad)
                    InputField(label: "Weight (kg)", placeholder: "75", text: $viewModel.weightKG)
                        .keyboardType(.decimalPad)
                }

                // Activity level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity level")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ActivityLevel.allCases, id: \.self) { level in
                                SelectionChip(
                                    title: level.rawValue,
                                    isSelected: viewModel.selectedActivity == level
                                ) {
                                    viewModel.selectedActivity = level
                                }
                            }
                        }
                    }
                }

                // Experience level
                VStack(alignment: .leading, spacing: 8) {
                    Text("Experience level")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            SelectionChip(
                                title: level.rawValue,
                                isSelected: viewModel.selectedExperience == level
                            ) {
                                viewModel.selectedExperience = level
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                // Injuries
                VStack(alignment: .leading, spacing: 8) {
                    Text("Injuries or limitations (optional)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    TextField("e.g. lower back pain, bad knee", text: $viewModel.injuries)
                        .inputFieldStyle()
                }

                Spacer(minLength: 20)

                Button {
                    viewModel.saveProfile(context: context, appState: appState)
                } label: {
                    Text("Save and continue")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(viewModel.isValid ? Color(hex: "7F77DD") : Color.secondary.opacity(0.2))
                        .foregroundStyle(viewModel.isValid ? .white : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!viewModel.isValid)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
}
