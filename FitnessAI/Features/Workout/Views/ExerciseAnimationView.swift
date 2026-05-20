//
//  ExerciseAnimationView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 05/05/2026.
//

//
//  ExerciseAnimationView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 05/05/2026.
//

import SwiftUI

struct ExerciseAnimationView: View {
    let exercise: ExerciseType
    @State private var phase: Double = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Color.appBG
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Rectangle()
                .fill(Color.appLime.opacity(0.3))
                .frame(height: 1)
                .frame(maxWidth: 120)
                .offset(y: 75)

            Canvas { context, size in
                let cx = size.width / 2
                let cy = size.height / 2
                let t = sin(phase * .pi)
                drawFigure(context: context, cx: cx, cy: cy, t: t)
            }
            .frame(width: 200, height: 200)

            VStack {
                Spacer()
                Text(phaseLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.appLime)
                    .padding(.bottom, 8)
            }
        }
        .onAppear { startAnimation() }
        .onDisappear { timer?.invalidate() }
    }

    private var phaseLabel: String {
        switch exercise {
        case .squat:         return phase < 0.5 ? "Lowering down" : "Pressing up"
        case .pushUp:        return phase < 0.5 ? "Lowering chest" : "Pushing up"
        case .plank:         return "Hold — breathe steady"
        case .shoulderPress: return phase < 0.5 ? "Lowering bar" : "Pressing overhead"
        case .deadlift:      return phase < 0.5 ? "Hinging down" : "Driving up"
        case .lunge:           return phase < 0.5 ? "Stepping back" : "Standing up"
        case .gluteBridge:     return phase < 0.5 ? "Lowering hips" : "Drive hips up"
        case .mountainClimber: return phase < 0.5 ? "Left knee drive" : "Right knee drive"
        case .highKnees:       return phase < 0.5 ? "Left knee up" : "Right knee up"
        case .general:         return "Stay controlled"
        }
    }

    private func startAnimation() {
        phase = 0
        let speed: Double = exercise == .plank ? 0.003 : 0.008
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            phase += speed
            if phase >= 1.0 { phase = 0 }
        }
    }

    private func line(
        _ context: GraphicsContext,
        from: CGPoint,
        to: CGPoint,
        color: Color,
        width: CGFloat = 3
    ) {
        var p = Path()
        p.move(to: from)
        p.addLine(to: to)
        context.stroke(p, with: .color(color), lineWidth: width)
    }

    private func circle(
        _ context: GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color
    ) {
        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    private func drawFigure(
        context: GraphicsContext,
        cx: Double,
        cy: Double,
        t: Double
    ) {
        let purple = Color.appLime
        let green  = Color.appGood

        switch exercise {
        case .squat:         drawSquat(context, cx, cy, t, purple, green)
        case .pushUp:        drawPushUp(context, cx, cy, t, purple, green)
        case .plank:         drawPlank(context, cx, cy, purple, green)
        case .shoulderPress: drawPress(context, cx, cy, t, purple, green)
        case .deadlift:      drawDeadlift(context, cx, cy, t, purple, green)
        case .lunge:           drawLunge(context, cx, cy, t, purple, green)
        case .gluteBridge:     drawGluteBridge(context, cx, cy, t, purple, green)
        case .mountainClimber: drawMountainClimber(context, cx, cy, t, purple, green)
        case .highKnees:       drawHighKnees(context, cx, cy, t, purple)
        case .general:         drawWalk(context, cx, cy, t, purple)
        }
    }

    private func drawSquat(
        _ ctx: GraphicsContext,
        _ cx: Double, _ cy: Double,
        _ t: Double,
        _ c: Color, _ a: Color
    ) {
        let drop = t * 28
        circle(ctx, center: CGPoint(x: cx, y: cy - 75), radius: 9, color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-66),
             to: CGPoint(x: cx - drop*0.3, y: cy-20+drop*0.4), color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-55),
             to: CGPoint(x: cx-20, y: cy-28+drop*0.3), color: a)
        line(ctx, from: CGPoint(x: cx, y: cy-55),
             to: CGPoint(x: cx+20, y: cy-28+drop*0.3), color: a)
        line(ctx, from: CGPoint(x: cx-drop*0.3, y: cy-20+drop*0.4),
             to: CGPoint(x: cx-18-drop*0.3, y: cy+35+drop*0.3), color: c)
        line(ctx, from: CGPoint(x: cx-18-drop*0.3, y: cy+35+drop*0.3),
             to: CGPoint(x: cx-14-drop*0.2, y: cy+75), color: c)
        line(ctx, from: CGPoint(x: cx-drop*0.3, y: cy-20+drop*0.4),
             to: CGPoint(x: cx+18+drop*0.3, y: cy+35+drop*0.3), color: c)
        line(ctx, from: CGPoint(x: cx+18+drop*0.3, y: cy+35+drop*0.3),
             to: CGPoint(x: cx+14+drop*0.2, y: cy+75), color: c)
    }

    private func drawPushUp(
        _ ctx: GraphicsContext,
        _ cx: Double, _ cy: Double,
        _ t: Double,
        _ c: Color, _ a: Color
    ) {
        let drop = t * 20
        let oy: Double = 20
        circle(ctx, center: CGPoint(x: cx+45, y: cy-drop-12+oy), radius: 9, color: c)
        line(ctx, from: CGPoint(x: cx+45, y: cy-drop-3+oy),
             to: CGPoint(x: cx-45, y: cy+10+oy), color: c)
        line(ctx, from: CGPoint(x: cx+22, y: cy-drop+4+oy),
             to: CGPoint(x: cx+22, y: cy+28+oy), color: a)
        line(ctx, from: CGPoint(x: cx-18, y: cy+3+oy),
             to: CGPoint(x: cx-18, y: cy+28+oy), color: a)
        line(ctx, from: CGPoint(x: cx-45, y: cy+10+oy),
             to: CGPoint(x: cx-65, y: cy+28+oy), color: c)
    }

    private func drawPlank(
        _ ctx: GraphicsContext,
        _ cx: Double, _ cy: Double,
        _ c: Color, _ a: Color
    ) {
        let oy: Double = 10
        circle(ctx, center: CGPoint(x: cx+48, y: cy-18+oy), radius: 9, color: c)
        line(ctx, from: CGPoint(x: cx+48, y: cy-9+oy),
             to: CGPoint(x: cx-50, y: cy+6+oy), color: c)
        line(ctx, from: CGPoint(x: cx+25, y: cy+2+oy),
             to: CGPoint(x: cx+20, y: cy+26+oy), color: a)
        line(ctx, from: CGPoint(x: cx-8, y: cy+5+oy),
             to: CGPoint(x: cx-14, y: cy+26+oy), color: a)
        line(ctx, from: CGPoint(x: cx-50, y: cy+6+oy),
             to: CGPoint(x: cx-70, y: cy+26+oy), color: c)
    }

    private func drawPress(
        _ ctx: GraphicsContext,
        _ cx: Double, _ cy: Double,
        _ t: Double,
        _ c: Color, _ a: Color
    ) {
        let raise = t * 32
        circle(ctx, center: CGPoint(x: cx, y: cy-78), radius: 9, color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-69),
             to: CGPoint(x: cx, y: cy-12), color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-55),
             to: CGPoint(x: cx-18, y: cy-32-raise*0.3), color: a)
        line(ctx, from: CGPoint(x: cx-18, y: cy-32-raise*0.3),
             to: CGPoint(x: cx-22, y: cy-58-raise), color: a)
        line(ctx, from: CGPoint(x: cx, y: cy-55),
             to: CGPoint(x: cx+18, y: cy-32-raise*0.3), color: a)
        line(ctx, from: CGPoint(x: cx+18, y: cy-32-raise*0.3),
             to: CGPoint(x: cx+22, y: cy-58-raise), color: a)
        line(ctx, from: CGPoint(x: cx-36, y: cy-58-raise),
             to: CGPoint(x: cx+36, y: cy-58-raise), color: c, width: 4)
        line(ctx, from: CGPoint(x: cx, y: cy-12),
             to: CGPoint(x: cx-16, y: cy+38), color: c)
        line(ctx, from: CGPoint(x: cx-16, y: cy+38),
             to: CGPoint(x: cx-16, y: cy+78), color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-12),
             to: CGPoint(x: cx+16, y: cy+38), color: c)
        line(ctx, from: CGPoint(x: cx+16, y: cy+38),
             to: CGPoint(x: cx+16, y: cy+78), color: c)
    }

    private func drawDeadlift(
        _ ctx: GraphicsContext,
        _ cx: Double, _ cy: Double,
        _ t: Double,
        _ c: Color, _ a: Color
    ) {
        let hinge = t * 38
        let headX = cx + hinge * 0.2
        let headY = cy - 75 + hinge * 0.6
        circle(ctx, center: CGPoint(x: headX, y: headY), radius: 9, color: c)
        line(ctx, from: CGPoint(x: headX, y: headY+9),
             to: CGPoint(x: cx-hinge*0.4, y: cy-10+hinge*0.3), color: c)
        line(ctx, from: CGPoint(x: headX, y: headY+22),
             to: CGPoint(x: cx-14+hinge*0.2, y: cy+18+hinge*0.2), color: a)
        line(ctx, from: CGPoint(x: headX, y: headY+22),
             to: CGPoint(x: cx+14-hinge*0.1, y: cy+18+hinge*0.2), color: a)
        line(ctx, from: CGPoint(x: cx-50, y: cy+78),
             to: CGPoint(x: cx+50, y: cy+78), color: Color.appLime, width: 5)
        line(ctx, from: CGPoint(x: cx-hinge*0.4, y: cy-10+hinge*0.3),
             to: CGPoint(x: cx-20, y: cy+40), color: c)
        line(ctx, from: CGPoint(x: cx-20, y: cy+40),
             to: CGPoint(x: cx-18, y: cy+78), color: c)
        line(ctx, from: CGPoint(x: cx-hinge*0.4, y: cy-10+hinge*0.3),
             to: CGPoint(x: cx+20, y: cy+40), color: c)
        line(ctx, from: CGPoint(x: cx+20, y: cy+40),
             to: CGPoint(x: cx+18, y: cy+78), color: c)
    }

    private func drawWalk(
        _ ctx: GraphicsContext,
        _ cx: Double, _ cy: Double,
        _ t: Double,
        _ c: Color
    ) {
        let swing = t * 18
        circle(ctx, center: CGPoint(x: cx, y: cy-75), radius: 9, color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-66),
             to: CGPoint(x: cx, y: cy-12), color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-52),
             to: CGPoint(x: cx-18-swing*0.3, y: cy-22), color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-52),
             to: CGPoint(x: cx+18+swing*0.3, y: cy-22), color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-12),
             to: CGPoint(x: cx-swing*0.5, y: cy+35), color: c)
        line(ctx, from: CGPoint(x: cx-swing*0.5, y: cy+35),
             to: CGPoint(x: cx-swing*0.3, y: cy+78), color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-12),
             to: CGPoint(x: cx+swing*0.5, y: cy+35), color: c)
        line(ctx, from: CGPoint(x: cx+swing*0.5, y: cy+35),
             to: CGPoint(x: cx+swing*0.3, y: cy+78), color: c)
    }
    private func drawLunge(
        _ ctx: GraphicsContext,
        _ cx: Double, _ cy: Double,
        _ t: Double,
        _ c: Color, _ a: Color
    ) {
        let drop = t * 30
        circle(ctx, center: CGPoint(x: cx, y: cy-75), radius: 9, color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-66), to: CGPoint(x: cx, y: cy-12), color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-50), to: CGPoint(x: cx-20, y: cy-25), color: a)
        line(ctx, from: CGPoint(x: cx, y: cy-50), to: CGPoint(x: cx+20, y: cy-25), color: a)
        // front leg
        line(ctx, from: CGPoint(x: cx, y: cy-12), to: CGPoint(x: cx+22, y: cy+28), color: c)
        line(ctx, from: CGPoint(x: cx+22, y: cy+28), to: CGPoint(x: cx+30, y: cy+78), color: c)
        // back leg (drops with t)
        line(ctx, from: CGPoint(x: cx, y: cy-12), to: CGPoint(x: cx-20, y: cy+28+drop*0.4), color: c)
        line(ctx, from: CGPoint(x: cx-20, y: cy+28+drop*0.4), to: CGPoint(x: cx-30, y: cy+78), color: c)
    }

    private func drawGluteBridge(
        _ ctx: GraphicsContext,
        _ cx: Double, _ cy: Double,
        _ t: Double,
        _ c: Color, _ a: Color
    ) {
        let lift = t * 28
        let oy: Double = 20
        circle(ctx, center: CGPoint(x: cx-52, y: cy-10+oy), radius: 9, color: c)
        line(ctx, from: CGPoint(x: cx-52, y: cy-1+oy), to: CGPoint(x: cx-4, y: cy-10-lift+oy), color: c)
        line(ctx, from: CGPoint(x: cx-28, y: cy-6+oy), to: CGPoint(x: cx-32, y: cy+24+oy), color: a)
        line(ctx, from: CGPoint(x: cx-4, y: cy-10-lift+oy), to: CGPoint(x: cx+18, y: cy+20+oy), color: c)
        line(ctx, from: CGPoint(x: cx+18, y: cy+20+oy), to: CGPoint(x: cx+18, y: cy+55+oy), color: c)
    }

    private func drawMountainClimber(
        _ ctx: GraphicsContext,
        _ cx: Double, _ cy: Double,
        _ t: Double,
        _ c: Color, _ a: Color
    ) {
        let drive = t * 30
        let oy: Double = 10
        circle(ctx, center: CGPoint(x: cx+52, y: cy-18+oy), radius: 9, color: c)
        line(ctx, from: CGPoint(x: cx+52, y: cy-9+oy), to: CGPoint(x: cx-52, y: cy+6+oy), color: c)
        line(ctx, from: CGPoint(x: cx+26, y: cy+1+oy), to: CGPoint(x: cx+22, y: cy+26+oy), color: a)
        line(ctx, from: CGPoint(x: cx-6, y: cy+4+oy), to: CGPoint(x: cx-12, y: cy+26+oy), color: a)
        // driving knee
        line(ctx, from: CGPoint(x: cx-52, y: cy+6+oy), to: CGPoint(x: cx-52+drive, y: cy+30-drive*0.4+oy), color: c)
        line(ctx, from: CGPoint(x: cx-52+drive, y: cy+30-drive*0.4+oy), to: CGPoint(x: cx-52+drive+10, y: cy+60+oy), color: c)
        // trailing leg
        line(ctx, from: CGPoint(x: cx-52, y: cy+6+oy), to: CGPoint(x: cx-52-8, y: cy+44+oy), color: c)
        line(ctx, from: CGPoint(x: cx-52-8, y: cy+44+oy), to: CGPoint(x: cx-52-4, y: cy+78+oy), color: c)
    }

    private func drawHighKnees(
        _ ctx: GraphicsContext,
        _ cx: Double, _ cy: Double,
        _ t: Double,
        _ c: Color
    ) {
        let kneeUp = t * 35
        circle(ctx, center: CGPoint(x: cx, y: cy-75), radius: 9, color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-66), to: CGPoint(x: cx, y: cy-12), color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-50), to: CGPoint(x: cx-22, y: cy-30+kneeUp*0.3), color: c)
        line(ctx, from: CGPoint(x: cx, y: cy-50), to: CGPoint(x: cx+22, y: cy-30-kneeUp*0.3), color: c)
        // lifted knee
        line(ctx, from: CGPoint(x: cx, y: cy-12), to: CGPoint(x: cx-10, y: cy+8-kneeUp*0.7), color: c)
        line(ctx, from: CGPoint(x: cx-10, y: cy+8-kneeUp*0.7), to: CGPoint(x: cx-14, y: cy+30), color: c)
        // standing leg
        line(ctx, from: CGPoint(x: cx, y: cy-12), to: CGPoint(x: cx+10, y: cy+38), color: c)
        line(ctx, from: CGPoint(x: cx+10, y: cy+38), to: CGPoint(x: cx+10, y: cy+78), color: c)
    }

}
