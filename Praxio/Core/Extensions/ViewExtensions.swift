//
//  ViewExtensions.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

//  ViewExtensions.swift — FitnessAI
//
//  ViewExtensions.swift
//  FitnessAI
//

import SwiftUI


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}


// MARK: - Design tokens
extension Color {
    // Backgrounds
    static let appBG    = Color(hex: "080c14")   // deep navy-black
    static let appBG1   = Color(hex: "0c1018")
    static let appBG2   = Color(hex: "111827")   // card
    static let appBG3   = Color(hex: "1a2333")   // elevated card

    // Hairlines
    static let appHair  = Color.white.opacity(0.08)
    static let appHair2 = Color.white.opacity(0.14)

    // Text
    static let appT2    = Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.78)
    static let appT3    = Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.55)
    static let appT4    = Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.32)

    // Primary neon cyan (matches prototype)
    static let appCyan  = Color(hex: "00E5FF")
    static let appCyan2 = Color(hex: "0AE8F0")

    // Secondary accents
    static let appLime  = Color(hex: "C6FF3D")   // kept for other views
    static let appMove  = Color(hex: "FA114F")
    static let appStand = Color(hex: "00E5FF")
    static let appGood  = Color(hex: "30D158")
    static let appWarn  = Color(hex: "FFB020")
}

// MARK: - Input field modifier
extension View {
    func inputFieldStyle() -> some View { modifier(InputFieldModifier()) }
}

struct InputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.appBG2)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appCyan.opacity(0.4), lineWidth: 1)
            )
    }
}
