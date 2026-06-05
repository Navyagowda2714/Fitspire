//  OnboardingView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

//  OnboardingView.swift — FitnessAI
//
//  OnboardingView.swift
//  FitnessAI
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    private let totalPages = 2

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    SplashPageView().tag(0)
                    FeaturesPageView().tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? Color.appCyan : Color.white.opacity(0.25))
                            .frame(width: i == currentPage ? 20 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 28)

                // Get Started button
                Button {
                    if currentPage < totalPages - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        appState.markOnboardingComplete()
                    }
                } label: {
                    HStack {
                        Text("Get Started")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.appCyan)
                    }
                    .padding(.horizontal, 28)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.appCyan, lineWidth: 1.5)
                    )
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Page 1: Splash with neon runner
struct SplashPageView: View {
    @State private var glowPulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Neon runner illustration
            ZStack {
                // Ground glow
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.appCyan.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 220, height: 40)
                    .offset(y: 140)
                    .blur(radius: 12)

                // Outer atmospheric glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appCyan.opacity(glowPulse ? 0.18 : 0.10), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                               value: glowPulse)

                // Mid glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appCyan.opacity(glowPulse ? 0.28 : 0.18), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true),
                               value: glowPulse)

                // Runner figure — layered for neon glow effect
                Image(systemName: "figure.run")
                    .font(.system(size: 140, weight: .thin))
                    .foregroundStyle(Color.clear)
                    .overlay(
                        Image(systemName: "figure.run")
                            .font(.system(size: 140, weight: .thin))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.appCyan, Color(hex: "0070FF")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.appCyan.opacity(0.9), radius: 20)
                            .shadow(color: Color.appCyan.opacity(0.5), radius: 40)
                            .shadow(color: Color.appCyan.opacity(0.3), radius: 60)
                    )
                    .scaleEffect(x: -1, y: 1)  // mirror to face right

                // Joint dot highlights
                ForEach(runnerJoints, id: \.id) { joint in
                    Circle()
                        .fill(Color.appCyan)
                        .frame(width: joint.size, height: joint.size)
                        .shadow(color: Color.appCyan, radius: 4)
                        .offset(x: joint.x, y: joint.y)
                        .opacity(glowPulse ? 1.0 : 0.7)
                        .animation(
                            .easeInOut(duration: 1.5 + joint.delay)
                            .repeatForever(autoreverses: true),
                            value: glowPulse
                        )
                }
            }
            .frame(height: 320)
            .onAppear { glowPulse = true }

            Spacer().frame(height: 32)

            // Title
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    Text("Fitspire ")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Coach")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color.appCyan)
                        .shadow(color: Color.appCyan.opacity(0.6), radius: 8)
                }

                Text("Your AI Form Correction and Analysis")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appT3)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // Approximate joint dot positions on the runner figure
    private var runnerJoints: [JointDot] {
        [
            JointDot(id: 0, x: 0,   y: -90, size: 7, delay: 0.0),   // head
            JointDot(id: 1, x: 0,   y: -55, size: 6, delay: 0.2),   // neck
            JointDot(id: 2, x: -22, y: -30, size: 5, delay: 0.4),   // left shoulder
            JointDot(id: 3, x: 22,  y: -30, size: 5, delay: 0.3),   // right shoulder
            JointDot(id: 4, x: -30, y: 5,   size: 5, delay: 0.5),   // left elbow
            JointDot(id: 5, x: 30,  y: 5,   size: 5, delay: 0.1),   // right elbow
            JointDot(id: 6, x: 0,   y: 10,  size: 6, delay: 0.6),   // hip center
            JointDot(id: 7, x: -15, y: 45,  size: 5, delay: 0.2),   // left knee
            JointDot(id: 8, x: 20,  y: 30,  size: 5, delay: 0.4),   // right knee
            JointDot(id: 9, x: -20, y: 85,  size: 5, delay: 0.3),   // left ankle
            JointDot(id: 10, x: 25, y: 70,  size: 5, delay: 0.5),   // right ankle
        ]
    }
}

private struct JointDot: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let delay: Double
}

// MARK: - Page 2: Features
struct FeaturesPageView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Your Progress",
                    subtitle: "See your form score improve over time"
                )
                FeatureCard(
                    icon: "shield.checkered",
                    title: "Prevent Injuries",
                    subtitle: "Catch bad form before it causes problems"
                )
                FeatureCard(
                    icon: "camera.viewfinder",
                    title: "Real-Time Form Analysis",
                    subtitle: "AI checks your form on every rep"
                )
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 18) {
            // Icon box
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appCyan.opacity(0.12))
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.appCyan.opacity(0.3), lineWidth: 1)
                    )
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(Color.appCyan)
                    .shadow(color: Color.appCyan.opacity(0.6), radius: 6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appT3)
            }
            Spacer()
        }
    }
}
