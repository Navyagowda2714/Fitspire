//
//  FormRuleEngine.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 01/05/2026.
//
//
//  FormRuleEngine.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

import Foundation
import Vision
import CoreGraphics

final class FormRuleEngine: Sendable {

    func evaluate(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
        exercise: ExerciseType
    ) -> [FormAlert] {
        switch exercise {
        case .squat:          return evaluateSquat(joints: joints)
        case .plank:          return evaluatePlank(joints: joints)
        case .pushUp:         return evaluatePushUp(joints: joints)
        case .shoulderPress:  return evaluateShoulderPress(joints: joints)
        case .deadlift:       return evaluateDeadlift(joints: joints)
        case .lunge:          return evaluateLunge(joints: joints)
        case .gluteBridge:    return evaluateGluteBridge(joints: joints)
        case .mountainClimber: return evaluateMountainClimber(joints: joints)
        case .highKnees:      return evaluateHighKnees(joints: joints)
        case .general:        return evaluateGeneral(joints: joints)
        }
    }

    // MARK: - Squat

    private func evaluateSquat(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> [FormAlert] {
        var alerts: [FormAlert] = []

        // Knee valgus — left
        if let leftHip   = joints[.leftHip],
           let leftKnee  = joints[.leftKnee],
           let leftAnkle = joints[.leftAnkle] {
            let deviation = abs(leftKnee.x - ((leftHip.x + leftAnkle.x) / 2))
            alerts += checkThreshold(
                value: Double(deviation),
                rule: ExerciseFormRules.squat[0],
                exercise: .squat
            )
        }

        // Knee valgus — right
        if let rightHip   = joints[.rightHip],
           let rightKnee  = joints[.rightKnee],
           let rightAnkle = joints[.rightAnkle] {
            let deviation = abs(rightKnee.x - ((rightHip.x + rightAnkle.x) / 2))
            alerts += checkThreshold(
                value: Double(deviation),
                rule: ExerciseFormRules.squat[1],
                exercise: .squat
            )
        }

        // Forward lean
        if let nose = joints[.nose],
           let root = joints[.root] {
            let lean = abs(nose.x - root.x)
            alerts += checkThreshold(
                value: Double(lean),
                rule: ExerciseFormRules.squat[2],
                exercise: .squat
            )
        }

        return alerts
    }

    // MARK: - Plank

    private func evaluatePlank(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> [FormAlert] {
        var alerts: [FormAlert] = []

        if let leftShoulder  = joints[.leftShoulder],
           let leftHip       = joints[.leftHip],
           let leftAnkle     = joints[.leftAnkle] {

            // Hip sag
            let expectedHipY = (leftShoulder.y + leftAnkle.y) / 2
            let hipSag       = max(0, Double(leftHip.y - expectedHipY))
            alerts += checkThreshold(
                value: hipSag,
                rule: ExerciseFormRules.plank[0],
                exercise: .plank
            )

            // Hip pike
            let hipPike = max(0, Double(expectedHipY - leftHip.y))
            alerts += checkThreshold(
                value: hipPike,
                rule: ExerciseFormRules.plank[1],
                exercise: .plank
            )
        }

        // Neck position
        if let nose = joints[.nose],
           let neck = joints[.neck] {
            let deviation = abs(nose.x - neck.x)
            alerts += checkThreshold(
                value: Double(deviation),
                rule: ExerciseFormRules.plank[2],
                exercise: .plank
            )
        }

        return alerts
    }

    // MARK: - Push-up

    private func evaluatePushUp(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> [FormAlert] {
        var alerts: [FormAlert] = []

        // Elbow flare
        if let leftShoulder = joints[.leftShoulder],
           let leftElbow    = joints[.leftElbow],
           let leftWrist    = joints[.leftWrist] {
            let angle = AngleCalculator.angle(
                pointA: leftShoulder,
                pointB: leftElbow,
                pointC: leftWrist
            )
            alerts += checkThreshold(
                value: angle,
                rule: ExerciseFormRules.pushUp[0],
                exercise: .pushUp
            )
        }

        // Hip drop — same logic as plank
        if let leftShoulder = joints[.leftShoulder],
           let leftHip      = joints[.leftHip],
           let leftAnkle    = joints[.leftAnkle] {
            let expectedHipY = (leftShoulder.y + leftAnkle.y) / 2
            let hipDrop      = max(0, Double(leftHip.y - expectedHipY))
            alerts += checkThreshold(
                value: hipDrop,
                rule: ExerciseFormRules.pushUp[1],
                exercise: .pushUp
            )
        }

        return alerts
    }

    // MARK: - Shoulder press

    private func evaluateShoulderPress(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> [FormAlert] {
        var alerts: [FormAlert] = []

        // Back arch
        if let neck = joints[.neck],
           let root = joints[.root] {
            let arch = abs(neck.x - root.x)
            alerts += checkThreshold(
                value: Double(arch),
                rule: ExerciseFormRules.shoulderPress[0],
                exercise: .shoulderPress
            )
        }

        // Shoulder imbalance
        if let leftShoulder  = joints[.leftShoulder],
           let rightShoulder = joints[.rightShoulder] {
            let diff = abs(leftShoulder.y - rightShoulder.y)
            alerts += checkThreshold(
                value: Double(diff),
                rule: ExerciseFormRules.shoulderPress[1],
                exercise: .shoulderPress
            )
        }

        return alerts
    }

    // MARK: - Deadlift

    private func evaluateDeadlift(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> [FormAlert] {
        var alerts: [FormAlert] = []

        // Spine rounding
        if let neck = joints[.neck],
           let root = joints[.root] {
            let rounding = abs(neck.x - root.x)
            alerts += checkThreshold(
                value: Double(rounding),
                rule: ExerciseFormRules.deadlift[0],
                exercise: .deadlift
            )
        }

        // Knee cave
        if let leftHip   = joints[.leftHip],
           let leftKnee  = joints[.leftKnee],
           let leftAnkle = joints[.leftAnkle] {
            let deviation = abs(leftKnee.x - ((leftHip.x + leftAnkle.x) / 2))
            alerts += checkThreshold(
                value: Double(deviation),
                rule: ExerciseFormRules.deadlift[1],
                exercise: .deadlift
            )
        }

        return alerts
    }

    // MARK: - General posture

    private func evaluateGeneral(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> [FormAlert] {
        var alerts: [FormAlert] = []

        if let leftShoulder  = joints[.leftShoulder],
           let rightShoulder = joints[.rightShoulder] {
            let diff = abs(leftShoulder.y - rightShoulder.y)
            if diff > 0.06 {
                alerts.append(FormAlert(
                    severity: .warning,
                    message: "Uneven shoulder height",
                    correction: "Level your shoulders before continuing.",
                    affectedJoint: "Shoulders",
                    exercise: .general
                ))
            }
        }

        return alerts
    }

    // MARK: - Threshold checker

    private func checkThreshold(
        value: Double,
        rule: FormThreshold,
        exercise: ExerciseType
    ) -> [FormAlert] {
        if value >= rule.dangerValue {
            return [FormAlert(
                severity: .danger,
                message: rule.message,
                correction: rule.correction,
                affectedJoint: rule.affectedJoint,
                exercise: exercise
            )]
        } else if value >= rule.warningValue {
            return [FormAlert(
                severity: .warning,
                message: rule.message,
                correction: rule.correction,
                affectedJoint: rule.affectedJoint,
                exercise: exercise
            )]
        }
        return []
    }
    // MARK: - Lunge

    private func evaluateLunge(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> [FormAlert] {
        var alerts: [FormAlert] = []
        // Use best-confidence side
        let useLeft = (joints[.leftHip] != nil && joints[.leftKnee] != nil && joints[.leftAnkle] != nil)
        let hpK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip   : .rightHip
        let knK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee  : .rightKnee
        let anK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle : .rightAnkle

        if let _ = joints[hpK], let kn = joints[knK], let an = joints[anK] {
            // Knee over toe: knee x vs ankle x
            let kneeOverToe = Double(kn.x - an.x)
            alerts += checkThreshold(value: abs(kneeOverToe), rule: ExerciseFormRules.lunge[0], exercise: .lunge)
        }
        if let neck = joints[.neck], let root = joints[.root] {
            let torsoLean = abs(neck.x - root.x)
            alerts += checkThreshold(value: Double(torsoLean), rule: ExerciseFormRules.lunge[1], exercise: .lunge)
        }
        return alerts
    }

    // MARK: - Glute Bridge

    private func evaluateGluteBridge(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> [FormAlert] {
        var alerts: [FormAlert] = []
        if let ls = joints[.leftShoulder], let lh = joints[.leftHip], let la = joints[.leftAnkle] {
            let expected = (ls.y + la.y) / 2
            let sag = max(0, Double(lh.y - expected))   // hip below line = not driven up
            alerts += checkThreshold(value: sag, rule: ExerciseFormRules.gluteBridge[0], exercise: .gluteBridge)
        }
        if let lk = joints[.leftKnee], let rk = joints[.rightKnee] {
            let drift = abs(lk.x - rk.x)
            alerts += checkThreshold(value: Double(drift), rule: ExerciseFormRules.gluteBridge[1], exercise: .gluteBridge)
        }
        return alerts
    }

    // MARK: - Mountain Climber

    private func evaluateMountainClimber(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> [FormAlert] {
        var alerts: [FormAlert] = []
        if let ls = joints[.leftShoulder], let lh = joints[.leftHip], let la = joints[.leftAnkle] {
            let expectedHipY = (ls.y + la.y) / 2
            let hipPike = max(0, Double(expectedHipY - lh.y))  // hip above line = too high
            let hipSag  = max(0, Double(lh.y - expectedHipY))
            alerts += checkThreshold(value: hipPike, rule: ExerciseFormRules.mountainClimber[0], exercise: .mountainClimber)
            alerts += checkThreshold(value: hipSag,  rule: ExerciseFormRules.mountainClimber[1], exercise: .mountainClimber)
        }
        return alerts
    }

    // MARK: - High Knees

    private func evaluateHighKnees(
        joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    ) -> [FormAlert] {
        var alerts: [FormAlert] = []
        let useLeft = (joints[.leftKnee] != nil && joints[.leftHip] != nil)
        let hpK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip  : .rightHip
        let knK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee : .rightKnee

        if let hp = joints[hpK], let kn = joints[knK] {
            // Knee should be at or above hip (higher y value in Vision = lower on screen)
            let belowHip = max(0, Double(hp.y - kn.y))  // positive = knee below hip
            alerts += checkThreshold(value: belowHip, rule: ExerciseFormRules.highKnees[0], exercise: .highKnees)
        }
        if let neck = joints[.neck], let root = joints[.root] {
            let lean = abs(neck.x - root.x)
            alerts += checkThreshold(value: Double(lean), rule: ExerciseFormRules.highKnees[1], exercise: .highKnees)
        }
        return alerts
    }


}
