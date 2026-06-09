//
//  AIFormCheckIntroView.swift
//  Praxio
//

import SwiftUI

struct AIFormCheckIntroView: View {

    let exercise: HomeExercise
    let onContinue: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            VStack {
                Spacer()

                if let fileName = exercise.videoFileName {
                    ExerciseVideoPlayerView(videoName: fileName)
                        .frame(maxWidth: .infinity)
                        .frame(height: 680)
                        .clipped()
                        /*.clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 24)*/
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                        Image(systemName: "play.circle")
                            .font(.system(size: 56, weight: .light))
                            .foregroundStyle(Color.appT3)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 680)
                    /*.padding(.horizontal, 24)*/
                }

                Spacer()
            }
        }
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

