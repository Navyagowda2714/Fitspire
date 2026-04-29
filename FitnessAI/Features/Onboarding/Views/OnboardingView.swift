OnboardingPage.swift//
//  OnboardingView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {

            // Pages
            TabView(selection: $viewModel.currentPage) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentPage)

            // Dots
            HStack(spacing: 6) {
                ForEach(0..<viewModel.pages.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            i == viewModel.currentPage
                            ? Color(hex: "7F77DD")
                            : Color(hex: "7F77DD").opacity(0.2)
                        )
                        .frame(
                            width: i == viewModel.currentPage ? 20 : 6,
                            height: 6
                        )
                        .animation(.easeInOut, value: viewModel.currentPage)
                }
            }
            .padding(.bottom, 24)

            // Buttons
            VStack(spacing: 10) {
                Button {
                    if viewModel.isLastPage {
                        appState.markOnboardingComplete()
                    } else {
                        viewModel.nextPage()
                    }
                } label: {
                    Text(viewModel.isLastPage ? "Get started" : "Next")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "7F77DD"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if !viewModel.isLastPage {
                    Button {
                        appState.markOnboardingComplete()
                    } label: {
                        Text("Skip intro")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 44)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}
