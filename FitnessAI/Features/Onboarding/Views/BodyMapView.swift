//
//  BodyMapView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 13/05/2026.
//


import SwiftUI

// MARK: - Muscle Group Model
enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest       = "Chest"
    case back        = "Back"
    case shoulders   = "Shoulders"
    case biceps      = "Biceps"
    case triceps     = "Triceps"
    case core        = "Core / Abs"
    case quads       = "Quads"
    case hamstrings  = "Hamstrings"
    case glutes      = "Glutes"
    case calves      = "Calves"

    var id: String { rawValue }

    var isFront: Bool {
        switch self {
        case .chest, .biceps, .core, .quads, .calves: return true
        default: return false
        }
    }

    var color: Color {
        switch self {
        case .chest:      return Color(hex: "1D9E75")
        case .back:       return Color(hex: "7F77DD")
        case .shoulders:  return Color(hex: "2ABFFF")
        case .biceps:     return Color(hex: "1D9E75")
        case .triceps:    return Color(hex: "7F77DD")
        case .core:       return Color(hex: "D85A30")
        case .quads:      return Color(hex: "2ABFFF")
        case .hamstrings: return Color(hex: "D85A30")
        case .glutes:     return Color(hex: "7F77DD")
        case .calves:     return Color(hex: "1D9E75")
        }
    }

    var icon: String {
        switch self {
        case .chest:      return "heart.fill"
        case .back:       return "arrow.up.and.down"
        case .shoulders:  return "figure.arms.open"
        case .biceps:     return "figure.strengthtraining.traditional"
        case .triceps:    return "figure.strengthtraining.functional"
        case .core:       return "tornado"
        case .quads:      return "figure.run"
        case .hamstrings: return "figure.walk"
        case .glutes:     return "figure.cooldown"
        case .calves:     return "figure.stairs"
        }
    }
}

// MARK: - Main View
struct BodyMapView: View {
    let gender: Gender

    @State private var selectedMuscles: Set<MuscleGroup> = []
    @State private var showingFront = true
    @State private var isAnimating = false
    @State private var navigateToWorkout = false
    @State private var flipDegrees: Double = 0

    var frontMuscles: [MuscleGroup] { MuscleGroup.allCases.filter { $0.isFront } }
    var backMuscles:  [MuscleGroup] { MuscleGroup.allCases.filter { !$0.isFront } }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0E1A").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 6) {
                        Text("Select Muscle Groups")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        Text("Tap areas to target · Rotate to see back")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    // Front/Back Toggle
                    HStack(spacing: 0) {
                        ForEach(["Front", "Back"], id: \.self) { side in
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    showingFront = (side == "Front")
                                    flipDegrees += 180
                                }
                            } label: {
                                Text(side)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(
                                        (side == "Front") == showingFront ? .white : .white.opacity(0.4)
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        (side == "Front") == showingFront
                                            ? Color(hex: "1D9E75").opacity(0.25)
                                            : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 60)
                    .padding(.bottom, 12)

                    // Body + Muscle Buttons
                    ZStack {
                        // Ambient glow
                        if !selectedMuscles.isEmpty {
                            ForEach(Array(selectedMuscles), id: \.self) { m in
                                Ellipse()
                                    .fill(m.color.opacity(0.12))
                                    .frame(width: 180, height: 180)
                                    .blur(radius: 50)
                            }
                        }

                        // Body Silhouette
                        BodySilhouette(
                            isFront: showingFront,
                            selectedMuscles: selectedMuscles
                        )
                        .frame(height: 320)
                        .rotation3DEffect(
                            .degrees(flipDegrees),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: flipDegrees)
                    }
                    .padding(.bottom, 8)

                    // Selected Count Badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "1D9E75"))
                            .frame(width: 8, height: 8)
                        Text(selectedMuscles.isEmpty
                             ? "Tap muscle groups below to select"
                             : "\(selectedMuscles.count) group\(selectedMuscles.count == 1 ? "" : "s") selected")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.bottom, 10)

