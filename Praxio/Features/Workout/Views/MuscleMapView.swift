//
//  MuscleMapView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 17/05/2026.
//



import SwiftUI

// MARK: - View

struct AnatomicalMuscleMapView: View {
    let exercise: HomeExercise
    let isFemale: Bool

    @State private var showBack    = false
    @State private var flipAngle: Double = 0

    private var activation: MuscleActivation { exercise.muscleActivation }

    var body: some View {
        VStack(spacing: 14) {

            // ── Front / Back toggle ──────────────────────────────────────
            HStack(spacing: 0) {
                toggleBtn("Front", selected: !showBack) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        showBack = false; flipAngle = 0
                    }
                }
                toggleBtn("Back", selected: showBack) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        showBack = true; flipAngle = 180
                    }
                }
            }
            .padding(3)
            .background(Color(hex: "0E1621"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))

            // ── Body diagram ─────────────────────────────────────────────
            ZStack {
                // Dark vignette card
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "0B1520"), Color(hex: "0D1A2B")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                // Subtle grid lines
                Canvas { ctx, size in
                    let stride: CGFloat = 22
                    var x: CGFloat = 0
                    while x < size.width {
                        var p = Path(); p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: size.height))
                        ctx.stroke(p, with: .color(Color.white.opacity(0.025)), lineWidth: 0.5)
                        x += stride
                    }
                    var y: CGFloat = 0
                    while y < size.height {
                        var p = Path(); p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: size.width, y: y))
                        ctx.stroke(p, with: .color(Color.white.opacity(0.025)), lineWidth: 0.5)
                        y += stride
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))

                // Body
                GeometryReader { geo in
                    let s = geo.size
                    ZStack {
                        if showBack {
                            BackBodyView(isFemale: isFemale, activation: activation, size: s)
                                .transition(AnyTransition.opacity)
                        } else {
                            FrontBodyView(isFemale: isFemale, activation: activation, size: s)
                                .transition(AnyTransition.opacity)
                        }
                    }
                    .frame(width: s.width, height: s.height)
                }
                .padding(16)

                // Muscle name labels for active muscles
                MuscleLabels(activation: activation, showBack: showBack)
            }
            .frame(height: 320)
            .shadow(color: Color.appCyan.opacity(0.08), radius: 20)

            // ── Legend ───────────────────────────────────────────────────
            HStack(spacing: 24) {
                legendItem(Color(hex: "E8FF5A"), "Primary")
                legendItem(Color(hex: "1D9E75"), "Secondary")
                legendItem(Color.white.opacity(0.12), "Inactive")
            }
        }
    }

    private func toggleBtn(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(selected ? Color.black : Color.white.opacity(0.4))
                .frame(maxWidth: .infinity).frame(height: 30)
                .background(selected ? Color(hex: "E8FF5A") : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain)
    }

    private func legendItem(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 18, height: 10)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(color.opacity(0.4), lineWidth: 0.5))
            Text(label).font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.4))
        }
    }
}

// MARK: - Muscle label overlay

struct MuscleLabels: View {
    let activation: MuscleActivation
    let showBack: Bool

    private var visiblePrimary: [String] {
        activation.primary.filter { isVisible($0) }.map { $0.rawValue }
    }

    private func isVisible(_ r: MuscleRegion) -> Bool {
        let backRegions: Set<MuscleRegion> = [.traps, .rearShoulders, .lats, .lowerBack, .glutes, .hamstrings, .calves, .triceps]
        return showBack ? backRegions.contains(r) : !backRegions.contains(r)
    }

    var body: some View {
        VStack {
            Spacer()
            if !visiblePrimary.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(visiblePrimary, id: \.self) { name in
                            Text(name)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Color(hex: "E8FF5A"))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.bottom, 10)
            }
        }
    }
}

// MARK: - Front Body

