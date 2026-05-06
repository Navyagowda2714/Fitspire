//
//  LoginView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//
import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 0) {
                heroSection
                bottomCard
            }
            .ignoresSafeArea(edges: .top)
        }
        .overlay {
            if viewModel.isLoading {
                loadingOverlay
            }
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            Color(hex: "0D0D0D")
                .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "7F77DD").opacity(0.6),
                            Color(hex: "7F77DD").opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: -100, y: animateGradient ? -80 : -120)
                .blur(radius: 60)
                .animation(
                    .easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: animateGradient
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "1D9E75").opacity(0.4),
                            Color(hex: "1D9E75").opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: 140, y: animateGradient ? 120 : 80)
                .blur(radius: 60)
                .animation(
                    .easeInOut(duration: 5).repeatForever(autoreverses: true),
                    value: animateGradient
                )
        }
        .onAppear { animateGradient = true }
    }

    // MARK: - Hero section

    private var heroSection: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "7F77DD"), Color(hex: "534AB7")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(
                        color: Color(hex: "7F77DD").opacity(0.5),
                        radius: 20, x: 0, y: 10
                    )

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 38))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 20)

            Text("FitnessAI")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
                .padding(.bottom, 8)

            Text("Your personal AI fitness coach")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 12)

            HStack(spacing: 8) {
                featurePill(icon: "camera.viewfinder", text: "Pose detection")
                featurePill(icon: "heart.fill",        text: "HealthKit")
                featurePill(icon: "applewatch",        text: "Watch alerts")
            }

            Spacer()
        }
        .frame(height: 420)
    }

    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "7F77DD"))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }

    // MARK: - Bottom card

    private var bottomCard: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.2))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 28)

            VStack(alignment: .leading, spacing: 6) {
                Text("Get started")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                Text("Sign in to begin your fitness journey")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, 28)

            VStack(spacing: 12) {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    viewModel.signInWithApple(result: result, appState: appState)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                Button {
                    Task {
                        await viewModel.signInWithBiometrics(appState: appState)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                            .font(.system(size: 20))
                        Text("Continue with Face ID")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                }

                // Debug bypass — remove before App Store submission
                #if DEBUG
                Button {
                    appState.markAuthenticated()
                } label: {
                    Text("Skip sign in (debug only)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.25))
                        .padding(.top, 4)
                }
                #endif
            }
            .padding(.horizontal, 28)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "D85A30"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
            }

            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 0.5)
                Text("Secure · Private · On-device")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
                    .fixedSize()
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 0.5)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)

            Text("Your data stays on-device. FitnessAI never sells or shares your personal information.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 36)
                .padding(.top, 14)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(hex: "141414"))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Loading overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                Text("Signing in...")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(28)
            .background(Color(hex: "1A1A1A"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