                    // Muscle Chip Grid
                    let muscles = showingFront ? frontMuscles : backMuscles
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(muscles) { muscle in
                            MuscleChip(
                                muscle: muscle,
                                isSelected: selectedMuscles.contains(muscle)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedMuscles.contains(muscle) {
                                        selectedMuscles.remove(muscle)
                                    } else {
                                        selectedMuscles.insert(muscle)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 12)

                    // Generate Workout Button
                    NavigationLink(destination: WorkoutView(
                        gender: gender,
                        selectedMuscles: selectedMuscles.isEmpty
                            ? Set(MuscleGroup.allCases) : selectedMuscles
                    )) {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.fill")
                            Text(selectedMuscles.isEmpty ? "Full Body Workout" : "Generate Workout")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "1D9E75"), Color(hex: "0d7a5b")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "1D9E75").opacity(0.4), radius: 12, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Body Silhouette (stylised SVG-like)
struct BodySilhouette: View {
    let isFront: Bool
    let selectedMuscles: Set<MuscleGroup>

    func isHighlighted(_ muscle: MuscleGroup) -> Bool {
        selectedMuscles.contains(muscle)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w / 2

            ZStack {
                // ── Base silhouette ──
                SilhouetteShape(isFront: isFront)
                    .fill(Color.white.opacity(0.07))

                SilhouetteShape(isFront: isFront)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1.5)

                if isFront {
                    // Chest
                    MuscleZone(
                        rect: CGRect(x: cx - 44, y: h * 0.17, width: 88, height: 44),
                        cornerRadius: 18,
                        color: MuscleGroup.chest.color,
                        active: isHighlighted(.chest)
                    )
                    // Shoulders
                    MuscleZone(rect: CGRect(x: cx - 80, y: h * 0.12, width: 32, height: 36), cornerRadius: 14, color: MuscleGroup.shoulders.color, active: isHighlighted(.shoulders))
                    MuscleZone(rect: CGRect(x: cx + 48, y: h * 0.12, width: 32, height: 36), cornerRadius: 14, color: MuscleGroup.shoulders.color, active: isHighlighted(.shoulders))
                    // Biceps
                    MuscleZone(rect: CGRect(x: cx - 90, y: h * 0.27, width: 22, height: 38), cornerRadius: 10, color: MuscleGroup.biceps.color, active: isHighlighted(.biceps))
                    MuscleZone(rect: CGRect(x: cx + 68, y: h * 0.27, width: 22, height: 38), cornerRadius: 10, color: MuscleGroup.biceps.color, active: isHighlighted(.biceps))
                    // Core
                    MuscleZone(rect: CGRect(x: cx - 30, y: h * 0.33, width: 60, height: 72), cornerRadius: 14, color: MuscleGroup.core.color, active: isHighlighted(.core))
                    // Quads
                    MuscleZone(rect: CGRect(x: cx - 48, y: h * 0.62, width: 38, height: 60), cornerRadius: 14, color: MuscleGroup.quads.color, active: isHighlighted(.quads))
                    MuscleZone(rect: CGRect(x: cx + 10, y: h * 0.62, width: 38, height: 60), cornerRadius: 14, color: MuscleGroup.quads.color, active: isHighlighted(.quads))
                    // Calves (front)
                    MuscleZone(rect: CGRect(x: cx - 46, y: h * 0.82, width: 28, height: 40), cornerRadius: 12, color: MuscleGroup.calves.color, active: isHighlighted(.calves))
                    MuscleZone(rect: CGRect(x: cx + 18, y: h * 0.82, width: 28, height: 40), cornerRadius: 12, color: MuscleGroup.calves.color, active: isHighlighted(.calves))
                } else {
                    // Traps / Back
                    MuscleZone(rect: CGRect(x: cx - 44, y: h * 0.13, width: 88, height: 38), cornerRadius: 18, color: MuscleGroup.back.color, active: isHighlighted(.back))
                    // Rear shoulders
                    MuscleZone(rect: CGRect(x: cx - 80, y: h * 0.12, width: 32, height: 32), cornerRadius: 14, color: MuscleGroup.shoulders.color, active: isHighlighted(.shoulders))
                    MuscleZone(rect: CGRect(x: cx + 48, y: h * 0.12, width: 32, height: 32), cornerRadius: 14, color: MuscleGroup.shoulders.color, active: isHighlighted(.shoulders))
                    // Triceps
                    MuscleZone(rect: CGRect(x: cx - 90, y: h * 0.27, width: 22, height: 38), cornerRadius: 10, color: MuscleGroup.triceps.color, active: isHighlighted(.triceps))
                    MuscleZone(rect: CGRect(x: cx + 68, y: h * 0.27, width: 22, height: 38), cornerRadius: 10, color: MuscleGroup.triceps.color, active: isHighlighted(.triceps))
                    // Lats
                    MuscleZone(rect: CGRect(x: cx - 52, y: h * 0.28, width: 36, height: 52), cornerRadius: 14, color: MuscleGroup.back.color, active: isHighlighted(.back))
                    MuscleZone(rect: CGRect(x: cx + 16, y: h * 0.28, width: 36, height: 52), cornerRadius: 14, color: MuscleGroup.back.color, active: isHighlighted(.back))
                    // Glutes
                    MuscleZone(rect: CGRect(x: cx - 48, y: h * 0.53, width: 40, height: 38), cornerRadius: 16, color: MuscleGroup.glutes.color, active: isHighlighted(.glutes))
                    MuscleZone(rect: CGRect(x: cx + 8,  y: h * 0.53, width: 40, height: 38), cornerRadius: 16, color: MuscleGroup.glutes.color, active: isHighlighted(.glutes))
                    // Hamstrings
                    MuscleZone(rect: CGRect(x: cx - 48, y: h * 0.62, width: 38, height: 52), cornerRadius: 14, color: MuscleGroup.hamstrings.color, active: isHighlighted(.hamstrings))
                    MuscleZone(rect: CGRect(x: cx + 10, y: h * 0.62, width: 38, height: 52), cornerRadius: 14, color: MuscleGroup.hamstrings.color, active: isHighlighted(.hamstrings))
                    // Calves (back)
                    MuscleZone(rect: CGRect(x: cx - 44, y: h * 0.82, width: 28, height: 38), cornerRadius: 12, color: MuscleGroup.calves.color, active: isHighlighted(.calves))
                    MuscleZone(rect: CGRect(x: cx + 16, y: h * 0.82, width: 28, height: 38), cornerRadius: 12, color: MuscleGroup.calves.color, active: isHighlighted(.calves))
                }
            }
        }
    }
}

