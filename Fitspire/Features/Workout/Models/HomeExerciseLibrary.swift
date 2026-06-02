

//
//  HomeExerciseLibrary.swift
//  FitnessAI
//
//  Complete home/bodyweight exercise library.
//  Each exercise knows: targets, form cues, mistakes+injuries, difficulty,
//  and whether AI pose detection is available (only squat/plank/pushUp have it).
//
//
//  HomeExerciseLibrary.swift
//  FitnessAI
//
//  Complete home/bodyweight exercise library.
//  Each exercise knows: targets, form cues, mistakes+injuries, difficulty,
//  and whether AI pose detection is available (only squat/plank/pushUp have it).
//

import Foundation

// MARK: - Model

struct HomeExercise: Identifiable {
    let id          = UUID()
    let name:         String
    let icon:         String          // SF Symbol
    let category:     Category
    let targetMuscles: String
    let primaryMuscles: [String]
    let difficulty:   Level
    let sets:         Int
    let repsOrTime:   String          // "12 reps" or "30 sec hold"
    let restSeconds:  Int
    let calories:     Int             // approx per set
    let isBodyweight: Bool
    /// If non-nil, this exercise uses Vision AI pose detection
    let poseType:     ExerciseType?
    let formCues:     [String]        // ✅ correct form steps
    let mistakes:     [MistakeInfo]   // ❌ mistakes + injury risk
    let tips:         String          // coach tip

    enum Category: String {
        case core       = "Core"
        case upperBody  = "Upper Body"
        case lowerBody  = "Lower Body"
        case fullBody   = "Full Body"
        case cardio     = "Cardio"
    }

    enum Level: String {
        case beginner     = "Beginner"
        case intermediate = "Intermediate"
        case advanced     = "Advanced"

        var color: String {
            switch self {
            case .beginner:     return "1D9E75"
            case .intermediate: return "F5A623"
            case .advanced:     return "D85A30"
            }
        }
    }

    struct MistakeInfo: Identifiable {
        let id         = UUID()
        let mistake:   String
        let whyItHappens: String
        let injuryRisk: String
        let severity:  String   // "High" / "Moderate" / "Low"
        let fix:       String
    }
}

// MARK: - Library

struct HomeExerciseLibrary {

    /// All bodyweight exercises (no equipment required)
    static let bodyweight: [HomeExercise] = [
        plank, squat, pushUp, lunge, gluteBridge,
        mountainClimber, burpee, tricepDip, highKnees, superman
    ]

    /// Exercises available with resistance bands
    static let withBands: [HomeExercise] = bodyweight

    /// Filter based on user's equipment selection
    static func exercises(for equipment: [HomeEquipment]) -> [HomeExercise] {
        // For now all are bodyweight — expand when equipment-specific exercises added
        return bodyweight
    }

    // ── PLANK ──────────────────────────────────────────────────────────────
    static let plank = HomeExercise(
        name: "Plank",
        icon: "figure.core.training",
        category: .core,
        targetMuscles: "Core · Shoulders · Back",
        primaryMuscles: ["Rectus Abdominis", "Transverse Abdominis", "Deltoids"],
        difficulty: .beginner,
        sets: 3, repsOrTime: "30–60 sec", restSeconds: 45, calories: 4,
        isBodyweight: true,
        poseType: .plank,       // ← AI pose detection available
        formCues: [
            "Forearms flat, elbows directly under your shoulders",
            "Body forms a straight line from head to heel — no sag or pike",
            "Squeeze your glutes and abs at the same time",
            "Keep your neck neutral — gaze at a spot on the floor",
            "Breathe steadily: 3 sec in, 3 sec out"
        ],
        mistakes: [
            HomeExercise.MistakeInfo(
                mistake: "Hips sagging toward the floor",
                whyItHappens: "Core fatigue — lower back takes over",
                injuryRisk: "Lumbar disc herniation, chronic lower back strain",
                severity: "High",
                fix: "Squeeze glutes harder or drop to knees to reset"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Hips raised too high (piking)",
                whyItHappens: "Trying to avoid core work by shifting load to shoulders",
                injuryRisk: "Shoulder impingement, reduced core activation",
                severity: "Moderate",
                fix: "Lower hips until body is a straight diagonal line"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Looking up or craning neck",
                whyItHappens: "Checking form in a mirror or screen directly ahead",
                injuryRisk: "Cervical spine compression, neck strain",
                severity: "Moderate",
                fix: "Pick a spot 30 cm in front of your hands to look at"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Holding your breath",
                whyItHappens: "Gripping tension — confuses breath-hold with core bracing",
                injuryRisk: "Blood pressure spike, early failure, dizziness",
                severity: "High",
                fix: "Practice box breathing — 3 sec in, hold 1, 3 sec out"
            )
        ],
        tips: "If 30 seconds is too easy, add a shoulder tap every 5 seconds to challenge stability."
    )

