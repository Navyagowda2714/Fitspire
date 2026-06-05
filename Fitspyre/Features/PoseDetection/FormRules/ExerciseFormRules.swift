//
//  ExerciseFormRules.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

//
//  ExerciseFormRules.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

import Foundation

struct FormThreshold {
    let name: String
    let warningValue: Double
    let dangerValue: Double
    let message: String
    let correction: String
    let affectedJoint: String
}

struct ExerciseFormRules {

    // MARK: - Squat rules
    static let squat: [FormThreshold] = [
        FormThreshold(
            name: "knee_valgus_left",
            warningValue: 0.04,
            dangerValue: 0.08,
            message: "Left knee caving inward",
            correction: "Push your left knee out to align with your toes.",
            affectedJoint: "Left Knee"
        ),
        FormThreshold(
            name: "knee_valgus_right",
            warningValue: 0.04,
            dangerValue: 0.08,
            message: "Right knee caving inward",
            correction: "Push your right knee out to align with your toes.",
            affectedJoint: "Right Knee"
        ),
        FormThreshold(
            name: "forward_lean",
            warningValue: 0.08,
            dangerValue: 0.15,
            message: "Excessive forward lean",
            correction: "Keep your chest up and torso more upright.",
            affectedJoint: "Spine"
        ),
        FormThreshold(
            name: "back_angle",
            warningValue: 45.0,
            dangerValue: 60.0,
            message: "Back bending too far forward",
            correction: "Keep your back neutral. Reduce load if needed.",
            affectedJoint: "Lower Back"
        )
    ]

    // MARK: - Plank rules
    static let plank: [FormThreshold] = [
        FormThreshold(
            name: "hip_sag",
            warningValue: 0.05,
            dangerValue: 0.10,
            message: "Hips dropping too low",
            correction: "Lift your hips to form a straight line from head to heel.",
            affectedJoint: "Hips"
        ),
        FormThreshold(
            name: "hip_pike",
            warningValue: 0.05,
            dangerValue: 0.10,
            message: "Hips raised too high",
            correction: "Lower your hips to align with your shoulders and ankles.",
            affectedJoint: "Hips"
        ),
        FormThreshold(
            name: "neck_extension",
            warningValue: 0.04,
            dangerValue: 0.08,
            message: "Neck out of alignment",
            correction: "Keep your chin neutral and gaze toward the floor.",
            affectedJoint: "Neck"
        )
    ]

    // MARK: - Push-up rules
    static let pushUp: [FormThreshold] = [
        FormThreshold(
            name: "elbow_flare",
            warningValue: 50.0,
            dangerValue: 70.0,
            message: "Elbows flaring too wide",
            correction: "Tuck your elbows closer to your body at roughly 45 degrees.",
            affectedJoint: "Elbows"
        ),
        FormThreshold(
            name: "hip_drop",
            warningValue: 0.05,
            dangerValue: 0.10,
            message: "Hips sagging during push-up",
            correction: "Engage your core and keep your body in a straight line.",
            affectedJoint: "Hips"
        ),
        FormThreshold(
            name: "head_position",
            warningValue: 0.06,
            dangerValue: 0.12,
            message: "Head position out of neutral",
            correction: "Keep your head in line with your spine. Look at the floor.",
            affectedJoint: "Neck"
        )
    ]

    // MARK: - Shoulder press rules
    static let shoulderPress: [FormThreshold] = [
        FormThreshold(
            name: "back_arch",
            warningValue: 0.06,
            dangerValue: 0.12,
            message: "Excessive lower back arch",
            correction: "Brace your core and keep your lower back neutral.",
            affectedJoint: "Lower Back"
        ),
        FormThreshold(
            name: "shoulder_imbalance",
            warningValue: 0.04,
            dangerValue: 0.08,
            message: "Uneven shoulder height",
            correction: "Keep both arms at equal height throughout the press.",
            affectedJoint: "Shoulders"
        )
    ]

    // MARK: - Deadlift rules
    static let deadlift: [FormThreshold] = [
        FormThreshold(
            name: "spine_rounding",
            warningValue: 0.06,
            dangerValue: 0.12,
            message: "Spine rounding detected",
            correction: "Keep your back flat. Hinge at the hips and brace your core.",
            affectedJoint: "Spine"
        ),
        FormThreshold(
            name: "knee_cave",
            warningValue: 0.04,
            dangerValue: 0.08,
            message: "Knees caving during deadlift",
            correction: "Push your knees out in line with your toes as you lift.",
            affectedJoint: "Knees"
        ),
        FormThreshold(
            name: "bar_distance",
            warningValue: 0.08,
            dangerValue: 0.15,
            message: "Bar drifting away from body",
            correction: "Keep the bar close to your body throughout the lift.",
            affectedJoint: "Arms"
        )
    ]

    // MARK: - Lunge rules
    static let lunge: [FormThreshold] = [
        FormThreshold(
            name: "knee_over_toe",
            warningValue: 0.12,
            dangerValue: 0.20,
            message: "Front knee too far forward",
            correction: "Step back further so your shin stays vertical.",
            affectedJoint: "Left Knee"
        ),
        FormThreshold(
            name: "torso_lean",
            warningValue: 0.08,
            dangerValue: 0.14,
            message: "Torso leaning too far forward",
            correction: "Keep your chest up and torso upright throughout the lunge.",
            affectedJoint: "Spine"
        )
    ]

    // MARK: - Glute bridge rules
    static let gluteBridge: [FormThreshold] = [
        FormThreshold(
            name: "hip_not_extended",
            warningValue: 0.06,
            dangerValue: 0.12,
            message: "Hips not fully driven up",
            correction: "Squeeze your glutes and drive hips until body is in a straight line.",
            affectedJoint: "Hips"
        ),
        FormThreshold(
            name: "knee_drift",
            warningValue: 0.05,
            dangerValue: 0.10,
            message: "Knees drifting apart",
            correction: "Keep your knees hip-width apart throughout the movement.",
            affectedJoint: "Knees"
        )
    ]

    // MARK: - Mountain climber rules
    static let mountainClimber: [FormThreshold] = [
        FormThreshold(
            name: "hip_too_high",
            warningValue: 0.06,
            dangerValue: 0.12,
            message: "Hips raised too high",
            correction: "Lower your hips — keep body in a straight plank line.",
            affectedJoint: "Hips"
        ),
        FormThreshold(
            name: "hip_sag",
            warningValue: 0.05,
            dangerValue: 0.10,
            message: "Hips sagging during climbers",
            correction: "Engage your core to keep hips level.",
            affectedJoint: "Hips"
        )
    ]

    // MARK: - High knees rules
    static let highKnees: [FormThreshold] = [
        FormThreshold(
            name: "knee_height",
            warningValue: 0.04,
            dangerValue: 0.08,
            message: "Knees not reaching hip height",
            correction: "Drive each knee up to at least hip level on every rep.",
            affectedJoint: "Knees"
        ),
        FormThreshold(
            name: "back_lean",
            warningValue: 0.06,
            dangerValue: 0.12,
            message: "Leaning back too much",
            correction: "Keep your torso upright — don't lean back as knees come up.",
            affectedJoint: "Spine"
        )
    ]
}