// MARK: - Muscle Zone Overlay
struct MuscleZone: View {
    let rect: CGRect
    let cornerRadius: CGFloat
    let color: Color
    let active: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(active ? color.opacity(0.55) : color.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(active ? color : color.opacity(0.3), lineWidth: active ? 1.5 : 0.8)
            )
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .shadow(color: active ? color.opacity(0.6) : .clear, radius: 8)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: active)
    }
}

// MARK: - Body Silhouette Shape
struct SilhouetteShape: Shape {
    let isFront: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = w / 2

        // Head
        p.addEllipse(in: CGRect(x: cx - 22, y: h * 0.00, width: 44, height: 52))
        // Neck
        p.addRoundedRect(in: CGRect(x: cx - 10, y: h * 0.10, width: 20, height: 16), cornerSize: CGSize(width: 6, height: 6))
        // Torso
        p.addRoundedRect(in: CGRect(x: cx - 52, y: h * 0.14, width: 104, height: 108), cornerSize: CGSize(width: 20, height: 20))
        // Hip/Pelvis
        p.addRoundedRect(in: CGRect(x: cx - 44, y: h * 0.46, width: 88, height: 44), cornerSize: CGSize(width: 16, height: 16))
        // Arms
        p.addRoundedRect(in: CGRect(x: cx - 90, y: h * 0.14, width: 34, height: 100), cornerSize: CGSize(width: 14, height: 14))
        p.addRoundedRect(in: CGRect(x: cx + 56, y: h * 0.14, width: 34, height: 100), cornerSize: CGSize(width: 14, height: 14))
        // Forearms
        p.addRoundedRect(in: CGRect(x: cx - 92, y: h * 0.38, width: 28, height: 80), cornerSize: CGSize(width: 12, height: 12))
        p.addRoundedRect(in: CGRect(x: cx + 64, y: h * 0.38, width: 28, height: 80), cornerSize: CGSize(width: 12, height: 12))
        // Legs
        p.addRoundedRect(in: CGRect(x: cx - 48, y: h * 0.57, width: 42, height: 126), cornerSize: CGSize(width: 16, height: 16))
        p.addRoundedRect(in: CGRect(x: cx + 6,  y: h * 0.57, width: 42, height: 126), cornerSize: CGSize(width: 16, height: 16))

        return p
    }
}

// MARK: - Muscle Chip
struct MuscleChip: View {
    let muscle: MuscleGroup
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: muscle.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? muscle.color : .white.opacity(0.4))
                    .frame(width: 20)

                Text(muscle.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.55))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(muscle.color)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? muscle.color.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? muscle.color.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BodyMapView(gender: .male)
}
