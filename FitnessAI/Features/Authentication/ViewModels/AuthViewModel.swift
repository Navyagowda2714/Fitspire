//
//  AuthViewModel.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//
import Foundation
import AuthenticationServices

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authService = AuthService()

    func signInWithApple(
        result: Result<ASAuthorization, Error>,
        appState: AppState
    ) {
        isLoading = true
        errorMessage = nil

        let success = authService.handleSignInWithApple(result)

        if success {
            appState.markAuthenticated()
        } else {
            errorMessage = "Sign in failed. Please try again."
        }
        isLoading = false
    }

    func signInWithBiometrics(appState: AppState) async {
        isLoading = true
        errorMessage = nil

        let success = await authService.authenticateWithBiometrics()

        if success {
            appState.markAuthenticated()
        } else {
            errorMessage = "Biometric authentication failed."
        }
        isLoading = false
    }

    func hasStoredAppleID() -> Bool {
        authService.hasStoredAppleID()
    }
}
