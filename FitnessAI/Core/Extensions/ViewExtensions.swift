//
//  ViewExtensions.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
//

//  ViewExtensions.swift — FitnessAI
import SwiftUI

// MARK: - Hex colour init (unchanged)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Design tokens
extension Color {
    static let appBG    = Color(hex: "000000")
    static let appBG1   = Color(hex: "0c0c0e")
    static let appBG2   = Color(hex: "161618")
    static let appBG3   = Color(hex: "1f1f22")
    static let appHair  = Color.white.opacity(0.08)
    static let appHair2 = Color.white.opacity(0.14)
    static let appT2    = Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.78)
    static let appT3    = Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.55)
    static let appT4    = Color(red: 235/255, green: 235/255, blue: 245/255).opacity(0.32)
    static let appLime  = Color(hex: "C6FF3D")
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
            .font(.system(size: 15))
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.appBG2)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appHair2, lineWidth: 0.5))
    }
}