struct FrontBodyView: View {
    let isFemale: Bool
    let activation: MuscleActivation
    let size: CGSize

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let cx = w / 2
            let scale = min(w / 160, h / 340)

            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: cx + x * scale, y: y * scale + 10)
            }

            func col(_ region: MuscleRegion) -> Color {
                if activation.primary.contains(region)   { return Color(hex: "E8FF5A").opacity(0.92) }
                if activation.secondary.contains(region) { return Color(hex: "1D9E75").opacity(0.75) }
                return Color(hex: "1E3050").opacity(0.85)
            }

            // ── Body silhouette (filled first, low-opacity) ───────────────
            let silhouette = humanFrontSilhouette(pt: pt, isFemale: isFemale)
            ctx.fill(silhouette, with: .color(Color(hex: "102030").opacity(0.95)))
            ctx.stroke(silhouette, with: .color(Color.white.opacity(0.08)), lineWidth: 1.5)

            // ── Individual muscle groups ───────────────────────────────────

            // HEAD
            let headPath = Path(ellipseIn: CGRect(
                x: cx - 18*scale, y: 4*scale,
                width: 36*scale, height: 44*scale
            ))
            ctx.fill(headPath, with: .color(Color(hex: "1E3050").opacity(0.8)))
            ctx.stroke(headPath, with: .color(Color.white.opacity(0.1)), lineWidth: 1)

            // NECK
            let neckW: CGFloat = isFemale ? 10 : 13
            let neck = Path(roundedRect: CGRect(
                x: cx - neckW*scale, y: 44*scale,
                width: neckW*2*scale, height: 16*scale
            ), cornerRadius: 4*scale)
            ctx.fill(neck, with: .color(Color(hex: "1E3050").opacity(0.8)))

            // SHOULDERS
            let shW: CGFloat = isFemale ? 18 : 22
            for side: CGFloat in [-1, 1] {
                let sx = side * (isFemale ? 32 : 36) * scale
                let shoulder = Path(ellipseIn: CGRect(
                    x: cx + sx - shW*0.5*scale, y: 58*scale,
                    width: shW*scale, height: shW*0.9*scale
                ))
                ctx.fill(shoulder, with: .color(col(.frontShoulders)))
                ctx.stroke(shoulder, with: .color(Color.white.opacity(0.12)), lineWidth: 0.8)
            }

            // CHEST  (two pecs)
            let pecW: CGFloat = isFemale ? 22 : 28
            let pecH: CGFloat = isFemale ? 20 : 24
            for side: CGFloat in [-1, 1] {
                let px = side * (isFemale ? 14 : 16) * scale
                let pec = Path(ellipseIn: CGRect(
                    x: cx + px - pecW*0.5*scale, y: 74*scale,
                    width: pecW*scale, height: pecH*scale
                ))
                ctx.fill(pec, with: .color(col(.chest)))
                ctx.stroke(pec, with: .color(Color.white.opacity(0.12)), lineWidth: 0.8)
            }

            // ABS  (6-pack: 3 rows × 2 cols)
            let absW: CGFloat = isFemale ? 13 : 16
            let absH: CGFloat = isFemale ? 11 : 13
            for row in 0..<3 {
                for side: CGFloat in [-1, 1] {
                    let ax = side * (absW * 0.55) * scale
                    let ay = (100 + CGFloat(row) * (absH + 3)) * scale
                    let ab = Path(roundedRect: CGRect(
                        x: cx + ax - absW*0.5*scale, y: ay,
                        width: absW*scale, height: absH*scale
                    ), cornerRadius: 4*scale)
                    ctx.fill(ab, with: .color(col(.abs)))
                    ctx.stroke(ab, with: .color(Color.white.opacity(0.15)), lineWidth: 0.7)
                }
            }

            // OBLIQUES
            for side: CGFloat in [-1, 1] {
                let obPath = Path { p in
                    let ox = cx + side * (absW + 6) * scale
                    p.move(to: CGPoint(x: ox, y: 100*scale))
                    p.addCurve(
                        to:        CGPoint(x: ox + side*8*scale, y: 148*scale),
                        control1:  CGPoint(x: ox + side*10*scale, y: 112*scale),
                        control2:  CGPoint(x: ox + side*12*scale, y: 132*scale)
                    )
                    p.addLine(to: CGPoint(x: ox + side*2*scale, y: 148*scale))
                    p.addCurve(
                        to:        CGPoint(x: ox - side*2*scale, y: 100*scale),
                        control1:  CGPoint(x: ox + side*4*scale, y: 132*scale),
                        control2:  CGPoint(x: ox, y: 112*scale)
                    )
                }
                ctx.fill(obPath, with: .color(col(.obliques)))
            }

            // HIP FLEXORS
            let hipPath = Path(roundedRect: CGRect(
                x: cx - 22*scale, y: 148*scale,
                width: 44*scale, height: 22*scale
            ), cornerRadius: 6*scale)
            ctx.fill(hipPath, with: .color(col(.hipFlexors)))
            ctx.stroke(hipPath, with: .color(Color.white.opacity(0.10)), lineWidth: 0.7)

            // BICEPS
            let bicW: CGFloat = isFemale ? 9 : 12
            for side: CGFloat in [-1, 1] {
                let bx = cx + side * (isFemale ? 48 : 54) * scale
                let bic = Path(ellipseIn: CGRect(
                    x: bx - bicW*0.5*scale, y: 78*scale,
                    width: bicW*scale, height: 34*scale
                ))
                ctx.fill(bic, with: .color(col(.biceps)))
                ctx.stroke(bic, with: .color(Color.white.opacity(0.12)), lineWidth: 0.7)
            }

            // FOREARMS
            let faW: CGFloat = isFemale ? 7 : 9
            for side: CGFloat in [-1, 1] {
                let fx = cx + side * (isFemale ? 50 : 56) * scale
                let fa = Path(roundedRect: CGRect(
                    x: fx - faW*0.5*scale, y: 118*scale,
                    width: faW*scale, height: 36*scale
                ), cornerRadius: faW*0.5*scale)
                ctx.fill(fa, with: .color(col(.forearms)))
                ctx.stroke(fa, with: .color(Color.white.opacity(0.10)), lineWidth: 0.7)
            }

            // QUADS
            let quadW: CGFloat = isFemale ? 19 : 22
            let quadH: CGFloat = 60.0
            for side: CGFloat in [-1, 1] {
                let qx = cx + side * (isFemale ? 14 : 15) * scale
                let quad = Path(roundedRect: CGRect(
                    x: qx - quadW*0.5*scale, y: 174*scale,
                    width: quadW*scale, height: quadH*scale
                ), cornerRadius: 8*scale)
                ctx.fill(quad, with: .color(col(.quads)))
                ctx.stroke(quad, with: .color(Color.white.opacity(0.12)), lineWidth: 0.8)
            }

            // KNEES
            for side: CGFloat in [-1, 1] {
                let kx = cx + side * (isFemale ? 14 : 15) * scale
                let knee = Path(ellipseIn: CGRect(
                    x: kx - 9*scale, y: 236*scale,
                    width: 18*scale, height: 14*scale
                ))
                ctx.fill(knee, with: .color(Color(hex: "1E3050").opacity(0.9)))
                ctx.stroke(knee, with: .color(Color.white.opacity(0.15)), lineWidth: 0.7)
            }

            // SHINS
            for side: CGFloat in [-1, 1] {
                let sx2 = cx + side * (isFemale ? 13 : 14) * scale
                let shin = Path(roundedRect: CGRect(
                    x: sx2 - 8*scale, y: 252*scale,
                    width: 16*scale, height: 50*scale
                ), cornerRadius: 6*scale)
                ctx.fill(shin, with: .color(col(.shins)))
                ctx.stroke(shin, with: .color(Color.white.opacity(0.10)), lineWidth: 0.7)
            }
        }
    }
}

