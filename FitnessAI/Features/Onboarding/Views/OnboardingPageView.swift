//
//  OnboardingPageView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "EEEDFE"))
                    .frame(width: 88, height: 88)
                Image(systemName: page.systemImage)
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "534AB7"))
            }
            .padding(.bottom, 28)

            // Title
            Text(page.title)
                .font(.system(size: 22, weight: .medium))
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)

            // Description
            Text(page.description)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 28)

            // Bullets
            VStack(alignment: .leading, spacing: 10) {
                ForEach(page.bullets, id: \.self) { bullet in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(hex: "1D9E75"))
                        Text(bullet)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}
