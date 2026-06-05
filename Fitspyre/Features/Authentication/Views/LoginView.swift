//
//  LoginView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//
//  LoginView.swift — FitnessAI

//
//  LoginView.swift
//  FitnessAI
//

//
//  LoginView.swift
//  FitnessAI
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            Circle()
                .fill(RadialGradient(colors: [Color.appCyan.opacity(glowPulse ? 0.20 : 0.12), Color.clear],
                                     center: .center, startRadius: 0, endRadius: 250))
                .frame(width: 500, height: 500).offset(y: -180).blur(radius: 60)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: glowPulse)
                .onAppear { glowPulse = true }

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 24).fill(Color.appCyan.opacity(0.15))
                        .frame(width: 88, height: 88)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.appCyan.opacity(0.4), lineWidth: 1))
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 38)).foregroundStyle(Color.appCyan)
                        .shadow(color: Color.appCyan.opacity(0.8), radius: 12)
                }.padding(.bottom, 24)

                // FIX: iOS 26 Text interpolation instead of Text + Text
                Text("Fitspire \(Text("Coach").foregroundStyle(Color.appCyan))")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: Color.appCyan.opacity(0.4), radius: 8)
                    .padding(.bottom, 8)

                Text("Your AI Form Correction and Analysis")
                    .font(.system(size: 15)).foregroundStyle(Color.appT3)
                    .multilineTextAlignment(.center).padding(.bottom, 48)

                Spacer()

                VStack(spacing: 12) {
                    SignInWithAppleButton(.continue) { r in r.requestedScopes = [.fullName, .email] }
                    onCompletion: { result in viewModel.signInWithApple(result: result, appState: appState) }
                    .signInWithAppleButtonStyle(.white).frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button { Task { await viewModel.signInWithBiometrics(appState: appState) } } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "faceid").font(.system(size: 20))
                            Text("Continue with Face ID").font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appCyan, lineWidth: 1.5))
                    }

                    #if DEBUG
                    Button { appState.markAuthenticated() } label: {
                        Text("Skip (debug)").font(.system(size: 12)).foregroundStyle(Color.appT4)
                    }.padding(.top, 4)
                    #endif
                }.padding(.horizontal, 28)

                if let error = viewModel.errorMessage {
                    Text(error).font(.system(size: 13)).foregroundStyle(Color.appMove)
                        .multilineTextAlignment(.center).padding(.horizontal, 28).padding(.top, 12)
                }

                Text("Secure · Private · On-device").font(.system(size: 11)).foregroundStyle(Color.appT4)
                    .padding(.top, 20).padding(.bottom, 44)
            }
        }
        .overlay { if viewModel.isLoading { loadingOverlay } }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView().tint(Color.appCyan).scaleEffect(1.2)
                Text("Signing in...").font(.system(size: 14)).foregroundStyle(Color.appT2)
            }.padding(28).background(Color.appBG2).clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}