// MARK: - Back Body

struct BackBodyView: View {
    let isFemale: Bool
    let activation: MuscleActivation
    let size: CGSize

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let cx = w / 2
            let scale = min(w / 160, h / 340)

            func col(_ region: MuscleRegion) -> Color {
                if activation.primary.contains(region)   { return Color(hex: "E8FF5A").opacity(0.92) }
                if activation.secondary.contains(region) { return Color(hex: "1D9E75").opacity(0.75) }
                return Color(hex: "1E3050").opacity(0.85)
            }

            // HEAD (back)
            let headPath = Path(ellipseIn: CGRect(x: cx-18*scale, y: 4*scale, width: 36*scale, height: 44*scale))
            ctx.fill(headPath, with: .color(Color(hex: "1E3050").opacity(0.8)))
            ctx.stroke(headPath, with: .color(Color.white.opacity(0.1)), lineWidth: 1)

            // NECK
            let neckW: CGFloat = isFemale ? 10 : 13
            let neck = Path(roundedRect: CGRect(x: cx-neckW*scale, y: 44*scale, width: neckW*2*scale, height: 14*scale), cornerRadius: 4*scale)
            ctx.fill(neck, with: .color(Color(hex: "1E3050").opacity(0.8)))

            // TRAPS (diamond shape)
            let trapPath = Path { p in
                p.move(to: CGPoint(x: cx, y: 56*scale))
                p.addCurve(to: CGPoint(x: cx-(isFemale ? 38:44)*scale, y: 76*scale),
                           control1: CGPoint(x: cx-20*scale, y: 58*scale),
                           control2: CGPoint(x: cx-38*scale, y: 64*scale))
                p.addLine(to: CGPoint(x: cx-(isFemale ? 22:26)*scale, y: 98*scale))
                p.addCurve(to: CGPoint(x: cx, y: 88*scale),
                           control1: CGPoint(x: cx-16*scale, y: 100*scale),
                           control2: CGPoint(x: cx-8*scale, y: 94*scale))
                p.addCurve(to: CGPoint(x: cx+(isFemale ? 22:26)*scale, y: 98*scale),
                           control1: CGPoint(x: cx+8*scale, y: 94*scale),
                           control2: CGPoint(x: cx+16*scale, y: 100*scale))
                p.addLine(to: CGPoint(x: cx+(isFemale ? 38:44)*scale, y: 76*scale))
                p.addCurve(to: CGPoint(x: cx, y: 56*scale),
                           control1: CGPoint(x: cx+38*scale, y: 64*scale),
                           control2: CGPoint(x: cx+20*scale, y: 58*scale))
            }
            ctx.fill(trapPath, with: .color(col(.traps)))
            ctx.stroke(trapPath, with: .color(Color.white.opacity(0.12)), lineWidth: 0.8)

