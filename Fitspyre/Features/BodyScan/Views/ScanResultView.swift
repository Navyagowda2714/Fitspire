//
//  ScanResultView.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 01/05/2026.
//


import SwiftUI

struct ScanResultView: View {
    let viewModel: BodyScanViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Scan complete")
                    .font(.system(size: 28, weight: .medium))
                Text("Your baseline posture analysis.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 20)

            // Scores
            HStack(spacing: 10) {
                ScoreCard(label: "Posture",  value: Int(viewModel.postureScore))
                ScoreCard(label: "Symmetry", value: Int(viewModel.symmetryScore))
                ScoreCard(label: "Mobility", value: Int(viewModel.mobilityScore))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Training intensity
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "7F77DD"))
                Text("Recommended intensity: \(viewModel.recommendedIntensity)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "534AB7"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: "EEEDFE"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Notes
            VStack(alignment: .leading, spacing: 10) {
                Text("Scan notes")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                ForEach(viewModel.scanNotes, id: \.self) { note in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "7F77DD"))
                            .padding(.top, 1)
                        Text(note)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Disclaimer
            Text("Scan results are estimates based on visible landmarks. Not a medical assessment.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button(action: onContinue) {
                Text("Continue to goal selection")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "7F77DD"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

struct ScoreCard: View {
    let label: String
    let value: Int

    var color: Color {
        switch value {
        case 80...100: return Color(hex: "1D9E75")
        case 60...79:  return Color(hex: "7F77DD")
        default:       return Color(hex: "D85A30")
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
