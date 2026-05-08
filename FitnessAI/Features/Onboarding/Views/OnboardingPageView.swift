//
//  OnboardingPageView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//
//  OnboardingPageView.swift — FitnessAI
import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(Color.appLime)
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.appLime.opacity(0.4), radius: 20, y: 8)
                Image(systemName: page.systemImage).font(.system(size: 40)).foregroundStyle(.black)
            }.padding(.bottom, 28)

            Text(page.title)
                .font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
                .multilineTextAlignment(.center).padding(.bottom, 10)
            Text(page.description)
                .font(.system(size: 15)).foregroundStyle(Color.appT3)
                .multilineTextAlignment(.center).padding(.horizontal, 32).padding(.bottom, 28).lineSpacing(3)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(page.bullets, id: \.self) { bullet in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16)).foregroundStyle(Color.appLime)
                        Text(bullet).font(.system(size: 14)).foregroundStyle(Color.appT2)
                    }
                }
            }.padding(.horizontal, 40)
            Spacer()
        }
    }
}
