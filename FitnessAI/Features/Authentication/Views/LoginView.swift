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

    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: 12) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "7F77DD"))
                        .frame(width: 72, height: 72)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                }
                Text("FitnessAI")
                    .font(.system(size: 28, weight: .medium))
                Text("Your personal AI fitness coach")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .background(Color(hex: "7F77DD").opacity(0.08))

            VStack(spacing: 12) {
                Spacer(minLength: 24)

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    viewModel.signInWithApple(result: result, appState: appState)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    Task {
                        await viewModel.signInWithBiometrics(appState: appState)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                            .font(.system(size: 18))
                        Text("Continue with Face ID")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "7F77DD").opacity(0.1))
                    .foregroundStyle(Color(hex: "534AB7"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "534AB7").opacity(0.3), lineWidth: 0.5)
                    )
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Text("Your data stays private and on-device.\nWe do not sell your information.")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .ignoresSafeArea(edges: .top)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .tint(Color(hex: "7F77DD"))
            }
        }
    }
}
