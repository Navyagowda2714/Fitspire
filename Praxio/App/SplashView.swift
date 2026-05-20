//
//  SplashView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 16/05/2026.
//


//
//  SplashView.swift
//  FitnessAI
//
//  Animated logo splash shown on every launch for ~2.5 seconds.
//  Uses brand colors: deep navy bg, cyan accent, lime pulse.
//

import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void

    @State private var logoScale:    CGFloat = 0.4
    @State private var logoOpacity:  Double  = 0
    @State private var textOpacity:  Double  = 0
    @State private var taglineSlide: CGFloat = 20
    @State private var ringScale:    CGFloat = 0.6
    @State private var ringOpacity:  Double  = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "060a12"), Color(hex: "0c1422"), Color(hex: "060a12")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient glow behind logo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appCyan.opacity(0.18), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            VStack(spacing: 28) {
                Spacer()

                // Logo mark
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.appCyan, Color.appLime, Color.appCyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 110, height: 110)
                        .opacity(logoOpacity * 0.6)

                    // Inner circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "111827"), Color(hex: "0d1420")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.appCyan.opacity(0.25), radius: 20)

                    // AI bolt icon
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.appCyan, Color.appLime],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.appCyan.opacity(0.5), radius: 8)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // App name
                VStack(spacing: 8) {
                    Text("FitnessAI")
                        .font(.system(size: 38, weight: .heavy, design: .default))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.appT2],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .tracking(1)

                    Text("Your AI-powered coach")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.appCyan)
                        .offset(y: taglineSlide)
                }
                .opacity(textOpacity)

                Spacer()

                // Bottom loading bar
                VStack(spacing: 12) {
                    LoadingBar()
                        .frame(width: 80, height: 3)
                        .opacity(textOpacity)

                    Text("Powered by AI · Built for you")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appT3)
                        .opacity(textOpacity * 0.7)
                }
                .padding(.bottom, 52)
            }
        }
        .onAppear {
            animateIn()
        }
    }

    private func animateIn() {
        // Ambient glow
        withAnimation(.easeOut(duration: 1.2)) {
            ringScale   = 1.0
            ringOpacity = 1.0
        }

        // Logo pop
        withAnimation(.spring(response: 0.65, dampingFraction: 0.55).delay(0.15)) {
            logoScale   = 1.0
            logoOpacity = 1.0
        }

        // Text fade + slide
        withAnimation(.easeOut(duration: 0.6).delay(0.55)) {
            textOpacity  = 1.0
            taglineSlide = 0
        }

        // Auto-dismiss after 2.6 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                onFinished()
            }
        }
    }
}

// Animated loading bar
struct LoadingBar: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 3)
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.appCyan, Color.appLime],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: 3)
                    .animation(.easeInOut(duration: 2.0), value: progress)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                progress = 1.0
            }
        }
    }
}