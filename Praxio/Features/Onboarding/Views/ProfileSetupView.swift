//
//  ProfileSetupView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 28/04/2026.
///
//  ProfileSetupView.swift
//  FitnessAI

// ✅ Fully self-contained — navigation built in, no wiring needed
// ✅ Continue button pinned above keyboard (never overlaps fields)
// ✅ Navigates directly to BodyMapView on Continue

import SwiftUI

struct ProfileSetupView: View {

    // MARK: - Form State
    @State private var age:            String = ""
    @State private var weight:         String = ""
    @State private var height:         String = ""
    @State private var weightUnit:     WeightUnit   = .kg
    @State private var heightUnit:     HeightUnit   = .cm
    @State private var selectedGender: UserGender   = .female

    // MARK: - Navigation State
    @State private var goToBodyMap = false

    @FocusState private var focused: FormField?

    // MARK: - Enums
    enum FormField:  Hashable { case age, weight, height }
    enum WeightUnit: String, CaseIterable { case kg = "KG"; case lb = "LB" }
    enum HeightUnit: String, CaseIterable { case cm = "CM"; case ft = "FT" }
    enum UserGender: String, CaseIterable {
        case female = "Female"; case male = "Male"; case other = "Other"
        var genderForBodyMap: Gender {
            switch self {
            case .female: return .female
            case .male:   return .male
            case .other:  return .other
            }
        }
    }

    var canContinue: Bool { !age.isEmpty && !weight.isEmpty && !height.isEmpty }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0E1A").ignoresSafeArea()

                // ── Scrollable form ────────────────────────
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Let's set your baseline!")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.45))
                                .padding(.top, 8)
                            HStack(spacing: 6) {
                                Text("Tell us about")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Text("yourself")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(hex: "2ABFFF"))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)

                        // Age
                        section("AGE") {
                            HStack {
                                TextField("25", text: $age)
                                    .keyboardType(.numberPad)
                                    .focused($focused, equals: .age)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                Text("years")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                            .padding(.horizontal, 18)
                            .frame(height: 56)
                            .background(fieldBG(active: focused == .age))
                        }

                        // Weight
                        section("WEIGHT") {
                            HStack(spacing: 10) {
                                TextField("65", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .focused($focused, equals: .weight)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(fieldBG(active: focused == .weight))
                                unitPicker(options: WeightUnit.allCases.map(\.rawValue),
                                           selected: weightUnit.rawValue) {
                                    weightUnit = WeightUnit(rawValue: $0) ?? .kg
                                }
                            }
                        }

                        // Height
                        section("HEIGHT") {
                            HStack(spacing: 10) {
                                TextField("165", text: $height)
                                    .keyboardType(.decimalPad)
                                    .focused($focused, equals: .height)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(fieldBG(active: focused == .height))
                                unitPicker(options: HeightUnit.allCases.map(\.rawValue),
                                           selected: heightUnit.rawValue) {
                                    heightUnit = HeightUnit(rawValue: $0) ?? .cm
                                }
                            }
                        }

                        // Gender
                        section("GENDER") {
                            HStack(spacing: 10) {
                                ForEach(UserGender.allCases, id: \.self) { g in
                                    Button {
                                        withAnimation(.spring(response: 0.25)) {
                                            selectedGender = g
                                            focused = nil
                                        }
                                    } label: {
                                        Text(g.rawValue)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(
                                                selectedGender == g
                                                ? Color(hex: "0A0E1A") : .white.opacity(0.55))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 48)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedGender == g
                                                          ? Color(hex: "2ABFFF")
                                                          : Color.white.opacity(0.07))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.top, 16)
                }
                .scrollDismissesKeyboard(.interactively)

                // navigationDestination replaces deprecated NavigationLink(isActive:)
                // (iOS 16+ approach — no hidden EmptyView needed)
                EmptyView()
                    .navigationDestination(isPresented: $goToBodyMap) {
                        BodyMapView(gender: selectedGender.genderForBodyMap)
                    }
            }

            // ✅ Continue button always above keyboard
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button {
                    focused = nil
                    goToBodyMap = true          // ← triggers navigation
                } label: {
                    HStack(spacing: 10) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                canContinue
                                ? LinearGradient(
                                    colors: [Color(hex: "1D9E75"), Color(hex: "0d7a5b")],
                                    startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.10), Color.white.opacity(0.10)],
                                    startPoint: .leading, endPoint: .trailing)
                            )
                            .animation(.easeInOut(duration: 0.2), value: canContinue)
                    )
                }
                .disabled(!canContinue)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .background(Color(hex: "0A0E1A"))
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Helpers
    @ViewBuilder
    func section<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "2ABFFF"))
                .tracking(1.2)
            content()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    func fieldBG(active: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        active
                        ? Color(hex: "2ABFFF").opacity(0.9)
                        : Color(hex: "2ABFFF").opacity(0.25),
                        lineWidth: active ? 1.5 : 1
                    )
            )
    }

    @ViewBuilder
    func unitPicker(options: [String], selected: String,
                    onSelect: @escaping (String) -> Void) -> some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { opt in
                Button {
                    withAnimation(.spring(response: 0.25)) { onSelect(opt) }
                } label: {
                    Text(opt)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(
                            selected == opt ? Color(hex: "0A0E1A") : .white.opacity(0.45))
                        .frame(width: 48, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selected == opt ? Color(hex: "2ABFFF") : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "2ABFFF").opacity(0.25), lineWidth: 1)
                )
        )
    }
}

#Preview { ProfileSetupView() }
