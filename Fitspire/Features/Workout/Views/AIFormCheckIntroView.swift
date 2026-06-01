//
//  AIFormCheckIntroView.swift
//  Praxio
//
//  Created by Navyashree Byregowda on 25/05/2026.
//

//
//  AIFormCheckIntroView.swift
//  Praxio
//
//  ──────────────────────────────────────────────────────────────────────────
//  PLACEHOLDER SCREEN — Ready for design work
//  ──────────────────────────────────────────────────────────────────────────
//
//  This screen appears AFTER the user taps "Start with AI Form Check"
//  and BEFORE the live camera view opens.
//
//  Current state: blank dark screen with a Continue button.
//  Hand this file to your designer/developer to build out the UI.
//
//  HOW IT FITS IN THE FLOW:
//  HomeExerciseDemoView  →  AIFormCheckIntroView  →  ExerciseLiveView (camera)
//
//  TO CUSTOMISE:
//  • Add instructions, tips, camera permission explanation, countdown etc.
//  • The exercise name is available via: exercise.name
//  • Call onContinue() when the user is ready to open the camera
//
//  ──────────────────────────────────────────────────────────────────────────

import SwiftUI

struct AIFormCheckIntroView: View {

    // The exercise the user selected — use this to show exercise-specific tips
    let exercise: HomeExercise

    // Call this when the user is ready to proceed to the live camera
    let onContinue: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {

            // ── Background ────────────────────────────────────────────────
            Color.appBG.ignoresSafeArea()

            // ── DESIGN GOES HERE ──────────────────────────────────────────
            //
            //  This is the blank canvas. Add your UI between here and the
            //  Continue button below. Ideas:
            //
            //  • Camera setup tips ("Stand 2m from phone")
            //  • Exercise-specific cues (exercise.name, exercise.formCues)
            //  • Animated countdown (3...2...1)
            //  • Camera permission explanation
            //  • Position guide overlay / illustration
            //
            VStack {
                Spacer()

                // Placeholder label — replace with your design
                Text("Design screen here")
                    .font(.title2)
                    .foregroundStyle(Color.appT3)

                Spacer()
            }
            // ── END DESIGN AREA ───────────────────────────────────────────
        }

        // ── Continue button (keep at bottom) ─────────────────────────────
        .overlay(alignment: .bottom) {
            VStack(spacing: 12) {
                Button(action: onContinue) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                        Text("Open Camera")
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.appLime)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.appLime.opacity(0.4), radius: 14, y: 4)
                }

                Button("Back") { dismiss() }
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appT3)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .padding(.top, 16)
            .background(
                LinearGradient(
                    colors: [Color.appBG.opacity(0), Color.appBG],
                    startPoint: .top, endPoint: .bottom
                )
            )
        }
        .preferredColorScheme(.dark)
    }
}
