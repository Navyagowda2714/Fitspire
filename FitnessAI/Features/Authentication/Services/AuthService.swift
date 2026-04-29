//
//  AuthService.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//
import Foundation
import AuthenticationServices
import LocalAuthentication

@MainActor
final class AuthService: ObservableObject {

    // Sign in with Apple
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) -> Bool {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                let userID = credential.user
                UserDefaults.standard.set(userID, forKey: "appleUserID")
                return true
            }
            return false
        case .failure:
            return false
        }
    }

    // Face ID / Touch ID
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        ) else { return false }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Sign in to FitnessAI"
            )
        } catch {
            return false
        }
    }

    // Check if returning user has Apple ID stored
    func hasStoredAppleID() -> Bool {
        UserDefaults.standard.string(forKey: "appleUserID") != nil
    }
}