            // REAR SHOULDERS
            let shW: CGFloat = isFemale ? 18 : 22
            for side: CGFloat in [-1, 1] {
                let sx = side * (isFemale ? 32 : 36) * scale
                let sh = Path(ellipseIn: CGRect(x: cx+sx-shW*0.5*scale, y: 60*scale, width: shW*scale, height: shW*0.9*scale))
                ctx.fill(sh, with: .color(col(.rearShoulders)))
                ctx.stroke(sh, with: .color(Color.white.opacity(0.12)), lineWidth: 0.8)
            }

            // LATS (wing shapes)
            for side: CGFloat in [-1, 1] {
                let latPath = Path { p in
                    let lx = cx + side * (isFemale ? 20 : 24) * scale
                    p.move(to: CGPoint(x: lx, y: 90*scale))
                    p.addCurve(to: CGPoint(x: lx + side*26*scale, y: 148*scale),
                               control1: CGPoint(x: lx + side*30*scale, y: 102*scale),
                               control2: CGPoint(x: lx + side*32*scale, y: 128*scale))
                    p.addCurve(to: CGPoint(x: lx + side*6*scale, y: 152*scale),
                               control1: CGPoint(x: lx + side*20*scale, y: 154*scale),
                               control2: CGPoint(x: lx + side*12*scale, y: 155*scale))
                    p.addCurve(to: CGPoint(x: lx, y: 90*scale),
                               control1: CGPoint(x: lx + side*2*scale, y: 140*scale),
                               control2: CGPoint(x: lx - side*2*scale, y: 112*scale))
                }
                ctx.fill(latPath, with: .color(col(.lats)))
                ctx.stroke(latPath, with: .color(Color.white.opacity(0.12)), lineWidth: 0.8)
            }

