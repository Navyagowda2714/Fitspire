//
//  BSkelotonOverlayView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 01/05/2026.
//


import SwiftUI
import Vision

struct SkeletonOverlayView: View {
    let detectedBody: DetectedBody
    let size: CGSize

    private let connections: [(VNHumanBodyPoseObservation.JointName,
                                VNHumanBodyPoseObservation.JointName)] = [
        (.nose, .neck),
        (.neck, .leftShoulder),
        (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.neck, .root),
        (.root, .leftHip),
        (.root, .rightHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle)
    ]

    var body: some View {
        Canvas { context, canvasSize in
            let joints = detectedBody.joints

            for (startJoint, endJoint) in connections {
                guard
                    let start = joints[startJoint],
                    let end = joints[endJoint]
                else { continue }

                let startPoint = CGPoint(
                    x: start.x * canvasSize.width,
                    y: start.y * canvasSize.height
                )
                let endPoint = CGPoint(
                    x: end.x * canvasSize.width,
                    y: end.y * canvasSize.height
                )

                var path = Path()
                path.move(to: startPoint)
                path.addLine(to: endPoint)

                context.stroke(
                    path,
                    with: .color(.green.opacity(0.85)),
                    lineWidth: 2.5
                )
            }

            for (_, point) in joints {
                let screenPoint = CGPoint(
                    x: point.x * canvasSize.width,
                    y: point.y * canvasSize.height
                )
                let dotRect = CGRect(
                    x: screenPoint.x - 5,
                    y: screenPoint.y - 5,
                    width: 10,
                    height: 10
                )
                context.fill(
                    Path(ellipseIn: dotRect),
                    with: .color(.green)
                )
                context.stroke(
                    Path(ellipseIn: dotRect),
                    with: .color(.white.opacity(0.8)),
                    lineWidth: 1
                )
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
