//
//  IntroView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 16/05/2026.
//



import SwiftUI

struct IntroView: View {
    var onFinished: () -> Void

    @State private var currentPage: Int = 0
    @State private var dragOffset:  CGFloat = 0

    private let pages: [IntroPage] = IntroPage.all

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation(.spring(response: 0.4)) {
                                currentPage = pages.count - 1
                            }
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.appT3)
                        .padding(.horizontal, 24)
                        .padding(.top, 56)
                    } else {
                        Color.clear.frame(height: 56).padding(.top, 0)
                    }
                }
                .frame(height: 72)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        IntroPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.45, dampingFraction: 0.82), value: currentPage)

                // Dots + CTA
                VStack(spacing: 28) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.appCyan : Color.appHair2)
                                .frame(width: i == currentPage ? 24 : 7, height: 7)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // CTA button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4)) {
                                currentPage += 1
                            }
                        } else {
                            onFinished()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Text(currentPage < pages.count - 1 ? "Next" : "Let's Go!")
                                .font(.system(size: 17, weight: .bold))
                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "bolt.fill")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            LinearGradient(
                                colors: [Color.appCyan, Color.appLime],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color.appCyan.opacity(0.35), radius: 16, y: 6)
                    }
                    .padding(.horizontal, 28)
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Single intro page
struct IntroPageView: View {
    let page: IntroPage
    @State private var appear = false

    var body: some View {
        VStack(spacing: 0) {
            // Icon illustration
            ZStack {
                // Gradient orb background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.color.opacity(0.22), Color.clear],
                            center: .center, startRadius: 0, endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(appear ? 1 : 0.5)

                // Icon circles (layered)
                ZStack {
                    Circle()
                        .fill(page.color.opacity(0.12))
                        .frame(width: 140, height: 140)
                    Circle()
                        .fill(page.color.opacity(0.18))
                        .frame(width: 100, height: 100)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.appBG2, Color.appBG3],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: page.color.opacity(0.3), radius: 16)

                    Image(systemName: page.icon)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(page.color)
                        .shadow(color: page.color.opacity(0.5), radius: 8)
                }
                .scaleEffect(appear ? 1 : 0.6)
            }
            .padding(.bottom, 40)

            // Title
            Text(page.title)
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)
                .padding(.bottom, 16)

            // Subtitle
            Text(page.subtitle)
                .font(.system(size: 16))
                .foregroundStyle(Color.appT3)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 36)
                .offset(y: appear ? 0 : 16)
                .opacity(appear ? 1 : 0)

            // Feature bullets
            VStack(alignment: .leading, spacing: 10) {
                ForEach(page.bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(page.color)
                            .padding(.top, 1)
                        Text(bullet)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appT2)
                            .lineSpacing(3)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 12)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appear = true
            }
        }
        .onDisappear { appear = false }
    }
}

// MARK: - Data model
struct IntroPage {
    let icon:     String
    let title:    String
    let subtitle: String
    let bullets:  [String]
    let color:    Color

    static let all: [IntroPage] = [
        IntroPage(
            icon: "bolt.fill",
            title: "Welcome to FitnessAI",
            subtitle: "Your intelligent personal trainer that watches your form, builds your plan, and keeps you on track — right from your phone.",
            bullets: [
                "100% personalised to your goals and body",
                "No gym required — works anywhere",
                "Adapts as you improve"
            ],
            color: Color.appCyan
        ),
        IntroPage(
            icon: "camera.viewfinder",
            title: "AI Form Correction",
            subtitle: "Your phone camera becomes a personal coach. FitnessAI uses Vision AI to track your body in real time and catch mistakes before they cause injury.",
            bullets: [
                "Skeleton overlay shows every joint position",
                "Green = correct · Red = needs fixing",
                "Instant alerts with injury risk warnings"
            ],
            color: Color.appLime
        ),
        IntroPage(
            icon: "chart.bar.fill",
            title: "Built Around You",
            subtitle: "Answer a quick 9-step questionnaire and FitnessAI generates a fully personalised workout plan — matched to your fitness level, equipment, and schedule.",
            bullets: [
                "Safety screening included (PAR-Q)",
                "Adapts for injuries and health conditions",
                "Generates in seconds using AI"
            ],
            color: Color(hex: "7F77DD")
        ),
        IntroPage(
            icon: "figure.core.training",
            title: "How It Works",
            subtitle: "Getting started takes about 5 minutes. Here's what to expect before you begin your first session.",
            bullets: [
                "Step 1: Tell us your name, age, and goal",
                "Step 2: Answer a quick health & safety check",
                "Step 3: Select your equipment and training days",
                "Step 4: Get your personalised plan instantly"
            ],
            color: Color.appWarn
        )
    ]
}