            // LOWER BACK (erectors)
            let lbPath = Path { p in
                let lbW: CGFloat = isFemale ? 14 : 18
                p.move(to: CGPoint(x: cx-lbW*scale, y: 148*scale))
                p.addCurve(to: CGPoint(x: cx+lbW*scale, y: 148*scale),
                           control1: CGPoint(x: cx-lbW*0.5*scale, y: 144*scale),
                           control2: CGPoint(x: cx+lbW*0.5*scale, y: 144*scale))
                p.addCurve(to: CGPoint(x: cx+(lbW-2)*scale, y: 174*scale),
                           control1: CGPoint(x: cx+lbW*1.1*scale, y: 158*scale),
                           control2: CGPoint(x: cx+lbW*0.9*scale, y: 168*scale))
                p.addCurve(to: CGPoint(x: cx-(lbW-2)*scale, y: 174*scale),
                           control1: CGPoint(x: cx+4*scale, y: 178*scale),
                           control2: CGPoint(x: cx-4*scale, y: 178*scale))
                p.addCurve(to: CGPoint(x: cx-lbW*scale, y: 148*scale),
                           control1: CGPoint(x: cx-lbW*0.9*scale, y: 168*scale),
                           control2: CGPoint(x: cx-lbW*1.1*scale, y: 158*scale))
            }
            ctx.fill(lbPath, with: .color(col(.lowerBack)))
            ctx.stroke(lbPath, with: .color(Color.white.opacity(0.12)), lineWidth: 0.8)

            // TRICEPS
            let tricW: CGFloat = isFemale ? 9 : 11
            for side: CGFloat in [-1, 1] {
                let tx = cx + side * (isFemale ? 48 : 54) * scale
                let tric = Path(ellipseIn: CGRect(x: tx-tricW*0.5*scale, y: 78*scale, width: tricW*scale, height: 36*scale))
                ctx.fill(tric, with: .color(col(.triceps)))
                ctx.stroke(tric, with: .color(Color.white.opacity(0.12)), lineWidth: 0.7)
            }

            // GLUTES (two rounded cheeks)
            let gluteW: CGFloat = isFemale ? 24 : 20
            let gluteH: CGFloat = isFemale ? 26 : 22
            for side: CGFloat in [-1, 1] {
                let gx = cx + side * (isFemale ? 12 : 10) * scale
                let glute = Path(ellipseIn: CGRect(x: gx-gluteW*0.5*scale, y: 174*scale, width: gluteW*scale, height: gluteH*scale))
                ctx.fill(glute, with: .color(col(.glutes)))
                ctx.stroke(glute, with: .color(Color.white.opacity(0.12)), lineWidth: 0.8)
            }

            // HAMSTRINGS
            let hamW: CGFloat = isFemale ? 18 : 21
            for side: CGFloat in [-1, 1] {
                let hx = cx + side * (isFemale ? 14 : 15) * scale
                let ham = Path(roundedRect: CGRect(x: hx-hamW*0.5*scale, y: 200*scale, width: hamW*scale, height: 58*scale), cornerRadius: 8*scale)
                ctx.fill(ham, with: .color(col(.hamstrings)))
                ctx.stroke(ham, with: .color(Color.white.opacity(0.12)), lineWidth: 0.8)
            }

