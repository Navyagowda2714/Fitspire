//
//  PoseOverlayView.swift
//  Fitspire
//
//  Created by Navyashree Byregowda on 01/06/2026.
//


import SwiftUI
import Vision

struct PoseOverlayView: View {
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let size: CGSize

    private let connections: [(VNHumanBodyPoseObservation.JointName,
                                VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
        (.neck, .leftShoulder), (.neck, .rightShoulder)
    ]

    var body: some View {
        Canvas { ctx, _ in
            // Draw bones
            for (a, b) in connections {
                guard let pa = joints[a], let pb = joints[b] else { continue }
                var path = Path()
                path.move(to: scaled(pa))
                path.addLine(to: scaled(pb))
                ctx.stroke(path, with: .color(Color(hex: "#00E5FF").opacity(0.8)), lineWidth: 2)
            }
            // Draw joints
            for (_, pt) in joints {
                let s = scaled(pt)
                let rect = CGRect(x: s.x - 4, y: s.y - 4, width: 8, height: 8)
                ctx.fill(Path(ellipseIn: rect), with: .color(.white))
            }
        }
        .allowsHitTesting(false)
    }

    private func scaled(_ pt: CGPoint) -> CGPoint {
        CGPoint(x: pt.x * size.width, y: pt.y * size.height)
    }
}