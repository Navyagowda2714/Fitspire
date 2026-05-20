//
//  AuthView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 13/05/2026.
// AuthView.swift
// LOCATION: FitnessAI/Features/Auth/Views/AuthView.swift
// Target: FitnessAI ONLY
//
// ✅ Self-contained — zero external dependencies
// ✅ Native SwiftUI SignInWithAppleButton (no UIViewRepresentable)
// ✅ Proper centered layout with safe area

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    // Callbacks — wire to your AuthenticationManager in the parent
    var onAppleSignIn: (ASAuthorization) -> Void = { _ in }
    var onAppleError:  (Error) -> Void            = { _ in }
    var onFaceID:      () -> Void                 = {}
    var onSkip:        () -> Void                 = {}

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────
            Color(hex: "060D18").ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: "1D9E75").opacity(0.20), .clear],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 10,
                endRadius: 380
            )
            .ignoresSafeArea()

            // ── Content ─────────────────────────────────────
            VStack(spacing: 0) {

                Spacer()

                // ── Logo block ──────────────────────────────
                VStack(spacing: 18) {
                    // App icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 26)
                            .fill(Color(hex: "0a2420"))
                            .frame(width: 96, height: 96)
                            .overlay(
                                RoundedRectangle(cornerRadius: 26)
                                    .stroke(Color(hex: "1D9E75").opacity(0.50), lineWidth: 1.5)
                            )

                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 44, weight: .regular))
                            .foregroundColor(Color(hex: "2ABFFF"))
                    }

                    // Title
                    HStack(spacing: 6) {
                        Text("FitnessAI")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Coach")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "2ABFFF"))
                    }

                    // Subtitle
                    Text("Your AI Form Correction and Analysis")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.40))
                }

                Spacer()

                // ── Button stack ────────────────────────────
                VStack(spacing: 14) {

                    // Apple Sign In — native SwiftUI button
                    SignInWithAppleButton(.continue,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let auth): onAppleSignIn(auth)
                            case .failure(let err):  onAppleError(err)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.whiteOutline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .cornerRadius(16)

                    // Face ID button
                    Button(action: onFaceID) {
                        HStack(spacing: 12) {
                            Image(systemName: "faceid")
                                .font(.system(size: 20))
                            Text("Continue with Face ID")
                                .font(.system(size: 16, weight: .medium))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: "1D9E75").opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "1D9E75").opacity(0.55), lineWidth: 1.5)
                                )
                        )
                    }

                    // Debug skip (disappears in Release builds)
                    #if DEBUG
                    Button("Skip (debug)", action: onSkip)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.28))
                        .padding(.top, 2)
                    #endif

                    // Footer
                    HStack(spacing: 6) {
                        ForEach(["Secure", "Private", "On-device"], id: \.self) { word in
                            Text(word)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.25))
                            if word != "On-device" {
                                Text("·")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.18))
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                // ✅ Fixed padding — works on all iPhone sizes
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    AuthView()
}