            // CALVES
            for side: CGFloat in [-1, 1] {
                let cvx = cx + side * (isFemale ? 13 : 14) * scale
                let calfPath = Path { p in
                    p.move(to: CGPoint(x: cvx - 6*scale, y: 260*scale))
                    p.addCurve(to: CGPoint(x: cvx + 6*scale, y: 260*scale),
                               control1: CGPoint(x: cvx-8*scale, y: 256*scale),
                               control2: CGPoint(x: cvx+8*scale, y: 256*scale))
                    p.addCurve(to: CGPoint(x: cvx+5*scale, y: 308*scale),
                               control1: CGPoint(x: cvx+10*scale, y: 276*scale),
                               control2: CGPoint(x: cvx+8*scale, y: 296*scale))
                    p.addCurve(to: CGPoint(x: cvx-5*scale, y: 308*scale),
                               control1: CGPoint(x: cvx+2*scale, y: 312*scale),
                               control2: CGPoint(x: cvx-2*scale, y: 312*scale))
                    p.addCurve(to: CGPoint(x: cvx-6*scale, y: 260*scale),
                               control1: CGPoint(x: cvx-8*scale, y: 296*scale),
                               control2: CGPoint(x: cvx-10*scale, y: 276*scale))
                }
                ctx.fill(calfPath, with: .color(col(.calves)))
                ctx.stroke(calfPath, with: .color(Color.white.opacity(0.10)), lineWidth: 0.7)
            }
        }
    }
}

// MARK: - Human silhouette path (front)

func humanFrontSilhouette(pt: (CGFloat, CGFloat) -> CGPoint, isFemale: Bool) -> Path {
    let sw: CGFloat = isFemale ? 38 : 44    // shoulder half-width
    let ww: CGFloat = isFemale ? 24 : 32    // waist half-width
    let hw: CGFloat = isFemale ? 34 : 30    // hip half-width
    let kw: CGFloat = isFemale ? 12 : 14    // knee width
    let aw: CGFloat = isFemale ? 10 : 13    // arm width

    return Path { p in
        // Head
        p.move(to: pt(-18, 4))
        p.addCurve(to: pt(18, 4), control1: pt(-22, -4), control2: pt(22, -4))
        p.addCurve(to: pt(18, 48), control1: pt(24, 14), control2: pt(24, 38))
        p.addCurve(to: pt(-18, 48), control1: pt(10, 52), control2: pt(-10, 52))
        p.addCurve(to: pt(-18, 4), control1: pt(-24, 38), control2: pt(-24, 14))

        // Right arm (viewer's left) outer
        p.move(to: pt(sw, 62))
        p.addCurve(to: pt(sw + aw, 62), control1: pt(sw+2, 58), control2: pt(sw+aw-2, 58))
        p.addLine(to: pt(sw + aw - 2, 158))
        p.addLine(to: pt(sw - 2, 158))

        // Left arm
        p.move(to: pt(-sw - aw, 62))
        p.addCurve(to: pt(-sw, 62), control1: pt(-sw-aw+2, 58), control2: pt(-sw-2, 58))
        p.addLine(to: pt(-sw + 2, 158))
        p.addLine(to: pt(-sw - aw + 2, 158))

        // Torso + legs
        p.move(to: pt(-sw, 60))
        p.addLine(to: pt(sw, 60))
        p.addCurve(to: pt(ww, 148), control1: pt(sw + 6, 100), control2: pt(ww + 8, 128))
        p.addCurve(to: pt(hw, 174), control1: pt(ww + 4, 158), control2: pt(hw - 4, 165))
        // right leg
        p.addLine(to: pt(kw + 2, 236))
        p.addLine(to: pt(kw, 310))
        p.addLine(to: pt(0, 310))
        // left leg
        p.addLine(to: pt(-kw, 310))
        p.addLine(to: pt(-kw - 2, 236))
        p.addLine(to: pt(-hw, 174))
        p.addCurve(to: pt(-ww, 148), control1: pt(-hw + 4, 165), control2: pt(-ww - 4, 158))
        p.addCurve(to: pt(-sw, 60), control1: pt(-ww - 8, 128), control2: pt(-sw - 6, 100))
    }
}