    // ── SQUAT ──────────────────────────────────────────────────────────────
    static let squat = HomeExercise(
        name: "Bodyweight Squat",
        icon: "figure.strengthtraining.traditional",
        category: .lowerBody,
        targetMuscles: "Quads · Glutes · Hamstrings · Core",
        primaryMuscles: ["Quadriceps", "Gluteus Maximus", "Hamstrings"],
        difficulty: .beginner,
        sets: 3, repsOrTime: "15 reps", restSeconds: 60, calories: 6,
        isBodyweight: true,
        poseType: .squat,       // ← AI pose detection available
        formCues: [
            "Stand with feet shoulder-width apart, toes slightly turned out",
            "Drive your knees out in line with your toes — not caving inward",
            "Keep your chest up and your back straight throughout",
            "Lower until thighs are parallel to the floor (or as low as comfortable)",
            "Push through your heels to stand, squeezing glutes at the top"
        ],
        mistakes: [
            HomeExercise.MistakeInfo(
                mistake: "Knees caving inward (valgus collapse)",
                whyItHappens: "Weak glutes and hip abductors",
                injuryRisk: "ACL stress, patellofemoral pain, IT band syndrome",
                severity: "High",
                fix: "Push knees outward actively throughout — try a mini resistance band"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Heels rising off the floor",
                whyItHappens: "Tight ankle or calf muscles",
                injuryRisk: "Achilles tendon strain, knee joint overload",
                severity: "Moderate",
                fix: "Elevate heels on a folded mat or work on ankle mobility first"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Rounding the lower back at depth",
                whyItHappens: "Limited hip mobility — pelvis tilts under (butt wink)",
                injuryRisk: "Lumbar disc compression, lower back strain",
                severity: "High",
                fix: "Only squat to depth where your spine stays neutral"
            )
        ],
        tips: "Pause 1 second at the bottom of each rep to build control and eliminate momentum."
    )

    // ── PUSH-UP ────────────────────────────────────────────────────────────
    static let pushUp = HomeExercise(
        name: "Push-Up",
        icon: "figure.highintensity.intervaltraining",
        category: .upperBody,
        targetMuscles: "Chest · Triceps · Shoulders · Core",
        primaryMuscles: ["Pectoralis Major", "Triceps Brachii", "Anterior Deltoid"],
        difficulty: .beginner,
        sets: 3, repsOrTime: "10–15 reps", restSeconds: 60, calories: 7,
        isBodyweight: true,
        poseType: .pushUp,      // ← AI pose detection available
        formCues: [
            "Hands shoulder-width apart, fingers pointing forward",
            "Elbows at 45° — NOT flared out to 90°",
            "Body forms a straight line from head to heel (plank position)",
            "Lower until your chest nearly touches the floor",
            "Exhale as you push up, inhale on the way down"
        ],
        mistakes: [
            HomeExercise.MistakeInfo(
                mistake: "Elbows flaring out to 90°",
                whyItHappens: "Natural tendency — feels easier but loads the wrong muscles",
                injuryRisk: "Rotator cuff impingement, AC joint pain, elbow tendinopathy",
                severity: "High",
                fix: "Tuck elbows to roughly 45° — imagine you are trying to screw your hands into the floor"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Hips sagging during the rep",
                whyItHappens: "Core not engaged — back takes over",
                injuryRisk: "Lumbar hyperextension, lower back strain",
                severity: "High",
                fix: "Squeeze abs and glutes before you start each rep"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Only going halfway down",
                whyItHappens: "Fatigue or fear of failing at the bottom",
                injuryRisk: "Reduced muscle development, imbalanced strength",
                severity: "Low",
                fix: "Go to full range — drop to incline push-up (hands on bench) if needed"
            )
        ],
        tips: "Can't do a full push-up? Start on your knees — it's the same movement pattern with less load."
    )

