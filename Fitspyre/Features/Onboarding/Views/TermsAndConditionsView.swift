//
//  TermsAndConditionsView.swift
//  Fitspyre
//
//  First-launch injury / medical disclaimer. The user must read and accept
//  before continuing into the app. Shown once (gated on AppState.hasAcceptedTerms).
//

import SwiftUI

struct TermsAndConditionsView: View {
    var onAccept: () -> Void

    @State private var agreed = false

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.appWarn)
                        .padding(.top, 56)
                    Text("Before you start")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Please read and accept the terms below")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appT3)
                }
                .padding(.bottom, 18)

                ScrollView(showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        clause(
                            icon: "figure.run",
                            title: "Exercise at your own risk",
                            body: "Fitspyre suggests exercises based on the information you provide. If you have an injury, a medical condition, or are recovering from one, an exercise we recommend may not be safe for you. If you choose to perform it, you do so entirely at your own risk."
                        )
                        clause(
                            icon: "cross.case.fill",
                            title: "Not medical advice",
                            body: "Fitspyre is not a doctor, physiotherapist, or medical service. Nothing in this app is medical advice. If you are on medication, pregnant, managing a health condition, or otherwise under medical care, consult a qualified healthcare professional before using this app or starting any exercise."
                        )
                        clause(
                            icon: "shield.lefthalf.filled",
                            title: "No liability for injury",
                            body: "If you use Fitspyre without first getting clearance from a doctor where one is needed, neither Fitspyre nor its makers are responsible for any injury, harm, or aggravation of an existing condition that may result."
                        )
                        clause(
                            icon: "hand.raised.fill",
                            title: "Stop if it hurts",
                            body: "Stop immediately and seek medical help if you feel pain, dizziness, shortness of breath, or any other warning sign. AI form feedback is guidance only and can be wrong — trust your body first."
                        )

                        Text("By tapping Accept you confirm you have read and understood the above and agree to use Fitspyre on these terms.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appT4)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }

                // Agree toggle + button
                VStack(spacing: 14) {
                    Button { agreed.toggle() } label: {
                        HStack(spacing: 12) {
                            Image(systemName: agreed ? "checkmark.square.fill" : "square")
                                .font(.system(size: 22))
                                .foregroundStyle(agreed ? Color.appGood : Color.appT3)
                            Text("I have read and agree to these terms")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.appT2)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        guard agreed else { return }
                        onAccept()
                    } label: {
                        Text("Accept & Continue")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(agreed ? .black : Color.appT4)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(agreed ? Color.appLime : Color.appBG3)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!agreed)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 36)
                .background(Color.appBG)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func clause(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.appCyan)
                .frame(width: 26)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appT3)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(Color.appBG2, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appHair, lineWidth: 0.5))
    }
}
