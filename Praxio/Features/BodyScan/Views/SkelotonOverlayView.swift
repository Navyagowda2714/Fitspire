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
    var activeAlerts: [FormAlert] = []   // ← NEW: pass from LivePoseViewModel

   
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

    // MARK: - Compute which joints are flagged

    /// Maps alert affectedJoint strings to the Vision joint names they represent.
    private var alertedJoints: Set<VNHumanBodyPoseObservation.JointName> {
        var result = Set<VNHumanBodyPoseObservation.JointName>()
        for alert in activeAlerts {
            switch alert.affectedJoint {
            case "Hips":
                result.formUnion([.leftHip, .rightHip, .root])
            case "Neck":
                result.formUnion([.neck, .nose, .leftEar, .rightEar])
            case "Lower Back", "Spine":
                result.formUnion([.root, .neck])
            case "Left Knee":
                result.insert(.leftKnee)
            case "Right Knee":
                result.insert(.rightKnee)
            case "Knees":
                result.formUnion([.leftKnee, .rightKnee])
            case "Elbows", "Arms":
                result.formUnion([.leftElbow, .rightElbow, .leftWrist, .rightWrist])
            case "Shoulders":
                result.formUnion([.leftShoulder, .rightShoulder])
            default:
                break
            }
        }
        return result
    }

    /// True if any active alert is at danger severity
    private var hasDanger: Bool {
        activeAlerts.contains { $0.severity == .danger }
    }

    private func isJointAlerting(_ joint: VNHumanBodyPoseObservation.JointName) -> Bool {
        alertedJoints.contains(joint)
    }

    private func isConnectionAlerting(
        _ a: VNHumanBodyPoseObservation.JointName,
        _ b: VNHumanBodyPoseObservation.JointName
    ) -> Bool {
        alertedJoints.contains(a) || alertedJoints.contains(b)
    }

    // MARK: - Body

    var body: some View {
        Canvas { context, canvasSize in
            let joints = detectedBody.joints

            // Draw bones (connections)
            for (startJoint, endJoint) in connections {
                guard
                    let start = joints[startJoint],
                    let end   = joints[endJoint]
                else { continue }

                let startPt = CGPoint(x: start.x * canvasSize.width,  y: start.y * canvasSize.height)
                let endPt   = CGPoint(x: end.x   * canvasSize.width,  y: end.y   * canvasSize.height)

                var path = Path()
                path.move(to: startPt)
                path.addLine(to: endPt)

                let isAlerting = isConnectionAlerting(startJoint, endJoint)
                let boneColor: Color = isAlerting
                    ? Color(red: 1, green: 0.2, blue: 0.2).opacity(0.9)    // 🔴 bad
                    : Color(red: 0.2, green: 1, blue: 0.5).opacity(0.85)   // 🟢 good

                // Draw a faint glow for red bones
                if isAlerting {
                    var glowPath = Path()
                    glowPath.move(to: startPt)
                    glowPath.addLine(to: endPt)
                    context.stroke(glowPath,
                                   with: .color(Color.red.opacity(0.25)),
                                   lineWidth: 7)
                }

                context.stroke(path, with: .color(boneColor), lineWidth: 2.5)
            }

            // Draw joints (dots)
            for (jointName, point) in joints {
                let screenPt = CGPoint(x: point.x * canvasSize.width, y: point.y * canvasSize.height)
                let isAlerting = isJointAlerting(jointName)

                let dotRadius: CGFloat = isAlerting ? 7 : 5
                let dotColor: Color = isAlerting
                    ? Color(red: 1, green: 0.15, blue: 0.15)    // 🔴 bad joint
                    : Color(red: 0, green: 0.95, blue: 0.4)     // 🟢 good joint

                let dotRect = CGRect(x: screenPt.x - dotRadius,
                                     y: screenPt.y - dotRadius,
                                     width: dotRadius * 2,
                                     height: dotRadius * 2)

                // Glow ring for alerted joints
                if isAlerting {
                    let glowRect = dotRect.insetBy(dx: -4, dy: -4)
                    context.fill(Path(ellipseIn: glowRect),
                                 with: .color(Color.red.opacity(0.20)))
                }

                context.fill(Path(ellipseIn: dotRect), with: .color(dotColor))
                context.stroke(Path(ellipseIn: dotRect),
                               with: .color(Color.white.opacity(0.7)),
                               lineWidth: 1.2)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