    // ── LUNGE ──────────────────────────────────────────────────────────────
    static let lunge = HomeExercise(
        name: "Reverse Lunge",
        icon: "figure.walk",
        category: .lowerBody,
        targetMuscles: "Quads · Glutes · Hamstrings · Balance",
        primaryMuscles: ["Quadriceps", "Gluteus Maximus", "Hamstrings"],
        difficulty: .beginner,
        sets: 3, repsOrTime: "10 each leg", restSeconds: 60, calories: 6,
        isBodyweight: true,
        poseType: .lunge,          // no pose detection — uses guided timer
        formCues: [
            "Stand tall with feet hip-width apart",
            "Step one foot BACK (reverse lunge is easier on the knee than forward)",
            "Lower your back knee toward the floor — keep it just above the ground",
            "Front knee stays directly over your front foot — not past the toes",
            "Push through the front heel to return to standing"
        ],
        mistakes: [
            HomeExercise.MistakeInfo(
                mistake: "Front knee tracking past the toes",
                whyItHappens: "Step isn't long enough, or leaning forward",
                injuryRisk: "Patellofemoral pain (runner's knee), patellar tendon overload",
                severity: "High",
                fix: "Take a bigger step back — front shin should be nearly vertical"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Torso leaning forward",
                whyItHappens: "Hip flexor tightness or loss of balance",
                injuryRisk: "Lower back strain, quad dominance imbalance",
                severity: "Moderate",
                fix: "Keep chest up and shoulders back — look straight ahead"
            )
        ],
        tips: "Reverse lunges are gentler on your knees than forward lunges — perfect for beginners."
    )

    // ── GLUTE BRIDGE ───────────────────────────────────────────────────────
    static let gluteBridge = HomeExercise(
        name: "Glute Bridge",
        icon: "figure.yoga",
        category: .lowerBody,
        targetMuscles: "Glutes · Hamstrings · Lower Back",
        primaryMuscles: ["Gluteus Maximus", "Hamstrings", "Erector Spinae"],
        difficulty: .beginner,
        sets: 3, repsOrTime: "15 reps", restSeconds: 45, calories: 4,
        isBodyweight: true,
        poseType: .gluteBridge,
        formCues: [
            "Lie on your back, knees bent, feet flat on the floor hip-width apart",
            "Press your lower back gently into the floor before lifting",
            "Drive through your heels to lift your hips — squeeze glutes hard at the top",
            "Hold the top position for 1–2 seconds",
            "Lower slowly — don't let hips crash to the floor"
        ],
        mistakes: [
            HomeExercise.MistakeInfo(
                mistake: "Using lower back instead of glutes to lift",
                whyItHappens: "Glutes not firing — hip flexors take over",
                injuryRisk: "Lower back pain, SI joint irritation",
                severity: "Moderate",
                fix: "Squeeze your glutes BEFORE you lift — think 'crack a walnut between your cheeks'"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Feet too far from body",
                whyItHappens: "Setup error — shifts load to hamstrings too much",
                injuryRisk: "Hamstring cramp, reduced glute activation",
                severity: "Low",
                fix: "Set up so shins are vertical when hips are raised"
            )
        ],
        tips: "Single-leg glute bridges (one foot on floor, one extended) triple the difficulty when ready."
    )

    // ── MOUNTAIN CLIMBER ───────────────────────────────────────────────────
    static let mountainClimber = HomeExercise(
        name: "Mountain Climber",
        icon: "figure.climbing",
        category: .fullBody,
        targetMuscles: "Core · Hip Flexors · Cardio",
        primaryMuscles: ["Transverse Abdominis", "Hip Flexors", "Shoulders"],
        difficulty: .intermediate,
        sets: 3, repsOrTime: "30 sec", restSeconds: 45, calories: 8,
        isBodyweight: true,
        poseType: nil,
        formCues: [
            "Start in a high plank (arms straight, hands under shoulders)",
            "Drive one knee toward your chest while keeping hips level",
            "Quickly switch legs — alternate in a running motion",
            "Keep hips DOWN — do not let them rise as you speed up",
            "Look at the floor between your hands to keep neck neutral"
        ],
        mistakes: [
            HomeExercise.MistakeInfo(
                mistake: "Hips rising into a pike as pace increases",
                whyItHappens: "Core fatigues — body compensates by elevating hips",
                injuryRisk: "Lower back overload, shoulder strain",
                severity: "Moderate",
                fix: "Slow down — control beats speed. Keep hips at shoulder height"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Bouncing on hands and locking elbows",
                whyItHappens: "Arms not engaged — treating them as passive support",
                injuryRisk: "Wrist and elbow joint impact stress",
                severity: "Low",
                fix: "Press your hands into the floor actively throughout"
            )
        ],
        tips: "Slow mountain climbers (3 sec per rep) build more core strength than fast ones."
    )

    // ── BURPEE ─────────────────────────────────────────────────────────────
    static let burpee = HomeExercise(
        name: "Burpee",
        icon: "figure.jumprope",
        category: .fullBody,
        targetMuscles: "Full Body · Cardio · Power",
        primaryMuscles: ["Chest", "Quads", "Core", "Shoulders"],
        difficulty: .intermediate,
        sets: 3, repsOrTime: "8–10 reps", restSeconds: 90, calories: 12,
        isBodyweight: true,
        poseType: nil,
        formCues: [
            "Stand with feet shoulder-width apart",
            "Hinge at hips and place hands on floor — jump or step feet back to plank",
            "Perform ONE controlled push-up (optional for beginners — skip it)",
            "Jump or step feet back to your hands",
            "Explode upward — jump and clap overhead at the top"
        ],
        mistakes: [
            HomeExercise.MistakeInfo(
                mistake: "Landing with straight legs from the jump",
                whyItHappens: "Fatigue — not controlling the descent",
                injuryRisk: "Knee joint impact stress, ankle sprain",
                severity: "High",
                fix: "Land softly with bent knees — imagine you are landing on thin ice"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Sagging hips in the plank phase",
                whyItHappens: "Rushing through the rep",
                injuryRisk: "Lower back strain",
                severity: "Moderate",
                fix: "Take a breath in plank before jumping back up"
            )
        ],
        tips: "A 'step burpee' (step instead of jump) has the same full-body benefit with far less joint impact."
    )

    // ── TRICEP DIP (CHAIR) ─────────────────────────────────────────────────
    static let tricepDip = HomeExercise(
        name: "Tricep Dip",
        icon: "chair.lounge.fill",
        category: .upperBody,
        targetMuscles: "Triceps · Chest · Shoulders",
        primaryMuscles: ["Triceps Brachii", "Anterior Deltoid", "Pectoralis Minor"],
        difficulty: .beginner,
        sets: 3, repsOrTime: "12 reps", restSeconds: 60, calories: 5,
        isBodyweight: true,
        poseType: nil,
        formCues: [
            "Sit on the edge of a sturdy chair or low surface",
            "Hands gripping the edge, fingers pointing forward",
            "Slide your bottom off the edge — legs extended or bent at 90°",
            "Lower your body by bending elbows — aim for 90° at elbows",
            "Press back up through your palms — don't use your legs to assist"
        ],
        mistakes: [
            HomeExercise.MistakeInfo(
                mistake: "Dipping too low — elbows past 90°",
                whyItHappens: "Trying to work harder — actually increases injury risk",
                injuryRisk: "Anterior shoulder impingement, rotator cuff strain",
                severity: "High",
                fix: "Stop when elbows reach 90° — lower isn't better here"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Flaring elbows outward",
                whyItHappens: "Weak triceps — compensating with chest",
                injuryRisk: "Elbow joint stress, reduced tricep activation",
                severity: "Moderate",
                fix: "Keep elbows pointing directly behind you throughout"
            )
        ],
        tips: "Use a lower surface (floor level) to make it harder, higher surface (kitchen counter) to make it easier."
    )

    // ── HIGH KNEES ─────────────────────────────────────────────────────────
    static let highKnees = HomeExercise(
        name: "High Knees",
        icon: "figure.run",
        category: .cardio,
        targetMuscles: "Hip Flexors · Quads · Cardio",
        primaryMuscles: ["Hip Flexors", "Quadriceps", "Core"],
        difficulty: .beginner,
        sets: 3, repsOrTime: "30 sec", restSeconds: 30, calories: 9,
        isBodyweight: true,
        poseType: .highKnees,
        formCues: [
            "Stand tall with feet hip-width apart",
            "Drive knees up alternately to hip height — like running in place",
            "Arms pump in opposition: left arm with right knee",
            "Land softly on the balls of your feet — not flat-footed",
            "Keep core braced — don't let torso lean back"
        ],
        mistakes: [
            HomeExercise.MistakeInfo(
                mistake: "Not lifting knees high enough",
                whyItHappens: "Fatigue or poor hip flexor mobility",
                injuryRisk: "Reduced cardiovascular and hip flexor benefit",
                severity: "Low",
                fix: "Place your hands at hip height — aim to touch your palms with each knee"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Landing heavily on heels",
                whyItHappens: "Not controlling the descent — low body awareness",
                injuryRisk: "Shin splints, knee joint impact",
                severity: "Moderate",
                fix: "Stay on the balls of your feet throughout the entire movement"
            )
        ],
        tips: "High knees burns nearly as many calories as running — and you can do it in 2 square metres."
    )

    // ── SUPERMAN ───────────────────────────────────────────────────────────
    static let superman = HomeExercise(
        name: "Superman Hold",
        icon: "figure.cooldown",
        category: .core,
        targetMuscles: "Lower Back · Glutes · Posterior Chain",
        primaryMuscles: ["Erector Spinae", "Gluteus Maximus", "Rear Deltoids"],
        difficulty: .beginner,
        sets: 3, repsOrTime: "10 reps × 3 sec hold", restSeconds: 45, calories: 3,
        isBodyweight: true,
        poseType: nil,
        formCues: [
            "Lie face down with arms extended overhead — like Superman flying",
            "Simultaneously lift arms, chest, and legs off the floor",
            "Squeeze your glutes and back muscles — hold for 3 seconds",
            "Keep your neck neutral — look at the floor, not forward",
            "Lower slowly and repeat"
        ],
        mistakes: [
            HomeExercise.MistakeInfo(
                mistake: "Cranking the neck up to look forward",
                whyItHappens: "Trying to see how high you are lifting",
                injuryRisk: "Cervical spine compression, neck strain",
                severity: "Moderate",
                fix: "Keep ears between arms — your gaze stays at the floor"
            ),
            HomeExercise.MistakeInfo(
                mistake: "Only lifting the arms (not legs) or vice versa",
                whyItHappens: "Asymmetric strength",
                injuryRisk: "Imbalanced posterior chain development",
                severity: "Low",
                fix: "Focus on lifting BOTH ends simultaneously from the start"
            )
        ],
        tips: "Superman is one of the best exercises to counteract the hunched posture of sitting all day."
    )
}

// MARK: - Muscle regions

enum MuscleRegion: String, CaseIterable {
    case chest          = "Chest"
    case frontShoulders = "Front Shoulders"
    case biceps         = "Biceps"
    case forearms       = "Forearms"
    case abs            = "Abs"
    case obliques       = "Obliques"
    case hipFlexors     = "Hip Flexors"
    case quads          = "Quads"
    case knees          = "Knees"
    case shins          = "Shins"
    case traps          = "Traps"
    case rearShoulders  = "Rear Shoulders"
    case lats           = "Lats"
    case triceps        = "Triceps"
    case lowerBack      = "Lower Back"
    case glutes         = "Glutes"
    case hamstrings     = "Hamstrings"
    case calves         = "Calves"
    case core           = "Core"
    case neck           = "Neck"
}

struct MuscleActivation {
    let primary:   [MuscleRegion]
    let secondary: [MuscleRegion]
}

// MARK: - Exercise → muscle activation mapping

extension HomeExercise {
    var muscleActivation: MuscleActivation {
        switch name {
        case "Plank":
            return MuscleActivation(
                primary:   [.abs, .core, .frontShoulders, .lowerBack],
                secondary: [.glutes, .quads, .traps, .chest]
            )
        case "Bodyweight Squat":
            return MuscleActivation(
                primary:   [.quads, .glutes, .hamstrings],
                secondary: [.lowerBack, .core, .calves]
            )
        case "Push-Up":
            return MuscleActivation(
                primary:   [.chest, .triceps, .frontShoulders],
                secondary: [.abs, .core, .biceps]
            )
        case "Reverse Lunge":
            return MuscleActivation(
                primary:   [.quads, .glutes, .hamstrings],
                secondary: [.calves, .core, .hipFlexors]
            )
        case "Glute Bridge":
            return MuscleActivation(
                primary:   [.glutes, .hamstrings],
                secondary: [.lowerBack, .abs, .core]
            )
        case "Mountain Climber":
            return MuscleActivation(
                primary:   [.abs, .core, .hipFlexors],
                secondary: [.frontShoulders, .quads, .chest]
            )
        case "Burpee":
            return MuscleActivation(
                primary:   [.chest, .quads, .glutes, .abs],
                secondary: [.triceps, .frontShoulders, .hamstrings, .core]
            )
        case "Tricep Dip":
            return MuscleActivation(
                primary:   [.triceps, .frontShoulders],
                secondary: [.chest, .forearms]
            )
        case "High Knees":
            return MuscleActivation(
                primary:   [.hipFlexors, .quads, .abs],
                secondary: [.calves, .core, .hamstrings]
            )
        case "Superman Hold":
            return MuscleActivation(
                primary:   [.lowerBack, .glutes, .rearShoulders],
                secondary: [.hamstrings, .traps, .lats]
            )
        default:
            return MuscleActivation(primary: [], secondary: [])
        }
    }
}
