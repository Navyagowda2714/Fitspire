//
//  ExerciseFormViews.swift
//  Fitspyre
//
//  All exercise live-camera form-check views built with the exact same
//  Vision + angle-analysis architecture as the squat (ContentView.swift).
//  Each exercise has: Issue enum, Phase enum, PostureResult, ViewModel,
//  SkeletonOverlay, AngleCards, rep/hold counting, bad-rep flash.
//
//  Router: ExerciseLiveView(exercise: HomeExercise) picks the right view.
//

import SwiftUI
import AVFoundation
@preconcurrency import Vision
import Combine

// Shared angle card
struct LiveAngleCard: View {
    let title: String
    let angle: Double
    let isOk: Bool
    let idealRange: String
    var body: some View {
        VStack(spacing: 5) {
            Text(title).font(.caption).foregroundColor(.white.opacity(0.7))
            Text("\(Int(angle))°").font(.headline.bold()).foregroundColor(isOk ? .green : .red)
            Text(idealRange).font(.caption2).foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(isOk ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
        .cornerRadius(12)
    }
}

// Shared form alert banner
struct LiveFormBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text(message).font(.subheadline.bold()).foregroundColor(.white)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.orange, lineWidth: 1.5))
        .shadow(color: .orange.opacity(0.4), radius: 8)
        .padding(.horizontal)
    }
}

struct FormAlertBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text(message).font(.subheadline.bold()).foregroundColor(.white)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.orange, lineWidth: 1.5))
        .shadow(color: .orange.opacity(0.4), radius: 8).padding(.horizontal)
    }
}



// MARK: - Session preview (AVCaptureSession → SwiftUI)
// Self-contained so ExerciseFormViews has no dependency on CameraPreviewView.swift

struct ExerciseSessionPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> ExercisePreviewUIView {
        let v = ExercisePreviewUIView()
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        return v
    }
    func updateUIView(_ uiView: ExercisePreviewUIView, context: Context) {}
}

final class ExercisePreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}


// MARK: - Rule engine integration helper

/// Calls FormRuleEngine and returns the highest-severity alert message, if any.
/// This supplements the angle-based analysis already in each ViewModel.
private func ruleEngineAlert(
    joints: [VNHumanBodyPoseObservation.JointName: CGPoint],
    exercise: ExerciseType
) -> String? {
    let engine = FormRuleEngine()
    let alerts = engine.evaluate(joints: joints, exercise: exercise)
    // Prefer danger over warning
    if let danger = alerts.first(where: { $0.severity == .danger }) {
        return "⚠️ \(danger.message) — \(danger.correction)"
    }
    if let warning = alerts.first(where: { $0.severity == .warning }) {
        return "⚡ \(warning.message)"
    }
    return nil
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

func calcAngle(first: CGPoint, middle: CGPoint, last: CGPoint) -> Double {
    let a = atan2(first.y - middle.y, first.x - middle.x)
    let b = atan2(last.y - middle.y, last.x - middle.x)
    var angle = abs((a - b) * 180 / .pi)
    if angle > 180 { angle = 360 - angle }
    return angle
}

func betterSideConf(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
                     joints: [VNHumanBodyPoseObservation.JointName]) -> Bool {
    let leftJoints:  [VNHumanBodyPoseObservation.JointName] = [.leftShoulder, .leftHip, .leftKnee, .leftAnkle, .leftWrist, .leftElbow]
    let rightJoints: [VNHumanBodyPoseObservation.JointName] = [.rightShoulder, .rightHip, .rightKnee, .rightAnkle, .rightWrist, .rightElbow]
    let lSum = joints.compactMap { lj -> Float? in
        let idx = leftJoints.firstIndex(of: lj)
        return idx.flatMap { points[leftJoints[$0]]?.confidence }
    }.reduce(0, +)
    let rSum = joints.compactMap { lj -> Float? in
        let idx = leftJoints.firstIndex(of: lj)
        return idx.flatMap { points[rightJoints[$0 < rightJoints.count ? $0 : 0]]?.confidence }
    }.reduce(0, +)
    return lSum >= rSum
}

func mappedPoints(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
    var out: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    for (j, p) in points where p.confidence > 0.3 {
        out[j] = CGPoint(x: p.location.x, y: 1 - p.location.y)
    }
    return out
}

// Shared score circle
struct ScoreRing: View {
    let score: Int
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.2), lineWidth: 5).frame(width: 65, height: 65)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(score >= 80 ? Color.green : score >= 55 ? Color.yellow : Color.red,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 65, height: 65).rotationEffect(.degrees(-90))
            Text("\(score)").font(.headline.bold()).foregroundColor(.white)
        }
    }
}




// Bad-rep flash overlay
struct BadRepFlash: View {
    let reason: String
    var body: some View {
        ZStack {
            Color.red.opacity(0.25).ignoresSafeArea().allowsHitTesting(false)
            VStack {
                Spacer()
                Text("⚠️ Rep Not Counted\n\(reason)")
                    .font(.title3.bold()).foregroundColor(.white)
                    .multilineTextAlignment(.center).padding()
                    .background(Color.red.opacity(0.85)).cornerRadius(16)
                    .padding(.bottom, 220)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - ROUTER
// ─────────────────────────────────────────────────────────────────────────────

struct ExerciseLiveView: View {
    let exercise: HomeExercise
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                                switch exercise.name {
                case "Bodyweight Squat":  SquatCameraView()
                case "Plank":             PlankCameraView()
                case "Push-Up":           PushupCameraView()
                case "Reverse Lunge":     LungeCameraView()
                case "Glute Bridge":
                    GluteBridgeCameraView()
                case "High Knees":
                    HighKneesView()
                case "Mountain Climber":
                    MountainClimberCameraViewV2()
                case "Burpee":
                    BurpeeCameraViewV2()
                case "Tricep Dip":
                    TricepDipCameraView()
                case "Superman Hold":
                    SupermanCameraView()
                default:                  SquatCameraView()
                }
            }
            // Back button on top of every view
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(.top, 56).padding(.leading, 20)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PLANK
// ─────────────────────────────────────────────────────────────────────────────

import SwiftUI
import AVFoundation
import Vision
import Combine

// MARK: - PLANK ISSUE
enum PlankIssue: String {
    case correct      = "✅ Perfect Plank"
    case ready        = "🧍 Get Into Plank Position"
    case hipsTooHigh  = "❌ Lower Your Hips"
    case hipsTooLow   = "❌ Raise Your Hips"
    case backSagging  = "❌ Keep Back Straight"
    case headDropping = "❌ Keep Head Neutral"
    case detecting    = "🔍 Detecting..."
    case notVisible   = "📷 Full Body Not Visible"
}

// MARK: - HOLD RECORD
struct HoldRecord: Identifiable {
    let id          = UUID()
    let holdNumber:  Int
    let seconds:     Int
    let score:       Int
    let timestamp:   Date

    var isGood: Bool { seconds >= 5 && score >= 70 }

    var formattedDuration: String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - PLANK RESULT
struct PlankResult {
    var issue: PlankIssue = .detecting
    var postureScore: Int  = 100
    var hipAngle:   Double = 180
    var spineAngle: Double = 180
    var neckAngle:  Double = 180
    var trackedLeftSide: Bool = true
    var hipOk   = true
    var spineOk = true
    var neckOk  = true
    var formIsValid: Bool { hipOk && spineOk && neckOk }
}

// MARK: - PLANK CAMERA VIEW
struct PlankCameraView: View {
    @StateObject private var viewModel = PlankViewModel()
    @State private var showGoalSheet   = false

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.session).ignoresSafeArea()

            PlankSkeletonOverlay(
                bodyPoints: viewModel.bodyPoints,
                result:     viewModel.plankResult
            ).ignoresSafeArea()

            VStack {
                topBar
                Spacer()

                if viewModel.showFormAlert {
                    PlankFormAlertBanner(message: viewModel.formAlertMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: viewModel.showFormAlert)
                }

                Spacer()
                bottomPanel
            }

            if viewModel.showFormBreakFlash {
                Color.orange.opacity(0.25)
                    .ignoresSafeArea().allowsHitTesting(false)
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.4), value: viewModel.showFormBreakFlash)

                VStack {
                    Spacer()
                    Text("⏸ Timer Paused — Fix Your Form")
                        .font(.title3.bold()).foregroundColor(.white)
                        .padding().background(Color.orange.opacity(0.9))
                        .cornerRadius(14).padding(.bottom, 220)
                }
            }
        }
        .sheet(isPresented: $viewModel.showStats) { PlankStatsSheet(viewModel: viewModel) }
        .sheet(isPresented: $showGoalSheet)        { PlankGoalSetupSheet(viewModel: viewModel) }
        .onAppear    { viewModel.start() }
        .onDisappear { viewModel.stopAndSave() }
    }

    // MARK: - Top bar (minimal floating pill)
    private var topBar: some View {
        HStack(spacing: 8) {
            // Session timer pill
            Text(viewModel.sessionTimeString)
                .font(.caption.monospacedDigit().bold())
                .foregroundColor(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.black.opacity(0.5)).cornerRadius(20)

            Spacer()

            // Score ring (40 px)
            ZStack {
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 3).frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.plankResult.postureScore) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40).rotationEffect(.degrees(-90))
                Text("\(viewModel.plankResult.postureScore)")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
            }

            // Action buttons — single frosted pill
            HStack(spacing: 4) {
                Button { viewModel.showStats = true } label: {
                    Image(systemName: "chart.bar.fill").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                Button { showGoalSheet = true } label: {
                    Image(systemName: "target").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                Button { viewModel.switchCamera() } label: {
                    Image(systemName: "camera.rotate").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(.black.opacity(0.5)).cornerRadius(24)
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    // MARK: - Bottom panel (compact)
    private var bottomPanel: some View {
        VStack(spacing: 10) {

            // Issue label + timer-state pill on same row
            HStack {
                Text(viewModel.plankResult.issue.rawValue)
                    .font(.subheadline.bold()).foregroundColor(.white)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(viewModel.isHolding ? "🔥 Holding" : "⏸ Paused")
                    .font(.caption.bold())
                    .foregroundColor(viewModel.isHolding ? .green : .orange)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background((viewModel.isHolding ? Color.green : Color.orange).opacity(0.15))
                    .cornerRadius(12)
            }

            // Angle chips
            HStack(spacing: 6) {
                PlankAngleChip(label: "Hip",   angle: viewModel.plankResult.hipAngle,   isOk: viewModel.plankResult.hipOk)
                PlankAngleChip(label: "Back",  angle: viewModel.plankResult.spineAngle, isOk: viewModel.plankResult.spineOk)
                PlankAngleChip(label: "Neck",  angle: viewModel.plankResult.neckAngle,  isOk: viewModel.plankResult.neckOk)
            }

            // Goal progress bar (only when goal is active)
            if viewModel.targetSeconds > 0 {
                PlankGoalProgressBar(
                    elapsed: viewModel.elapsedSeconds,
                    target:  viewModel.targetSeconds
                )
            }

            // Hold time row
            HStack(alignment: .center, spacing: 0) {
                // Current hold — dominant
                VStack(spacing: 0) {
                    Text(viewModel.formattedTime)
                        .font(.system(size: 52, weight: .heavy, design: .monospaced))
                        .foregroundColor(viewModel.isHolding ? .green : .white.opacity(0.5))
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: viewModel.formattedTime)
                    Text("HOLD")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .kerning(1.2)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 44)

                // Best hold
                VStack(spacing: 0) {
                    Text(viewModel.formattedBestTime)
                        .font(.system(size: 28, weight: .heavy, design: .monospaced))
                        .foregroundColor(.yellow)
                    Text("BEST")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .kerning(1.2)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 44)

                // Reset
                Button { viewModel.resetTimer() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3).foregroundColor(.white.opacity(0.7))
                        Text("RESET").font(.system(size: 10)).foregroundColor(.white.opacity(0.4)).kerning(1.2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 2)

            // Status pill (build-up indicator / holding state)
            PlankStatusPill(
                isHolding:    viewModel.isHolding,
                issue:        viewModel.plankResult.issue,
                readyFrames:  viewModel.consecutiveGoodFrames,
                neededFrames: viewModel.goodFramesNeeded
            )
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(.ultraThinMaterial.opacity(0.95))
        .background(Color.black.opacity(0.6))
        .cornerRadius(24)
        .padding(.horizontal, 12).padding(.bottom, 8)
    }

    private var scoreColor: Color {
        let s = viewModel.plankResult.postureScore
        if s >= 80 { return .green }
        if s >= 55 { return .yellow }
        return .red
    }
}

// MARK: - ANGLE CHIP  (replaces PlankAngleCard)
struct PlankAngleChip: View {
    let label: String
    let angle: Double
    let isOk:  Bool
    var unit:  String = "°"

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(isOk ? Color.green : Color.red).frame(width: 6, height: 6)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.6))
            Text("\(Int(angle))\(unit)").font(.system(size: 12, weight: .bold)).foregroundColor(isOk ? .green : .red)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(isOk ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - GOAL SETUP SHEET
struct PlankGoalSetupSheet: View {
    @ObservedObject var viewModel: PlankViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var targetSeconds = 60

    var body: some View {
        NavigationView {
            Form {
                Section("Hold Goal") {
                    Stepper("Target: \(targetSeconds)s",
                            value: $targetSeconds, in: 10...600, step: 10)
                    Text("≈ \(targetSeconds / 60)m \(targetSeconds % 60)s")
                        .font(.caption).foregroundColor(.secondary)
                }
                Section {
                    Button("Set Goal") {
                        viewModel.setGoal(seconds: targetSeconds); dismiss()
                    }.foregroundColor(.green).bold()
                    Button("Clear Goal") {
                        viewModel.clearGoal(); dismiss()
                    }.foregroundColor(.red)
                }
            }
            .navigationTitle("Set Hold Goal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } }
            }
            .onAppear {
                if viewModel.targetSeconds > 0 { targetSeconds = viewModel.targetSeconds }
            }
        }
    }
}

// MARK: - GOAL PROGRESS BAR
struct PlankGoalProgressBar: View {
    let elapsed: Int
    let target:  Int

    private var progress: CGFloat {
        CGFloat(min(elapsed, target)) / CGFloat(max(target, 1))
    }
    private var isComplete: Bool { elapsed >= target }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(isComplete ? "🎉 Goal reached!" : "Goal")
                    .font(.caption)
                    .foregroundColor(isComplete ? .green : .white.opacity(0.7))
                Spacer()
                Text("\(elapsed)/\(target)s")
                    .font(.caption.bold()).foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.15)).frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isComplete ? Color.yellow : Color.green)
                        .frame(width: geo.size.width * progress, height: 10)
                        .animation(.spring(response: 0.3), value: elapsed)
                }
            }.frame(height: 10)
        }.padding(.horizontal, 4)
    }
}

// MARK: - SESSION STATS SHEET
struct PlankStatsSheet: View {
    @ObservedObject var viewModel: PlankViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        PlankStatCard(title: "Best Hold",    value: viewModel.formattedBestTime, color: .yellow)
                        PlankStatCard(title: "Current Hold", value: viewModel.formattedTime,
                                      color: viewModel.isHolding ? .green : .white)
                        PlankStatCard(title: "Session Time", value: viewModel.sessionTimeString,  color: .cyan)
                        PlankStatCard(title: "Avg Form Score",
                                      value: viewModel.holdHistory.isEmpty
                                        ? "—" : "\(viewModel.averageFormScore)%",
                                      color: scoreColor(viewModel.averageFormScore))
                        PlankStatCard(title: "Total Holds",
                                      value: "\(viewModel.holdHistory.count)", color: .purple)
                        PlankStatCard(title: "Good Holds",
                                      value: "\(viewModel.holdHistory.filter(\.isGood).count)", color: .green)
                    }
                    .padding(.horizontal)

                    Divider().padding(.horizontal)

                    if viewModel.holdHistory.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 44)).foregroundColor(.secondary)
                            Text("No holds recorded yet.\nGet into position and hold! 🔥")
                                .multilineTextAlignment(.center).foregroundColor(.secondary)
                        }.padding(.top, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hold History").font(.headline).padding(.horizontal)
                            ForEach(viewModel.holdHistory.reversed()) { hold in
                                HStack {
                                    Text("#\(hold.holdNumber)")
                                        .font(.caption.bold()).foregroundColor(.secondary)
                                        .frame(width: 28, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(hold.formattedDuration)
                                            .font(.headline.bold())
                                            .foregroundColor(hold.isGood ? .green : .orange)
                                        Text("Score: \(hold.score)%").font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(hold.isGood ? "✅" : "⚠️").font(.title3)
                                }
                                .padding(.horizontal).padding(.vertical, 8)
                                .background(Color(.systemGray6)).cornerRadius(10).padding(.horizontal)
                            }
                        }
                    }
                    Spacer(minLength: 30)
                }.padding(.top)
            }
            .navigationTitle("Session Stats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return .green }
        if score >= 55 { return .yellow }
        return .red
    }
}

// MARK: - STAT CARD
struct PlankStatCard: View {
    let title: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(Color(.systemGray6)).cornerRadius(12)
    }
}

// MARK: - FORM ALERT BANNER
struct PlankFormAlertBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text(message).font(.subheadline.bold()).foregroundColor(.white)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.orange, lineWidth: 1.5))
        .shadow(color: .orange.opacity(0.4), radius: 8).padding(.horizontal)
    }
}

// MARK: - SKELETON OVERLAY
struct PlankSkeletonOverlay: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let result: PlankResult

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let ear:      VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftEar      : .rightEar
                let shoulder: VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftShoulder : .rightShoulder
                let hip:      VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftHip      : .rightHip
                let knee:     VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftKnee     : .rightKnee
                let ankle:    VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftAnkle    : .rightAnkle

                drawLine(ear,      shoulder, geo, ok: result.neckOk)
                drawLine(shoulder, hip,      geo, ok: result.spineOk)
                drawLine(hip,      knee,     geo, ok: result.hipOk)
                drawLine(knee,     ankle,    geo, ok: result.hipOk)

                if let hipPt = bodyPoints[hip] {
                    let refY = hipPt.y * geo.size.height
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: refY))
                        p.addLine(to: CGPoint(x: geo.size.width, y: refY))
                    }
                    .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [8, 5]))
                }

                ForEach([ear, shoulder, hip, knee, ankle], id: \.self) { joint in
                    if let point = bodyPoints[joint] {
                        Circle().fill(dotColor(for: joint, ear: ear, shoulder: shoulder,
                                               hip: hip, knee: knee, ankle: ankle))
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                            .position(x: point.x * geo.size.width, y: point.y * geo.size.height)
                    }
                }
            }
        }
    }

    private func dotColor(for joint: VNHumanBodyPoseObservation.JointName,
                          ear: VNHumanBodyPoseObservation.JointName,
                          shoulder: VNHumanBodyPoseObservation.JointName,
                          hip: VNHumanBodyPoseObservation.JointName,
                          knee: VNHumanBodyPoseObservation.JointName,
                          ankle: VNHumanBodyPoseObservation.JointName) -> Color {
        if joint == ear                    { return result.neckOk  ? .green : .red }
        if joint == shoulder               { return result.spineOk ? .green : .red }
        if joint == hip                    { return result.hipOk   ? .green : .red }
        if joint == knee || joint == ankle { return result.hipOk   ? .green : .red }
        return .white
    }

    @ViewBuilder
    private func drawLine(_ j1: VNHumanBodyPoseObservation.JointName,
                          _ j2: VNHumanBodyPoseObservation.JointName,
                          _ geo: GeometryProxy, ok: Bool) -> some View {
        if let p1 = bodyPoints[j1], let p2 = bodyPoints[j2] {
            Path { path in
                path.move(to: CGPoint(x: p1.x * geo.size.width, y: p1.y * geo.size.height))
                path.addLine(to: CGPoint(x: p2.x * geo.size.width, y: p2.y * geo.size.height))
            }
            .stroke(ok ? Color.green : Color.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
}

// MARK: - STATUS PILL
struct PlankStatusPill: View {
    let isHolding:    Bool
    let issue:        PlankIssue
    let readyFrames:  Int
    let neededFrames: Int

    var body: some View {
        if isHolding {
            label("🔥 Keep holding — great form!", color: .green)
        } else if issue == .ready {
            label("📐 Get into plank position", color: .white.opacity(0.7),
                  bg: Color.white.opacity(0.1))
        } else if issue == .correct || issue == .detecting {
            buildUpView
        } else {
            label("⏸ Fix form to resume timer", color: .orange)
        }
    }

    private var buildUpView: some View {
        let progress = min(Double(readyFrames) / Double(max(neededFrames, 1)), 1.0)
        return VStack(spacing: 6) {
            Text("Hold steady — timer starting...")
                .font(.caption.bold()).foregroundColor(.yellow)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.15)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4).fill(Color.yellow)
                        .frame(width: geo.size.width * CGFloat(progress), height: 6)
                        .animation(.linear(duration: 0.1), value: readyFrames)
                }
            }.frame(height: 6)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(Color.yellow.opacity(0.1)).cornerRadius(20)
    }

    private func label(_ text: String, color: Color, bg: Color = Color.clear) -> some View {
        Text(text).font(.caption.bold()).foregroundColor(color)
            .padding(.horizontal, 16).padding(.vertical, 6)
            .background(bg == Color.clear ? color.opacity(0.15) : bg)
            .cornerRadius(20)
    }
}

// MARK: - PLANK VIEW MODEL
final class PlankViewModel: NSObject, ObservableObject,
                             AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession()

    @Published var bodyPoints:      [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var plankResult      = PlankResult()
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var elapsedSeconds:  Int  = 0
    @Published var bestSeconds:     Int  = 0
    @Published var isHolding:       Bool = false
    @Published var showFormAlert      = false
    @Published var formAlertMessage   = ""
    @Published var showFormBreakFlash = false
    @Published var consecutiveGoodFrames = 0
    @Published var showStats = false

    @Published var targetSeconds: Int = 0

    func setGoal(seconds: Int) {
        DispatchQueue.main.async { self.targetSeconds = seconds }
    }

    func clearGoal() {
        DispatchQueue.main.async { self.targetSeconds = 0 }
    }

    @Published var holdHistory:      [HoldRecord] = []
    @Published var sessionTimeString = "00:00"

    private var sessionStartDate: Date?
    private var sessionClockTimer: Timer?

    private var holdScoreAccum:   Int = 0
    private var holdScoreFrames:  Int = 0

    var averageFormScore: Int {
        guard !holdHistory.isEmpty else { return 0 }
        return holdHistory.map(\.score).reduce(0, +) / holdHistory.count
    }

    let goodFramesNeeded = 10

    private let hipExcellentMin:    Double = 170
    private let hipAcceptableMin:   Double = 165
    private let spineExcellentMin:  Double = 175
    private let spineAcceptableMin: Double = 165
    private let neckExcellentMin:   Double = 170
    private let neckAcceptableMin:  Double = 160
    private let standingGuardMin:   Double = 120

    private let badFramesRequired    = 5
    private var consecutiveBadFrames = 0
    private var holdingState         = false

    private var _isProcessingFrame = false
    private let poseRequest = VNDetectHumanBodyPoseRequest()

    private var pointsBuffer: [[VNHumanBodyPoseObservation.JointName: CGPoint]] = []
    private let pointsBufferSize = 6

    private var angleBuffer: [(hip: Double, spine: Double, neck: Double)] = []
    private let angleBufferSize = 8

    private var stableIssueFrames = 0
    private var lastIssue: PlankIssue = .detecting
    private var notVisibleFrames = 0

    private var timerTask:  Task<Void, Never>?
    private var alertTimer: Timer?

    private var lastNotifTime: [String: Date] = [:]
    private let notifCooldown: TimeInterval   = 4.0

    private var announcedMilestones = Set<Int>()
    private var goalAnnounced       = false

    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastSpokenTime: [String: Date] = [:]
    private let voiceCooldown: TimeInterval = 4.0

    // add with the other private vars, around line 2770
    private var isConfiguring = false
    // add with other private vars
    private let cameraQueue = DispatchQueue(label: "plankCameraQueue")
    private var sessionTimer: Timer?
    private var restTimer: Timer?
    
    // MARK: - Lifecycle
    func start() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
                    guard granted else { return }
                    DispatchQueue.global(qos: .userInitiated).async { self.setupCamera() }
                }
        startSessionClock()
        speak("Get into plank position. Timer starts when your form is perfect.")
        fireWatchNotification(
            title: "🏋️ Plank Started",
            body:  "Get into position. Timer starts when form is perfect."
        )
    }

    func stop() {
        sessionTimer?.invalidate()
        restTimer?.invalidate()
        cameraQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func resetTimer() {
        DispatchQueue.main.async {
            self.recordHoldIfNeeded()
            self.stopTimer()
            self.holdingState            = false
            self.isHolding               = false
            self.elapsedSeconds          = 0
            self.consecutiveGoodFrames   = 0
            self.consecutiveBadFrames    = 0
            self.angleBuffer.removeAll()
            self.pointsBuffer.removeAll()
            self.announcedMilestones.removeAll()
            self.goalAnnounced   = false
            self.holdScoreAccum  = 0
            self.holdScoreFrames = 0
        }
    }

    private func startSessionClock() {
        sessionStartDate = Date()
        sessionClockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.sessionStartDate else { return }
            let elapsed = Int(Date().timeIntervalSince(start))
            self.sessionTimeString = self.formatSeconds(elapsed)
        }
    }

    private func stopSessionClock() {
        sessionClockTimer?.invalidate()
        sessionClockTimer = nil
    }

    private func recordHoldIfNeeded() {
        guard elapsedSeconds >= 1 else { return }
        let avgScore = holdScoreFrames > 0 ? holdScoreAccum / holdScoreFrames : plankResult.postureScore
        let record = HoldRecord(
            holdNumber: holdHistory.count + 1,
            seconds:    elapsedSeconds,
            score:      avgScore,
            timestamp:  Date()
        )
        holdHistory.append(record)
        holdScoreAccum  = 0
        holdScoreFrames = 0
    }

    // MARK: Camera
    private func setupCamera() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            guard !self.session.isRunning else { return }
            // Remove any stale inputs/outputs from a previous session
            self.isConfiguring = true
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            self.session.inputs.forEach  { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition),
                let input  = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(input)
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "squatVideoQueue"))
            output.alwaysDiscardsLateVideoFrames = true
            if self.session.canAddOutput(output) { self.session.addOutput(output) }
            self.session.commitConfiguration()
            self.isConfiguring = false
            self.session.startRunning()
        }
    }

    func switchCamera() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.isConfiguring = true
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            guard
                let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                let inp = try? AVCaptureDeviceInput(device: dev),
                self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(inp)
            self.session.commitConfiguration()
            self.isConfiguring = false
            DispatchQueue.main.async { self.cameraPosition = newPos }
        }
    }

    // MARK: - Frame delivery
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                DispatchQueue.main.async {
                    let orientation: CGImagePropertyOrientation = self.cameraPosition == .front ? .leftMirrored : .right
                    guard !self._isProcessingFrame else { return }
                    self._isProcessingFrame = true
                    self.analyzeFrame(pixelBuffer: pixelBuffer, orientation: orientation)
                }
            }
        // MARK: - Analysis pipeline
    private func analyzeFrame(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) {
                defer { _isProcessingFrame = false }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        do {
            try handler.perform([poseRequest])
            guard let observation = poseRequest.results?.first else { return }
            let points = try observation.recognizedPoints(.all)

            let smoothedBodyPoints = buildSmoothedPoints(points)

            guard var result = extractAngles(from: points) else {
                notVisibleFrames += 1
                if notVisibleFrames >= 8 {
                    DispatchQueue.main.async { self.plankResult.issue = .notVisible }
                    pauseTimer()
                }
                return
            }
            notVisibleFrames = 0

            let s = smooth(result)
            result.hipAngle   = s.hip
            result.spineAngle = s.spine
            result.neckAngle  = s.neck

            evaluateForm(result: &result)
            updateTimerState(result: result)

            if holdingState {
                holdScoreAccum  += result.postureScore
                holdScoreFrames += 1
            }

            if result.issue == lastIssue { stableIssueFrames += 1 }
            else { stableIssueFrames = 0; lastIssue = result.issue }
            var published = result
            if stableIssueFrames < 3 { published.issue = plankResult.issue }

            let alertMsg   = buildAlertMessage(result: result)
            let goodFrames = consecutiveGoodFrames

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.bodyPoints  = smoothedBodyPoints
                self.plankResult = published
                self.consecutiveGoodFrames = goodFrames

                if let msg = alertMsg {
                    if self.formAlertMessage != msg {
                        self.formAlertMessage = msg
                        self.alertTimer?.invalidate()
                        self.alertTimer = Timer.scheduledTimer(
                            withTimeInterval: 2.5, repeats: false
                        ) { [weak self] _ in self?.showFormAlert = false }
                    }
                    self.showFormAlert = true
                } else {
                    self.alertTimer?.invalidate()
                    self.alertTimer = nil
                    self.showFormAlert = false
                }
            }

            if let msg = alertMsg {
                fireWatchNotification(title: "⚠️ Fix Your Form", body: msg, key: msg)
                speak(msg)
            }
        } catch { print("Plank Vision error: \(error)") }
    }

    private func buildSmoothedPoints(
        _ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
        var mapped: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (joint, point) in points where point.confidence > 0.2 {
            mapped[joint] = CGPoint(x: point.location.x, y: 1 - point.location.y)
        }
        pointsBuffer.append(mapped)
        if pointsBuffer.count > pointsBufferSize { pointsBuffer.removeFirst() }
        var smoothed: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        let uniqueJoints = Set(pointsBuffer.flatMap { $0.keys })
        for joint in uniqueJoints {
            let positions = pointsBuffer.compactMap { $0[joint] }
            guard !positions.isEmpty else { continue }
            let n = CGFloat(positions.count)
            smoothed[joint] = CGPoint(x: positions.map(\.x).reduce(0,+)/n,
                                      y: positions.map(\.y).reduce(0,+)/n)
        }
        return smoothed
    }

    private func extractAngles(
        from points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> PlankResult? {
        let useLeft = betterSide(points)
        let shoulderKey: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let hipKey:      VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let kneeKey:     VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee     : .rightKnee
        let ankleKey:    VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle    : .rightAnkle
        let earKey:      VNHumanBodyPoseObservation.JointName = useLeft ? .leftEar      : .rightEar

        for joint in [shoulderKey, hipKey, kneeKey, ankleKey, earKey] {
            guard let p = points[joint], p.confidence > 0.2 else { return nil }
        }

        let shoulder = points[shoulderKey]!.location
        let hip      = points[hipKey]!.location
        let knee     = points[kneeKey]!.location
        let ankle    = points[ankleKey]!.location
        let ear      = points[earKey]!.location

        var result = PlankResult()
        result.trackedLeftSide = useLeft
        result.hipAngle   = calculateAngle(first: shoulder, middle: hip,      last: knee)
        result.spineAngle = calculateAngle(first: shoulder, middle: hip,      last: ankle)
        result.neckAngle  = calculateAngle(first: ear,      middle: shoulder, last: hip)
        return result
    }

    private func evaluateForm(result: inout PlankResult) {
        let hip   = result.hipAngle
        let spine = result.spineAngle
        let neck  = result.neckAngle

        guard spine >= standingGuardMin else {
            result.hipOk = true; result.spineOk = true; result.neckOk = true
            result.issue = .ready; result.postureScore = 100
            return
        }

        result.hipOk   = hip   >= hipAcceptableMin
        result.spineOk = spine >= spineAcceptableMin
        result.neckOk  = neck  >= neckAcceptableMin

        var score = 100
        if !result.spineOk { score -= 40 }
        if !result.hipOk   { score -= 35 }
        if !result.neckOk  { score -= 25 }
        result.postureScore = max(score, 0)

        if !result.spineOk      { result.issue = .backSagging  }
        else if !result.hipOk   { result.issue = .hipsTooLow   }
        else if !result.neckOk  { result.issue = .headDropping }
        else                    { result.issue = .correct      }
    }

    private func updateTimerState(result: PlankResult) {
        if result.formIsValid {
            consecutiveBadFrames  = 0
            consecutiveGoodFrames = min(consecutiveGoodFrames + 1, goodFramesNeeded + 1)
            if consecutiveGoodFrames >= goodFramesNeeded { startTimer() }
        } else {
            consecutiveGoodFrames = max(0, consecutiveGoodFrames - 1)
            consecutiveBadFrames += 1
            if consecutiveBadFrames >= badFramesRequired {
                pauseTimer()
                DispatchQueue.main.async {
                    self.showFormBreakFlash = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.showFormBreakFlash = false
                    }
                }
            }
        }
    }

    private func startTimer() {
        guard !holdingState else { return }
        holdingState = true
        DispatchQueue.main.async { self.isHolding = true }

        timerTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    self.elapsedSeconds += 1

                    if self.targetSeconds > 0,
                       self.elapsedSeconds == self.targetSeconds,
                       !self.goalAnnounced {
                        self.goalAnnounced = true
                        self.speakImmediate("Goal reached! Amazing hold!")
                        self.fireWatchNotification(
                            title: "🎯 Goal Reached!",
                            body:  "You hit your \(self.formatSeconds(self.targetSeconds)) target!"
                        )
                    }

                    let milestones = [10, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300]
                    if milestones.contains(self.elapsedSeconds),
                       !self.announcedMilestones.contains(self.elapsedSeconds) {
                        self.announcedMilestones.insert(self.elapsedSeconds)
                        let secs  = self.elapsedSeconds
                        let label = secs < 60 ? "\(secs) seconds"
                                              : "\(secs / 60) minute\(secs / 60 > 1 ? "s" : "")"
                        self.speakImmediate("\(label)! Keep it up!")
                    }

                    if self.elapsedSeconds > self.bestSeconds {
                        self.bestSeconds = self.elapsedSeconds
                        if milestones.contains(self.bestSeconds) {
                            self.fireWatchNotification(
                                title: "🏆 New Best!",
                                body:  "You held for \(self.formatSeconds(self.bestSeconds))!"
                            )
                            self.speakImmediate("New personal best!")
                        }
                    }
                }
            }
        }
    }

    private func pauseTimer() {
        guard holdingState else { return }
        holdingState = false
        timerTask?.cancel()
        timerTask = nil
        DispatchQueue.main.async {
            self.isHolding = false
            self.recordHoldIfNeeded()
            self.elapsedSeconds = 0
            self.announcedMilestones.removeAll()
            self.goalAnnounced = false
        }
    }

    private func stopTimer() {
        holdingState = false
        timerTask?.cancel()
        timerTask = nil
    }

    private func buildAlertMessage(result: PlankResult) -> String? {
        guard !result.formIsValid else { return nil }
        if !result.spineOk { return "Keep Your Back Straight — Hips Are Sagging!" }
        if !result.hipOk   { return "Raise Your Hips — They're Too Low!" }
        if !result.neckOk  { return "Keep Your Head Neutral — Don't Drop It!" }
        return nil
    }

    func fireWatchNotification(title: String, body: String, key: String? = nil) {
        let throttleKey = key ?? title
        let now = Date()
        if let last = lastNotifTime[throttleKey],
           now.timeIntervalSince(last) < notifCooldown { return }
        lastNotifTime[throttleKey] = now
        NotificationManager.shared.send(title: title, body: body)
        WatchConnectivityManager.shared.sendFormAlert(exercise: "Plank", issue: "\(title): \(body)")
    }

    private func speak(_ text: String) {
        let now = Date()
        if let last = lastSpokenTime[text], now.timeIntervalSince(last) < voiceCooldown { return }
        lastSpokenTime[text] = now
        guard !speechSynthesizer.isSpeaking else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5; utterance.voice = AVSpeechSynthesisVoice(language: "en-US"); utterance.volume = 1.0
        speechSynthesizer.speak(utterance)
    }

    private func speakImmediate(_ text: String) {
        speechSynthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5; utterance.voice = AVSpeechSynthesisVoice(language: "en-US"); utterance.volume = 1.0
        speechSynthesizer.speak(utterance)
    }

    private func betterSide(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> Bool {
        let lShoulder: Float = points[.leftShoulder]?.confidence ?? 0
        let lHip:      Float = points[.leftHip]?.confidence      ?? 0
        let lKnee:     Float = points[.leftKnee]?.confidence     ?? 0
        let lAnkle:    Float = points[.leftAnkle]?.confidence    ?? 0
        let lEar:      Float = points[.leftEar]?.confidence      ?? 0
        let rShoulder: Float = points[.rightShoulder]?.confidence ?? 0
        let rHip:      Float = points[.rightHip]?.confidence      ?? 0
        let rKnee:     Float = points[.rightKnee]?.confidence     ?? 0
        let rAnkle:    Float = points[.rightAnkle]?.confidence    ?? 0
        let rEar:      Float = points[.rightEar]?.confidence      ?? 0
        return (lShoulder + lHip + lKnee + lAnkle + lEar) >= (rShoulder + rHip + rKnee + rAnkle + rEar)
    }

    private func calculateAngle(first: CGPoint, middle: CGPoint, last: CGPoint) -> Double {
        let a = atan2(first.y  - middle.y, first.x  - middle.x)
        let b = atan2(last.y   - middle.y, last.x   - middle.x)
        var angle = abs((a - b) * 180 / .pi)
        if angle > 180 { angle = 360 - angle }
        return angle
    }

    private func smooth(_ result: PlankResult) -> (hip: Double, spine: Double, neck: Double) {
        angleBuffer.append((result.hipAngle, result.spineAngle, result.neckAngle))
        if angleBuffer.count > angleBufferSize { angleBuffer.removeFirst() }
        let n = Double(angleBuffer.count)
        return (
            hip:   angleBuffer.map(\.hip).reduce(0,   +) / n,
            spine: angleBuffer.map(\.spine).reduce(0, +) / n,
            neck:  angleBuffer.map(\.neck).reduce(0,  +) / n
        )
    }

    var formattedTime:     String { formatSeconds(elapsedSeconds) }
    var formattedBestTime: String { formatSeconds(bestSeconds) }

    func formatSeconds(_ total: Int) -> String {
        String(format: "%02d:%02d", total / 60, total % 60)
    }
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PUSH-UP
// ─────────────────────────────────────────────────────────────────────────────
//
//  PushUpView.swift
//  PostureCorrect
//
//  Camera placement: SIDE-ON — phone on the floor to your left or right,
//  ~1.5–2 m away, lens at shoulder/hip height. Full body must be visible.
//
//  ─────────────────────────────────────────────────────────────────────────
//  BIOMECHANICALLY CORRECT PUSH-UP ANGLES  (Vision side-on, floor camera)
//  ─────────────────────────────────────────────────────────────────────────
//
//  1. Elbow angle  (shoulder → elbow → wrist)
//     • Top (arms extended):        150°–180°
//     • Bottom excellent:            80°–100°
//     • Bottom acceptable:           70°–110°
//     • Depth threshold:            ≤ 72°   (4 consecutive frames — based on observed ~58° bottom)
//     • Excellent depth:              ≤ 65°
//     • Minimum descent to record a rep event: ≤ 100°
//     • Descent trigger: < 145°
//
//  2. Hip angle  (shoulder → hip → knee)
//     • Excellent:   170°–180°
//     • Acceptable:  155°–170°  (was 165° — too strict for side-on camera)
//     • Poor:        < 155°
//     • Sagging fail: < 145°
//
//  3. Plank alignment score  (0–100, higher = straighter body)
//     • Perfect plank:   100  (hip exactly on shoulder–ankle line)
//     • Good form:       ≥ 85 (standing, bottom, ascending)
//     • Descending:      ≥ 80 (slight shift allowed)
//     • Visible sag/pike: < 80
//     • Extreme:          0   (hip ≥30% of body length off the line)
//     • spineSagging = true → hip below line (sagging); false → piking
//
//  4. Neck angle  (ear → shoulder → hip)
//     • Excellent:   170°–180°
//     • Acceptable:  160°–170°
//     • Poor:        < 160°
//
//  ─────────────────────────────────────────────────────────────────────────
//  REP COUNTING — STRICT FORM-GATED STATE MACHINE
//  ─────────────────────────────────────────────────────────────────────────
//
//  A rep is counted ONLY when ALL of the following are satisfied:
//    1. Elbow reached ≤ 110° for ≥ 3 consecutive smoothed frames (depth)
//    2. Arms returned to ≥ 150° for ≥ 2 consecutive smoothed frames (top)
//    3. Zero hip form errors (hipAngle < 165°) for ≥ 3 frames during the rep
//    4. Zero spine form errors (spineAngle > 35°) for ≥ 3 frames during the rep
//    5. Zero neck form errors (neckAngle < 155°) for ≥ 3 frames during the rep
//       (neck is advisory only when ear joint confidence < 0.15 — skipped)
//
//  Anti-jitter:
//    • 8-frame angle smoother on all rep-counting angles
//    • 6-frame overlay buffer keeps skeleton locked to body
//    • validDepthFrames uses += only; never hard-resets mid-rep
//    • minElbowAngle anchors the true bottom
//    • validStandingFrames resets immediately when elbow drops below elbowUpMin
//    • notVisibleFrames: 8 frames before surfacing "not visible"
//    • stableIssueFrames: 3 frames before changing the issue label
//

import SwiftUI
import AVFoundation
import Vision
import Combine
import AVKit

// ─────────────────────────────────────────────
// MARK: - DESIGN TOKENS  (shared with SquatView palette)
// ─────────────────────────────────────────────
private enum PUDT {
    static let bg0    = Color(red: 0.04, green: 0.04, blue: 0.07)
    static let bg1    = Color(red: 0.08, green: 0.09, blue: 0.13)
    static let bg2    = Color(red: 0.12, green: 0.13, blue: 0.18)
    static let lime   = Color(red: 0.27, green: 0.98, blue: 0.56)
    static let sky    = Color(red: 0.35, green: 0.72, blue: 1.00)
    static let amber  = Color(red: 1.00, green: 0.74, blue: 0.18)
    static let coral  = Color(red: 1.00, green: 0.33, blue: 0.38)
    static let violet = Color(red: 0.72, green: 0.50, blue: 1.00)
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.45)
    static let textMono      = Font.system(size: 9, weight: .bold, design: .monospaced)
    static let stroke        = Color.white.opacity(0.07)
}

// MARK: - PUSHUP ISSUE
enum PushUpIssue: String {
    case correct       = "✅ Perfect Push-Up"
    case ready         = "🧍 Get Into Push-Up Position"
    case hipsTooLow    = "❌ Raise Your Hips"
    case hipsTooHigh   = "❌ Lower Your Hips"
    case backSagging   = "❌ Keep Body Straight"
    case neckBad       = "❌ Keep Head Neutral"
    case notDeepEnough = "❌ Go Lower"
    case detecting     = "🔍 Detecting..."
    case notVisible    = "📷 Full Body Not Visible"
    case improperDepth = "⚠️ Go Deeper Next Time"
}

// MARK: - PUSHUP PHASE
enum PushUpPhase { case standing, descending, bottom, ascending }

// MARK: - PUSHUP RESULT
struct PushUpResult {
    var issue: PushUpIssue  = .detecting
    var postureScore: Int   = 100
    var elbowAngle:  Double = 180
    var hipAngle:    Double = 180
    var spineAngle:  Double = 0         // plank alignment score 0–100
    var spineSagging: Bool  = false     // true = hip below plank line (sag); false = piking
    var neckAngle:   Double = 175       // ear → shoulder → hip
    var neckTracked: Bool   = false     // false when ear joint not visible
    var trackedLeftSide: Bool = true
    var elbowOk:  Bool = true
    var hipOk:    Bool = true
    var spineOk:  Bool = true
    var neckOk:   Bool = true
}

// MARK: - CAMERA VIEW  (compact GluteBridge-style UI)
struct PushupCameraView: View {
    @StateObject private var viewModel = PushUpViewModel()
    @State private var showGoalSheet   = false
    @State private var showStatsSheet  = false

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.session).ignoresSafeArea()

            PushUpSkeletonOverlay(
                bodyPoints: viewModel.bodyPoints,
                result:     viewModel.postureResult
            ).ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                if viewModel.showFormAlert {
                    PushUpFormAlertBanner(message: viewModel.formAlertMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: viewModel.showFormAlert)
                }
                Spacer()
                bottomPanel
            }

            // Good rep flash
            if viewModel.showGoodRepFlash {
                Color.green.opacity(0.22).ignoresSafeArea().allowsHitTesting(false)
            }

            // Bad rep flash overlay
            if viewModel.badRepMessage != nil {
                Color.red.opacity(0.25).ignoresSafeArea().allowsHitTesting(false)
                VStack {
                    Spacer()
                    Text(viewModel.badRepMessage ?? "")
                        .font(.title3.bold()).foregroundColor(.white)
                        .multilineTextAlignment(.center).padding()
                        .background(Color.red.opacity(0.85)).cornerRadius(16)
                        .padding(.bottom, 220)
                }
            }
        }
        .onAppear    { viewModel.start() }
        .onDisappear { viewModel.stopAndSave() }
        .sheet(isPresented: $showGoalSheet)  { PushUpGoalSetupSheet(viewModel: viewModel) }
        .sheet(isPresented: $showStatsSheet) { PushUpStatsSheet(viewModel: viewModel) }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack(spacing: 8) {
            Text(viewModel.sessionTimeString)
                .font(.caption.monospacedDigit().bold())
                .foregroundColor(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.black.opacity(0.5)).cornerRadius(20)

            Spacer()

            ZStack {
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 3).frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.postureResult.postureScore) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40).rotationEffect(.degrees(-90))
                Text("\(viewModel.postureResult.postureScore)")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
            }

            HStack(spacing: 4) {
                Button { showStatsSheet = true } label: {
                    Image(systemName: "chart.bar.fill").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                Button { showGoalSheet = true } label: {
                    Image(systemName: "target").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                Button { viewModel.switchCamera() } label: {
                    Image(systemName: "camera.rotate").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(.black.opacity(0.5)).cornerRadius(24)
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    // MARK: - Bottom panel
    private var bottomPanel: some View {
        VStack(spacing: 10) {

            HStack {
                Text(viewModel.postureResult.issue.rawValue)
                    .font(.subheadline.bold()).foregroundColor(.white)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(viewModel.phaseText)
                    .font(.caption.bold())
                    .foregroundColor(viewModel.phaseColor)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(viewModel.phaseColor.opacity(0.15))
                    .cornerRadius(12)
            }

            HStack(spacing: 6) {
                PushUpAngleChip(label: "Elbow", angle: viewModel.postureResult.elbowAngle, isOk: viewModel.postureResult.elbowOk)
                PushUpAngleChip(label: "Hip",   angle: viewModel.postureResult.hipAngle,   isOk: viewModel.postureResult.hipOk)
                PushUpAngleChip(label: "Back",  angle: viewModel.postureResult.spineAngle, isOk: viewModel.postureResult.spineOk, unit: "")
                if viewModel.postureResult.neckTracked {
                    PushUpAngleChip(label: "Neck", angle: viewModel.postureResult.neckAngle, isOk: viewModel.postureResult.neckOk)
                }
            }

            if viewModel.targetReps > 0 {
                PushUpProgressBar(
                    currentSet: viewModel.currentSet,
                    totalSets:  viewModel.targetSets,
                    repsInSet:  viewModel.repsInCurrentSet,
                    targetReps: viewModel.targetReps
                )
            }

            HStack(alignment: .center, spacing: 0) {
                VStack(spacing: 0) {
                    Text("\(viewModel.repsInCurrentSet)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(viewModel.targetReps > 0
                         ? "SET \(viewModel.currentSet) OF \(viewModel.targetSets)"
                         : "REPS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .kerning(1.2)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 44)

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Label("\(viewModel.goodReps)", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("\(viewModel.badReps)", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .font(.subheadline.bold())
                    Text("QUALITY").font(.system(size: 10)).foregroundColor(.white.opacity(0.5)).kerning(1.2)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 44)

                Button { viewModel.resetSession() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3).foregroundColor(.white.opacity(0.7))
                        Text("RESET").font(.system(size: 10)).foregroundColor(.white.opacity(0.4)).kerning(1.2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(.ultraThinMaterial.opacity(0.95))
        .background(Color.black.opacity(0.6))
        .cornerRadius(24)
        .padding(.horizontal, 12).padding(.bottom, 8)
    }

    private var scoreColor: Color {
        let s = viewModel.postureResult.postureScore
        if s >= 80 { return .green }
        if s >= 55 { return .yellow }
        return .red
    }
}

// MARK: - FORM ALERT BANNER
struct PushUpFormAlertBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text(message).font(.subheadline.bold()).foregroundColor(.white)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.orange, lineWidth: 1.5))
        .shadow(color: .orange.opacity(0.4), radius: 8).padding(.horizontal)
    }
}

// MARK: - ANGLE CHIP
struct PushUpAngleChip: View {
    let label: String
    let angle: Double
    let isOk:  Bool
    var unit:  String = "°"

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(isOk ? Color.green : Color.red).frame(width: 6, height: 6)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.6))
            Text("\(Int(angle))\(unit)").font(.system(size: 12, weight: .bold)).foregroundColor(isOk ? .green : .red)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(isOk ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - PROGRESS BAR
struct PushUpProgressBar: View {
    let currentSet: Int; let totalSets: Int; let repsInSet: Int; let targetReps: Int
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Set \(currentSet) of \(totalSets)")
                    .font(.caption).foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(repsInSet)/\(targetReps) reps")
                    .font(.caption.bold()).foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.15)).frame(height: 10)
                    RoundedRectangle(cornerRadius: 6).fill(Color.blue)
                        .frame(
                            width: geo.size.width * CGFloat(min(repsInSet, targetReps)) / CGFloat(max(targetReps, 1)),
                            height: 10
                        )
                        .animation(.spring(response: 0.3), value: repsInSet)
                }
            }.frame(height: 10)
        }.padding(.horizontal, 4)
    }
}

// MARK: - SKELETON OVERLAY
struct PushUpSkeletonOverlay: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let result: PushUpResult

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let shoulder: VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftShoulder : .rightShoulder
                let elbow:    VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftElbow    : .rightElbow
                let wrist:    VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftWrist    : .rightWrist
                let hip:      VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftHip      : .rightHip
                let knee:     VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftKnee     : .rightKnee
                let ankle:    VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftAnkle    : .rightAnkle
                let ear:      VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftEar      : .rightEar

                drawLine(shoulder, elbow, geo, ok: result.elbowOk)
                drawLine(elbow,    wrist, geo, ok: result.elbowOk)
                drawLine(shoulder, hip,   geo, ok: result.spineOk)
                drawLine(hip,      knee,  geo, ok: result.hipOk)
                drawLine(knee,     ankle, geo, ok: result.hipOk)
                if result.neckTracked {
                    drawLine(ear, shoulder, geo, ok: result.neckOk)
                }

                let joints: [VNHumanBodyPoseObservation.JointName] = result.neckTracked
                    ? [shoulder, elbow, wrist, hip, knee, ankle, ear]
                    : [shoulder, elbow, wrist, hip, knee, ankle]

                ForEach(joints, id: \.self) { joint in
                    if let pt = bodyPoints[joint] {
                        Circle()
                            .fill(dotColor(for: joint,
                                          shoulder: shoulder, elbow: elbow, wrist: wrist,
                                          hip: hip, knee: knee, ankle: ankle, ear: ear))
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                            .position(x: pt.x * geo.size.width, y: pt.y * geo.size.height)
                    }
                }
            }
        }
    }

    private func dotColor(
        for joint: VNHumanBodyPoseObservation.JointName,
        shoulder: VNHumanBodyPoseObservation.JointName,
        elbow:    VNHumanBodyPoseObservation.JointName,
        wrist:    VNHumanBodyPoseObservation.JointName,
        hip:      VNHumanBodyPoseObservation.JointName,
        knee:     VNHumanBodyPoseObservation.JointName,
        ankle:    VNHumanBodyPoseObservation.JointName,
        ear:      VNHumanBodyPoseObservation.JointName
    ) -> Color {
        switch joint {
        case elbow, wrist:   return result.elbowOk ? .green : .red
        case shoulder:       return (result.spineOk && result.neckOk) ? .green : .red
        case hip:            return result.hipOk   ? .green : .red
        case knee, ankle:    return result.hipOk   ? .green : .red
        case ear:            return result.neckOk  ? .green : .red
        default:             return .white
        }
    }

    @ViewBuilder
    private func drawLine(
        _ j1: VNHumanBodyPoseObservation.JointName,
        _ j2: VNHumanBodyPoseObservation.JointName,
        _ geo: GeometryProxy,
        ok: Bool
    ) -> some View {
        if let p1 = bodyPoints[j1], let p2 = bodyPoints[j2] {
            Path { path in
                path.move(to:    CGPoint(x: p1.x * geo.size.width, y: p1.y * geo.size.height))
                path.addLine(to: CGPoint(x: p2.x * geo.size.width, y: p2.y * geo.size.height))
            }
            .stroke(ok ? Color.green : Color.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - GOAL SETUP SHEET  (premium dark — matches SquatGoalSetupSheet)
// ─────────────────────────────────────────────
struct PushUpGoalSetupSheet: View {
    @ObservedObject var viewModel: PushUpViewModel
    @Environment(\.dismiss) var dismiss

    @State private var sets     = 3
    @State private var reps     = 10
    @State private var restSec  = 60
    @State private var launched = false

    private struct Preset {
        let name: String; let icon: String
        let sets: Int;    let reps: Int; let rest: Int
        let color: Color
    }
    private let presets: [Preset] = [
        Preset(name: "Beginner",  icon: "leaf.fill",          sets: 2, reps: 6,  rest: 90,  color: PUDT.lime),
        Preset(name: "Standard",  icon: "figure.strengthtraining.traditional",
                                                               sets: 3, reps: 10, rest: 60,  color: PUDT.sky),
        Preset(name: "Strength",  icon: "bolt.fill",          sets: 4, reps: 8,  rest: 90,  color: PUDT.amber),
        Preset(name: "Endurance", icon: "flame.fill",         sets: 4, reps: 15, rest: 45,  color: PUDT.coral),
        Preset(name: "HIIT",      icon: "timer",              sets: 5, reps: 12, rest: 30,  color: PUDT.violet),
    ]

    var body: some View {
        ZStack {
            PUDT.bg0.ignoresSafeArea()

            ZStack {
                Circle().fill(PUDT.coral.opacity(0.07)).frame(width: 300).blur(radius: 80).offset(x: 100, y: -180)
                Circle().fill(PUDT.amber.opacity(0.05)).frame(width: 240).blur(radius: 70).offset(x: -120, y: 200)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    goalHeader
                    presetRow
                    sliderSection
                    summaryCard
                    actionButtons
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .opacity(launched ? 1 : 0)
                .offset(y: launched ? 0 : 24)
                .animation(.spring(response: 0.5, dampingFraction: 0.78), value: launched)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { launched = true } }
    }

    // ── Header ──────────────────────────────
    private var goalHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("WORKOUT")
                    .font(PUDT.textMono).foregroundColor(PUDT.coral).kerning(3)
                Text("Set Goal")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(PUDT.textPrimary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(PUDT.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(PUDT.bg2).clipShape(Circle())
                    .overlay(Circle().stroke(PUDT.stroke, lineWidth: 1))
            }
        }
        .padding(.top, 24)
    }

    // ── Preset pills ────────────────────────
    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PRESETS")
                .font(PUDT.textMono).foregroundColor(PUDT.textSecondary).kerning(2)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(presets, id: \.name) { p in
                        let active = sets == p.sets && reps == p.reps && restSec == p.rest
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                sets = p.sets; reps = p.reps; restSec = p.rest
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: p.icon)
                                    .font(.system(size: 18)).foregroundColor(p.color)
                                Text(p.name)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(PUDT.textPrimary)
                                Text("\(p.sets)×\(p.reps)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(PUDT.textSecondary)
                            }
                            .frame(width: 76).padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(active ? p.color.opacity(0.18) : PUDT.bg1)
                                    .overlay(RoundedRectangle(cornerRadius: 16)
                                        .stroke(active ? p.color.opacity(0.50) : PUDT.stroke, lineWidth: 1))
                            )
                        }
                    }
                }
                .padding(.bottom, 2)
            }
        }
    }

    // ── Sliders ─────────────────────────────
    private var sliderSection: some View {
        VStack(spacing: 18) {
            PushUpGoalSliderRow(label: "SETS",         value: $sets,    range: 1...10,   step: 1,  accent: PUDT.coral,  display: "\(sets)")
            PushUpGoalSliderRow(label: "REPS PER SET", value: $reps,    range: 1...30,   step: 1,  accent: PUDT.amber,  display: "\(reps)")
            PushUpGoalSliderRow(label: "REST",         value: $restSec, range: 10...180, step: 10, accent: PUDT.sky,    display: "\(restSec)s")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(PUDT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(PUDT.stroke, lineWidth: 1))
        )
    }

    // ── Summary ─────────────────────────────
    private var summaryCard: some View {
        HStack(spacing: 0) {
            PushUpGoalSummaryCell(value: "\(sets)",        label: "SETS",     accent: PUDT.coral)
            Rectangle().fill(PUDT.stroke).frame(width: 1, height: 36)
            PushUpGoalSummaryCell(value: "\(reps)",        label: "REPS/SET", accent: PUDT.amber)
            Rectangle().fill(PUDT.stroke).frame(width: 1, height: 36)
            PushUpGoalSummaryCell(value: "\(sets * reps)", label: "TOTAL",    accent: PUDT.lime)
            Rectangle().fill(PUDT.stroke).frame(width: 1, height: 36)
            PushUpGoalSummaryCell(value: "\(restSec)s",    label: "REST",     accent: PUDT.sky)
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18).fill(PUDT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(PUDT.stroke, lineWidth: 1))
        )
    }

    // ── Actions ─────────────────────────────
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.setGoal(sets: sets, reps: reps, restSeconds: restSec)
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill").font(.system(size: 14, weight: .bold))
                    Text("Start Workout")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 17)
                .background(
                    ZStack {
                        LinearGradient(colors: [PUDT.coral, PUDT.amber],
                                       startPoint: .leading, endPoint: .trailing)
                        LinearGradient(colors: [Color.white.opacity(0.18), Color.clear],
                                       startPoint: .top, endPoint: .bottom)
                    }
                )
                .cornerRadius(16)
                .shadow(color: PUDT.coral.opacity(0.4), radius: 14, y: 6)
            }

            Button {
                viewModel.clearGoal(); dismiss()
            } label: {
                Text("Clear Goal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PUDT.coral)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(PUDT.coral.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(PUDT.coral.opacity(0.22), lineWidth: 1))
                    )
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - GOAL SUB-VIEWS
// ─────────────────────────────────────────────
private struct PushUpGoalSliderRow: View {
    let label:   String
    @Binding var value: Int
    let range:   ClosedRange<Int>
    let step:    Int
    let accent:  Color
    let display: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(PUDT.textMono).foregroundColor(PUDT.textSecondary).kerning(1.5)
                Spacer()
                Text(display)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(accent)
            }
            GeometryReader { geo in
                let pct   = CGFloat(value - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound)
                let fillW = geo.size.width * pct
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.07)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [accent.opacity(0.9), accent],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, fillW), height: 6)
                    Circle().fill(accent).frame(width: 22, height: 22)
                        .shadow(color: accent.opacity(0.5), radius: 6)
                        .offset(x: max(0, fillW - 11))
                }
                .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                    let raw     = drag.location.x / geo.size.width
                    let clamped = min(max(0, raw), 1)
                    let floatV  = Double(range.lowerBound) + clamped * Double(range.upperBound - range.lowerBound)
                    let stepped = Int(round(floatV / Double(step))) * step
                    value = min(max(range.lowerBound, stepped), range.upperBound)
                })
            }
            .frame(height: 22)
        }
    }
}

private struct PushUpGoalSummaryCell: View {
    let value: String; let label: String; let accent: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(accent)
            Text(label)
                .font(PUDT.textMono).foregroundColor(PUDT.textSecondary).kerning(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// ─────────────────────────────────────────────
// MARK: - SESSION STATS SHEET  (premium dark — matches SquatStatsSheet)
// ─────────────────────────────────────────────
struct PushUpStatsSheet: View {
    @ObservedObject var viewModel: PushUpViewModel
    @Environment(\.dismiss) var dismiss

    private var qualityRate: Int {
        let total = viewModel.goodReps + viewModel.badReps
        guard total > 0 else { return 0 }
        return Int(Double(viewModel.goodReps) / Double(total) * 100)
    }

    var body: some View {
        ZStack {
            PUDT.bg0.ignoresSafeArea()

            ZStack {
                Circle().fill(PUDT.coral.opacity(0.06)).frame(width: 320).blur(radius: 80).offset(x: -100, y: -200)
                Circle().fill(PUDT.amber.opacity(0.05)).frame(width: 260).blur(radius: 70).offset(x: 140, y: 100)
                Circle().fill(PUDT.sky.opacity(0.04)).frame(width: 200).blur(radius: 60).offset(x: -60, y: 400)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    statsHeader
                    heroBlock
                    fourPillsRow
                    if viewModel.repHistory.count > 1 { graphCard }
                    timelineCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
            }
        }
        .preferredColorScheme(.dark)
    }

    // ── Header ──────────────────────────────
    private var statsHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SESSION")
                    .font(PUDT.textMono).foregroundColor(PUDT.coral).kerning(3)
                Text("Analytics")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(PUDT.textPrimary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(PUDT.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(PUDT.bg2).clipShape(Circle())
                    .overlay(Circle().stroke(PUDT.stroke, lineWidth: 1))
            }
        }
        .padding(.top, 24)
    }

    // ── Hero block ──────────────────────────
    private var heroBlock: some View {
        HStack(spacing: 16) {
            // Quality ring
            ZStack {
                Circle().stroke(Color.white.opacity(0.06), lineWidth: 10).frame(width: 112, height: 112)
                Circle()
                    .trim(from: 0, to: CGFloat(qualityRate) / 100)
                    .stroke(AngularGradient(colors: [PUDT.coral, PUDT.amber, PUDT.coral], center: .center),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 112, height: 112).rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.9), value: qualityRate)
                // Glow
                Circle()
                    .trim(from: 0, to: CGFloat(qualityRate) / 100)
                    .stroke(PUDT.coral.opacity(0.22), lineWidth: 16)
                    .frame(width: 112, height: 112).rotationEffect(.degrees(-90))
                    .blur(radius: 6)
                    .animation(.easeOut(duration: 0.9), value: qualityRate)
                VStack(spacing: 1) {
                    Text("\(qualityRate)%")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(PUDT.textPrimary)
                    Text("QUALITY")
                        .font(PUDT.textMono).foregroundColor(PUDT.textSecondary).kerning(1)
                }
            }
            // Tiles
            VStack(spacing: 10) {
                PushUpStatsHeroTile(value: "\(viewModel.totalRepsAllTime)", label: "TOTAL REPS", accent: PUDT.coral)
                PushUpStatsHeroTile(value: viewModel.sessionTimeString,     label: "DURATION",   accent: PUDT.sky)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(PUDT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(PUDT.stroke, lineWidth: 1))
        )
    }

    // ── Four metric pills ───────────────────
    private var fourPillsRow: some View {
        HStack(spacing: 8) {
            PushUpStatsMetricPill(value: "\(viewModel.goodReps)",    label: "GOOD", color: PUDT.lime,  icon: "checkmark.circle.fill")
            PushUpStatsMetricPill(value: "\(viewModel.badReps)",     label: "BAD",  color: PUDT.coral, icon: "xmark.circle.fill")
            PushUpStatsMetricPill(value: "\(viewModel.averageScore)",label: "AVG",  color: PUDT.amber, icon: "waveform.path.ecg")
            PushUpStatsMetricPill(value: "\(viewModel.bestRepScore)",label: "BEST", color: PUDT.sky,   icon: "bolt.fill")
        }
    }

    // ── Score graph ─────────────────────────
    private var graphCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            PushUpStatsSectionLabel(title: "REP SCORES", sub: "\(viewModel.repHistory.count) reps")
            PushUpRepScoreGraph(records: viewModel.repHistory).frame(height: 140)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(PUDT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(PUDT.stroke, lineWidth: 1))
        )
    }

    // ── Rep timeline ────────────────────────
    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            PushUpStatsSectionLabel(title: "REP HISTORY", sub: "Most recent first")
            if viewModel.repHistory.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 36)).foregroundColor(Color.white.opacity(0.10))
                    Text("No reps yet — start pushing! 💪")
                        .font(.system(size: 13, weight: .medium)).foregroundColor(PUDT.textSecondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30)
            } else {
                VStack(spacing: 7) {
                    ForEach(viewModel.repHistory.reversed()) { rep in
                        PushUpStatsRepRow(rep: rep)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(PUDT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(PUDT.stroke, lineWidth: 1))
        )
    }
}

// ─────────────────────────────────────────────
// MARK: - STATS SUB-VIEWS
// ─────────────────────────────────────────────
private struct PushUpStatsHeroTile: View {
    let value: String; let label: String; let accent: Color
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 3, height: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundColor(PUDT.textPrimary)
                Text(label)
                    .font(PUDT.textMono).foregroundColor(PUDT.textSecondary).kerning(1.2)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(PUDT.bg2).cornerRadius(13)
    }
}

private struct PushUpStatsMetricPill: View {
    let value: String; let label: String; let color: Color; let icon: String
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(PUDT.textPrimary)
            Text(label).font(PUDT.textMono).foregroundColor(PUDT.textSecondary).kerning(1)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.18), lineWidth: 1))
        )
    }
}

private struct PushUpStatsSectionLabel: View {
    let title: String; let sub: String
    var body: some View {
        HStack(alignment: .bottom) {
            Text(title).font(PUDT.textMono).foregroundColor(PUDT.coral).kerning(2.5)
            Spacer()
            Text(sub).font(.system(size: 11, weight: .medium)).foregroundColor(PUDT.textSecondary)
        }
    }
}

private struct PushUpStatsRepRow: View {
    let rep: RepRecord
    private var col: Color { rep.isGood ? PUDT.lime : PUDT.coral }
    var body: some View {
        HStack(spacing: 10) {
            Text("#\(rep.repNumber)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(col).frame(width: 32)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05))
                    RoundedRectangle(cornerRadius: 4).fill(col.opacity(0.6))
                        .frame(width: g.size.width * CGFloat(rep.score) / 100)
                        .animation(.spring(response: 0.5), value: rep.score)
                }
            }
            .frame(height: 7)
            Text(rep.isGood ? "\(rep.score)" : "—")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(rep.isGood ? .white : PUDT.textSecondary)
                .frame(width: 28, alignment: .trailing)
            Image(systemName: rep.isGood ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 13)).foregroundColor(col)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(Color.white.opacity(0.025)).cornerRadius(9)
    }
}

private struct PushUpRepScoreGraph: View {
    let records: [RepRecord]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width; let h = geo.size.height
            let count = records.count
            guard count > 0 else { return AnyView(EmptyView()) }
            let slot = w / CGFloat(count)
            return AnyView(ZStack(alignment: .bottom) {
                // Grid lines
                ForEach([0, 25, 50, 75, 100], id: \.self) { val in
                    let y = h * (1 - CGFloat(val) / 100)
                    Path { p in p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: w, y: y)) }
                        .stroke(val == 0 ? Color.white.opacity(0.12) : Color.white.opacity(0.04),
                                style: StrokeStyle(lineWidth: 1, dash: val == 0 ? [] : [4, 4]))
                    if val > 0 {
                        Text("\(val)")
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.18))
                            .position(x: 12, y: max(8, y - 6))
                    }
                }
                // Connecting line
                if count > 1 {
                    Path { path in
                        for (i, rep) in records.enumerated() {
                            let x = slot * CGFloat(i) + slot / 2
                            let y = h * (1 - CGFloat(rep.score) / 100)
                            i == 0 ? path.move(to: .init(x: x, y: y)) : path.addLine(to: .init(x: x, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
                // Bars
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(records) { rep in
                        let barH = max(6, h * CGFloat(rep.score) / 100)
                        let col  = rep.isGood ? PUDT.lime : PUDT.coral
                        VStack(spacing: 0) {
                            Circle().fill(col).frame(width: 4, height: 4)
                            Rectangle()
                                .fill(LinearGradient(colors: [col.opacity(0.9), col.opacity(0.15)],
                                                     startPoint: .top, endPoint: .bottom))
                                .frame(height: max(1, barH - 4)).cornerRadius(3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            })
        }
    }
}

// MARK: - VIEW MODEL
final class PushUpViewModel: NSObject, ObservableObject,
                              AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession()

    @Published var bodyPoints:     [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var postureResult   = PushUpResult()
    @Published var currentPhase: PushUpPhase = .standing
    @Published var phaseText       = "Up"
    @Published var phaseColor: Color = .white
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    @Published var showFormAlert     = false
    @Published var formAlertMessage  = ""
    @Published var showGoodRepFlash  = false
    @Published var badRepMessage: String? = nil

    // Analytics
    @Published var repHistory:      [RepRecord] = []
    @Published var goodReps         = 0
    @Published var badReps          = 0
    @Published var totalRepsAllTime = 0
    @Published var averageScore     = 0
    @Published var bestRepScore     = 0

    // Sets / Goal
    @Published var targetSets        = 0
    @Published var targetReps        = 0
    @Published var currentSet        = 1
    @Published var repsInCurrentSet  = 0

    // Session timer
    @Published var sessionTimeString = "00:00"
    private var sessionStartDate: Date?
    private var sessionTimer: Timer?
    
    // add with the other private vars, around line 2770
    private var isConfiguring = false
    // add with other private vars
    private let cameraQueue = DispatchQueue(label: "squatCameraQueue")

    @Published var reps = 0

    // ── Smoothing buffers ────────────────────────────────────────────────────
    private var pointsBuffer: [[VNHumanBodyPoseObservation.JointName: CGPoint]] = []
    private var frameBuffer:  [PushUpResult] = []

    // ── Rep-counting state ───────────────────────────────────────────────────
    private var lastElbowAngle      = 180.0
    private var minElbowAngle       = 180.0
    private var pushUpStarted       = false
    private var depthReached        = false
    private var bottomReached       = false
    private var validDepthFrames    = 0
    private var validBottomFrames   = 0
    private var validStandingFrames = 0

    // ── Debounce / noise ─────────────────────────────────────────────────────
    private var stableIssueFrames  = 0
    private var notVisibleFrames   = 0
    private var lastIssue: PushUpIssue = .detecting
    private var alertTimer: Timer?

    // ── Per-rep form error accumulators ─────────────────────────────────────
    private var hipErrorFrames    = 0
    private var spineErrorFrames  = 0
    private var neckErrorFrames   = 0
    private var hadHipError       = false
    private var hadSpineError     = false
    private var hadNeckError      = false

    // ── Watch / notification throttle ───────────────────────────────────────
    private var lastNotifTime: [String: Date] = [:]
    private let notifCooldown: TimeInterval   = 5.0

    private let speechSynth      = AVSpeechSynthesizer()
    private var lastSpeechTime:  Date = .distantPast
    private var lastSpokenIssue: PushUpIssue = .detecting

    // ════════════════════════════════════════════════════════════════════════
    // THRESHOLDS
    // ════════════════════════════════════════════════════════════════════════

    private let elbowDescentTrigger: Double = 145
    private let elbowMinimumDescent: Double = 100
    private let elbowDepthMax:       Double = 72
    private let elbowDepthExcellent: Double = 65
    private let elbowUpMin:          Double = 150

    private let hipExcellentMin:  Double = 170
    private let hipAcceptableMin: Double = 155
    private let hipSaggingFail:   Double = 145

    private let spineIdealMax: Double = 35
    private let uprightGuard:  Double = 60

    private let neckAcceptableMin: Double = 160
    private let neckErrorMin:      Double = 155

    private let depthFramesRequired:    Int = 4
    private let standingFramesRequired: Int = 2
    
    private var restTimer: Timer?

    // MARK: - Lifecycle
    func start() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { return }
            DispatchQueue.global(qos: .userInitiated).async { self.setupCamera() }
        }
        startSessionTimer()
        fireWatchNotification(title: "🏋️ Push-Up Started", body: "Get into position and begin.")
    }

    func stop() {
        sessionTimer?.invalidate()
        restTimer?.invalidate()
        cameraQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func resetSession() {
        DispatchQueue.main.async {
            self.reps = 0; self.repsInCurrentSet = 0; self.currentSet = 1
            self.goodReps = 0; self.badReps = 0; self.totalRepsAllTime = 0
            self.averageScore = 0; self.bestRepScore = 0; self.repHistory = []
            self.currentPhase = .standing; self.phaseText = "Up"; self.phaseColor = .white
        }
        resetPushUpState()
    }

    private func resetPushUpState() {
        pushUpStarted = false; depthReached = false; bottomReached = false
        validDepthFrames = 0; validBottomFrames = 0; validStandingFrames = 0
        lastElbowAngle = 180; minElbowAngle = 180
        hipErrorFrames = 0; spineErrorFrames = 0; neckErrorFrames = 0
        hadHipError = false; hadSpineError = false; hadNeckError = false
        frameBuffer = []; pointsBuffer = []
        DispatchQueue.main.async {
            self.currentPhase = .standing; self.phaseText = "Up"; self.phaseColor = .white
        }
    }

    // MARK: - Goal
    func setGoal(sets: Int, reps: Int, restSeconds: Int) {
        DispatchQueue.main.async {
            self.targetSets = sets; self.targetReps = reps
            self.currentSet = 1; self.repsInCurrentSet = 0
        }
    }

    func clearGoal() {
        DispatchQueue.main.async {
            self.targetSets = 0; self.targetReps = 0
            self.currentSet = 1; self.repsInCurrentSet = 0
        }
    }

    // MARK: - Session timer
    private func startSessionTimer() {
        sessionStartDate = Date()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.sessionStartDate else { return }
            let e = Int(Date().timeIntervalSince(start))
            DispatchQueue.main.async {
                self.sessionTimeString = String(format: "%02d:%02d", e / 60, e % 60)
            }
        }
    }

    // MARK: Camera
    private func setupCamera() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            guard !self.session.isRunning else { return }
            // Remove any stale inputs/outputs from a previous session
            self.isConfiguring = true
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            self.session.inputs.forEach  { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition),
                let input  = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(input)
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "squatVideoQueue"))
            output.alwaysDiscardsLateVideoFrames = true
            if self.session.canAddOutput(output) { self.session.addOutput(output) }
            self.session.commitConfiguration()
            self.isConfiguring = false
            self.session.startRunning()
        }
    }

    func switchCamera() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.isConfiguring = true
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            guard
                let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                let inp = try? AVCaptureDeviceInput(device: dev),
                self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(inp)
            self.session.commitConfiguration()
            self.isConfiguring = false
            DispatchQueue.main.async { self.cameraPosition = newPos }
        }
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let orientation: CGImagePropertyOrientation = cameraPosition == .front ? .leftMirrored : .right
        analyzeFrame(pixelBuffer: pixelBuffer, orientation: orientation)
    }

    // MARK: - Analyze frame
    private func analyzeFrame(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return }
            let points = try observation.recognizedPoints(.all)

            updateBodyPoints(points)

            let rawResult = analyzePushUpPosture(points)

            if rawResult.issue == .notVisible {
                notVisibleFrames += 1
                if notVisibleFrames >= 8 {
                    DispatchQueue.main.async { self.postureResult = rawResult }
                }
                return
            } else {
                notVisibleFrames = 0
            }

            var smoothed = smoothResult(rawResult)
            updatePhaseAndReps(smoothedResult: smoothed)

            if smoothed.issue == lastIssue { stableIssueFrames += 1 }
            else { stableIssueFrames = 0; lastIssue = smoothed.issue }
            if stableIssueFrames < 3 { smoothed.issue = postureResult.issue }

            updateFormAlert(result: smoothed)
            DispatchQueue.main.async { self.postureResult = smoothed }
        } catch {
            print("PushUp Vision error: \(error)")
        }
    }

    // MARK: - Posture analysis
    private func analyzePushUpPosture(
        _ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> PushUpResult {
        var result = PushUpResult()
        let useLeft = betterSide(points)
        result.trackedLeftSide = useLeft

        let shoulderKey: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let elbowKey:    VNHumanBodyPoseObservation.JointName = useLeft ? .leftElbow    : .rightElbow
        let wristKey:    VNHumanBodyPoseObservation.JointName = useLeft ? .leftWrist    : .rightWrist
        let hipKey:      VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let kneeKey:     VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee     : .rightKnee
        let ankleKey:    VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle    : .rightAnkle
        let earKey:      VNHumanBodyPoseObservation.JointName = useLeft ? .leftEar      : .rightEar

        let conf: Float = 0.15
        for joint in [shoulderKey, elbowKey, wristKey, hipKey, kneeKey] {
            guard let p = points[joint], p.confidence > conf else {
                result.issue = .notVisible; return result
            }
        }

        let shoulder = points[shoulderKey]!.location
        let elbow    = points[elbowKey]!.location
        let wrist    = points[wristKey]!.location
        let hip      = points[hipKey]!.location
        let knee     = points[kneeKey]!.location

        result.elbowAngle = calculateAngle(first: shoulder, middle: elbow, last: wrist)
        result.hipAngle   = calculateAngle(first: shoulder, middle: hip,   last: knee)

        let ankleConf = points[ankleKey]?.confidence ?? 0
        let anklePoint: CGPoint = ankleConf > 0.1
            ? points[ankleKey]!.location
            : CGPoint(x: knee.x + (knee.x - hip.x) * 0.6,
                      y: knee.y + (knee.y - hip.y) * 0.6)

        let refDX = anklePoint.x - shoulder.x
        let refDY = anklePoint.y - shoulder.y
        let refLen = sqrt(refDX * refDX + refDY * refDY)
        let crossZ   = refDX * (hip.y - shoulder.y) - refDY * (hip.x - shoulder.x)
        let perpDist = refLen > 0.001 ? Double(crossZ) / Double(refLen) : 0.0
        let clampedDev = max(-0.3, min(0.3, perpDist))
        let alignScore = 100.0 - (abs(clampedDev) / 0.3) * 100.0

        result.spineAngle   = alignScore
        result.spineSagging = perpDist < 0

        if let earPoint = points[earKey], earPoint.confidence > 0.15 {
            result.neckAngle   = calculateAngle(first: earPoint.location, middle: shoulder, last: hip)
            result.neckTracked = true
            result.neckOk      = result.neckAngle >= neckAcceptableMin
        } else {
            result.neckTracked = false
            result.neckOk      = true
        }

        let personIsUpright = result.elbowAngle >= 165 && result.hipAngle >= 165
        guard !personIsUpright else {
            result.elbowOk = true; result.hipOk = true; result.spineOk = true; result.neckOk = true
            result.issue = .ready; result.postureScore = 100
            return result
        }

        let spineThresh: Double = (currentPhase == .descending) ? 80.0 : 85.0
        result.spineOk = result.spineAngle >= spineThresh
        result.hipOk   = result.hipAngle >= hipAcceptableMin

        switch currentPhase {
        case .standing, .ascending:
            result.elbowOk = result.elbowAngle >= elbowUpMin
        case .descending:
            result.elbowOk = result.elbowAngle < elbowDescentTrigger
        case .bottom:
            result.elbowOk = result.elbowAngle <= elbowDepthMax
        }

        var score = 100
        if result.hipAngle < hipSaggingFail       { score -= 40 }
        else if result.hipAngle < hipAcceptableMin { score -= 25 }
        else if result.hipAngle < hipExcellentMin  { score -= 10 }
        if !result.spineOk { score -= 30 }
        if !result.elbowOk { score -= 20 }
        if result.neckTracked && !result.neckOk { score -= 15 }
        if currentPhase == .bottom || currentPhase == .descending {
            if result.elbowAngle <= elbowDepthExcellent   { score = min(100, score + 5) }
            else if result.elbowAngle > elbowDepthMax      { score -= 10 }
        }
        result.postureScore = max(score, 0)

        if !result.hipOk {
            result.issue = .hipsTooLow
        } else if !result.spineOk {
            result.issue = result.spineSagging ? .hipsTooLow : .backSagging
        } else if result.neckTracked && !result.neckOk {
            result.issue = .neckBad
        } else {
            result.issue = .correct
        }

        return result
    }

    // MARK: - Phase & rep counting state machine
    private func updatePhaseAndReps(smoothedResult: PushUpResult) {
        let elbowAngle = smoothedResult.elbowAngle
        let prev       = lastElbowAngle
        var nextPhase  = currentPhase
        var addRep     = false

        if currentPhase == .descending || currentPhase == .bottom || currentPhase == .ascending {
            if !smoothedResult.hipOk   { hipErrorFrames += 1   } else { hipErrorFrames   = max(0, hipErrorFrames - 1)   }
            if !smoothedResult.spineOk { spineErrorFrames += 1 } else { spineErrorFrames = max(0, spineErrorFrames - 1) }
            if smoothedResult.neckTracked {
                if smoothedResult.neckAngle < neckErrorMin { neckErrorFrames += 1 } else { neckErrorFrames = max(0, neckErrorFrames - 1) }
            }
            if hipErrorFrames   >= 3 { hadHipError   = true }
            if spineErrorFrames >= 3 { hadSpineError = true }
            if neckErrorFrames  >= 3 { hadNeckError  = true }
        }

        if elbowAngle < elbowDescentTrigger && prev > elbowAngle && !pushUpStarted {
            nextPhase     = .descending
            pushUpStarted = true
        }

        if elbowAngle < minElbowAngle { minElbowAngle = elbowAngle }

        if elbowAngle <= elbowDepthMax {
            validDepthFrames += 1
            if validDepthFrames >= depthFramesRequired { depthReached = true }
        } else if elbowAngle > (elbowDepthMax + 8) && !depthReached {
            validDepthFrames = 0
        }

        let startedRising = depthReached && elbowAngle > (minElbowAngle + 4)
        if startedRising && !bottomReached {
            validBottomFrames += 1
            if validBottomFrames >= 3 { nextPhase = .bottom; bottomReached = true }
        } else if !depthReached {
            validBottomFrames = 0
        }

        if bottomReached && elbowAngle > (prev + 2) && elbowAngle < elbowUpMin {
            nextPhase = .ascending
        }

        if elbowAngle < elbowUpMin { validStandingFrames = 0 }

        if pushUpStarted && elbowAngle >= elbowUpMin {
            validStandingFrames += 1
            if validStandingFrames >= standingFramesRequired {
                let hadRealDescent = minElbowAngle <= elbowMinimumDescent
                if hadRealDescent {
                    if depthReached {
                        let formWasGood = !hadHipError && !hadSpineError && !hadNeckError
                        if formWasGood {
                            addRep = true
                            triggerGoodRepFeedback(score: smoothedResult.postureScore)
                        } else {
                            triggerBadRepFeedback()
                        }
                    } else {
                        triggerBadRepFeedback()
                    }
                }
                nextPhase = .standing
                pushUpStarted = false; depthReached = false; bottomReached = false
                validStandingFrames = 0; validBottomFrames = 0
                validDepthFrames    = 0; minElbowAngle     = 180
                hipErrorFrames  = 0; spineErrorFrames  = 0; neckErrorFrames = 0
                hadHipError     = false; hadSpineError = false; hadNeckError  = false
            }
        }

        lastElbowAngle = elbowAngle
        let scoreSnapshot = smoothedResult.postureScore

        DispatchQueue.main.async {
            if addRep {
                self.reps             += 1
                self.repsInCurrentSet += 1
                self.totalRepsAllTime += 1
                self.speakRepCount(self.repsInCurrentSet)
                WatchConnectivityManager.shared.sendRepUpdate(
                    exercise: "Push-Up", repsInSet: self.repsInCurrentSet,
                    targetReps: self.targetReps, currentSet: self.currentSet,
                    totalSets: self.targetSets, formScore: scoreSnapshot,
                    feedback: scoreSnapshot >= 85 ? "Good form!" : "Keep it clean")

                if self.targetReps > 0 && self.repsInCurrentSet >= self.targetReps {
                    if self.currentSet < self.targetSets {
                        self.speakText("Set \(self.currentSet) complete!")
                        self.currentSet       += 1
                        self.repsInCurrentSet  = 0
                        self.fireWatchNotification(
                            title: "✅ Set Complete",
                            body:  "Rest, then start set \(self.currentSet)."
                        )
                    } else {
                        self.speakText("Workout complete! Great job!")
                        self.fireWatchNotification(
                            title: "🎉 Workout Complete!",
                            body:  "You finished all \(self.targetSets) sets."
                        )
                    }
                }

                let record = RepRecord(
                    repNumber: self.totalRepsAllTime,
                    score:     scoreSnapshot,
                    isGood:    true,
                    timestamp: Date()
                )
                self.repHistory.append(record)
                self.updateScoreStats()
            }

            self.currentPhase = nextPhase
            switch nextPhase {
            case .standing:   self.phaseText = "Up";          self.phaseColor = .white
            case .descending: self.phaseText = "Going Down";  self.phaseColor = .yellow
            case .bottom:     self.phaseText = "Deep ✅";     self.phaseColor = .green
            case .ascending:  self.phaseText = "Coming Up";   self.phaseColor = .blue
            }
        }
    }

    private func updateScoreStats() {
        goodReps = repHistory.filter { $0.isGood }.count
        badReps  = repHistory.filter { !$0.isGood }.count
        if !repHistory.isEmpty {
            averageScore = repHistory.map { $0.score }.reduce(0,+) / repHistory.count
            bestRepScore = repHistory.map { $0.score }.max() ?? 0
        }
    }

    // MARK: - Feedback
    private func triggerGoodRepFeedback(score: Int) {
        DispatchQueue.main.async {
            self.showGoodRepFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.showGoodRepFlash = false }
        }
    }

    private func triggerBadRepFeedback() {
        var reasons: [String] = []
        if hadSpineError { reasons.append("Keep body straight") }
        if hadHipError   { reasons.append("Hips sagging") }
        if hadNeckError  { reasons.append("Head dropping") }
        if !depthReached { reasons.append("Go lower") }
        if reasons.isEmpty { reasons.append("Check your form") }
        let message = "⚠️ Rep Not Counted\n" + reasons.joined(separator: " • ")

        if hadSpineError      { speakText("Keep your body straight") }
        else if hadHipError   { speakText("Keep your hips up") }
        else if hadNeckError  { speakText("Keep your head neutral") }
        else                  { speakText("Go lower next time") }

        fireWatchNotification(title: "❌ Bad Rep!", body: reasons.joined(separator: " • "))

        DispatchQueue.main.async {
            self.badRepMessage = message
            let record = RepRecord(
                repNumber: self.totalRepsAllTime + 1,
                score:     0,
                isGood:    false,
                timestamp: Date()
            )
            self.repHistory.append(record)
            self.totalRepsAllTime += 1
            self.badReps          += 1
            self.updateScoreStats()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.badRepMessage = nil }
        }
    }

    private func speakFormCue(result: PushUpResult) {
        guard currentPhase == .descending || currentPhase == .bottom else { return }
        let now = Date()
        guard now.timeIntervalSince(lastSpeechTime) > 3.0 else { return }
        var cue: String? = nil
        if !result.spineOk                           { cue = "Keep your body straight" }
        else if !result.hipOk                        { cue = "Keep your hips up" }
        else if result.neckTracked && !result.neckOk { cue = "Keep your head neutral" }
        else if !result.elbowOk && currentPhase == .descending { cue = "Go lower" }
        guard let text = cue, result.issue != lastSpokenIssue else { return }
        lastSpokenIssue = result.issue
        lastSpeechTime  = now
        let u = AVSpeechUtterance(string: text); u.rate = 0.5; u.volume = 0.9
        DispatchQueue.main.async { self.speechSynth.speak(u) }
    }

    private func updateFormAlert(result: PushUpResult) {
        guard currentPhase == .descending || currentPhase == .bottom else {
            DispatchQueue.main.async { self.showFormAlert = false }
            return
        }
        var message: String? = nil
        if !result.spineOk                           { message = "Keep Your Body Straight!" }
        else if !result.hipOk                        { message = "Raise Your Hips — They're Sagging!" }
        else if result.neckTracked && !result.neckOk { message = "Keep Your Head Neutral!" }

        if let msg = message {
            fireWatchNotification(title: "⚠️ Fix Your Form", body: msg)
            speakFormCue(result: result)
        }

        DispatchQueue.main.async {
            if let msg = message {
                self.formAlertMessage = msg
                self.showFormAlert    = true
                self.alertTimer?.invalidate()
                self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                    DispatchQueue.main.async { self.showFormAlert = false }
                }
            } else {
                self.showFormAlert = false
            }
        }
    }

    // MARK: - Watch notification
    func fireWatchNotification(title: String, body: String) {
        let now = Date()
        if let last = lastNotifTime[title], now.timeIntervalSince(last) < notifCooldown { return }
        lastNotifTime[title] = now
        NotificationManager.shared.send(title: title, body: body)
        WatchConnectivityManager.shared.sendFormAlert(exercise: "Push-Up", issue: "\(title): \(body)")
    }

    // MARK: - Helpers
    private func betterSide(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> Bool {
        let lS = points[.leftShoulder]?.confidence  ?? 0
        let lE = points[.leftElbow]?.confidence     ?? 0
        let lW = points[.leftWrist]?.confidence     ?? 0
        let lH = points[.leftHip]?.confidence       ?? 0
        let lK = points[.leftKnee]?.confidence      ?? 0
        let rS = points[.rightShoulder]?.confidence ?? 0
        let rE = points[.rightElbow]?.confidence    ?? 0
        let rW = points[.rightWrist]?.confidence    ?? 0
        let rH = points[.rightHip]?.confidence      ?? 0
        let rK = points[.rightKnee]?.confidence     ?? 0
        let leftTotal:  Float = lS + lE + lW + lH + lK
        let rightTotal: Float = rS + rE + rW + rH + rK
        return leftTotal >= rightTotal
    }

    private func updateBodyPoints(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var mapped: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (joint, point) in points where point.confidence > 0.3 {
            mapped[joint] = CGPoint(x: point.location.x, y: 1 - point.location.y)
        }
        pointsBuffer.append(mapped)
        if pointsBuffer.count > 6 { pointsBuffer.removeFirst() }

        var smoothed: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        let allJoints = Set(pointsBuffer.flatMap { $0.keys })
        for joint in allJoints {
            let positions = pointsBuffer.compactMap { $0[joint] }
            guard !positions.isEmpty else { continue }
            let n = CGFloat(positions.count)
            smoothed[joint] = CGPoint(
                x: positions.map(\.x).reduce(0, +) / n,
                y: positions.map(\.y).reduce(0, +) / n
            )
        }
        DispatchQueue.main.async { self.bodyPoints = smoothed }
    }

    private func calculateAngle(first: CGPoint, middle: CGPoint, last: CGPoint) -> Double {
        let a = atan2(first.y  - middle.y, first.x  - middle.x)
        let b = atan2(last.y   - middle.y, last.x   - middle.x)
        var angle = abs((a - b) * 180 / .pi)
        if angle > 180 { angle = 360 - angle }
        return angle
    }

    private func smoothResult(_ result: PushUpResult) -> PushUpResult {
        frameBuffer.append(result)
        if frameBuffer.count > 8 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        var s = result
        s.elbowAngle   = frameBuffer.map(\.elbowAngle).reduce(0,  +) / n
        s.hipAngle     = frameBuffer.map(\.hipAngle).reduce(0,    +) / n
        s.spineAngle   = frameBuffer.map(\.spineAngle).reduce(0,  +) / n
        s.neckAngle    = frameBuffer.map(\.neckAngle).reduce(0,   +) / n
        s.postureScore = Int(Double(frameBuffer.map(\.postureScore).reduce(0, +)) / n)
        s.trackedLeftSide = result.trackedLeftSide
        s.neckTracked     = result.neckTracked
        let saggingCount = frameBuffer.filter { $0.spineSagging }.count
        s.spineSagging = saggingCount > frameBuffer.count / 2
        return s
    }

    // MARK: - Speech
    private func speakRepCount(_ count: Int) {
        let u = AVSpeechUtterance(string: "\(count)")
        u.rate = 0.55; u.volume = 1.0
        DispatchQueue.main.async { self.speechSynth.speak(u) }
    }

    private func speakText(_ text: String) {
        let u = AVSpeechUtterance(string: text)
        u.rate = 0.5; u.volume = 1.0
        DispatchQueue.main.async { self.speechSynth.speak(u) }
    }
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: - LUNGE
// ─────────────────────────────────────────────────────────────────────────────
import SwiftUI
import AVFoundation
import Vision
import Combine

// ─────────────────────────────────────────────
// MARK: - LUNGE ISSUE
// ─────────────────────────────────────────────
enum LungeIssue: String {
    case correct          = "✅ Good Lunge"
    case kneeOverToe      = "❌ Front Knee Too Far Forward"
    case backNotStraight  = "❌ Keep Torso Upright"
    case notDeep          = "❌ Lower Back Knee More"
    case detecting        = "🔍 Detecting..."
    case notVisible       = "📷 Full Body Not Visible"
}

// ─────────────────────────────────────────────
// MARK: - LUNGE PHASE
// ─────────────────────────────────────────────
enum LungePhase { case standing, descending, bottom, ascending }

// ─────────────────────────────────────────────
// MARK: - LUNGE RESULT
// ─────────────────────────────────────────────
struct LungeResult {
    var issue: LungeIssue = .detecting
    var postureScore: Int  = 100
    var kneeAngle:  Double = 180
    var hipAngle:   Double = 180
    var torsoAngle: Double = 90
    var kneeOk   = true
    var hipOk    = true
    var torsoOk  = true
}

// ─────────────────────────────────────────────
// MARK: - REP RECORD
// ─────────────────────────────────────────────
struct LungeRepRecord: Identifiable {
    let id        = UUID()
    let repNumber: Int
    let score:     Int
    let isGood:    Bool
    let timestamp: Date
}

// ─────────────────────────────────────────────
// MARK: - CAMERA VIEW
// ─────────────────────────────────────────────
struct LungeCameraView: View {
    @StateObject private var viewModel   = LungeViewModel()
    @State private var showGoalSheet     = false
    @State private var showStatsSheet    = false

    var body: some View {
        ZStack {
            ExerciseSessionPreview(session: viewModel.session).ignoresSafeArea()

            LungeSkeletonOverlay(
                bodyPoints: viewModel.bodyPoints,
                result:     viewModel.result
            ).ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                if viewModel.showAlert {
                    LungeFormAlertBanner(message: viewModel.alertMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: viewModel.showAlert)
                }
                Spacer()

                if viewModel.isResting {
                    LungeRestTimerView(secondsLeft: viewModel.restSecondsLeft)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(), value: viewModel.isResting)
                }

                bottomPanel
            }

            // Bad-rep overlay
            if viewModel.showBadRepFlash {
                Color.red.opacity(0.25).ignoresSafeArea().allowsHitTesting(false)
                VStack {
                    Spacer()
                    Text(viewModel.badRepReason)
                        .font(.title3.bold()).foregroundColor(.white)
                        .multilineTextAlignment(.center).padding()
                        .background(Color.red.opacity(0.85)).cornerRadius(16)
                        .padding(.bottom, 220)
                }
            }
        }
        .onAppear    { viewModel.start() }
        .onDisappear { viewModel.stop()  }
        .sheet(isPresented: $showGoalSheet)  { LungeGoalSheet(viewModel: viewModel) }
        .sheet(isPresented: $showStatsSheet) { LungeStatsSheet(viewModel: viewModel) }
        .navigationBarHidden(true)
    }

    // ── Top bar ──────────────────────────────
    private var topBar: some View {
        HStack(spacing: 8) {
            Text(viewModel.sessionTimeString)
                .font(.caption.monospacedDigit().bold())
                .foregroundColor(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.black.opacity(0.5)).cornerRadius(20)

            Spacer()

            ZStack {
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 3).frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.result.postureScore) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40).rotationEffect(.degrees(-90))
                Text("\(viewModel.result.postureScore)")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
            }

            HStack(spacing: 4) {
                Button { showStatsSheet = true } label: {
                    Image(systemName: "chart.bar.fill").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                Button { showGoalSheet = true } label: {
                    Image(systemName: "target").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                Button { viewModel.switchCamera() } label: {
                    Image(systemName: "camera.rotate").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(.black.opacity(0.5)).cornerRadius(24)
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    // ── Bottom panel ─────────────────────────
    private var bottomPanel: some View {
        VStack(spacing: 10) {
            HStack {
                Text(viewModel.result.issue.rawValue)
                    .font(.subheadline.bold()).foregroundColor(.white)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(viewModel.phaseText)
                    .font(.caption.bold())
                    .foregroundColor(viewModel.phaseColor)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(viewModel.phaseColor.opacity(0.15))
                    .cornerRadius(12)
            }

            HStack(spacing: 6) {
                LungeAngleChip(label: "Knee",  value: viewModel.result.kneeAngle,  isOk: viewModel.result.hipOk,   unit: "°")
                LungeAngleChip(label: "Torso", value: viewModel.result.torsoAngle, isOk: viewModel.result.torsoOk, unit: "°")
                LungeAngleChip(label: "Score", value: Double(viewModel.result.postureScore), isOk: viewModel.result.postureScore >= 70, unit: "")
            }

            if viewModel.targetReps > 0 {
                LungeProgressBarView(
                    currentSet: viewModel.currentSet,
                    totalSets:  viewModel.targetSets,
                    repsInSet:  viewModel.repsInCurrentSet,
                    targetReps: viewModel.targetReps
                )
            }

            HStack(alignment: .center, spacing: 0) {
                VStack(spacing: 0) {
                    Text("\(viewModel.repsInCurrentSet)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(viewModel.targetReps > 0
                         ? "SET \(viewModel.currentSet) OF \(viewModel.targetSets)"
                         : "REPS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .kerning(1.2)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 44)

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Label("\(viewModel.goodReps)", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("\(viewModel.badReps)", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .font(.subheadline.bold())
                    Text("QUALITY").font(.system(size: 10)).foregroundColor(.white.opacity(0.5)).kerning(1.2)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 44)

                Button { viewModel.resetSession() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3).foregroundColor(.white.opacity(0.7))
                        Text("RESET").font(.system(size: 10)).foregroundColor(.white.opacity(0.4)).kerning(1.2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(.ultraThinMaterial.opacity(0.95))
        .background(Color.black.opacity(0.6))
        .cornerRadius(24)
        .padding(.horizontal, 12).padding(.bottom, 8)
    }

    private var scoreColor: Color {
        let s = viewModel.result.postureScore
        if s >= 80 { return .green }
        if s >= 55 { return .yellow }
        return .red
    }
}

// ─────────────────────────────────────────────
// MARK: - SUPPORTING VIEWS
// ─────────────────────────────────────────────
struct LungeAngleChip: View {
    let label: String
    let value: Double
    let isOk:  Bool
    var unit:  String = "°"

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(isOk ? Color.green : Color.red).frame(width: 6, height: 6)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.6))
            Text("\(Int(value))\(unit)").font(.system(size: 12, weight: .bold)).foregroundColor(isOk ? .green : .red)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(isOk ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}

struct LungeProgressBarView: View {
    let currentSet: Int; let totalSets: Int; let repsInSet: Int; let targetReps: Int
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Set \(currentSet) of \(totalSets)").font(.caption).foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(repsInSet)/\(targetReps) reps").font(.caption.bold()).foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.15)).frame(height: 10)
                    RoundedRectangle(cornerRadius: 6).fill(Color.green)
                        .frame(width: geo.size.width * CGFloat(min(repsInSet, targetReps)) / CGFloat(max(targetReps, 1)),
                               height: 10)
                        .animation(.spring(response: 0.3), value: repsInSet)
                }
            }.frame(height: 10)
        }.padding(.horizontal, 4)
    }
}

struct LungeRestTimerView: View {
    let secondsLeft: Int
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer").foregroundColor(.cyan)
            Text("Rest: \(secondsLeft)s").font(.title3.bold()).foregroundColor(.white)
            Text("Next set coming up...").font(.caption).foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.cyan, lineWidth: 1.5))
        .shadow(color: .cyan.opacity(0.4), radius: 8).padding(.horizontal)
    }
}

struct LungeFormAlertBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text(message).font(.subheadline.bold()).foregroundColor(.white)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.orange, lineWidth: 1.5))
        .shadow(color: .orange.opacity(0.4), radius: 8).padding(.horizontal)
    }
}

// ─────────────────────────────────────────────
// MARK: - SKELETON OVERLAY
// ─────────────────────────────────────────────
struct LungeSkeletonOverlay: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let result: LungeResult

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let shoulder: VNHumanBodyPoseObservation.JointName = .leftShoulder
                let hip:      VNHumanBodyPoseObservation.JointName = .leftHip
                let knee:     VNHumanBodyPoseObservation.JointName = .leftKnee
                let ankle:    VNHumanBodyPoseObservation.JointName = .leftAnkle

                drawLine(shoulder, hip,   geo, ok: result.torsoOk)
                drawLine(hip,      knee,  geo, ok: result.kneeOk)
                drawLine(knee,     ankle, geo, ok: result.kneeOk)

                ForEach([shoulder, hip, knee, ankle], id: \.self) { joint in
                    if let point = bodyPoints[joint] {
                        Circle().fill(dotColor(for: joint)).frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                            .position(x: point.x * geo.size.width, y: point.y * geo.size.height)
                    }
                }
            }
        }
    }

    private func dotColor(for joint: VNHumanBodyPoseObservation.JointName) -> Color {
        switch joint {
        case .leftShoulder, .rightShoulder: return result.torsoOk ? .green : .red
        case .leftHip,      .rightHip:      return result.kneeOk  ? .green : .red
        case .leftKnee,     .rightKnee:     return result.kneeOk  ? .green : .red
        case .leftAnkle,    .rightAnkle:    return result.kneeOk  ? .green : .red
        default:                            return .white
        }
    }

    @ViewBuilder
    private func drawLine(_ j1: VNHumanBodyPoseObservation.JointName,
                          _ j2: VNHumanBodyPoseObservation.JointName,
                          _ geo: GeometryProxy, ok: Bool) -> some View {
        if let p1 = bodyPoints[j1], let p2 = bodyPoints[j2] {
            Path { path in
                path.move(to: CGPoint(x: p1.x * geo.size.width,  y: p1.y * geo.size.height))
                path.addLine(to: CGPoint(x: p2.x * geo.size.width, y: p2.y * geo.size.height))
            }
            .stroke(ok ? Color.green : Color.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - GOAL SETUP SHEET
// ─────────────────────────────────────────────
struct LungeGoalSheet: View {
    @ObservedObject var viewModel: LungeViewModel
    @Environment(\.dismiss) var dismiss

    @State private var sets    = 3
    @State private var reps    = 12
    @State private var restSec = 45
    @State private var launched = false

    private struct Preset {
        let name: String; let icon: String
        let sets: Int;    let reps: Int; let rest: Int
        let color: Color
    }
    private let presets: [Preset] = [
        Preset(name: "Beginner",  icon: "leaf.fill",        sets: 2, reps: 8,  rest: 60, color: DT.lime),
        Preset(name: "Standard",  icon: "figure.walk",      sets: 3, reps: 12, rest: 45, color: DT.sky),
        Preset(name: "Strength",  icon: "dumbbell.fill",    sets: 4, reps: 10, rest: 60, color: DT.amber),
        Preset(name: "Endurance", icon: "flame.fill",       sets: 4, reps: 20, rest: 30, color: DT.coral),
        Preset(name: "HIIT",      icon: "bolt.circle.fill", sets: 5, reps: 15, rest: 20, color: DT.violet),
    ]

    var body: some View {
        ZStack {
            DT.bg0.ignoresSafeArea()
            ZStack {
                Circle().fill(DT.violet.opacity(0.07)).frame(width: 300).blur(radius: 80).offset(x: 100,  y: -180)
                Circle().fill(DT.lime.opacity(0.05)).frame(width: 240).blur(radius: 70).offset(x: -120, y: 200)
            }.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    goalHeader
                    presetRow
                    sliderSection
                    summaryCard
                    actionButtons
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .opacity(launched ? 1 : 0)
                .offset(y: launched ? 0 : 24)
                .animation(.spring(response: 0.5, dampingFraction: 0.78), value: launched)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { launched = true } }
    }

    private var goalHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("WORKOUT")
                    .font(DT.textMono).foregroundColor(DT.violet).kerning(3)
                Text("Set Goal")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(DT.textPrimary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DT.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(DT.bg2).clipShape(Circle())
                    .overlay(Circle().stroke(DT.stroke, lineWidth: 1))
            }
        }.padding(.top, 24)
    }

    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PRESETS").font(DT.textMono).foregroundColor(DT.textSecondary).kerning(2)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(presets, id: \.name) { p in
                        let active = sets == p.sets && reps == p.reps && restSec == p.rest
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                sets = p.sets; reps = p.reps; restSec = p.rest
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: p.icon).font(.system(size: 18)).foregroundColor(p.color)
                                Text(p.name).font(.system(size: 11, weight: .bold)).foregroundColor(DT.textPrimary)
                                Text("\(p.sets)×\(p.reps)").font(.system(size: 10, design: .monospaced)).foregroundColor(DT.textSecondary)
                            }
                            .frame(width: 76).padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(active ? p.color.opacity(0.18) : DT.bg1)
                                    .overlay(RoundedRectangle(cornerRadius: 16)
                                        .stroke(active ? p.color.opacity(0.50) : DT.stroke, lineWidth: 1))
                            )
                        }
                    }
                }.padding(.bottom, 2)
            }
        }
    }

    private var sliderSection: some View {
        VStack(spacing: 18) {
            LungeGoalSliderRow(label: "SETS",         value: $sets,    range: 1...10,  step: 1,  accent: DT.violet, display: "\(sets)")
            LungeGoalSliderRow(label: "REPS PER SET", value: $reps,    range: 4...30,  step: 2,  accent: DT.lime,   display: "\(reps)")
            LungeGoalSliderRow(label: "REST",         value: $restSec, range: 10...120, step: 10, accent: DT.sky,   display: "\(restSec)s")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DT.stroke, lineWidth: 1))
        )
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            LungeGoalSummaryCell(value: "\(sets)",        label: "SETS",     accent: DT.violet)
            Rectangle().fill(DT.stroke).frame(width: 1, height: 36)
            LungeGoalSummaryCell(value: "\(reps)",        label: "REPS/SET", accent: DT.lime)
            Rectangle().fill(DT.stroke).frame(width: 1, height: 36)
            LungeGoalSummaryCell(value: "\(sets * reps)", label: "TOTAL",    accent: DT.amber)
            Rectangle().fill(DT.stroke).frame(width: 1, height: 36)
            LungeGoalSummaryCell(value: "\(restSec)s",    label: "REST",     accent: DT.sky)
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(DT.stroke, lineWidth: 1))
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.setGoal(sets: sets, reps: reps, restSeconds: restSec); dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill").font(.system(size: 14, weight: .bold))
                    Text("Start Workout").font(.system(size: 16, weight: .black, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 17)
                .background(ZStack {
                    LinearGradient(colors: [DT.lime, DT.sky], startPoint: .leading, endPoint: .trailing)
                    LinearGradient(colors: [Color.white.opacity(0.18), Color.clear], startPoint: .top, endPoint: .bottom)
                })
                .cornerRadius(16)
                .shadow(color: DT.lime.opacity(0.35), radius: 14, y: 6)
            }
            Button { viewModel.clearGoal(); dismiss() } label: {
                Text("Clear Goal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DT.coral)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(DT.coral.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(DT.coral.opacity(0.22), lineWidth: 1))
                    )
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - GOAL SUB-VIEWS
// ─────────────────────────────────────────────
private struct LungeGoalSliderRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>; let step: Int; let accent: Color; let display: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label).font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1.5)
                Spacer()
                Text(display).font(.system(size: 17, weight: .black, design: .rounded)).foregroundColor(accent)
            }
            GeometryReader { geo in
                let pct   = CGFloat(value - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound)
                let fillW = geo.size.width * pct
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.07)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [accent.opacity(0.9), accent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, fillW), height: 6)
                    Circle().fill(accent).frame(width: 22, height: 22)
                        .shadow(color: accent.opacity(0.5), radius: 6)
                        .offset(x: max(0, fillW - 11))
                }
                .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                    let raw     = drag.location.x / geo.size.width
                    let clamped = min(max(0, raw), 1)
                    let floatV  = Double(range.lowerBound) + clamped * Double(range.upperBound - range.lowerBound)
                    let stepped = Int(round(floatV / Double(step))) * step
                    value = min(max(range.lowerBound, stepped), range.upperBound)
                })
            }
            .frame(height: 22)
        }
    }
}

private struct LungeGoalSummaryCell: View {
    let value: String; let label: String; let accent: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 20, weight: .black, design: .rounded)).foregroundColor(accent)
            Text(label).font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// ─────────────────────────────────────────────
// MARK: - SESSION STATS SHEET
// ─────────────────────────────────────────────
struct LungeStatsSheet: View {
    @ObservedObject var viewModel: LungeViewModel
    @Environment(\.dismiss) var dismiss

    private var qualityRate: Int {
        let t = viewModel.goodReps + viewModel.badReps
        guard t > 0 else { return 0 }
        return Int(Double(viewModel.goodReps) / Double(t) * 100)
    }

    var body: some View {
        ZStack {
            DT.bg0.ignoresSafeArea()
            ZStack {
                Circle().fill(DT.lime.opacity(0.06)).frame(width: 320).blur(radius: 80).offset(x: -100, y: -200)
                Circle().fill(DT.sky.opacity(0.05)).frame(width: 260).blur(radius: 70).offset(x: 140, y: 100)
                Circle().fill(DT.violet.opacity(0.04)).frame(width: 200).blur(radius: 60).offset(x: -60, y: 400)
            }.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    statsHeader
                    heroBlock
                    fourPillsRow
                    if viewModel.repHistory.count > 1 { graphCard }
                    timelineCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var statsHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SESSION").font(DT.textMono).foregroundColor(DT.lime).kerning(3)
                Text("Analytics")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(DT.textPrimary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DT.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(DT.bg2).clipShape(Circle())
                    .overlay(Circle().stroke(DT.stroke, lineWidth: 1))
            }
        }.padding(.top, 24)
    }

    private var heroBlock: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.06), lineWidth: 10).frame(width: 112, height: 112)
                Circle()
                    .trim(from: 0, to: CGFloat(qualityRate) / 100)
                    .stroke(AngularGradient(colors: [DT.lime, DT.sky, DT.lime], center: .center),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 112, height: 112).rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.9), value: qualityRate)
                Circle().trim(from: 0, to: CGFloat(qualityRate) / 100)
                    .stroke(DT.lime.opacity(0.22), lineWidth: 16)
                    .frame(width: 112, height: 112).rotationEffect(.degrees(-90))
                    .blur(radius: 6)
                    .animation(.easeOut(duration: 0.9), value: qualityRate)
                VStack(spacing: 1) {
                    Text("\(qualityRate)%")
                        .font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(DT.textPrimary)
                    Text("QUALITY").font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1)
                }
            }
            VStack(spacing: 10) {
                LungeStatsHeroTile(value: "\(viewModel.totalRepsAllTime)", label: "TOTAL REPS", accent: DT.lime)
                LungeStatsHeroTile(value: viewModel.sessionTimeString,     label: "DURATION",   accent: DT.sky)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DT.stroke, lineWidth: 1))
        )
    }

    private var fourPillsRow: some View {
        HStack(spacing: 8) {
            LungeStatsMetricPill(value: "\(viewModel.goodReps)",     label: "GOOD", color: DT.lime,  icon: "checkmark.circle.fill")
            LungeStatsMetricPill(value: "\(viewModel.badReps)",      label: "BAD",  color: DT.coral, icon: "xmark.circle.fill")
            LungeStatsMetricPill(value: "\(viewModel.averageScore)", label: "AVG",  color: DT.amber, icon: "waveform.path.ecg")
            LungeStatsMetricPill(value: "\(viewModel.bestRepScore)", label: "BEST", color: DT.sky,   icon: "bolt.fill")
        }
    }

    private var graphCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            LungeStatsSectionLabel(title: "REP SCORES", sub: "\(viewModel.repHistory.count) reps")
            LungeStatsRepScoreGraph(records: viewModel.repHistory).frame(height: 140)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DT.stroke, lineWidth: 1))
        )
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            LungeStatsSectionLabel(title: "REP HISTORY", sub: "Most recent first")
            if viewModel.repHistory.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "figure.walk").font(.system(size: 36)).foregroundColor(Color.white.opacity(0.10))
                    Text("No reps yet — start lunging!").font(.system(size: 13, weight: .medium)).foregroundColor(DT.textSecondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30)
            } else {
                VStack(spacing: 7) {
                    ForEach(viewModel.repHistory.reversed()) { rep in LungeStatsRepRow(rep: rep) }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DT.stroke, lineWidth: 1))
        )
    }
}

// ─────────────────────────────────────────────
// MARK: - STATS SUB-VIEWS
// ─────────────────────────────────────────────
private struct LungeStatsHeroTile: View {
    let value: String; let label: String; let accent: Color
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 3, height: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(size: 21, weight: .black, design: .rounded)).foregroundColor(DT.textPrimary)
                Text(label).font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1.2)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(DT.bg2).cornerRadius(13)
    }
}

private struct LungeStatsMetricPill: View {
    let value: String; let label: String; let color: Color; let icon: String
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundColor(color)
            Text(value).font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(DT.textPrimary)
            Text(label).font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.18), lineWidth: 1))
        )
    }
}

private struct LungeStatsSectionLabel: View {
    let title: String; let sub: String
    var body: some View {
        HStack(alignment: .bottom) {
            Text(title).font(DT.textMono).foregroundColor(DT.lime).kerning(2.5)
            Spacer()
            Text(sub).font(.system(size: 11, weight: .medium)).foregroundColor(DT.textSecondary)
        }
    }
}

private struct LungeStatsRepRow: View {
    let rep: LungeRepRecord
    private var col: Color { rep.isGood ? DT.lime : DT.coral }
    var body: some View {
        HStack(spacing: 10) {
            Text("#\(rep.repNumber)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(col).frame(width: 32)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05))
                    RoundedRectangle(cornerRadius: 4).fill(col.opacity(0.6))
                        .frame(width: g.size.width * CGFloat(rep.score) / 100)
                        .animation(.spring(response: 0.5), value: rep.score)
                }
            }.frame(height: 7)
            Text(rep.isGood ? "\(rep.score)" : "—")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(rep.isGood ? .white : DT.textSecondary).frame(width: 28, alignment: .trailing)
            Image(systemName: rep.isGood ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 13)).foregroundColor(col)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(Color.white.opacity(0.025)).cornerRadius(9)
    }
}

private struct LungeStatsRepScoreGraph: View {
    let records: [LungeRepRecord]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width; let h = geo.size.height
            let count = records.count
            guard count > 0 else { return AnyView(EmptyView()) }
            let slot = w / CGFloat(count)
            return AnyView(ZStack(alignment: .bottom) {
                ForEach([0, 25, 50, 75, 100], id: \.self) { val in
                    let y = h * (1 - CGFloat(val) / 100)
                    Path { p in p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: w, y: y)) }
                        .stroke(val == 0 ? Color.white.opacity(0.12) : Color.white.opacity(0.04),
                                style: StrokeStyle(lineWidth: 1, dash: val == 0 ? [] : [4, 4]))
                    if val > 0 {
                        Text("\(val)").font(.system(size: 7, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.18)).position(x: 12, y: max(8, y - 6))
                    }
                }
                if count > 1 {
                    Path { path in
                        for (i, rep) in records.enumerated() {
                            let x = slot * CGFloat(i) + slot / 2
                            let y = h * (1 - CGFloat(rep.score) / 100)
                            i == 0 ? path.move(to: .init(x: x, y: y)) : path.addLine(to: .init(x: x, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(records) { rep in
                        let barH = max(6, h * CGFloat(rep.score) / 100)
                        let col  = rep.isGood ? DT.lime : DT.coral
                        VStack(spacing: 0) {
                            Circle().fill(col).frame(width: 4, height: 4)
                            Rectangle()
                                .fill(LinearGradient(colors: [col.opacity(0.9), col.opacity(0.15)],
                                                     startPoint: .top, endPoint: .bottom))
                                .frame(height: max(1, barH - 4)).cornerRadius(3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            })
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - VIEW MODEL
// ─────────────────────────────────────────────
final class LungeViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession()

    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result      = LungeResult()
    @Published var phase: LungePhase = .standing
    @Published var phaseText   = "Standing"
    @Published var phaseColor: Color = .white
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    // Alerts
    @Published var showAlert     = false
    @Published var alertMessage  = ""
    @Published var showBadRepFlash = false
    @Published var badRepReason  = ""

    // Analytics
    @Published var repHistory:      [LungeRepRecord] = []
    @Published var goodReps         = 0
    @Published var badReps          = 0
    @Published var totalRepsAllTime = 0
    @Published var averageScore     = 0
    @Published var bestRepScore     = 0

    // Sets / Goal
    @Published var targetSets       = 0
    @Published var targetReps       = 0
    @Published var currentSet       = 1
    @Published var repsInCurrentSet = 0

    // Rest timer
    @Published var isResting       = false
    @Published var restSecondsLeft = 0
    private var restDuration       = 45
    private var restTimer: Timer?

    // Session timer
    @Published var sessionTimeString = "00:00"
    private var sessionStartDate: Date?
    private var sessionTimer: Timer?

    // ── Original LungeViewModel rep-tracking state (preserved exactly) ──
    private var frameBuffer: [LungeResult] = []
    private var lastKnee: Double      = 180
    private var bottomReached         = false
    private var lungeStarted          = false
    private var validBottomFrames     = 0
    private var validStandFrames      = 0
    private var hadKneeError          = false
    private var kneeErrorFrames       = 0
    private var alertTimer: Timer?
    private let cameraQueue = DispatchQueue(label: "lungeCameraQueue")
    private var isConfiguring = false

    // Speech
    private let speechSynth           = AVSpeechSynthesizer()

    // Notifications
    private var lastNotifTime: [String: Date] = [:]
    private let notifCooldown: TimeInterval   = 5.0


    // MARK: Start / Stop
    func start() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard granted, let self else { return }
            self.setupCamera()   // setupCamera dispatches internally
        }
        startSessionTimer()
        fireWatchNotification(title: "🦵 Ready for Lunges!", body: "Step back and drop that knee!")
    }

    func stop() {
        sessionTimer?.invalidate()
        restTimer?.invalidate()
        cameraQueue.async { [weak self] in
            guard let self, !self.isConfiguring, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func startSessionTimer() {
        sessionStartDate = Date()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.sessionStartDate else { return }
            let e = Int(Date().timeIntervalSince(start))
            DispatchQueue.main.async { self.sessionTimeString = String(format: "%02d:%02d", e / 60, e % 60) }
        }
    }

    func setGoal(sets: Int, reps: Int, restSeconds: Int) {
        DispatchQueue.main.async {
            self.targetSets = sets; self.targetReps = reps
            self.restDuration = restSeconds
            self.currentSet = 1; self.repsInCurrentSet = 0
        }
    }

    func clearGoal() {
        DispatchQueue.main.async {
            self.targetSets = 0; self.targetReps = 0
            self.currentSet = 1; self.repsInCurrentSet = 0
        }
    }

    func resetSession() {
        DispatchQueue.main.async {
            self.repsInCurrentSet = 0; self.currentSet = 1
            self.goodReps = 0; self.badReps = 0; self.totalRepsAllTime = 0
            self.averageScore = 0; self.bestRepScore = 0; self.repHistory = []
            self.bottomReached = false; self.lungeStarted = false
            self.phase = .standing; self.phaseText = "Standing"; self.phaseColor = .white
            self.validBottomFrames = 0; self.validStandFrames = 0
            self.hadKneeError = false; self.kneeErrorFrames = 0
            self.isResting = false; self.restTimer?.invalidate()
            self.sessionStartDate = Date()
        }
    }

    // Keep the original resetReps for any callers that used it
    func resetReps() { resetSession() }

    func switchCamera() {
        cameraQueue.async { [weak self] in
            guard let self, !self.isConfiguring else { return }
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.isConfiguring = true
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            guard
                let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                let inp = try? AVCaptureDeviceInput(device: dev),
                self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(inp)
            self.session.commitConfiguration()
            self.isConfiguring = false
            DispatchQueue.main.async { self.cameraPosition = newPos }
        }
    }


    // MARK: Camera
    private func setupCamera() {
        cameraQueue.async { [weak self] in
            guard let self, !self.isConfiguring, !self.session.isRunning else { return }
            self.isConfiguring = true
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            // Clear any stale inputs/outputs
            self.session.inputs.forEach  { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition),
                let input  = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(input)
            let output = AVCaptureVideoDataOutput()
            // Use a SEPARATE dedicated queue for sample delivery, not cameraQueue
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "lungeVideoQueue"))
            output.alwaysDiscardsLateVideoFrames = true
            if self.session.canAddOutput(output) { self.session.addOutput(output) }
            self.session.commitConfiguration()
            self.isConfiguring = false
            self.session.startRunning()
        }
    }


    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pxBuf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let orient: CGImagePropertyOrientation = cameraPosition == .front ? .leftMirrored : .right
        let req = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pxBuf, orientation: orient)
        do {
            try handler.perform([req])
            guard let obs = req.results?.first else { return }
            let pts = try obs.recognizedPoints(.all)
            DispatchQueue.main.async { self.bodyPoints = mappedPoints(pts) }
            analyze(pts)
        } catch {}
    }

    // ─────────────────────────────────────────
    // MARK: Analyze — ORIGINAL LOGIC PRESERVED
    // ─────────────────────────────────────────
    private func analyze(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        guard !isResting else { return }

        var r = LungeResult()
        let lLegConf: Float = (points[.leftHip]?.confidence ?? 0) + (points[.leftKnee]?.confidence ?? 0) + (points[.leftAnkle]?.confidence ?? 0)
        let rLegConf: Float = (points[.rightHip]?.confidence ?? 0) + (points[.rightKnee]?.confidence ?? 0) + (points[.rightAnkle]?.confidence ?? 0)
        let useLeft = lLegConf >= rLegConf
        let shK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let hpK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let knK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee     : .rightKnee
        let anK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle    : .rightAnkle
        for j in [hpK, knK, anK] {
            guard let p = points[j], p.confidence > 0.35 else { r.issue = .notVisible; DispatchQueue.main.async { self.result = r }; return }
        }
        let hp = points[hpK]!.location
        let kn = points[knK]!.location
        let an = points[anK]!.location
        r.kneeAngle = calcAngle(first: hp, middle: kn, last: an)
        if let sh = points[shK], sh.confidence > 0.3 {
            r.hipAngle = calcAngle(first: sh.location, middle: hp, last: kn)
            let torso = abs(atan2(sh.location.y - hp.y, sh.location.x - hp.x) * 180 / .pi)
            r.torsoAngle = torso
            r.torsoOk = torso >= 60
        } else { r.torsoOk = true }
        r.kneeOk = abs(kn.x - an.x) <= 0.20
        r.hipOk  = r.kneeAngle <= 100 || phase != .bottom

        var score = 100
        if !r.kneeOk  { score -= 30 }
        if !r.torsoOk { score -= 30 }
        if !r.hipOk   { score -= 20 }
        r.postureScore = max(score, 0)

        frameBuffer.append(r)
        if frameBuffer.count > 7 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        var sm = r
        sm.kneeAngle    = frameBuffer.map { $0.kneeAngle   }.reduce(0,+) / n
        sm.hipAngle     = frameBuffer.map { $0.hipAngle    }.reduce(0,+) / n
        sm.torsoAngle   = frameBuffer.map { $0.torsoAngle  }.reduce(0,+) / n
        sm.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)

        if !sm.kneeOk { kneeErrorFrames += 1 } else { kneeErrorFrames = 0 }
        if kneeErrorFrames >= 3 { hadKneeError = true }

        if sm.kneeAngle < 150 && sm.kneeAngle < lastKnee { lungeStarted = true }
        if lungeStarted && sm.kneeAngle <= 105 {
            validBottomFrames += 1
            if validBottomFrames >= 3 { bottomReached = true }
        }
        if lungeStarted && sm.kneeAngle >= 150 {
            validStandFrames += 1
            if validStandFrames >= 2 && bottomReached {
                let scoreSnapshot = sm.postureScore
                if hadKneeError {
                    DispatchQueue.main.async {
                        self.badRepReason = "⚠️ Rep Not Counted\nFront knee too far forward"
                        self.showBadRepFlash = true
                        let record = LungeRepRecord(repNumber: self.totalRepsAllTime + 1, score: 0, isGood: false, timestamp: Date())
                        self.repHistory.append(record); self.totalRepsAllTime += 1
                        self.updateScoreStats()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.showBadRepFlash = false }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.repsInCurrentSet += 1
                        self.totalRepsAllTime += 1
                        self.speakRepCount(self.repsInCurrentSet)
                        WatchConnectivityManager.shared.sendRepUpdate(
                            exercise: "Lunge", repsInSet: self.repsInCurrentSet,
                            targetReps: self.targetReps, currentSet: self.currentSet,
                            totalSets: self.targetSets, formScore: scoreSnapshot,
                            feedback: scoreSnapshot >= 85 ? "Good form!" : "Keep it clean")
                        let record = LungeRepRecord(repNumber: self.totalRepsAllTime, score: scoreSnapshot, isGood: true, timestamp: Date())
                        self.repHistory.append(record)
                        self.updateScoreStats()

                        if self.targetReps > 0 && self.repsInCurrentSet >= self.targetReps {
                            if self.currentSet < self.targetSets {
                                self.speakText("Set \(self.currentSet) complete! Rest now.")
                                self.startRestTimer()
                                self.currentSet += 1
                                self.repsInCurrentSet = 0
                            } else {
                                self.speakText("Workout complete! Great job!")
                                self.fireWatchNotification(
                                    title: "🎉 Workout Complete!",
                                    body:  "You finished all \(self.targetSets) sets. Great job!"
                                )
                            }
                        }
                    }
                }
                bottomReached = false; lungeStarted = false
                validBottomFrames = 0; validStandFrames = 0
                hadKneeError = false; kneeErrorFrames = 0
            }
        } else if sm.kneeAngle >= 150 { validStandFrames = 0 }

        lastKnee = sm.kneeAngle

        DispatchQueue.main.async {
            if sm.kneeAngle <= 105 {
                self.phase = .bottom; self.phaseText = "Deep ✅"; self.phaseColor = .green
            } else if sm.kneeAngle < 150 && sm.kneeAngle < self.lastKnee {
                self.phase = .descending; self.phaseText = "Stepping Back"; self.phaseColor = .yellow
            } else {
                self.phase = .standing; self.phaseText = "Standing"; self.phaseColor = .white
            }
        }

        if !sm.kneeOk { fireAlert("Front Knee Too Far — Step Back More!") }
        else if !sm.torsoOk { fireAlert("Keep Torso Upright!") }
        else { DispatchQueue.main.async { self.showAlert = false } }

        if !sm.torsoOk   { sm.issue = .backNotStraight }
        else if !sm.kneeOk { sm.issue = .kneeOverToe }
        else if !sm.hipOk  { sm.issue = .notDeep }
        else               { sm.issue = .correct }
        DispatchQueue.main.async { self.result = sm }
    }

    // MARK: Helpers
    private func updateScoreStats() {
        goodReps = repHistory.filter { $0.isGood }.count
        badReps  = repHistory.filter { !$0.isGood }.count
        let goodHistory = repHistory.filter { $0.isGood }
        if !goodHistory.isEmpty {
            averageScore = goodHistory.map { $0.score }.reduce(0, +) / goodHistory.count
            bestRepScore = goodHistory.map { $0.score }.max() ?? 0
        }
    }

    private func startRestTimer() {
        restSecondsLeft = restDuration; isResting = true
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            DispatchQueue.main.async {
                self.restSecondsLeft -= 1
                if self.restSecondsLeft <= 0 {
                    t.invalidate(); self.isResting = false
                    self.speakText("Go!")
                }
            }
        }
    }

    private func fireAlert(_ msg: String) {
        DispatchQueue.main.async {
            self.alertMessage = msg; self.showAlert = true
            self.alertTimer?.invalidate()
            self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                DispatchQueue.main.async { self.showAlert = false }
            }
        }
    }

    func fireWatchNotification(title: String, body: String) {
        let key = "\(title)"
        let now = Date()
        if let last = lastNotifTime[key], now.timeIntervalSince(last) < notifCooldown { return }
        lastNotifTime[key] = now
        NotificationManager.shared.send(title: title, body: body)
        WatchConnectivityManager.shared.sendFormAlert(exercise: "Lunge", issue: "\(title): \(body)")
    }

    private func speakRepCount(_ count: Int) {
        let u = AVSpeechUtterance(string: "\(count)"); u.rate = 0.55; u.volume = 1.0
        DispatchQueue.main.async { self.speechSynth.speak(u) }
    }

    private func speakText(_ text: String) {
        let u = AVSpeechUtterance(string: text); u.rate = 0.5; u.volume = 1.0
        DispatchQueue.main.async { self.speechSynth.speak(u) }
    }
}



// ─────────────────────────────────────────────────────────────────────────────
// MARK: - GLUTE BRIDGE
// ─────────────────────────────────────────────────────────────────────────────


import SwiftUI
import AVFoundation
import Vision
import Combine
import AVKit

// MARK: - GLUTE BRIDGE ISSUE
enum GluteBridgeIssue: String {
    case correct        = "✅ Perfect Bridge"
    case ready          = "🧍 Lie Down & Begin"
    case hipsTooLow     = "❌ Push Hips Higher"
    case hipsTooHigh    = "❌ Don't Hyperextend"
    case kneeTooWide    = "❌ Move Feet Closer"
    case kneeTooClose   = "❌ Move Feet Further"
    case backArched     = "❌ Keep Back Neutral"
    case shoulderLifted = "❌ Keep Shoulders Down"
    case detecting      = "🔍 Detecting..."
    case notVisible     = "📷 Full Body Not Visible"
}

// MARK: - GLUTE BRIDGE PHASE
enum GluteBridgePhase { case flat, ascending, top, descending }

enum GluteBridgeSheet: Identifiable {
    case goal, stats
    var id: Self { self }
}

// MARK: - REP RECORD
struct GluteBridgeRepRecord: Identifiable {
    let id         = UUID()
    let repNumber:  Int
    let score:      Int
    let isGood:     Bool
    let timestamp:  Date
}

// MARK: - GLUTE BRIDGE RESULT
struct GluteBridgeResult {
    var issue: GluteBridgeIssue = .detecting
    var postureScore: Int       = 100
    var hipAngle:     Double    = 160
    var kneeAngle:    Double    = 90
    var spineAngle:   Double    = 0
    var shoulderRise: Double    = 0
    var trackedLeftSide: Bool   = true
    var hipOk:      Bool = true
    var kneeOk:     Bool = true
    var spineOk:    Bool = true
    var shoulderOk: Bool = true
    var formIsValid: Bool { hipOk && kneeOk && spineOk && shoulderOk }
}

// MARK: - GLUTE BRIDGE CAMERA VIEW
struct GluteBridgeCameraView: View {
    @StateObject private var viewModel = GluteBridgeViewModel()
    @State private var activeSheet: GluteBridgeSheet?

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.session).ignoresSafeArea()

            GluteBridgeSkeletonOverlay(
                bodyPoints: viewModel.bodyPoints,
                result:     viewModel.bridgeResult
            ).ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                if viewModel.showFormAlert {
                    GluteBridgeAlertBanner(message: viewModel.formAlertMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: viewModel.showFormAlert)
                }
                Spacer()

                if viewModel.isResting {
                    GluteBridgeRestTimerView(secondsLeft: viewModel.restSecondsLeft)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(), value: viewModel.isResting)
                }

                bottomPanel
            }

            if viewModel.showBadRepFlash {
                Color.red.opacity(0.25).ignoresSafeArea().allowsHitTesting(false)
                VStack {
                    Spacer()
                    Text("⚠️ Rep Not Counted\n\(viewModel.badRepReason)")
                        .font(.title3.bold()).foregroundColor(.white)
                        .multilineTextAlignment(.center).padding()
                        .background(Color.red.opacity(0.85)).cornerRadius(16)
                        .padding(.bottom, 220)
                }
            }
        }
        .onAppear    { viewModel.start() }
        .onDisappear { viewModel.stopAndSave() }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .goal:  GluteBridgeGoalSetupSheet(viewModel: viewModel)
            case .stats: GluteBridgeStatsSheet(viewModel: viewModel)
            }
        }
    }

    // MARK: - Top controls (minimal floating pill)
    private var topBar: some View {
        HStack(spacing: 8) {
            // Session time
            Text(viewModel.sessionTimeString)
                .font(.caption.monospacedDigit().bold())
                .foregroundColor(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.black.opacity(0.5)).cornerRadius(20)

            Spacer()

            // Score ring
            ZStack {
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 3).frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.bridgeResult.postureScore) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40).rotationEffect(.degrees(-90))
                Text("\(viewModel.bridgeResult.postureScore)")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
            }

            // Action buttons
            HStack(spacing: 4) {
                Button { activeSheet = .stats } label: {
                    Image(systemName: "chart.bar.fill").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                Button { activeSheet = .goal } label: {
                    Image(systemName: "target").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                Button { viewModel.switchCamera() } label: {
                    Image(systemName: "camera.rotate").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(.black.opacity(0.5)).cornerRadius(24)
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    // MARK: - Bottom panel (compact)
    private var bottomPanel: some View {
        VStack(spacing: 10) {

            // Issue label + phase pill on same row
            HStack {
                Text(viewModel.bridgeResult.issue.rawValue)
                    .font(.subheadline.bold()).foregroundColor(.white)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(viewModel.phaseText)
                    .font(.caption.bold())
                    .foregroundColor(viewModel.phaseColor)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(viewModel.phaseColor.opacity(0.15))
                    .cornerRadius(12)
            }

            // Angle chips — compact single row
            HStack(spacing: 6) {
                GluteBridgeAngleChip(label: "Hip",  angle: viewModel.bridgeResult.hipAngle,      isOk: viewModel.bridgeResult.hipOk)
                GluteBridgeAngleChip(label: "Knee", angle: viewModel.bridgeResult.kneeAngle,     isOk: viewModel.bridgeResult.kneeOk)
                GluteBridgeAngleChip(label: "Back", angle: viewModel.bridgeResult.spineAngle,    isOk: viewModel.bridgeResult.spineOk)
                GluteBridgeAngleChip(label: "Shld", angle: viewModel.bridgeResult.shoulderRise,  isOk: viewModel.bridgeResult.shoulderOk)
            }

            // Progress bar (only when goal is set)
            if viewModel.targetReps > 0 {
                GluteBridgeProgressBarView(
                    currentSet:  viewModel.currentSet,
                    totalSets:   viewModel.targetSets,
                    repsInSet:   viewModel.repsInCurrentSet,
                    targetReps:  viewModel.targetReps
                )
            }

            // Rep count row
            HStack(alignment: .center, spacing: 0) {
                // Rep number — dominant
                VStack(spacing: 0) {
                    Text("\(viewModel.repsInCurrentSet)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(viewModel.targetReps > 0
                         ? "SET \(viewModel.currentSet) OF \(viewModel.targetSets)"
                         : "REPS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .kerning(1.2)
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 44)

                // Quality
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Label("\(viewModel.goodReps)", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("\(viewModel.badReps)", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .font(.subheadline.bold())
                    Text("QUALITY").font(.system(size: 10)).foregroundColor(.white.opacity(0.5)).kerning(1.2)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 44)

                // Reset
                Button { viewModel.resetSession() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3).foregroundColor(.white.opacity(0.7))
                        Text("RESET").font(.system(size: 10)).foregroundColor(.white.opacity(0.4)).kerning(1.2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(.ultraThinMaterial.opacity(0.95))
        .background(Color.black.opacity(0.6))
        .cornerRadius(24)
        .padding(.horizontal, 12).padding(.bottom, 8)
    }

    private var scoreColor: Color {
        let s = viewModel.bridgeResult.postureScore
        if s >= 80 { return .green }
        if s >= 55 { return .yellow }
        return .red
    }
}

// MARK: - ALERT BANNER
struct GluteBridgeAlertBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text(message).font(.subheadline.bold()).foregroundColor(.white)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.orange, lineWidth: 1.5))
        .shadow(color: .orange.opacity(0.4), radius: 8).padding(.horizontal)
    }
}

// MARK: - REST TIMER VIEW
struct GluteBridgeRestTimerView: View {
    let secondsLeft: Int
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer").foregroundColor(.cyan)
            Text("Rest: \(secondsLeft)s").font(.title3.bold()).foregroundColor(.white)
            Text("Next set coming up...").font(.caption).foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.cyan, lineWidth: 1.5))
        .shadow(color: .cyan.opacity(0.4), radius: 8).padding(.horizontal)
    }
}

// MARK: - PROGRESS BAR VIEW
struct GluteBridgeProgressBarView: View {
    let currentSet: Int; let totalSets: Int; let repsInSet: Int; let targetReps: Int
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Set \(currentSet) of \(totalSets)").font(.caption).foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(repsInSet)/\(targetReps) reps").font(.caption.bold()).foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.15)).frame(height: 10)
                    RoundedRectangle(cornerRadius: 6).fill(Color.green)
                        .frame(width: geo.size.width * CGFloat(min(repsInSet, targetReps)) / CGFloat(max(targetReps, 1)),
                               height: 10)
                        .animation(.spring(response: 0.3), value: repsInSet)
                }
            }.frame(height: 10)
        }.padding(.horizontal, 4)
    }
}

// MARK: - ANGLE CHIP (compact inline chip)
struct GluteBridgeAngleChip: View {
    let label: String; let angle: Double; let isOk: Bool
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(isOk ? Color.green : Color.red).frame(width: 6, height: 6)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.6))
            Text("\(Int(angle))°").font(.system(size: 12, weight: .bold)).foregroundColor(isOk ? .green : .red)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(isOk ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - GOAL SETUP SHEET
struct GluteBridgeGoalSetupSheet: View {
    @ObservedObject var viewModel: GluteBridgeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var sets    = 3
    @State private var reps    = 12
    @State private var restSec = 45

    var body: some View {
        NavigationView {
            Form {
                Section("Workout Goal") {
                    Stepper("Sets: \(sets)", value: $sets, in: 1...10)
                    Stepper("Reps per set: \(reps)", value: $reps, in: 1...30)
                }
                Section("Rest Timer") {
                    Stepper("Rest: \(restSec)s", value: $restSec, in: 10...180, step: 10)
                }
                Section {
                    Button("Start Workout") {
                        viewModel.setGoal(sets: sets, reps: reps, restSeconds: restSec)
                        dismiss()
                    }.foregroundColor(.green).bold()
                    Button("Clear Goal") {
                        viewModel.clearGoal(); dismiss()
                    }.foregroundColor(.red)
                }
            }
            .navigationTitle("Set Goal")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

// MARK: - STATS SHEET
struct GluteBridgeStatsSheet: View {
    @ObservedObject var viewModel: GluteBridgeViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        GluteBridgeStatCard(title: "Total Reps", value: "\(viewModel.totalRepsAllTime)", color: .blue)
                        GluteBridgeStatCard(title: "Good Reps",  value: "\(viewModel.goodReps)",         color: .green)
                        GluteBridgeStatCard(title: "Bad Reps",   value: "\(viewModel.badReps)",          color: .red)
                    }
                    HStack(spacing: 12) {
                        GluteBridgeStatCard(title: "Avg Score",    value: "\(viewModel.averageScore)",   color: .yellow)
                        GluteBridgeStatCard(title: "Best Score",   value: "\(viewModel.bestRepScore)",   color: .orange)
                        GluteBridgeStatCard(title: "Session Time", value: viewModel.sessionTimeString,   color: .cyan)
                    }

                    if !viewModel.repHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rep Score History").font(.headline).padding(.horizontal)
                            GluteBridgeRepScoreGraph(records: viewModel.repHistory)
                                .frame(height: 180).padding(.horizontal)
                        }
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6)).cornerRadius(16).padding(.horizontal)
                    }

                    if !viewModel.repHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Rep History").font(.headline).padding(.horizontal)
                            ForEach(viewModel.repHistory.reversed()) { rep in
                                HStack {
                                    Text("Rep \(rep.repNumber)").font(.subheadline)
                                    Spacer()
                                    Text("Score: \(rep.score)").font(.subheadline.bold())
                                        .foregroundColor(rep.isGood ? .green : .red)
                                    Text(rep.isGood ? "✅" : "❌")
                                }
                                .padding(.horizontal).padding(.vertical, 6)
                                .background(Color(.systemGray6)).cornerRadius(10).padding(.horizontal)
                            }
                        }
                    } else {
                        Text("No reps recorded yet.\nStart bridging! 🍑")
                            .multilineTextAlignment(.center).foregroundColor(.secondary).padding(.top, 40)
                    }
                }.padding(.vertical)
            }
            .navigationTitle("Session Stats")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

struct GluteBridgeStatCard: View {
    let title: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Color(.systemGray6)).cornerRadius(12)
    }
}

struct GluteBridgeRepScoreGraph: View {
    let records: [GluteBridgeRepRecord]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width; let h = geo.size.height
            let barW = max(8, min(28, w / CGFloat(records.count) - 4))
            ZStack(alignment: .bottom) {
                ForEach([0, 25, 50, 75, 100], id: \.self) { val in
                    let y = h * (1 - CGFloat(val) / 100)
                    Path { p in p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: w, y: y)) }
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(records) { rep in
                        VStack(spacing: 2) {
                            Text("\(rep.score)").font(.system(size: 8)).foregroundColor(.white.opacity(0.7))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(rep.isGood ? Color.green : Color.red)
                                .frame(width: barW, height: max(4, h * CGFloat(rep.score) / 100 - 16))
                        }
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}

// MARK: - SKELETON OVERLAY
struct GluteBridgeSkeletonOverlay: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let result: GluteBridgeResult

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let usedSide = result.trackedLeftSide
                let shoulder: VNHumanBodyPoseObservation.JointName = usedSide ? .leftShoulder : .rightShoulder
                let hip:      VNHumanBodyPoseObservation.JointName = usedSide ? .leftHip      : .rightHip
                let knee:     VNHumanBodyPoseObservation.JointName = usedSide ? .leftKnee     : .rightKnee
                let ankle:    VNHumanBodyPoseObservation.JointName = usedSide ? .leftAnkle    : .rightAnkle

                drawLine(shoulder, hip,   geo, ok: result.spineOk)
                drawLine(hip,      knee,  geo, ok: result.hipOk)
                drawLine(knee,     ankle, geo, ok: result.kneeOk)

                ForEach([shoulder, hip, knee, ankle], id: \.self) { joint in
                    if let pt = bodyPoints[joint] {
                        Circle()
                            .fill(dotColor(for: joint, s: shoulder, h: hip, k: knee, a: ankle))
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                            .position(x: pt.x * geo.size.width, y: pt.y * geo.size.height)
                    }
                }

                if let anklePt = bodyPoints[ankle] {
                    let y = anklePt.y * geo.size.height
                    Path { p in
                        p.move(to: .init(x: 0, y: y))
                        p.addLine(to: .init(x: geo.size.width, y: y))
                    }
                    .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                }
            }
        }
    }

    private func dotColor(for joint: VNHumanBodyPoseObservation.JointName,
                          s: VNHumanBodyPoseObservation.JointName,
                          h: VNHumanBodyPoseObservation.JointName,
                          k: VNHumanBodyPoseObservation.JointName,
                          a: VNHumanBodyPoseObservation.JointName) -> Color {
        if joint == s { return result.shoulderOk ? .green : .red }
        if joint == h { return result.hipOk      ? .green : .red }
        if joint == k { return result.kneeOk     ? .green : .red }
        if joint == a { return result.kneeOk     ? .green : .red }
        return .white
    }

    @ViewBuilder
    private func drawLine(_ j1: VNHumanBodyPoseObservation.JointName,
                          _ j2: VNHumanBodyPoseObservation.JointName,
                          _ geo: GeometryProxy, ok: Bool) -> some View {
        if let p1 = bodyPoints[j1], let p2 = bodyPoints[j2] {
            Path { path in
                path.move(to: CGPoint(x: p1.x * geo.size.width, y: p1.y * geo.size.height))
                path.addLine(to: CGPoint(x: p2.x * geo.size.width, y: p2.y * geo.size.height))
            }
            .stroke(ok ? Color.green : Color.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
}

// MARK: - GLUTE BRIDGE VIEW MODEL
final class GluteBridgeViewModel: NSObject, ObservableObject,
                                   AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession()

    @Published var bodyPoints:      [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var bridgeResult     = GluteBridgeResult()
    @Published var reps             = 0
    @Published var phaseText        = "Lie Flat"
    @Published var phaseColor: Color = .white
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var detectionStatus  = "Real-Time Form Check"

    @Published var showFormAlert    = false
    @Published var formAlertMessage = ""
    @Published var showBadRepFlash  = false
    @Published var badRepReason     = ""

    // Analytics
    @Published var repHistory:      [GluteBridgeRepRecord] = []
    @Published var goodReps         = 0
    @Published var badReps          = 0
    @Published var totalRepsAllTime = 0
    @Published var averageScore     = 0
    @Published var bestRepScore     = 0

    // Sets / Goal
    @Published var targetSets        = 0
    @Published var targetReps        = 0
    @Published var currentSet        = 1
    @Published var repsInCurrentSet  = 0

    // Rest timer
    @Published var isResting         = false
    @Published var restSecondsLeft   = 0
    private var restDuration         = 45
    private var restTimer: Timer?

    // Session timer
    @Published var sessionTimeString = "00:00"
    private var sessionStartDate: Date?
    private var sessionTimer: Timer?

    // Speech
    private let speechSynth        = AVSpeechSynthesizer()
    private var lastSpokenIssue: GluteBridgeIssue = .detecting
    private var lastSpeechTime: Date = .distantPast

    // Watch notification throttle
    private var lastNotifTime: [String: Date] = [:]
    private let notifCooldown: TimeInterval   = 5.0

    // ── Thresholds ────────────────────────────────────────────────────────────
    private let bridgeTopHipMin: Double = 145
    private let bridgeTopHipMax: Double = 178
    private let flatHipMin:      Double = 115
    private let kneeMin:         Double = 70
    private let kneeMax:         Double = 120
    private let spineMax:        Double = 30
    private let shoulderRiseMax: Double = 0.07

    private let hipRiseRequired:  Double = 0.05
    private let flatThreshold:    Double = 0.03
    private let framesForTop:     Int = 3
    private let framesForFlat:    Int = 3
    private let errorLatch:       Int = 4
    private let baselineRequired: Int = 8

    // ── Orientation locking ───────────────────────────────────────────────────
    private var lockedOrientation: CGImagePropertyOrientation? = nil
    private var orientationSearchFrames = 0
    private let orientationLockFrames   = 10
    private var missingBodyFrames       = 0
    private let relockThreshold         = 30

    private let candidateOrientations: [CGImagePropertyOrientation] = [
        .right, .left, .up, .down
    ]

    // ── Smoothing (display only) ──────────────────────────────────────────────
    private var angleBuffer: [(hip: Double, knee: Double, spine: Double, shoulder: Double)] = []
    private let angleBufferSize = 5

    // ── Locked side ───────────────────────────────────────────────────────────
    private var lockedSide: Bool? = nil

    // ── Rep state ─────────────────────────────────────────────────────────────
    private var repInProgress    = false
    private var topReached       = false
    private var framesAtTop      = 0
    private var framesAtFlat     = 0
    private var hipYBaseline:      Double? = nil
    private var shoulderYBaseline: Double? = nil
    private var baselineCaptured   = false
    private var baselineFrames     = 0

    private var hipErrFrames:      Int = 0;  private var hadHipError      = false
    private var kneeErrFrames:     Int = 0;  private var hadKneeError     = false
    private var spineErrFrames:    Int = 0;  private var hadSpineError    = false
    private var shoulderErrFrames: Int = 0;  private var hadShoulderError = false

    private var stableIssueFrames = 0
    private var lastIssue: GluteBridgeIssue = .detecting
    private var alertTimer: Timer?
    private var currentPhase: GluteBridgePhase = .flat
    
    // add with the other private vars, around line 2770
    private var isConfiguring = false
    // add with other private vars
    private let cameraQueue = DispatchQueue(label: "squatCameraQueue")

    // MARK: - Lifecycle
    func start() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { return }
            DispatchQueue.global(qos: .userInitiated).async { self.setupCamera() }
        }
        startSessionTimer()
        fireWatchNotification(title: "🏋️ Ready for Glute Bridge!", body: "Lie flat and begin when calibrated.")
    }

    func stop() {
        sessionTimer?.invalidate()
        restTimer?.invalidate()
        cameraQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: - Session timer
    private func startSessionTimer() {
        sessionStartDate = Date()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.sessionStartDate else { return }
            let e = Int(Date().timeIntervalSince(start))
            DispatchQueue.main.async {
                self.sessionTimeString = String(format: "%02d:%02d", e / 60, e % 60)
            }
        }
    }

    // MARK: - Goal
    func setGoal(sets: Int, reps: Int, restSeconds: Int) {
        DispatchQueue.main.async {
            self.targetSets = sets; self.targetReps = reps
            self.restDuration = restSeconds
            self.currentSet = 1; self.repsInCurrentSet = 0
        }
    }

    func clearGoal() {
        DispatchQueue.main.async {
            self.targetSets = 0; self.targetReps = 0
            self.currentSet = 1; self.repsInCurrentSet = 0
        }
    }

    // MARK: - Reset
    func resetSession() {
        DispatchQueue.main.async {
            self.reps = 0; self.repsInCurrentSet = 0; self.currentSet = 1
            self.goodReps = 0; self.badReps = 0; self.totalRepsAllTime = 0
            self.averageScore = 0; self.bestRepScore = 0; self.repHistory = []
            self.angleBuffer.removeAll()
            self.resetRepState()
            self.resetBaseline()
            self.lockedSide = nil
            self.lockedOrientation = nil
            self.orientationSearchFrames = 0
            self.missingBodyFrames = 0
            self.isResting = false; self.restTimer?.invalidate()
            self.sessionStartDate = Date()
            self.phaseText  = "Lie Flat"
            self.phaseColor = .white
        }
    }

    private func resetRepState() {
        repInProgress = false; topReached = false
        framesAtTop = 0; framesAtFlat = 0
        hipErrFrames = 0; hadHipError = false
        kneeErrFrames = 0; hadKneeError = false
        spineErrFrames = 0; hadSpineError = false
        shoulderErrFrames = 0; hadShoulderError = false
        currentPhase = .flat
    }

    private func resetBaseline() {
        hipYBaseline = nil; shoulderYBaseline = nil
        baselineCaptured = false; baselineFrames = 0
    }

    // MARK: - Rest timer
    private func startRestTimer() {
        restSecondsLeft = restDuration; isResting = true
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            DispatchQueue.main.async {
                self.restSecondsLeft -= 1
                if self.restSecondsLeft <= 0 {
                    t.invalidate(); self.isResting = false
                    self.resetRepState(); self.speakText("Go!")
                }
            }
        }
    }

    // MARK: Camera
    private func setupCamera() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            guard !self.session.isRunning else { return }
            // Remove any stale inputs/outputs from a previous session
            self.isConfiguring = true
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            self.session.inputs.forEach  { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition),
                let input  = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(input)
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "squatVideoQueue"))
            output.alwaysDiscardsLateVideoFrames = true
            if self.session.canAddOutput(output) { self.session.addOutput(output) }
            self.session.commitConfiguration()
            self.isConfiguring = false
            self.session.startRunning()
        }
    }

    func switchCamera() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.isConfiguring = true
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            guard
                let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                let inp = try? AVCaptureDeviceInput(device: dev),
                self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(inp)
            self.session.commitConfiguration()
            self.isConfiguring = false
            DispatchQueue.main.async { self.cameraPosition = newPos }
        }
    }


    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        analyzeFrame(pixelBuffer: pixelBuffer)
    }

    // MARK: - Best-orientation detection
    private func bestOrientation(for pixelBuffer: CVPixelBuffer)
        -> (orientation: CGImagePropertyOrientation,
            points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint])? {

        var bestScore: Float = 0
        var bestResult: (CGImagePropertyOrientation, [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint])?

        let keysToScore: [VNHumanBodyPoseObservation.JointName] = [
            .leftShoulder, .rightShoulder,
            .leftHip,      .rightHip,
            .leftKnee,     .rightKnee,
            .leftAnkle,    .rightAnkle
        ]

        let orientations: [CGImagePropertyOrientation] = cameraPosition == .front
            ? [.leftMirrored, .rightMirrored, .upMirrored, .downMirrored]
            : candidateOrientations

        for orientation in orientations {
            let request = VNDetectHumanBodyPoseRequest()
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                orientation: orientation)
            do {
                try handler.perform([request])
                guard let obs = request.results?.first,
                      let pts = try? obs.recognizedPoints(.all) else { continue }
                let score = keysToScore.reduce(Float(0)) { $0 + (pts[$1]?.confidence ?? 0) }
                if score > bestScore {
                    bestScore = score
                    bestResult = (orientation, pts)
                }
            } catch { continue }
        }
        guard let result = bestResult, bestScore > 0.4 else { return nil }
        return result
    }

    // MARK: - Analysis pipeline
    private func analyzeFrame(pixelBuffer: CVPixelBuffer) {
        guard !isResting else { return }

        let orientationToUse: CGImagePropertyOrientation
        var rawPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]

        if let locked = lockedOrientation {
            let request = VNDetectHumanBodyPoseRequest()
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: locked)
            do {
                try handler.perform([request])
                guard let obs = request.results?.first,
                      let pts = try? obs.recognizedPoints(.all) else {
                    missingBodyFrames += 1
                    if missingBodyFrames >= relockThreshold {
                        lockedOrientation = nil
                        orientationSearchFrames = 0
                        missingBodyFrames = 0
                        DispatchQueue.main.async { self.detectionStatus = "Searching..." }
                    }
                    DispatchQueue.main.async { self.bridgeResult.issue = .notVisible }
                    return
                }
                orientationToUse = locked
                rawPoints = pts
                missingBodyFrames = 0
            } catch {
                DispatchQueue.main.async { self.bridgeResult.issue = .notVisible }
                return
            }
        } else {
            guard let best = bestOrientation(for: pixelBuffer) else {
                DispatchQueue.main.async {
                    self.bridgeResult.issue = .notVisible
                    self.detectionStatus = "Searching — lie flat & stay still"
                }
                return
            }
            orientationToUse = best.orientation
            rawPoints = best.points

            orientationSearchFrames += 1
            if orientationSearchFrames >= orientationLockFrames {
                lockedOrientation = orientationToUse
                orientationSearchFrames = 0
                DispatchQueue.main.async { self.detectionStatus = "Real-Time Form Check" }
            }
        }

        let useLeft: Bool
        if let locked = lockedSide {
            useLeft = locked
        } else {
            useLeft = betterSide(rawPoints)
        }

        var mapped: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (joint, point) in rawPoints where point.confidence > 0.15 {
            mapped[joint] = CGPoint(x: point.location.x, y: 1 - point.location.y)
        }

        guard let rawResult = extractAngles(from: rawPoints, useLeft: useLeft) else {
            DispatchQueue.main.async {
                self.bodyPoints = mapped
                self.bridgeResult.issue = .notVisible
            }
            return
        }

        updateBaseline(result: rawResult, rawPoints: rawPoints, useLeft: useLeft)
        updatePhaseAndReps(result: rawResult, rawPoints: rawPoints, useLeft: useLeft)

        var displayResult = rawResult
        let s = smoothForDisplay(rawResult)
        displayResult.hipAngle     = s.hip
        displayResult.kneeAngle    = s.knee
        displayResult.spineAngle   = s.spine
        displayResult.shoulderRise = s.shoulder

        evaluateForm(result: &displayResult)

        if displayResult.issue == lastIssue { stableIssueFrames += 1 }
        else { stableIssueFrames = 0; lastIssue = displayResult.issue }
        var published = displayResult
        if stableIssueFrames < 3 { published.issue = bridgeResult.issue }

        speakFormCue(result: published)
        updateFormAlert(result: published)

        DispatchQueue.main.async {
            self.bodyPoints   = mapped
            self.bridgeResult = published
        }
    }

    // MARK: - Angle extraction
    private func extractAngles(from points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
                                useLeft: Bool) -> GluteBridgeResult? {
        let shoulderKey: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let hipKey:      VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let kneeKey:     VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee     : .rightKnee
        let ankleKey:    VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle    : .rightAnkle

        for j in [shoulderKey, hipKey, kneeKey, ankleKey] {
            guard let p = points[j], p.confidence > 0.15 else { return nil }
        }

        let shoulder = points[shoulderKey]!.location
        let hip      = points[hipKey]!.location
        let knee     = points[kneeKey]!.location
        let ankle    = points[ankleKey]!.location

        var result = GluteBridgeResult()
        result.trackedLeftSide = useLeft
        result.hipAngle   = calculateAngle(first: shoulder, middle: hip,  last: knee)
        result.kneeAngle  = calculateAngle(first: hip,      middle: knee, last: ankle)
        let spineRaw      = atan2(shoulder.y - hip.y, shoulder.x - hip.x) * 180 / .pi
        result.spineAngle = min(abs(spineRaw), 90)
        if let baseline = shoulderYBaseline {
            result.shoulderRise = max(0, shoulder.y - baseline) * 100
        }
        return result
    }

    // MARK: - Baseline capture
    private func updateBaseline(result: GluteBridgeResult,
                                rawPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
                                useLeft: Bool) {
        guard !baselineCaptured else { return }

        let hipKey:      VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let shoulderKey: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder

        guard let hipPt = rawPoints[hipKey], let shoulderPt = rawPoints[shoulderKey],
              hipPt.confidence > 0.15, shoulderPt.confidence > 0.15 else { return }

        let isFlat = result.spineAngle < 30 && result.hipAngle > flatHipMin

        if isFlat {
            baselineFrames += 1
            let w = 1.0 / Double(baselineFrames)
            hipYBaseline      = (hipYBaseline ?? hipPt.location.y) * (1 - w) + hipPt.location.y * w
            shoulderYBaseline = (shoulderYBaseline ?? shoulderPt.location.y) * (1 - w) + shoulderPt.location.y * w

            if baselineFrames >= baselineRequired {
                baselineCaptured = true
                lockedSide = useLeft
                DispatchQueue.main.async {
                    self.phaseText = "Ready ✅"; self.phaseColor = .green
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if self.currentPhase == .flat {
                            self.phaseText = "Lie Flat"; self.phaseColor = .white
                        }
                    }
                }
            }
        } else {
            baselineFrames = 0; hipYBaseline = nil; shoulderYBaseline = nil
        }
    }

    // MARK: - Form evaluation
    private func evaluateForm(result: inout GluteBridgeResult) {
        guard result.spineAngle < 50 else {
            result.hipOk = true; result.kneeOk = true
            result.spineOk = true; result.shoulderOk = true
            result.issue = .ready; result.postureScore = 100; return
        }

        let atTop = currentPhase == .top || currentPhase == .ascending

        result.hipOk = atTop
            ? (result.hipAngle >= bridgeTopHipMin && result.hipAngle <= bridgeTopHipMax)
            : true

        result.kneeOk = result.kneeAngle >= kneeMin && result.kneeAngle <= kneeMax

        result.spineOk = atTop ? result.spineAngle <= spineMax : true

        result.shoulderOk = result.shoulderRise <= (shoulderRiseMax * 100)

        var score = 100
        if !result.hipOk      { score -= 35 }
        if !result.kneeOk     { score -= 25 }
        if !result.spineOk    { score -= 25 }
        if !result.shoulderOk { score -= 15 }
        result.postureScore = max(score, 0)

        if !result.hipOk          { result.issue = result.hipAngle < bridgeTopHipMin ? .hipsTooLow : .hipsTooHigh }
        else if !result.spineOk   { result.issue = .backArched }
        else if !result.kneeOk    { result.issue = result.kneeAngle < kneeMin ? .kneeTooClose : .kneeTooWide }
        else if !result.shoulderOk { result.issue = .shoulderLifted }
        else                       { result.issue = .correct }
    }

    // MARK: - Rep state machine (original logic preserved exactly)
    private func updatePhaseAndReps(result: GluteBridgeResult,
                                    rawPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint],
                                    useLeft: Bool) {
        guard baselineCaptured, let hipBase = hipYBaseline else {
            DispatchQueue.main.async {
                self.phaseText = "Hold Still to Calibrate"
                self.phaseColor = .white.opacity(0.6)
            }
            return
        }

        let hipKey: VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip : .rightHip
        guard let hipPt = rawPoints[hipKey], hipPt.confidence > 0.15 else { return }

        let hipRise = hipPt.location.y - hipBase

        var nextPhase = currentPhase
        var addRep    = false

        if repInProgress {
            hipErrFrames      = result.hipOk      ? max(0, hipErrFrames - 1)      : hipErrFrames + 1
            kneeErrFrames     = result.kneeOk     ? max(0, kneeErrFrames - 1)     : kneeErrFrames + 1
            spineErrFrames    = result.spineOk    ? max(0, spineErrFrames - 1)    : spineErrFrames + 1
            shoulderErrFrames = result.shoulderOk ? max(0, shoulderErrFrames - 1) : shoulderErrFrames + 1
            if hipErrFrames      >= errorLatch { hadHipError      = true }
            if kneeErrFrames     >= errorLatch { hadKneeError     = true }
            if spineErrFrames    >= errorLatch { hadSpineError    = true }
            if shoulderErrFrames >= errorLatch { hadShoulderError = true }
        }

        if !repInProgress && hipRise >= hipRiseRequired {
            repInProgress = true; framesAtTop = 0; framesAtFlat = 0
            nextPhase = .ascending
        }

        if repInProgress && hipRise >= hipRiseRequired && nextPhase != .top {
            nextPhase = .ascending
        }

        if repInProgress && result.hipAngle >= bridgeTopHipMin && hipRise >= hipRiseRequired * 0.5 {
            framesAtTop += 1
            if framesAtTop >= framesForTop { topReached = true; nextPhase = .top }
        } else if repInProgress && nextPhase != .top {
            framesAtTop = max(0, framesAtTop - 1)
        }

        if topReached && hipRise < hipRiseRequired && hipRise > flatThreshold {
            nextPhase = .descending
        }

        if repInProgress && hipRise <= flatThreshold {
            framesAtFlat += 1
            if framesAtFlat >= framesForFlat {
                let topWasReached = topReached
                let reasons = buildBadRepReasons(topWasReached: topWasReached)
                if topWasReached && !hadHipError && !hadSpineError {
                    addRep = true
                } else {
                    let r = reasons
                    DispatchQueue.main.async { self.triggerBadRepFeedback(reasons: r) }
                }
                resetRepState()
                nextPhase = .flat
            }
        } else if repInProgress {
            framesAtFlat = 0
        }

        currentPhase = nextPhase
        let scoreSnapshot = result.postureScore

        DispatchQueue.main.async {
            if addRep {
                self.reps += 1
                self.repsInCurrentSet += 1
                self.totalRepsAllTime += 1
                self.speakRepCount(self.repsInCurrentSet)
                WatchConnectivityManager.shared.sendRepUpdate(
                    exercise: "Glute Bridge", repsInSet: self.repsInCurrentSet,
                    targetReps: self.targetReps, currentSet: self.currentSet,
                    totalSets: self.targetSets, formScore: scoreSnapshot,
                    feedback: scoreSnapshot >= 85 ? "Good form!" : "Keep it clean")

                if self.targetReps > 0 && self.repsInCurrentSet >= self.targetReps {
                    if self.currentSet < self.targetSets {
                        self.speakText("Set \(self.currentSet) complete! Rest now.")
                        self.fireWatchNotification(
                            title: "✅ Set \(self.currentSet) Done!",
                            body:  "Rest up, next set starting soon."
                        )
                        self.startRestTimer()
                        self.currentSet += 1
                        self.repsInCurrentSet = 0
                    } else {
                        self.speakText("Workout complete! Great job!")
                        self.fireWatchNotification(
                            title: "🎉 Workout Complete!",
                            body:  "You finished all \(self.targetSets) sets. Great job!"
                        )
                    }
                }

                let record = GluteBridgeRepRecord(
                    repNumber: self.totalRepsAllTime,
                    score: scoreSnapshot,
                    isGood: true,
                    timestamp: Date()
                )
                self.repHistory.append(record)
                self.updateScoreStats()
            }

            switch nextPhase {
            case .flat:       self.phaseText = "Lie Flat";       self.phaseColor = .white
            case .ascending:  self.phaseText = "Lifting Up";     self.phaseColor = .yellow
            case .top:        self.phaseText = "Full Bridge ✅"; self.phaseColor = .green
            case .descending: self.phaseText = "Lowering Down";  self.phaseColor = .blue
            }
        }
    }

    private func updateScoreStats() {
        goodReps = repHistory.filter { $0.isGood }.count
        badReps  = repHistory.filter { !$0.isGood }.count
        if !repHistory.isEmpty {
            averageScore = repHistory.map { $0.score }.reduce(0,+) / repHistory.count
            bestRepScore = repHistory.map { $0.score }.max() ?? 0
        }
    }

    private func buildBadRepReasons(topWasReached: Bool) -> String {
        var r: [String] = []
        if !topWasReached   { r.append("Didn't reach full extension") }
        if hadHipError      { r.append("Hips not high enough") }
        if hadSpineError    { r.append("Back arching") }
        if hadKneeError     { r.append("Foot placement off") }
        if hadShoulderError { r.append("Shoulders lifted") }
        return r.isEmpty ? "Check your form" : r.joined(separator: " • ")
    }

    private func triggerBadRepFeedback(reasons: String) {
        // Voice cue for bad rep
        if reasons.contains("Hips")        { speakText("Push your hips higher") }
        else if reasons.contains("arching") { speakText("Keep your back neutral") }
        else if reasons.contains("Foot")   { speakText("Check your foot placement") }
        else if reasons.contains("extension") { speakText("Reach full extension at the top") }
        else if reasons.contains("Shoulders") { speakText("Keep shoulders on the floor") }

        // Watch notification for bad rep
        fireWatchNotification(title: "❌ Rep Not Counted", body: reasons)

        // Record bad rep
        DispatchQueue.main.async {
            let record = GluteBridgeRepRecord(
                repNumber: self.totalRepsAllTime + 1,
                score: 0,
                isGood: false,
                timestamp: Date()
            )
            self.repHistory.append(record)
            self.totalRepsAllTime += 1
            self.updateScoreStats()
        }

        badRepReason = reasons; showBadRepFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.showBadRepFlash = false }
    }

    // MARK: - Voice cues
    private func speakFormCue(result: GluteBridgeResult) {
        guard currentPhase == .ascending || currentPhase == .top else { return }
        let now = Date()
        guard now.timeIntervalSince(lastSpeechTime) > 3.0 else { return }
        var cue: String? = nil
        if !result.hipOk       { cue = result.hipAngle < bridgeTopHipMin ? "Push hips higher" : "Don't hyperextend" }
        else if !result.spineOk { cue = "Keep your back neutral" }
        else if !result.shoulderOk { cue = "Keep shoulders on the floor" }
        else if !result.kneeOk  { cue = result.kneeAngle < kneeMin ? "Move feet further away" : "Move feet closer" }
        if let text = cue, result.issue != lastSpokenIssue {
            lastSpokenIssue = result.issue; lastSpeechTime = now
            speakText(text)
        }
    }

    private func speakRepCount(_ count: Int) {
        let u = AVSpeechUtterance(string: "\(count)"); u.rate = 0.55; u.volume = 1.0
        DispatchQueue.main.async { self.speechSynth.speak(u) }
    }

    private func speakText(_ text: String) {
        let u = AVSpeechUtterance(string: text); u.rate = 0.5; u.volume = 1.0
        DispatchQueue.main.async { self.speechSynth.speak(u) }
    }

    // MARK: - Form alert (fires watch notification for real-time errors)
    private func updateFormAlert(result: GluteBridgeResult) {
        guard currentPhase == .ascending || currentPhase == .top else {
            DispatchQueue.main.async { self.showFormAlert = false }; return
        }
        var message: String? = nil
        if !result.hipOk       { message = result.hipAngle < bridgeTopHipMin ? "Push Hips Higher!" : "Don't Hyperextend!" }
        else if !result.spineOk  { message = "Keep Back Neutral!" }
        else if !result.shoulderOk { message = "Keep Shoulders on the Floor!" }
        else if !result.kneeOk   { message = result.kneeAngle < kneeMin ? "Move Feet Further Away!" : "Move Feet Closer!" }

        if let msg = message {
            // Watch notification: real-time form error
            fireWatchNotification(title: "⚠️ Fix Your Form", body: msg)
        }

        DispatchQueue.main.async {
            if let msg = message {
                self.formAlertMessage = msg; self.showFormAlert = true
                self.alertTimer?.invalidate()
                self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                    DispatchQueue.main.async { self.showFormAlert = false }
                }
            } else { self.showFormAlert = false }
        }
    }

    // MARK: - Watch notification (fires both local notification + WatchConnectivity)
    func fireWatchNotification(title: String, body: String) {
        let key = title
        let now = Date()
        if let last = lastNotifTime[key], now.timeIntervalSince(last) < notifCooldown { return }
        lastNotifTime[key] = now

        // 1. Local notification — shows on iPhone + mirrors to watch
        NotificationManager.shared.send(title: title, body: body)

        // 2. WatchConnectivity — direct message to watch app for instant haptic
        WatchConnectivityManager.shared.sendFormAlert(
            exercise: "Glute Bridge",
            issue:    "\(title): \(body)"
        )
    }

    // MARK: - Helpers
    private func betterSide(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> Bool {
        let lScore: Float = (points[.leftShoulder]?.confidence ?? 0)
                          + (points[.leftHip]?.confidence      ?? 0)
                          + (points[.leftKnee]?.confidence     ?? 0)
                          + (points[.leftAnkle]?.confidence    ?? 0)
        let rScore: Float = (points[.rightShoulder]?.confidence ?? 0)
                          + (points[.rightHip]?.confidence      ?? 0)
                          + (points[.rightKnee]?.confidence     ?? 0)
                          + (points[.rightAnkle]?.confidence    ?? 0)
        return lScore >= rScore
    }

    private func calculateAngle(first: CGPoint, middle: CGPoint, last: CGPoint) -> Double {
        let a = atan2(first.y - middle.y, first.x - middle.x)
        let b = atan2(last.y  - middle.y, last.x  - middle.x)
        var angle = abs((a - b) * 180 / .pi)
        if angle > 180 { angle = 360 - angle }
        return angle
    }

    private func smoothForDisplay(_ r: GluteBridgeResult)
        -> (hip: Double, knee: Double, spine: Double, shoulder: Double) {
        angleBuffer.append((r.hipAngle, r.kneeAngle, r.spineAngle, r.shoulderRise))
        if angleBuffer.count > angleBufferSize { angleBuffer.removeFirst() }
        let n = Double(angleBuffer.count)
        return (angleBuffer.map(\.hip).reduce(0,+)      / n,
                angleBuffer.map(\.knee).reduce(0,+)     / n,
                angleBuffer.map(\.spine).reduce(0,+)    / n,
                angleBuffer.map(\.shoulder).reduce(0,+) / n)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - MOUNTAIN CLIMBER
// ─────────────────────────────────────────────────────────────────────────────

enum MCIssue: String {
    case correct    = "✅ Good Form"
    case hipTooHigh = "❌ Lower Your Hips"
    case notDriving = "❌ Drive Knee Further"
    case detecting  = "🔍 Detecting..."
    case notVisible = "📷 Full Body Not Visible"
}

struct MCResult {
    var issue: MCIssue = .detecting
    var postureScore: Int = 100
    var hipAngle: Double = 180
    var kneeReach: Double = 0
    var hipOk  = true
    var driveOk = true
}

final class MCViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = MCResult()
    @Published var reps = 0
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    private var isConfiguring = false
    private var frameBuffer: [MCResult] = []
    private var lastKneeReach: Double = 0
    private var driveCount = 0
    private var alertTimer: Timer?

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { g in
            guard g else { return }
            DispatchQueue.global(qos: .userInitiated).async { self.setupCamera() }
        }
    }
    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            guard !self.isConfiguring else {
                // Session is mid-configuration — wait briefly then stop
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.3) {
                    self.session.stopRunning()
                }
                return
            }
            self.session.stopRunning()
        }
    }
    func resetReps() { DispatchQueue.main.async { self.reps = 0; self.driveCount = 0 } }
    func switchCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.isConfiguring = true
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(inp); self.session.commitConfiguration()
            DispatchQueue.main.async { self.cameraPosition = newPos }
        }
    }
    private func setupCamera() {
        guard !session.isRunning else { return }
        session.beginConfiguration(); session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input)
        else { return }
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "mcQueue"))
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration(); session.startRunning()
    }
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pxBuf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let orient: CGImagePropertyOrientation = cameraPosition == .front ? .leftMirrored : .right
        let req = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pxBuf, orientation: orient)
        do {
            try handler.perform([req])
            guard let obs = req.results?.first else { return }
            let pts = try obs.recognizedPoints(.all)
            DispatchQueue.main.async { self.bodyPoints = mappedPoints(pts) }
            analyze(pts)
        } catch {}
    }
    private func analyze(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var r = MCResult()
        let useLeft = (points[.leftHip]?.confidence ?? 0) >= (points[.rightHip]?.confidence ?? 0)
        let shK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let hpK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let anK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle    : .rightAnkle
        let knL: VNHumanBodyPoseObservation.JointName = .leftKnee
        let knR: VNHumanBodyPoseObservation.JointName = .rightKnee
        for j in [shK, hpK, anK] {
            guard let p = points[j], p.confidence > 0.35 else { r.issue = .notVisible; DispatchQueue.main.async { self.result = r }; return }
        }
        let sh = points[shK]!.location
        let hp = points[hpK]!.location
        let an = points[anK]!.location
        r.hipAngle = calcAngle(first: sh, middle: hp, last: an)
        r.hipOk = r.hipAngle >= 155  // body should be near straight

        // Count knee drives: track leading knee position vs hip
        let leftKneeConf  = points[knL]?.confidence ?? 0
        let rightKneeConf = points[knR]?.confidence ?? 0
        let trackKnee = leftKneeConf >= rightKneeConf ? knL : knR
        if let kn = points[trackKnee], kn.confidence > 0.3 {
            r.kneeReach = abs(kn.location.x - hp.x)  // how far knee is from hip
            r.driveOk = r.kneeReach >= 0.08
            // Count drive if knee comes forward then back
            if r.kneeReach > lastKneeReach + 0.05 && lastKneeReach < 0.06 {
                driveCount += 1
                DispatchQueue.main.async { self.reps = self.driveCount / 2 }  // both legs = 1 rep
            }
        }

        var score = 100
        if !r.hipOk { score -= 40 }
        r.postureScore = max(score, 0)

        frameBuffer.append(r)
        if frameBuffer.count > 6 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        var sm = r
        sm.hipAngle  = frameBuffer.map { $0.hipAngle }.reduce(0,+) / n
        sm.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)
        lastKneeReach = r.kneeReach

        if !sm.hipOk { fireAlert("Hips Too High — Keep Body Flat!") }
        else { DispatchQueue.main.async { self.showAlert = false } }

        if sm.hipOk, let ruleMsg = ruleEngineAlert(joints: self.bodyPoints, exercise: .mountainClimber) {
            fireAlert(ruleMsg)
        }
        sm.issue = !sm.hipOk ? .hipTooHigh : .correct
        DispatchQueue.main.async { self.result = sm }
    }
    private func fireAlert(_ msg: String) {
        DispatchQueue.main.async {
            self.alertMessage = msg; self.showAlert = true
            self.alertTimer?.invalidate()
            self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                DispatchQueue.main.async { self.showAlert = false }
            }
        }
    }
}

struct MountainClimberCameraView: View {
    @StateObject private var vm = MCViewModel()
    var body: some View { mountainClimberUI }
    @ViewBuilder private var mcTopBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mountain Climber AI").font(.title2.bold()).foregroundColor(.white)
                Text("Keep Hips Level — Drive Knees!").font(.caption).foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            Button { vm.switchCamera() } label: {
                Image(systemName: "camera.rotate").font(.title2).foregroundColor(.white)
                    .padding(12).background(Color.white.opacity(0.2)).clipShape(Circle())
            }
            ScoreRing(score: vm.result.postureScore)
        }
        .padding().background(.black.opacity(0.65)).cornerRadius(20).padding()
    }
    @ViewBuilder private var mcBottomPanel: some View {
        VStack(spacing: 18) {
            Text(vm.result.issue.rawValue).font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
            LiveAngleCard(title: "Body Line", angle: vm.result.hipAngle, isOk: vm.result.hipOk, idealRange: "> 155°")
            HStack(spacing: 50) {
                VStack {
                    Text("\(vm.reps)").font(.system(size: 50, weight: .bold)).foregroundColor(.white)
                    Text("REPS").foregroundColor(.white.opacity(0.7))
                }
                VStack {
                    Text(vm.result.hipOk ? "Form OK ✅" : "Fix Form").font(.title3.bold()).foregroundColor(vm.result.hipOk ? Color.green : Color.red)
                    Text("STATUS").foregroundColor(.white.opacity(0.7))
                }
                Button { vm.resetReps() } label: {
                    VStack {
                        Image(systemName: "arrow.counterclockwise").font(.title2).foregroundColor(.white)
                        Text("RESET").foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding().background(.black.opacity(0.75)).cornerRadius(22).padding()
    }
    @ViewBuilder private var mountainClimberUI: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            SimpleSkeletonOverlay(bodyPoints: vm.bodyPoints, joints: [.leftShoulder,.rightShoulder,.leftHip,.rightHip,.leftKnee,.rightKnee,.leftAnkle,.rightAnkle], isOk: vm.result.hipOk).ignoresSafeArea()
            VStack {
                mcTopBar
                Spacer()
                if vm.showAlert { LiveFormBanner(message: vm.alertMessage).transition(.move(edge: .top).combined(with: .opacity)) }
                Spacer()
                mcBottomPanel
            }
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .animation(.spring(response: 0.4), value: vm.showAlert)
    }

}
// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HIGH KNEES
// ─────────────────────────────────────────────────────────────────────────────

import SwiftUI
import AVFoundation
import Vision
import Combine
import AVKit

// ─────────────────────────────────────────────
// MARK: - HIGH KNEES ISSUE
// ─────────────────────────────────────────────
enum HighKneesIssue: String {
    case correct       = "✅ Great Form!"
    case ready         = "🧍 Ready – Start Running!"
    case notHigh       = "❌ Lift Knees to Hip Height"
    case leaningBack   = "❌ Keep Torso Upright"
    case detecting     = "🔍 Detecting..."
    case notVisible    = "📷 Full Body Not Visible"
}

// ─────────────────────────────────────────────
// MARK: - HIGH KNEES PHASE
// ─────────────────────────────────────────────
enum HighKneesPhase { case idle, lifting, peak, lowering }

// ─────────────────────────────────────────────
// MARK: - REP RECORD  (reuse same struct as Squat)
// ─────────────────────────────────────────────
// RepRecord is already declared in SquatView.swift.
// If compiling together, remove the struct below and rely on the shared one.
// If compiling standalone, keep it.
#if !SQUAT_REPRECORD_DEFINED
struct HKRepRecord: Identifiable {
    let id        = UUID()
    let repNumber: Int
    let score:     Int
    let isGood:    Bool
    let timestamp: Date
}
#endif

// ─────────────────────────────────────────────
// MARK: - HIGH KNEES RESULT
// ─────────────────────────────────────────────
struct HighKneesResult {
    var issue: HighKneesIssue = .detecting
    var postureScore: Int   = 100
    var kneeHeight:   Double = 0   // hip.y – knee.y in normalised coords
    var torsoAngle:   Double = 90
    var trackedLeftSide: Bool = true
    var kneeOk:  Bool = true
    var torsoOk: Bool = true
    var formIsValid: Bool { kneeOk && torsoOk }
}

// ─────────────────────────────────────────────
// MARK: - CAMERA VIEW
// ─────────────────────────────────────────────
struct HighKneesView: View {
    @StateObject private var viewModel   = HighKneesViewModel()
    @State private var showGoalSheet     = false
    @State private var showStatsSheet    = false

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.session).ignoresSafeArea()

            HighKneesSkeletonOverlay(
                bodyPoints: viewModel.bodyPoints,
                result:     viewModel.postureResult
            ).ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                if viewModel.showFormAlert {
                    HighKneesFormAlertBanner(message: viewModel.formAlertMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: viewModel.showFormAlert)
                }
                Spacer()

                if viewModel.isResting {
                    HighKneesRestTimerView(secondsLeft: viewModel.restSecondsLeft)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(), value: viewModel.isResting)
                }

                bottomPanel
            }

            // Good-rep flash
            if viewModel.showGoodRepFlash {
                Color.green.opacity(0.2).ignoresSafeArea().allowsHitTesting(false)
            }

            // Bad-rep overlay
            if viewModel.badRepMessage != nil {
                Color.red.opacity(0.25).ignoresSafeArea().allowsHitTesting(false)
                VStack {
                    Spacer()
                    Text(viewModel.badRepMessage ?? "")
                        .font(.title3.bold()).foregroundColor(.white)
                        .multilineTextAlignment(.center).padding()
                        .background(Color.red.opacity(0.85)).cornerRadius(16)
                        .padding(.bottom, 220)
                }
            }
        }
        .onAppear    { viewModel.start() }
        .onDisappear { viewModel.stop() }
        .sheet(isPresented: $showGoalSheet)  { HighKneesGoalSheet(viewModel: viewModel) }
        .sheet(isPresented: $showStatsSheet) { HighKneesStatsSheet(viewModel: viewModel) }
        .navigationBarHidden(true)
    }

    // ── Top bar ──────────────────────────────
    private var topBar: some View {
        HStack(spacing: 8) {
            Text(viewModel.sessionTimeString)
                .font(.caption.monospacedDigit().bold())
                .foregroundColor(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.black.opacity(0.5)).cornerRadius(20)

            Spacer()

            ZStack {
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 3).frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.postureResult.postureScore) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40).rotationEffect(.degrees(-90))
                Text("\(viewModel.postureResult.postureScore)")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
            }

            HStack(spacing: 4) {
                Button { showStatsSheet = true } label: {
                    Image(systemName: "chart.bar.fill").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                Button { showGoalSheet = true } label: {
                    Image(systemName: "target").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                Button { viewModel.switchCamera() } label: {
                    Image(systemName: "camera.rotate").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(.black.opacity(0.5)).cornerRadius(24)
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    // ── Bottom panel ─────────────────────────
    private var bottomPanel: some View {
        VStack(spacing: 10) {
            HStack {
                Text(viewModel.postureResult.issue.rawValue)
                    .font(.subheadline.bold()).foregroundColor(.white)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(viewModel.phaseText)
                    .font(.caption.bold())
                    .foregroundColor(viewModel.phaseColor)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(viewModel.phaseColor.opacity(0.15))
                    .cornerRadius(12)
            }

            HStack(spacing: 6) {
                HKAngleChip(label: "Torso",  value: viewModel.postureResult.torsoAngle,       isOk: viewModel.postureResult.torsoOk,  unit: "°")
                HKAngleChip(label: "Knee H.", value: viewModel.postureResult.kneeHeight * 100, isOk: viewModel.postureResult.kneeOk,   unit: "%")
                HKAngleChip(label: "Score",  value: Double(viewModel.postureResult.postureScore), isOk: viewModel.postureResult.postureScore >= 70, unit: "")
            }

            if viewModel.targetReps > 0 {
                HKProgressBarView(
                    currentSet: viewModel.currentSet,
                    totalSets:  viewModel.targetSets,
                    repsInSet:  viewModel.repsInCurrentSet,
                    targetReps: viewModel.targetReps
                )
            }

            HStack(alignment: .center, spacing: 0) {
                VStack(spacing: 0) {
                    Text("\(viewModel.repsInCurrentSet)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(viewModel.targetReps > 0
                         ? "SET \(viewModel.currentSet) OF \(viewModel.targetSets)"
                         : "REPS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .kerning(1.2)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 44)

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Label("\(viewModel.goodReps)", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("\(viewModel.badReps)", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .font(.subheadline.bold())
                    Text("QUALITY").font(.system(size: 10)).foregroundColor(.white.opacity(0.5)).kerning(1.2)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 44)

                Button { viewModel.resetSession() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3).foregroundColor(.white.opacity(0.7))
                        Text("RESET").font(.system(size: 10)).foregroundColor(.white.opacity(0.4)).kerning(1.2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(.ultraThinMaterial.opacity(0.95))
        .background(Color.black.opacity(0.6))
        .cornerRadius(24)
        .padding(.horizontal, 12).padding(.bottom, 8)
    }

    private var scoreColor: Color {
        let s = viewModel.postureResult.postureScore
        if s >= 80 { return .green }
        if s >= 55 { return .yellow }
        return .red
    }
}

// ─────────────────────────────────────────────
// MARK: - CAMERA SUPPORTING VIEWS
// ─────────────────────────────────────────────
struct HKAngleChip: View {
    let label: String
    let value: Double
    let isOk:  Bool
    var unit:  String = "°"

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(isOk ? Color.green : Color.red).frame(width: 6, height: 6)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.6))
            Text("\(Int(value))\(unit)").font(.system(size: 12, weight: .bold)).foregroundColor(isOk ? .green : .red)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(isOk ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}

struct HKProgressBarView: View {
    let currentSet: Int; let totalSets: Int; let repsInSet: Int; let targetReps: Int
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Set \(currentSet) of \(totalSets)").font(.caption).foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(repsInSet)/\(targetReps) reps").font(.caption.bold()).foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.15)).frame(height: 10)
                    RoundedRectangle(cornerRadius: 6).fill(Color.green)
                        .frame(width: geo.size.width * CGFloat(min(repsInSet, targetReps)) / CGFloat(max(targetReps, 1)),
                               height: 10)
                        .animation(.spring(response: 0.3), value: repsInSet)
                }
            }.frame(height: 10)
        }.padding(.horizontal, 4)
    }
}

struct HighKneesRestTimerView: View {
    let secondsLeft: Int
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer").foregroundColor(.cyan)
            Text("Rest: \(secondsLeft)s").font(.title3.bold()).foregroundColor(.white)
            Text("Next set coming up...").font(.caption).foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.cyan, lineWidth: 1.5))
        .shadow(color: .cyan.opacity(0.4), radius: 8).padding(.horizontal)
    }
}

struct HighKneesFormAlertBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text(message).font(.subheadline.bold()).foregroundColor(.white)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.orange, lineWidth: 1.5))
        .shadow(color: .orange.opacity(0.4), radius: 8).padding(.horizontal)
    }
}

// ─────────────────────────────────────────────
// MARK: - SKELETON OVERLAY
// ─────────────────────────────────────────────
struct HighKneesSkeletonOverlay: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let result: HighKneesResult

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let shoulder: VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftShoulder : .rightShoulder
                let hip:      VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftHip      : .rightHip
                let knee:     VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftKnee     : .rightKnee

                drawLine(shoulder, hip,  geo, ok: result.torsoOk)
                drawLine(hip,      knee, geo, ok: result.kneeOk)

                ForEach([shoulder, hip, knee], id: \.self) { joint in
                    if let point = bodyPoints[joint] {
                        Circle().fill(dotColor(for: joint)).frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                            .position(x: point.x * geo.size.width, y: point.y * geo.size.height)
                    }
                }
            }
        }
    }

    private func dotColor(for joint: VNHumanBodyPoseObservation.JointName) -> Color {
        switch joint {
        case .leftShoulder, .rightShoulder: return result.torsoOk ? .green : .red
        case .leftHip,      .rightHip:      return result.kneeOk  ? .green : .red
        case .leftKnee,     .rightKnee:     return result.kneeOk  ? .green : .red
        default:                            return .white
        }
    }

    @ViewBuilder
    private func drawLine(_ j1: VNHumanBodyPoseObservation.JointName,
                          _ j2: VNHumanBodyPoseObservation.JointName,
                          _ geo: GeometryProxy, ok: Bool) -> some View {
        if let p1 = bodyPoints[j1], let p2 = bodyPoints[j2] {
            Path { path in
                path.move(to: CGPoint(x: p1.x * geo.size.width,  y: p1.y * geo.size.height))
                path.addLine(to: CGPoint(x: p2.x * geo.size.width, y: p2.y * geo.size.height))
            }
            .stroke(ok ? Color.green : Color.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - GOAL SETUP SHEET
// ─────────────────────────────────────────────
struct HighKneesGoalSheet: View {
    @ObservedObject var viewModel: HighKneesViewModel
    @Environment(\.dismiss) var dismiss

    @State private var sets    = 3
    @State private var reps    = 20
    @State private var restSec = 30
    @State private var launched = false

    private struct Preset {
        let name: String; let icon: String
        let sets: Int;    let reps: Int; let rest: Int
        let color: Color
    }
    private let presets: [Preset] = [
        Preset(name: "Beginner",  icon: "leaf.fill",       sets: 2, reps: 10, rest: 60, color: DT.lime),
        Preset(name: "Standard",  icon: "figure.run",      sets: 3, reps: 20, rest: 45, color: DT.sky),
        Preset(name: "Cardio",    icon: "heart.fill",      sets: 4, reps: 30, rest: 30, color: DT.amber),
        Preset(name: "Endurance", icon: "flame.fill",      sets: 5, reps: 40, rest: 20, color: DT.coral),
        Preset(name: "HIIT",      icon: "bolt.circle.fill",sets: 6, reps: 20, rest: 15, color: DT.violet),
    ]

    var body: some View {
        ZStack {
            DT.bg0.ignoresSafeArea()
            ZStack {
                Circle().fill(DT.violet.opacity(0.07)).frame(width: 300).blur(radius: 80).offset(x: 100,  y: -180)
                Circle().fill(DT.lime.opacity(0.05)).frame(width: 240).blur(radius: 70).offset(x: -120, y: 200)
            }.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    goalHeader
                    presetRow
                    sliderSection
                    summaryCard
                    actionButtons
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .opacity(launched ? 1 : 0)
                .offset(y: launched ? 0 : 24)
                .animation(.spring(response: 0.5, dampingFraction: 0.78), value: launched)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { launched = true } }
    }

    private var goalHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("WORKOUT")
                    .font(DT.textMono).foregroundColor(DT.violet).kerning(3)
                Text("Set Goal")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(DT.textPrimary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DT.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(DT.bg2).clipShape(Circle())
                    .overlay(Circle().stroke(DT.stroke, lineWidth: 1))
            }
        }.padding(.top, 24)
    }

    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PRESETS").font(DT.textMono).foregroundColor(DT.textSecondary).kerning(2)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(presets, id: \.name) { p in
                        let active = sets == p.sets && reps == p.reps && restSec == p.rest
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                sets = p.sets; reps = p.reps; restSec = p.rest
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: p.icon).font(.system(size: 18)).foregroundColor(p.color)
                                Text(p.name).font(.system(size: 11, weight: .bold)).foregroundColor(DT.textPrimary)
                                Text("\(p.sets)×\(p.reps)").font(.system(size: 10, design: .monospaced)).foregroundColor(DT.textSecondary)
                            }
                            .frame(width: 76).padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(active ? p.color.opacity(0.18) : DT.bg1)
                                    .overlay(RoundedRectangle(cornerRadius: 16)
                                        .stroke(active ? p.color.opacity(0.50) : DT.stroke, lineWidth: 1))
                            )
                        }
                    }
                }.padding(.bottom, 2)
            }
        }
    }

    private var sliderSection: some View {
        VStack(spacing: 18) {
            HKGoalSliderRow(label: "SETS",         value: $sets,    range: 1...10,  step: 1,  accent: DT.violet, display: "\(sets)")
            HKGoalSliderRow(label: "REPS PER SET", value: $reps,    range: 5...60,  step: 5,  accent: DT.lime,   display: "\(reps)")
            HKGoalSliderRow(label: "REST",         value: $restSec, range: 10...120, step: 10, accent: DT.sky,  display: "\(restSec)s")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DT.stroke, lineWidth: 1))
        )
    }

    private var summaryCard: some View {
        HStack(spacing: 0) {
            HKGoalSummaryCell(value: "\(sets)",        label: "SETS",     accent: DT.violet)
            Rectangle().fill(DT.stroke).frame(width: 1, height: 36)
            HKGoalSummaryCell(value: "\(reps)",        label: "REPS/SET", accent: DT.lime)
            Rectangle().fill(DT.stroke).frame(width: 1, height: 36)
            HKGoalSummaryCell(value: "\(sets * reps)", label: "TOTAL",    accent: DT.amber)
            Rectangle().fill(DT.stroke).frame(width: 1, height: 36)
            HKGoalSummaryCell(value: "\(restSec)s",    label: "REST",     accent: DT.sky)
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(DT.stroke, lineWidth: 1))
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.setGoal(sets: sets, reps: reps, restSeconds: restSec); dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill").font(.system(size: 14, weight: .bold))
                    Text("Start Workout").font(.system(size: 16, weight: .black, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 17)
                .background(ZStack {
                    LinearGradient(colors: [DT.lime, DT.sky], startPoint: .leading, endPoint: .trailing)
                    LinearGradient(colors: [Color.white.opacity(0.18), Color.clear], startPoint: .top, endPoint: .bottom)
                })
                .cornerRadius(16)
                .shadow(color: DT.lime.opacity(0.35), radius: 14, y: 6)
            }
            Button { viewModel.clearGoal(); dismiss() } label: {
                Text("Clear Goal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DT.coral)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(DT.coral.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(DT.coral.opacity(0.22), lineWidth: 1))
                    )
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - GOAL SUB-VIEWS
// ─────────────────────────────────────────────
private struct HKGoalSliderRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>; let step: Int; let accent: Color; let display: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label).font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1.5)
                Spacer()
                Text(display).font(.system(size: 17, weight: .black, design: .rounded)).foregroundColor(accent)
            }
            GeometryReader { geo in
                let pct   = CGFloat(value - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound)
                let fillW = geo.size.width * pct
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.07)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [accent.opacity(0.9), accent], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, fillW), height: 6)
                    Circle().fill(accent).frame(width: 22, height: 22)
                        .shadow(color: accent.opacity(0.5), radius: 6)
                        .offset(x: max(0, fillW - 11))
                }
                .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                    let raw     = drag.location.x / geo.size.width
                    let clamped = min(max(0, raw), 1)
                    let floatV  = Double(range.lowerBound) + clamped * Double(range.upperBound - range.lowerBound)
                    let stepped = Int(round(floatV / Double(step))) * step
                    value = min(max(range.lowerBound, stepped), range.upperBound)
                })
            }
            .frame(height: 22)
        }
    }
}

private struct HKGoalSummaryCell: View {
    let value: String; let label: String; let accent: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 20, weight: .black, design: .rounded)).foregroundColor(accent)
            Text(label).font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// ─────────────────────────────────────────────
// MARK: - SESSION STATS SHEET
// ─────────────────────────────────────────────
struct HighKneesStatsSheet: View {
    @ObservedObject var viewModel: HighKneesViewModel
    @Environment(\.dismiss) var dismiss

    private var qualityRate: Int {
        let t = viewModel.goodReps + viewModel.badReps
        guard t > 0 else { return 0 }
        return Int(Double(viewModel.goodReps) / Double(t) * 100)
    }

    var body: some View {
        ZStack {
            DT.bg0.ignoresSafeArea()
            ZStack {
                Circle().fill(DT.lime.opacity(0.06)).frame(width: 320).blur(radius: 80).offset(x: -100, y: -200)
                Circle().fill(DT.sky.opacity(0.05)).frame(width: 260).blur(radius: 70).offset(x: 140, y: 100)
                Circle().fill(DT.violet.opacity(0.04)).frame(width: 200).blur(radius: 60).offset(x: -60, y: 400)
            }.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    statsHeader
                    heroBlock
                    fourPillsRow
                    if viewModel.repHistory.count > 1 { graphCard }
                    timelineCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var statsHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SESSION").font(DT.textMono).foregroundColor(DT.lime).kerning(3)
                Text("Analytics")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(DT.textPrimary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DT.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(DT.bg2).clipShape(Circle())
                    .overlay(Circle().stroke(DT.stroke, lineWidth: 1))
            }
        }.padding(.top, 24)
    }

    private var heroBlock: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.06), lineWidth: 10).frame(width: 112, height: 112)
                Circle()
                    .trim(from: 0, to: CGFloat(qualityRate) / 100)
                    .stroke(AngularGradient(colors: [DT.lime, DT.sky, DT.lime], center: .center),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 112, height: 112).rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.9), value: qualityRate)
                Circle().trim(from: 0, to: CGFloat(qualityRate) / 100)
                    .stroke(DT.lime.opacity(0.22), lineWidth: 16)
                    .frame(width: 112, height: 112).rotationEffect(.degrees(-90))
                    .blur(radius: 6)
                    .animation(.easeOut(duration: 0.9), value: qualityRate)
                VStack(spacing: 1) {
                    Text("\(qualityRate)%")
                        .font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(DT.textPrimary)
                    Text("QUALITY").font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1)
                }
            }
            VStack(spacing: 10) {
                HKStatsHeroTile(value: "\(viewModel.totalRepsAllTime)", label: "TOTAL REPS", accent: DT.lime)
                HKStatsHeroTile(value: viewModel.sessionTimeString,     label: "DURATION",   accent: DT.sky)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DT.stroke, lineWidth: 1))
        )
    }

    private var fourPillsRow: some View {
        HStack(spacing: 8) {
            HKStatsMetricPill(value: "\(viewModel.goodReps)",     label: "GOOD", color: DT.lime,  icon: "checkmark.circle.fill")
            HKStatsMetricPill(value: "\(viewModel.badReps)",      label: "BAD",  color: DT.coral, icon: "xmark.circle.fill")
            HKStatsMetricPill(value: "\(viewModel.averageScore)", label: "AVG",  color: DT.amber, icon: "waveform.path.ecg")
            HKStatsMetricPill(value: "\(viewModel.bestRepScore)", label: "BEST", color: DT.sky,   icon: "bolt.fill")
        }
    }

    private var graphCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HKStatsSectionLabel(title: "REP SCORES", sub: "\(viewModel.repHistory.count) reps")
            HKStatsRepScoreGraph(records: viewModel.repHistory).frame(height: 140)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DT.stroke, lineWidth: 1))
        )
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HKStatsSectionLabel(title: "REP HISTORY", sub: "Most recent first")
            if viewModel.repHistory.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "figure.run").font(.system(size: 36)).foregroundColor(Color.white.opacity(0.10))
                    Text("No reps yet — start running!").font(.system(size: 13, weight: .medium)).foregroundColor(DT.textSecondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30)
            } else {
                VStack(spacing: 7) {
                    ForEach(viewModel.repHistory.reversed()) { rep in HKStatsRepRow(rep: rep) }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DT.stroke, lineWidth: 1))
        )
    }
}

// ─────────────────────────────────────────────
// MARK: - STATS SUB-VIEWS
// ─────────────────────────────────────────────
private struct HKStatsHeroTile: View {
    let value: String; let label: String; let accent: Color
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 3, height: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(size: 21, weight: .black, design: .rounded)).foregroundColor(DT.textPrimary)
                Text(label).font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1.2)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(DT.bg2).cornerRadius(13)
    }
}

private struct HKStatsMetricPill: View {
    let value: String; let label: String; let color: Color; let icon: String
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundColor(color)
            Text(value).font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(DT.textPrimary)
            Text(label).font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(color.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.18), lineWidth: 1))
        )
    }
}

private struct HKStatsSectionLabel: View {
    let title: String; let sub: String
    var body: some View {
        HStack(alignment: .bottom) {
            Text(title).font(DT.textMono).foregroundColor(DT.lime).kerning(2.5)
            Spacer()
            Text(sub).font(.system(size: 11, weight: .medium)).foregroundColor(DT.textSecondary)
        }
    }
}

private struct HKStatsRepRow: View {
    let rep: HKRepRecord
    private var col: Color { rep.isGood ? DT.lime : DT.coral }
    var body: some View {
        HStack(spacing: 10) {
            Text("#\(rep.repNumber)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(col).frame(width: 32)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05))
                    RoundedRectangle(cornerRadius: 4).fill(col.opacity(0.6))
                        .frame(width: g.size.width * CGFloat(rep.score) / 100)
                        .animation(.spring(response: 0.5), value: rep.score)
                }
            }.frame(height: 7)
            Text(rep.isGood ? "\(rep.score)" : "—")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(rep.isGood ? .white : DT.textSecondary).frame(width: 28, alignment: .trailing)
            Image(systemName: rep.isGood ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 13)).foregroundColor(col)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(Color.white.opacity(0.025)).cornerRadius(9)
    }
}

private struct HKStatsRepScoreGraph: View {
    let records: [HKRepRecord]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width; let h = geo.size.height
            let count = records.count
            guard count > 0 else { return AnyView(EmptyView()) }
            let slot = w / CGFloat(count)
            return AnyView(ZStack(alignment: .bottom) {
                ForEach([0, 25, 50, 75, 100], id: \.self) { val in
                    let y = h * (1 - CGFloat(val) / 100)
                    Path { p in p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: w, y: y)) }
                        .stroke(val == 0 ? Color.white.opacity(0.12) : Color.white.opacity(0.04),
                                style: StrokeStyle(lineWidth: 1, dash: val == 0 ? [] : [4, 4]))
                    if val > 0 {
                        Text("\(val)").font(.system(size: 7, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.18)).position(x: 12, y: max(8, y - 6))
                    }
                }
                if count > 1 {
                    Path { path in
                        for (i, rep) in records.enumerated() {
                            let x = slot * CGFloat(i) + slot / 2
                            let y = h * (1 - CGFloat(rep.score) / 100)
                            i == 0 ? path.move(to: .init(x: x, y: y)) : path.addLine(to: .init(x: x, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(records) { rep in
                        let barH = max(6, h * CGFloat(rep.score) / 100)
                        let col  = rep.isGood ? DT.lime : DT.coral
                        VStack(spacing: 0) {
                            Circle().fill(col).frame(width: 4, height: 4)
                            Rectangle()
                                .fill(LinearGradient(colors: [col.opacity(0.9), col.opacity(0.15)],
                                                     startPoint: .top, endPoint: .bottom))
                                .frame(height: max(1, barH - 4)).cornerRadius(3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            })
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - VIEW MODEL
// ─────────────────────────────────────────────
final class HighKneesViewModel: NSObject, ObservableObject,
                                 AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession()

    @Published var bodyPoints:    [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    private var pointsBuffer:     [[VNHumanBodyPoseObservation.JointName: CGPoint]] = []
    @Published var postureResult  = HighKneesResult()
    @Published var currentPhase: HighKneesPhase = .idle
    @Published var phaseText      = "Ready"
    @Published var phaseColor: Color = .white
    @Published var cameraPosition: AVCaptureDevice.Position = .front

    @Published var showFormAlert    = false
    @Published var formAlertMessage = ""
    @Published var showGoodRepFlash = false
    @Published var badRepMessage: String? = nil

    // Analytics
    @Published var repHistory:      [HKRepRecord] = []
    @Published var goodReps         = 0
    @Published var badReps          = 0
    @Published var totalRepsAllTime = 0
    @Published var averageScore     = 0
    @Published var bestRepScore     = 0

    // Sets / Goal
    @Published var targetSets       = 0
    @Published var targetReps       = 0
    @Published var currentSet       = 1
    @Published var repsInCurrentSet = 0

    // Rest timer
    @Published var isResting        = false
    @Published var restSecondsLeft  = 0
    private var restDuration        = 30
    private var restTimer: Timer?

    // Session timer
    @Published var sessionTimeString = "00:00"
    private var sessionStartDate: Date?
    private var sessionTimer: Timer?

    @Published var reps = 0

    // Rep tracking – knee-lift detection
    private var frameBuffer:         [HighKneesResult] = []
    private var lastKneeHeight:       Double = 0
    private var kneePeakReached       = false
    private var kneeRisingFrames      = 0
    private var kneeFallingFrames     = 0
    private var validLiftFrames       = 0
    private var notVisibleFrames      = 0
    private var stableIssueFrames     = 0
    private var lastIssue: HighKneesIssue = .detecting
    private var alertTimer: Timer?

    // Error tracking per lift cycle
    private var torsoErrorFrames      = 0
    private var hadTorsoError         = false
    private var hadKneeError          = false   // knee never reached hip height

    // Speech
    private let speechSynth           = AVSpeechSynthesizer()
    private var lastSpokenIssue: HighKneesIssue = .detecting
    private var lastSpeechTime: Date  = .distantPast

    // Notifications
    private var lastNotifTime: [String: Date] = [:]
    private let notifCooldown: TimeInterval   = 5.0

    private var isConfiguring         = false
    private let cameraQueue           = DispatchQueue(label: "hkCameraQueue")

    // Threshold: knee must rise this far above the hip–knee baseline to count
    private let kneeLiftThreshold: Double = 0.05   // normalised-coord units
    // Torso uprightness: angle from vertical must be below this value
    private let torsoAngleLimit: Double   = 35.0   // degrees from vertical

    // MARK: Start / Stop
    func start() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { return }
            DispatchQueue.global(qos: .userInitiated).async { self.setupCamera() }
        }
        startSessionTimer()
        fireWatchNotification(title: "🏃 Ready for High Knees!", body: "Drive those knees up!")
    }

    func stop() {
        sessionTimer?.invalidate(); restTimer?.invalidate()
        cameraQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func startSessionTimer() {
        sessionStartDate = Date()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.sessionStartDate else { return }
            let e = Int(Date().timeIntervalSince(start))
            DispatchQueue.main.async { self.sessionTimeString = String(format: "%02d:%02d", e / 60, e % 60) }
        }
    }

    func setGoal(sets: Int, reps: Int, restSeconds: Int) {
        DispatchQueue.main.async {
            self.targetSets = sets; self.targetReps = reps
            self.restDuration = restSeconds
            self.currentSet = 1; self.repsInCurrentSet = 0
        }
    }

    func clearGoal() {
        DispatchQueue.main.async {
            self.targetSets = 0; self.targetReps = 0
            self.currentSet = 1; self.repsInCurrentSet = 0
        }
    }

    func resetSession() {
        DispatchQueue.main.async {
            self.reps = 0; self.repsInCurrentSet = 0; self.currentSet = 1
            self.goodReps = 0; self.badReps = 0; self.totalRepsAllTime = 0
            self.averageScore = 0; self.bestRepScore = 0; self.repHistory = []
            self.currentPhase = .idle; self.phaseText = "Ready"; self.phaseColor = .white
            self.kneePeakReached = false; self.kneeRisingFrames = 0; self.kneeFallingFrames = 0
            self.validLiftFrames = 0; self.torsoErrorFrames = 0
            self.hadTorsoError = false; self.hadKneeError = false
            self.isResting = false; self.restTimer?.invalidate()
            self.sessionStartDate = Date()
        }
    }

    private func resetLiftState() {
        kneePeakReached = false; kneeRisingFrames = 0; kneeFallingFrames = 0
        validLiftFrames = 0; torsoErrorFrames = 0
        hadTorsoError = false; hadKneeError = false
        frameBuffer = []; pointsBuffer = []
        DispatchQueue.main.async { self.currentPhase = .idle; self.phaseText = "Ready"; self.phaseColor = .white }
    }

    // MARK: Camera
    private func setupCamera() {
        cameraQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.isConfiguring = true
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            self.session.inputs.forEach  { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition),
                let input  = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(input)
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "hkVideoQueue"))
            output.alwaysDiscardsLateVideoFrames = true
            if self.session.canAddOutput(output) { self.session.addOutput(output) }
            self.session.commitConfiguration()
            self.isConfiguring = false
            self.session.startRunning()
        }
    }

    func switchCamera() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.isConfiguring = true
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            guard
                let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                let inp = try? AVCaptureDeviceInput(device: dev),
                self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(inp)
            self.session.commitConfiguration()
            self.isConfiguring = false
            DispatchQueue.main.async { self.cameraPosition = newPos }
        }
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let orientation: CGImagePropertyOrientation = cameraPosition == .front ? .leftMirrored : .right
        analyzeFrame(pixelBuffer: pixelBuffer, orientation: orientation)
    }

    // MARK: Analyze frame
    private func analyzeFrame(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) {
        guard !isResting else { return }
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return }
            let points = try observation.recognizedPoints(.all)

            updateBodyPoints(points)
            let rawResult = analyzeHighKneesPosture(points)

            if rawResult.issue == .notVisible {
                notVisibleFrames += 1
                if notVisibleFrames >= 8 { DispatchQueue.main.async { self.postureResult = rawResult } }
                return
            } else { notVisibleFrames = 0 }

            var smoothed = smoothResult(rawResult)
            updatePhaseAndReps(smoothedResult: smoothed)

            if smoothed.issue == lastIssue { stableIssueFrames += 1 }
            else { stableIssueFrames = 0; lastIssue = smoothed.issue }
            if stableIssueFrames < 3 { smoothed.issue = postureResult.issue }

            updateFormAlert(result: smoothed)
            DispatchQueue.main.async { self.postureResult = smoothed }
        } catch { print(error) }
    }

    private func updateFormAlert(result: HighKneesResult) {
        guard currentPhase == .lifting || currentPhase == .peak else {
            DispatchQueue.main.async { self.showFormAlert = false }
            return
        }
        var message: String? = nil
        if !result.torsoOk { message = "Keep Torso Upright!" }
        else if !result.kneeOk { message = "Lift Knees Higher!" }

        if let msg = message { fireWatchNotification(title: "⚠️ Fix Your Form", body: msg) }

        DispatchQueue.main.async {
            if let msg = message {
                self.formAlertMessage = msg; self.showFormAlert = true
                self.alertTimer?.invalidate()
                self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                    DispatchQueue.main.async { self.showFormAlert = false }
                }
            } else { self.showFormAlert = false }
        }
    }

    // MARK: Phase & rep logic
    private func updatePhaseAndReps(smoothedResult: HighKneesResult) {
        let kneeH  = smoothedResult.kneeHeight
        let prev   = lastKneeHeight
        var addRep = false
        var nextPhase = currentPhase

        // Track errors during active lift
        if currentPhase == .lifting || currentPhase == .peak {
            if !smoothedResult.torsoOk { torsoErrorFrames += 1 } else { torsoErrorFrames = 0 }
            if torsoErrorFrames >= 3 { hadTorsoError = true }
            if !smoothedResult.kneeOk { hadKneeError = true }
        }

        // Rising detection
        if kneeH > prev + 0.01 {
            kneeRisingFrames += 1; kneeFallingFrames = 0
            if kneeRisingFrames >= 2 { nextPhase = .lifting }
        } else if kneeH < prev - 0.01 {
            kneeFallingFrames += 1; kneeRisingFrames = 0
        }

        // Peak detection: knee at or above hip-height threshold
        if kneeH >= kneeLiftThreshold {
            validLiftFrames += 1
            if validLiftFrames >= 3 { kneePeakReached = true; nextPhase = .peak }
        } else { validLiftFrames = 0 }

        // Rep completion: was rising, peaked, now falling back to near-zero
        if kneePeakReached && kneeFallingFrames >= 3 && kneeH < (kneeLiftThreshold * 0.5) {
            let formWasGood = !hadTorsoError && kneePeakReached
            if formWasGood {
                addRep = true
                triggerGoodRepFeedback(score: smoothedResult.postureScore)
            } else {
                triggerBadRepFeedback()
            }
            // Reset for next lift
            kneePeakReached = false; kneeRisingFrames = 0; kneeFallingFrames = 0
            validLiftFrames = 0; torsoErrorFrames = 0
            hadTorsoError = false; hadKneeError = false
            nextPhase = .lowering
        }

        // Return to idle after lowering
        if currentPhase == .lowering && kneeH < 0.02 { nextPhase = .idle }

        lastKneeHeight = kneeH
        let scoreSnapshot = smoothedResult.postureScore

        DispatchQueue.main.async {
            if addRep {
                self.reps += 1
                self.repsInCurrentSet += 1
                self.totalRepsAllTime += 1
                self.speakRepCount(self.repsInCurrentSet)
                WatchConnectivityManager.shared.sendRepUpdate(
                    exercise: "High Knees", repsInSet: self.repsInCurrentSet,
                    targetReps: self.targetReps, currentSet: self.currentSet,
                    totalSets: self.targetSets, formScore: scoreSnapshot,
                    feedback: scoreSnapshot >= 85 ? "Good form!" : "Keep it clean")

                if self.targetReps > 0 && self.repsInCurrentSet >= self.targetReps {
                    if self.currentSet < self.targetSets {
                        self.speakText("Set \(self.currentSet) complete! Rest now.")
                        self.startRestTimer()
                        self.currentSet += 1
                        self.repsInCurrentSet = 0
                    } else {
                        self.speakText("Workout complete! Great job!")
                        self.fireWatchNotification(
                            title: "🎉 Workout Complete!",
                            body:  "You finished all \(self.targetSets) sets. Great job!"
                        )
                    }
                }

                let record = HKRepRecord(repNumber: self.totalRepsAllTime,
                                         score: scoreSnapshot, isGood: true, timestamp: Date())
                self.repHistory.append(record)
                self.updateScoreStats()
            }

            self.currentPhase = nextPhase
            switch nextPhase {
            case .idle:     self.phaseText = "Ready";       self.phaseColor = .white
            case .lifting:  self.phaseText = "Lifting";     self.phaseColor = .yellow
            case .peak:     self.phaseText = "Hip High ✅"; self.phaseColor = .green
            case .lowering: self.phaseText = "Lowering";    self.phaseColor = .blue
            }
        }
    }

    private func updateScoreStats() {
        goodReps = repHistory.filter { $0.isGood }.count
        badReps  = repHistory.filter { !$0.isGood }.count
        if !repHistory.isEmpty {
            averageScore = repHistory.map { $0.score }.reduce(0, +) / repHistory.count
            bestRepScore = repHistory.map { $0.score }.max() ?? 0
        }
    }

    private func startRestTimer() {
        restSecondsLeft = restDuration; isResting = true
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            DispatchQueue.main.async {
                self.restSecondsLeft -= 1
                if self.restSecondsLeft <= 0 {
                    t.invalidate(); self.isResting = false
                    self.resetLiftState(); self.speakText("Go!")
                }
            }
        }
    }

    private func triggerGoodRepFeedback(score: Int) {
        DispatchQueue.main.async {
            self.showGoodRepFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.showGoodRepFlash = false }
        }
    }

    private func triggerBadRepFeedback() {
        var reasons: [String] = []
        if hadTorsoError { reasons.append("Keep torso upright") }
        if hadKneeError  { reasons.append("Lift knee to hip height") }
        if reasons.isEmpty { reasons.append("Incomplete lift") }
        let message = "⚠️ Rep Not Counted\n" + reasons.joined(separator: " • ")

        if hadTorsoError    { speakText("Keep your torso upright") }
        else if hadKneeError { speakText("Lift your knee higher") }
        else                 { speakText("Incomplete lift") }

        fireWatchNotification(title: "❌ Rep Not Counted", body: reasons.joined(separator: " • "))

        DispatchQueue.main.async {
            self.badRepMessage = message
            let record = HKRepRecord(repNumber: self.totalRepsAllTime + 1,
                                     score: 0, isGood: false, timestamp: Date())
            self.repHistory.append(record)
            self.totalRepsAllTime += 1
            self.updateScoreStats()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.badRepMessage = nil }
        }
    }

    func fireWatchNotification(title: String, body: String) {
        let key = "\(title)"
        let now = Date()
        if let last = lastNotifTime[key], now.timeIntervalSince(last) < notifCooldown { return }
        lastNotifTime[key] = now
        NotificationManager.shared.send(title: title, body: body)
        WatchConnectivityManager.shared.sendFormAlert(exercise: "HighKnees", issue: "\(title): \(body)")
    }

    // MARK: Posture analysis
    private func analyzeHighKneesPosture(
        _ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> HighKneesResult {
        var result = HighKneesResult()

        // Pick better-confidence side
        let lC: Float = (points[.leftHip]?.confidence  ?? 0) + (points[.leftKnee]?.confidence  ?? 0)
        let rC: Float = (points[.rightHip]?.confidence ?? 0) + (points[.rightKnee]?.confidence ?? 0)
        let useLeft = lC >= rC
        result.trackedLeftSide = useLeft

        let hipKey:      VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let kneeKey:     VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee     : .rightKnee
        let shoulderKey: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder

        guard
            let hip   = points[hipKey],   hip.confidence   > 0.4,
            let knee  = points[kneeKey],  knee.confidence  > 0.4
        else { result.issue = .notVisible; return result }

        // kneeHeight: positive when knee is above the hip in camera space
        // Vision coords: y=0 at bottom, y=1 at top, so hip.y – knee.y > 0 means knee is higher
        let kH = hip.location.y - knee.location.y
        result.kneeHeight = kH
        result.kneeOk     = kH >= kneeLiftThreshold

        // Torso uprightness
        if let sh = points[shoulderKey], sh.confidence > 0.3 {
            let rawAtan    = atan2(sh.location.y - hip.location.y, sh.location.x - hip.location.x) * 180 / .pi
            let fromVert   = abs(90.0 - abs(rawAtan))
            result.torsoAngle = fromVert
            result.torsoOk    = fromVert <= torsoAngleLimit
        } else {
            result.torsoOk = true
        }

        var score = 100
        if !result.kneeOk  { score -= 35 }
        if !result.torsoOk { score -= 30 }
        result.postureScore = max(score, 0)
        result.issue = !result.torsoOk ? .leaningBack : !result.kneeOk ? .notHigh : .correct
        return result
    }

    // MARK: Helpers
    private func updateBodyPoints(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var mapped: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (joint, point) in points where point.confidence > 0.3 {
            mapped[joint] = CGPoint(x: point.location.x, y: 1 - point.location.y)
        }
        pointsBuffer.append(mapped)
        if pointsBuffer.count > 6 { pointsBuffer.removeFirst() }
        var smoothed: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        let uniqueJoints = Set(pointsBuffer.flatMap { $0.keys })
        for joint in uniqueJoints {
            let positions = pointsBuffer.compactMap { $0[joint] }
            guard !positions.isEmpty else { continue }
            let n = CGFloat(positions.count)
            smoothed[joint] = CGPoint(x: positions.map(\.x).reduce(0, +) / n,
                                      y: positions.map(\.y).reduce(0, +) / n)
        }
        DispatchQueue.main.async { self.bodyPoints = smoothed }
    }

    private func smoothResult(_ result: HighKneesResult) -> HighKneesResult {
        frameBuffer.append(result)
        if frameBuffer.count > 8 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        var smoothed = result
        smoothed.kneeHeight   = frameBuffer.map(\.kneeHeight).reduce(0, +)   / n
        smoothed.torsoAngle   = frameBuffer.map(\.torsoAngle).reduce(0, +)   / n
        smoothed.postureScore = Int(Double(frameBuffer.map(\.postureScore).reduce(0, +)) / n)
        smoothed.trackedLeftSide = result.trackedLeftSide
        return smoothed
    }

    private func speakRepCount(_ count: Int) {
        let u = AVSpeechUtterance(string: "\(count)"); u.rate = 0.55; u.volume = 1.0
        DispatchQueue.main.async { self.speechSynth.speak(u) }
    }

    private func speakText(_ text: String) {
        let u = AVSpeechUtterance(string: text); u.rate = 0.5; u.volume = 1.0
        DispatchQueue.main.async { self.speechSynth.speak(u) }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SQUAT — Full implementation from ContentView.swift
// Better angle analysis, per-joint skeleton coloring, bad-rep detection.
// ─────────────────────────────────────────────────────────────────────────────

// MARK: - Squat posture issue
//

//

import SwiftUI
import AVFoundation
import Vision
import Combine
import AVKit

// ─────────────────────────────────────────────
// MARK: - DESIGN TOKENS
// ─────────────────────────────────────────────
private enum DT {
    static let bg0    = Color(red: 0.04, green: 0.04, blue: 0.07)
    static let bg1    = Color(red: 0.08, green: 0.09, blue: 0.13)
    static let bg2    = Color(red: 0.12, green: 0.13, blue: 0.18)
    static let lime   = Color(red: 0.27, green: 0.98, blue: 0.56)
    static let sky    = Color(red: 0.35, green: 0.72, blue: 1.00)
    static let amber  = Color(red: 1.00, green: 0.74, blue: 0.18)
    static let coral  = Color(red: 1.00, green: 0.33, blue: 0.38)
    static let violet = Color(red: 0.72, green: 0.50, blue: 1.00)
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.45)
    static let textMono      = Font.system(size: 9, weight: .bold, design: .monospaced)
    static let stroke        = Color.white.opacity(0.07)
}

// ─────────────────────────────────────────────
// MARK: - SQUAT ISSUE
// ─────────────────────────────────────────────
enum SquatIssue: String {
    case correct         = "✅ Perfect Squat"
    case ready           = "🧍 Ready to Squat"
    case kneesNotDeep    = "❌ Go Lower"
    case backNotStraight = "❌ Keep Back Straight"
    case hipTooHigh      = "❌ Lower Your Hips"
    case kneesOverToes   = "❌ Knees Too Forward"
    case detecting       = "🔍 Detecting..."
    case notVisible      = "📷 Full Body Not Visible"
    case improperDepth   = "⚠️ Go Deeper Next Time"
}

// ─────────────────────────────────────────────
// MARK: - SQUAT PHASE
// ─────────────────────────────────────────────
enum SquatPhase { case standing, descending, bottom, ascending }

// ─────────────────────────────────────────────
// MARK: - REP RECORD
// ─────────────────────────────────────────────
struct RepRecord: Identifiable {
    let id        = UUID()
    let repNumber: Int
    let score:     Int
    let isGood:    Bool
    let timestamp: Date
}

// ─────────────────────────────────────────────
// MARK: - SQUAT RESULT
// ─────────────────────────────────────────────
struct SquatResult {
    var issue: SquatIssue = .detecting
    var postureScore: Int = 100
    var kneeAngle:      Double = 180
    var hipAngle:       Double = 180
    var spineAngle:     Double = 0
    var kneeToeOffset:  Double = 0
    var trackedLeftSide: Bool  = true
    var kneeOk:  Bool = true
    var hipOk:   Bool = true
    var spineOk: Bool = true
    var ankleOk: Bool = true
    var formIsValid: Bool { kneeOk && hipOk && spineOk && ankleOk }
}

// ─────────────────────────────────────────────
// MARK: - CAMERA VIEW
// ─────────────────────────────────────────────
struct SquatCameraView: View {
    @StateObject private var viewModel = SquatViewModel()
    @State private var showGoalSheet   = false
    @State private var showStatsSheet  = false

    var body: some View {
        ZStack {
            CameraPreview(session: viewModel.session).ignoresSafeArea()

            SquatSkeletonOverlay(
                bodyPoints: viewModel.bodyPoints,
                result:     viewModel.postureResult
            ).ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                if viewModel.showFormAlert {
                    SquatFormAlertBanner(message: viewModel.formAlertMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: viewModel.showFormAlert)
                }
                Spacer()

                if viewModel.isResting {
                    SquatRestTimerView(secondsLeft: viewModel.restSecondsLeft)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(), value: viewModel.isResting)
                }

                bottomPanel
            }

            if viewModel.showGoodRepFlash {
                Color.green.opacity(0.2).ignoresSafeArea().allowsHitTesting(false)
            }

            if viewModel.badRepMessage != nil {
                Color.red.opacity(0.25).ignoresSafeArea().allowsHitTesting(false)
                VStack {
                    Spacer()
                    Text(viewModel.badRepMessage ?? "")
                        .font(.title3.bold()).foregroundColor(.white)
                        .multilineTextAlignment(.center).padding()
                        .background(Color.red.opacity(0.85)).cornerRadius(16)
                        .padding(.bottom, 220)
                }
            }
        }
        .onAppear    { viewModel.start() }
        .onDisappear { viewModel.stopAndSave() }
        .sheet(isPresented: $showGoalSheet)  { SquatGoalSetupSheet(viewModel: viewModel) }
        .sheet(isPresented: $showStatsSheet) { SquatStatsSheet(viewModel: viewModel) }
    }

    // MARK: Top bar
    private var topBar: some View {
        HStack(spacing: 8) {
            Text(viewModel.sessionTimeString)
                .font(.caption.monospacedDigit().bold())
                .foregroundColor(.white)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.black.opacity(0.5)).cornerRadius(20)

            Spacer()

            ZStack {
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 3).frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.postureResult.postureScore) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 40, height: 40).rotationEffect(.degrees(-90))
                Text("\(viewModel.postureResult.postureScore)")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
            }

            HStack(spacing: 4) {
                Button { showStatsSheet = true } label: {
                    Image(systemName: "chart.bar.fill").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                Button { showGoalSheet = true } label: {
                    Image(systemName: "target").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
                Button { viewModel.switchCamera() } label: {
                    Image(systemName: "camera.rotate").font(.subheadline).foregroundColor(.white)
                        .padding(8).background(Color.white.opacity(0.15)).clipShape(Circle())
                }
            }
            .padding(.horizontal, 6).padding(.vertical, 4)
            .background(.black.opacity(0.5)).cornerRadius(24)
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    // MARK: Bottom panel
    private var bottomPanel: some View {
        VStack(spacing: 10) {
            HStack {
                Text(viewModel.postureResult.issue.rawValue)
                    .font(.subheadline.bold()).foregroundColor(.white)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Spacer()
                Text(viewModel.phaseText)
                    .font(.caption.bold())
                    .foregroundColor(viewModel.phaseColor)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(viewModel.phaseColor.opacity(0.15))
                    .cornerRadius(12)
            }

            HStack(spacing: 6) {
                SquatAngleChip(label: "Knee",  angle: viewModel.postureResult.kneeAngle,  isOk: viewModel.postureResult.kneeOk)
                SquatAngleChip(label: "Hip",   angle: viewModel.postureResult.hipAngle,   isOk: viewModel.postureResult.hipOk)
                SquatAngleChip(label: "Back",  angle: viewModel.postureResult.spineAngle, isOk: viewModel.postureResult.spineOk)
                SquatAngleChip(label: "Ankle", angle: abs(viewModel.postureResult.kneeToeOffset * 100),
                               isOk: viewModel.postureResult.ankleOk, unit: "")
            }

            if viewModel.targetReps > 0 {
                SquatProgressBarView(
                    currentSet:  viewModel.currentSet,
                    totalSets:   viewModel.targetSets,
                    repsInSet:   viewModel.repsInCurrentSet,
                    targetReps:  viewModel.targetReps
                )
            }

            HStack(alignment: .center, spacing: 0) {
                VStack(spacing: 0) {
                    Text("\(viewModel.repsInCurrentSet)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(viewModel.targetReps > 0
                         ? "SET \(viewModel.currentSet) OF \(viewModel.targetSets)"
                         : "REPS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .kerning(1.2)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 44)

                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Label("\(viewModel.goodReps)", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("\(viewModel.badReps)", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .font(.subheadline.bold())
                    Text("QUALITY").font(.system(size: 10)).foregroundColor(.white.opacity(0.5)).kerning(1.2)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 44)

                Button { viewModel.resetSession() } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3).foregroundColor(.white.opacity(0.7))
                        Text("RESET").font(.system(size: 10)).foregroundColor(.white.opacity(0.4)).kerning(1.2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(.ultraThinMaterial.opacity(0.95))
        .background(Color.black.opacity(0.6))
        .cornerRadius(24)
        .padding(.horizontal, 12).padding(.bottom, 8)
    }

    private var scoreColor: Color {
        let s = viewModel.postureResult.postureScore
        if s >= 80 { return .green }
        if s >= 55 { return .yellow }
        return .red
    }
}

// ─────────────────────────────────────────────
// MARK: - CAMERA SUPPORTING VIEWS
// ─────────────────────────────────────────────
struct SquatAngleChip: View {
    let label: String
    let angle: Double
    let isOk:  Bool
    var unit:  String = "°"

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(isOk ? Color.green : Color.red).frame(width: 6, height: 6)
            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(.white.opacity(0.6))
            Text("\(Int(angle))\(unit)").font(.system(size: 12, weight: .bold)).foregroundColor(isOk ? .green : .red)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(isOk ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SquatProgressBarView: View {
    let currentSet: Int; let totalSets: Int; let repsInSet: Int; let targetReps: Int
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Set \(currentSet) of \(totalSets)").font(.caption).foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(repsInSet)/\(targetReps) reps").font(.caption.bold()).foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.15)).frame(height: 10)
                    RoundedRectangle(cornerRadius: 6).fill(Color.green)
                        .frame(width: geo.size.width * CGFloat(min(repsInSet, targetReps)) / CGFloat(max(targetReps, 1)),
                               height: 10)
                        .animation(.spring(response: 0.3), value: repsInSet)
                }
            }.frame(height: 10)
        }.padding(.horizontal, 4)
    }
}

struct SquatRestTimerView: View {
    let secondsLeft: Int
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer").foregroundColor(.cyan)
            Text("Rest: \(secondsLeft)s").font(.title3.bold()).foregroundColor(.white)
            Text("Next set coming up...").font(.caption).foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.cyan, lineWidth: 1.5))
        .shadow(color: .cyan.opacity(0.4), radius: 8).padding(.horizontal)
    }
}

struct SquatFormAlertBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text(message).font(.subheadline.bold()).foregroundColor(.white)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85)).cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.orange, lineWidth: 1.5))
        .shadow(color: .orange.opacity(0.4), radius: 8).padding(.horizontal)
    }
}

// ─────────────────────────────────────────────
// MARK: - GOAL SETUP SHEET
// ─────────────────────────────────────────────
struct SquatGoalSetupSheet: View {
    @ObservedObject var viewModel: SquatViewModel
    @Environment(\.dismiss) var dismiss

    @State private var sets     = 3
    @State private var reps     = 10
    @State private var restSec  = 60
    @State private var launched = false

    private struct Preset {
        let name: String; let icon: String
        let sets: Int;    let reps: Int; let rest: Int
        let color: Color
    }
    private let presets: [Preset] = [
        Preset(name: "Beginner",  icon: "leaf.fill",   sets: 2, reps: 8,  rest: 90, color: DT.lime),
        Preset(name: "Standard",  icon: "figure.walk", sets: 3, reps: 10, rest: 60, color: DT.sky),
        Preset(name: "Strength",  icon: "bolt.fill",   sets: 4, reps: 6,  rest: 90, color: DT.amber),
        Preset(name: "Endurance", icon: "flame.fill",  sets: 4, reps: 15, rest: 45, color: DT.coral),
        Preset(name: "HIIT",      icon: "timer",       sets: 5, reps: 12, rest: 30, color: DT.violet),
    ]

    var body: some View {
        ZStack {
            DT.bg0.ignoresSafeArea()

            // Mesh blobs
            ZStack {
                Circle().fill(DT.violet.opacity(0.07)).frame(width: 300).blur(radius: 80).offset(x: 100, y: -180)
                Circle().fill(DT.lime.opacity(0.05)).frame(width: 240).blur(radius: 70).offset(x: -120, y: 200)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    goalHeader
                    presetRow
                    sliderSection
                    summaryCard
                    actionButtons
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .opacity(launched ? 1 : 0)
                .offset(y: launched ? 0 : 24)
                .animation(.spring(response: 0.5, dampingFraction: 0.78), value: launched)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { launched = true } }
    }

    // ── Header ──────────────────────────────
    private var goalHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("WORKOUT")
                    .font(DT.textMono).foregroundColor(DT.violet).kerning(3)
                Text("Set Goal")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(DT.textPrimary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DT.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(DT.bg2).clipShape(Circle())
                    .overlay(Circle().stroke(DT.stroke, lineWidth: 1))
            }
        }
        .padding(.top, 24)
    }

    // ── Preset pills ────────────────────────
    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PRESETS")
                .font(DT.textMono).foregroundColor(DT.textSecondary).kerning(2)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(presets, id: \.name) { p in
                        let active = sets == p.sets && reps == p.reps && restSec == p.rest
                        Button {
                            withAnimation(.spring(response: 0.35)) {
                                sets = p.sets; reps = p.reps; restSec = p.rest
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: p.icon)
                                    .font(.system(size: 18)).foregroundColor(p.color)
                                Text(p.name)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(DT.textPrimary)
                                Text("\(p.sets)×\(p.reps)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(DT.textSecondary)
                            }
                            .frame(width: 76).padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(active ? p.color.opacity(0.18) : DT.bg1)
                                    .overlay(RoundedRectangle(cornerRadius: 16)
                                        .stroke(active ? p.color.opacity(0.50) : DT.stroke, lineWidth: 1))
                            )
                        }
                    }
                }
                .padding(.bottom, 2)
            }
        }
    }

    // ── Sliders ─────────────────────────────
    private var sliderSection: some View {
        VStack(spacing: 18) {
            GoalSliderRow(label: "SETS",        value: $sets,    range: 1...10, step: 1,  accent: DT.violet, display: "\(sets)")
            GoalSliderRow(label: "REPS PER SET", value: $reps,   range: 1...30, step: 1,  accent: DT.lime,   display: "\(reps)")
            GoalSliderRow(label: "REST",         value: $restSec, range: 10...180, step: 10, accent: DT.sky, display: "\(restSec)s")
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DT.stroke, lineWidth: 1))
        )
    }

    // ── Summary ─────────────────────────────
    private var summaryCard: some View {
        HStack(spacing: 0) {
            GoalSummaryCell(value: "\(sets)",        label: "SETS",     accent: DT.violet)
            Rectangle().fill(DT.stroke).frame(width: 1, height: 36)
            GoalSummaryCell(value: "\(reps)",        label: "REPS/SET", accent: DT.lime)
            Rectangle().fill(DT.stroke).frame(width: 1, height: 36)
            GoalSummaryCell(value: "\(sets * reps)", label: "TOTAL",    accent: DT.amber)
            Rectangle().fill(DT.stroke).frame(width: 1, height: 36)
            GoalSummaryCell(value: "\(restSec)s",    label: "REST",     accent: DT.sky)
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(DT.stroke, lineWidth: 1))
        )
    }

    // ── Actions ─────────────────────────────
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.setGoal(sets: sets, reps: reps, restSeconds: restSec)
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill").font(.system(size: 14, weight: .bold))
                    Text("Start Workout")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity).padding(.vertical, 17)
                .background(
                    ZStack {
                        LinearGradient(colors: [DT.lime, DT.sky],
                                       startPoint: .leading, endPoint: .trailing)
                        LinearGradient(colors: [Color.white.opacity(0.18), Color.clear],
                                       startPoint: .top, endPoint: .bottom)
                    }
                )
                .cornerRadius(16)
                .shadow(color: DT.lime.opacity(0.35), radius: 14, y: 6)
            }

            Button {
                viewModel.clearGoal(); dismiss()
            } label: {
                Text("Clear Goal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DT.coral)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(DT.coral.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(DT.coral.opacity(0.22), lineWidth: 1))
                    )
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - GOAL SUB-VIEWS
// ─────────────────────────────────────────────
private struct GoalSliderRow: View {
    let label:   String
    @Binding var value: Int
    let range:   ClosedRange<Int>
    let step:    Int
    let accent:  Color
    let display: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1.5)
                Spacer()
                Text(display)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(accent)
            }
            GeometryReader { geo in
                let pct   = CGFloat(value - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound)
                let fillW = geo.size.width * pct
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.07)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [accent.opacity(0.9), accent],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, fillW), height: 6)
                    Circle().fill(accent).frame(width: 22, height: 22)
                        .shadow(color: accent.opacity(0.5), radius: 6)
                        .offset(x: max(0, fillW - 11))
                }
                .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                    let raw     = drag.location.x / geo.size.width
                    let clamped = min(max(0, raw), 1)
                    let floatV  = Double(range.lowerBound) + clamped * Double(range.upperBound - range.lowerBound)
                    let stepped = Int(round(floatV / Double(step))) * step
                    value = min(max(range.lowerBound, stepped), range.upperBound)
                })
            }
            .frame(height: 22)
        }
    }
}

private struct GoalSummaryCell: View {
    let value: String; let label: String; let accent: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(accent)
            Text(label)
                .font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// ─────────────────────────────────────────────
// MARK: - SESSION STATS SHEET
// ─────────────────────────────────────────────
struct SquatStatsSheet: View {
    @ObservedObject var viewModel: SquatViewModel
    @Environment(\.dismiss) var dismiss

    private var qualityRate: Int {
        let t = viewModel.goodReps + viewModel.badReps
        guard t > 0 else { return 0 }
        return Int(Double(viewModel.goodReps) / Double(t) * 100)
    }

    var body: some View {
        ZStack {
            DT.bg0.ignoresSafeArea()

            // Mesh blobs
            ZStack {
                Circle().fill(DT.lime.opacity(0.06)).frame(width: 320).blur(radius: 80).offset(x: -100, y: -200)
                Circle().fill(DT.sky.opacity(0.05)).frame(width: 260).blur(radius: 70).offset(x: 140, y: 100)
                Circle().fill(DT.violet.opacity(0.04)).frame(width: 200).blur(radius: 60).offset(x: -60, y: 400)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    statsHeader
                    heroBlock
                    fourPillsRow
                    if viewModel.repHistory.count > 1 { graphCard }
                    timelineCard
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
            }
        }
        .preferredColorScheme(.dark)
    }

    // ── Header ──────────────────────────────
    private var statsHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SESSION")
                    .font(DT.textMono).foregroundColor(DT.lime).kerning(3)
                Text("Analytics")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(DT.textPrimary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DT.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(DT.bg2).clipShape(Circle())
                    .overlay(Circle().stroke(DT.stroke, lineWidth: 1))
            }
        }
        .padding(.top, 24)
    }

    // ── Hero block ──────────────────────────
    private var heroBlock: some View {
        HStack(spacing: 16) {
            // Quality ring
            ZStack {
                Circle().stroke(Color.white.opacity(0.06), lineWidth: 10).frame(width: 112, height: 112)
                Circle()
                    .trim(from: 0, to: CGFloat(qualityRate) / 100)
                    .stroke(AngularGradient(colors: [DT.lime, DT.sky, DT.lime], center: .center),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 112, height: 112).rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.9), value: qualityRate)
                // Glow
                Circle()
                    .trim(from: 0, to: CGFloat(qualityRate) / 100)
                    .stroke(DT.lime.opacity(0.22), lineWidth: 16)
                    .frame(width: 112, height: 112).rotationEffect(.degrees(-90))
                    .blur(radius: 6)
                    .animation(.easeOut(duration: 0.9), value: qualityRate)
                VStack(spacing: 1) {
                    Text("\(qualityRate)%")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(DT.textPrimary)
                    Text("QUALITY")
                        .font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1)
                }
            }
            // Tiles
            VStack(spacing: 10) {
                StatsHeroTile(value: "\(viewModel.totalRepsAllTime)", label: "TOTAL REPS", accent: DT.lime)
                StatsHeroTile(value: viewModel.sessionTimeString,     label: "DURATION",   accent: DT.sky)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DT.stroke, lineWidth: 1))
        )
    }

    // ── Four metric pills ───────────────────
    private var fourPillsRow: some View {
        HStack(spacing: 8) {
            StatsMetricPill(value: "\(viewModel.goodReps)",    label: "GOOD", color: DT.lime,  icon: "checkmark.circle.fill")
            StatsMetricPill(value: "\(viewModel.badReps)",     label: "BAD",  color: DT.coral, icon: "xmark.circle.fill")
            StatsMetricPill(value: "\(viewModel.averageScore)",label: "AVG",  color: DT.amber, icon: "waveform.path.ecg")
            StatsMetricPill(value: "\(viewModel.bestRepScore)",label: "BEST", color: DT.sky,   icon: "bolt.fill")
        }
    }

    // ── Score graph ─────────────────────────
    private var graphCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatsSectionLabel(title: "REP SCORES", sub: "\(viewModel.repHistory.count) reps")
            StatsRepScoreGraph(records: viewModel.repHistory).frame(height: 140)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DT.stroke, lineWidth: 1))
        )
    }

    // ── Rep timeline ────────────────────────
    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatsSectionLabel(title: "REP HISTORY", sub: "Most recent first")
            if viewModel.repHistory.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "figure.strengthtraining.functional")
                        .font(.system(size: 36)).foregroundColor(Color.white.opacity(0.10))
                    Text("No reps yet — start squatting!")
                        .font(.system(size: 13, weight: .medium)).foregroundColor(DT.textSecondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30)
            } else {
                VStack(spacing: 7) {
                    ForEach(viewModel.repHistory.reversed()) { rep in
                        StatsRepRow(rep: rep)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20).fill(DT.bg1)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(DT.stroke, lineWidth: 1))
        )
    }
}

// ─────────────────────────────────────────────
// MARK: - STATS SUB-VIEWS
// ─────────────────────────────────────────────
private struct StatsHeroTile: View {
    let value: String; let label: String; let accent: Color
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 3, height: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundColor(DT.textPrimary)
                Text(label)
                    .font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1.2)
            }
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(DT.bg2).cornerRadius(13)
    }
}

private struct StatsMetricPill: View {
    let value: String; let label: String; let color: Color; let icon: String
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(DT.textPrimary)
            Text(label).font(DT.textMono).foregroundColor(DT.textSecondary).kerning(1)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.18), lineWidth: 1))
        )
    }
}

private struct StatsSectionLabel: View {
    let title: String; let sub: String
    var body: some View {
        HStack(alignment: .bottom) {
            Text(title).font(DT.textMono).foregroundColor(DT.lime).kerning(2.5)
            Spacer()
            Text(sub).font(.system(size: 11, weight: .medium)).foregroundColor(DT.textSecondary)
        }
    }
}

private struct StatsRepRow: View {
    let rep: RepRecord
    private var col: Color { rep.isGood ? DT.lime : DT.coral }
    var body: some View {
        HStack(spacing: 10) {
            Text("#\(rep.repNumber)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(col).frame(width: 32)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05))
                    RoundedRectangle(cornerRadius: 4).fill(col.opacity(0.6))
                        .frame(width: g.size.width * CGFloat(rep.score) / 100)
                        .animation(.spring(response: 0.5), value: rep.score)
                }
            }
            .frame(height: 7)
            Text(rep.isGood ? "\(rep.score)" : "—")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(rep.isGood ? .white : DT.textSecondary)
                .frame(width: 28, alignment: .trailing)
            Image(systemName: rep.isGood ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 13)).foregroundColor(col)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(Color.white.opacity(0.025)).cornerRadius(9)
    }
}

private struct StatsRepScoreGraph: View {
    let records: [RepRecord]
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width; let h = geo.size.height
            let count = records.count
            guard count > 0 else { return AnyView(EmptyView()) }
            let slot = w / CGFloat(count)
            return AnyView(ZStack(alignment: .bottom) {
                // Grid
                ForEach([0, 25, 50, 75, 100], id: \.self) { val in
                    let y = h * (1 - CGFloat(val) / 100)
                    Path { p in p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: w, y: y)) }
                        .stroke(val == 0 ? Color.white.opacity(0.12) : Color.white.opacity(0.04),
                                style: StrokeStyle(lineWidth: 1, dash: val == 0 ? [] : [4,4]))
                    if val > 0 {
                        Text("\(val)")
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.18))
                            .position(x: 12, y: max(8, y - 6))
                    }
                }
                // Connecting line
                if count > 1 {
                    Path { path in
                        for (i, rep) in records.enumerated() {
                            let x = slot * CGFloat(i) + slot / 2
                            let y = h * (1 - CGFloat(rep.score) / 100)
                            i == 0 ? path.move(to: .init(x: x, y: y)) : path.addLine(to: .init(x: x, y: y))
                        }
                    }
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
                // Bars
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(records) { rep in
                        let barH = max(6, h * CGFloat(rep.score) / 100)
                        let col  = rep.isGood ? DT.lime : DT.coral
                        VStack(spacing: 0) {
                            Circle().fill(col).frame(width: 4, height: 4)
                            Rectangle()
                                .fill(LinearGradient(colors: [col.opacity(0.9), col.opacity(0.15)],
                                                     startPoint: .top, endPoint: .bottom))
                                .frame(height: max(1, barH - 4)).cornerRadius(3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            })
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - SKELETON OVERLAY
// ─────────────────────────────────────────────
struct SquatSkeletonOverlay: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let result: SquatResult

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let shoulder: VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftShoulder : .rightShoulder
                let hip:      VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftHip      : .rightHip
                let knee:     VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftKnee     : .rightKnee
                let ankle:    VNHumanBodyPoseObservation.JointName = result.trackedLeftSide ? .leftAnkle    : .rightAnkle

                drawLine(shoulder, hip,   geo, ok: result.spineOk)
                drawLine(hip,      knee,  geo, ok: result.hipOk)
                drawLine(knee,     ankle, geo, ok: result.ankleOk)

                ForEach([shoulder, hip, knee, ankle], id: \.self) { joint in
                    if let point = bodyPoints[joint] {
                        Circle().fill(dotColor(for: joint)).frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                            .position(x: point.x * geo.size.width, y: point.y * geo.size.height)
                    }
                }
            }
        }
    }

    private func dotColor(for joint: VNHumanBodyPoseObservation.JointName) -> Color {
        switch joint {
        case .leftShoulder, .rightShoulder: return result.spineOk ? .green : .red
        case .leftHip,      .rightHip:      return result.hipOk   ? .green : .red
        case .leftKnee,     .rightKnee:     return result.kneeOk  ? .green : .red
        case .leftAnkle,    .rightAnkle:    return result.ankleOk ? .green : .red
        default:                            return .white
        }
    }

    @ViewBuilder
    private func drawLine(_ j1: VNHumanBodyPoseObservation.JointName,
                          _ j2: VNHumanBodyPoseObservation.JointName,
                          _ geo: GeometryProxy, ok: Bool) -> some View {
        if let p1 = bodyPoints[j1], let p2 = bodyPoints[j2] {
            Path { path in
                path.move(to: CGPoint(x: p1.x * geo.size.width, y: p1.y * geo.size.height))
                path.addLine(to: CGPoint(x: p2.x * geo.size.width, y: p2.y * geo.size.height))
            }
            .stroke(ok ? Color.green : Color.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - VIEW MODEL
// ─────────────────────────────────────────────
final class SquatViewModel: NSObject, ObservableObject,
                             AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession()

    @Published var bodyPoints:    [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    private var pointsBuffer:     [[VNHumanBodyPoseObservation.JointName: CGPoint]] = []
    @Published var postureResult  = SquatResult()
    @Published var currentPhase: SquatPhase = .standing
    @Published var phaseText      = "Standing"
    @Published var phaseColor: Color = .white
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    @Published var showFormAlert    = false
    @Published var formAlertMessage = ""
    @Published var showGoodRepFlash = false
    @Published var badRepMessage: String? = nil

    // Analytics
    @Published var repHistory:       [RepRecord] = []
    @Published var goodReps          = 0
    @Published var badReps           = 0
    @Published var totalRepsAllTime  = 0
    @Published var averageScore      = 0
    @Published var bestRepScore      = 0

    // Sets / Goal
    @Published var targetSets       = 0
    @Published var targetReps       = 0
    @Published var currentSet       = 1
    @Published var repsInCurrentSet = 0

    // Rest timer
    @Published var isResting        = false
    @Published var restSecondsLeft  = 0
    private var restDuration        = 60
    private var restTimer: Timer?

    // Session timer
    @Published var sessionTimeString = "00:00"
    private var sessionStartDate: Date?
    private var sessionTimer: Timer?

    @Published var reps = 0

    private var frameBuffer:        [SquatResult] = []
    private var lastKneeAngle:      Double = 180
    private var bottomReached       = false
    private var depthReached        = false
    private var squatStarted        = false
    private var validBottomFrames   = 0
    private var minKneeAngle        = 180.0
    private var validDepthFrames    = 0
    private var validStandingFrames = 0
    private var stableIssueFrames   = 0
    private var notVisibleFrames    = 0
    private var lastIssue: SquatIssue = .detecting
    private var alertTimer: Timer?

    private var spineErrorFrames = 0
    private var ankleErrorFrames = 0
    private var hipErrorFrames   = 0
    private var hadSpineError    = false
    private var hadHipError      = false
    private var hadAnkleError    = false
    private var hadKneeError     = false

    private let speechSynth     = AVSpeechSynthesizer()
    private var lastSpokenIssue: SquatIssue = .detecting
    private var lastSpeechTime:  Date = .distantPast

    private var lastNotifTime: [String: Date] = [:]
    private let notifCooldown: TimeInterval   = 5.0
    
    // add with the other private vars, around line 2770
    private var isConfiguring = false
    // add with other private vars
    private let cameraQueue = DispatchQueue(label: "squatCameraQueue")


    // MARK: Start / Stop
    func start() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { return }
            DispatchQueue.global(qos: .userInitiated).async { self.setupCamera() }
        }
        startSessionTimer()
        fireWatchNotification(title: "🏋️ Ready for Squat!", body: "Get into position and begin.")
    }

    func stop() {
        sessionTimer?.invalidate()
        restTimer?.invalidate()
        cameraQueue.async { [weak self] in
            guard let self else { return }
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }


    private func startSessionTimer() {
        sessionStartDate = Date()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let start = self.sessionStartDate else { return }
            let e = Int(Date().timeIntervalSince(start))
            DispatchQueue.main.async {
                self.sessionTimeString = String(format: "%02d:%02d", e / 60, e % 60)
            }
        }
    }

    func setGoal(sets: Int, reps: Int, restSeconds: Int) {
        DispatchQueue.main.async {
            self.targetSets = sets; self.targetReps = reps
            self.restDuration = restSeconds
            self.currentSet = 1; self.repsInCurrentSet = 0
        }
    }

    func clearGoal() {
        DispatchQueue.main.async {
            self.targetSets = 0; self.targetReps = 0
            self.currentSet = 1; self.repsInCurrentSet = 0
        }
    }

    func resetSession() {
        DispatchQueue.main.async {
            self.reps = 0; self.repsInCurrentSet = 0; self.currentSet = 1
            self.goodReps = 0; self.badReps = 0; self.totalRepsAllTime = 0
            self.averageScore = 0; self.bestRepScore = 0; self.repHistory = []
            self.bottomReached = false; self.depthReached = false; self.squatStarted = false
            self.currentPhase = .standing; self.phaseText = "Standing"; self.phaseColor = .white
            self.validBottomFrames = 0; self.validStandingFrames = 0
            self.spineErrorFrames = 0; self.ankleErrorFrames = 0; self.hipErrorFrames = 0
            self.hadSpineError = false; self.hadHipError = false
            self.hadAnkleError = false; self.hadKneeError = false
            self.isResting = false; self.restTimer?.invalidate()
            self.sessionStartDate = Date()
        }
    }

    private func resetSquatState() {
        bottomReached = false; depthReached = false; squatStarted = false
        validBottomFrames = 0; validStandingFrames = 0; lastKneeAngle = 180
        spineErrorFrames = 0; ankleErrorFrames = 0; hipErrorFrames = 0
        hadSpineError = false; hadHipError = false; hadAnkleError = false; hadKneeError = false
        frameBuffer = []; pointsBuffer = []
        DispatchQueue.main.async {
            self.currentPhase = .standing; self.phaseText = "Standing"; self.phaseColor = .white
        }
    }

    // MARK: Camera
    private func setupCamera() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            guard !self.session.isRunning else { return }
            // Remove any stale inputs/outputs from a previous session
            self.isConfiguring = true
            self.session.beginConfiguration()
            self.session.sessionPreset = .high
            self.session.inputs.forEach  { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition),
                let input  = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(input)
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "squatVideoQueue"))
            output.alwaysDiscardsLateVideoFrames = true
            if self.session.canAddOutput(output) { self.session.addOutput(output) }
            self.session.commitConfiguration()
            self.isConfiguring = false
            self.session.startRunning()
        }
    }

    func switchCamera() {
        cameraQueue.async { [weak self] in
            guard let self else { return }
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.isConfiguring = true
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            guard
                let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                let inp = try? AVCaptureDeviceInput(device: dev),
                self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(inp)
            self.session.commitConfiguration()
            self.isConfiguring = false
            DispatchQueue.main.async { self.cameraPosition = newPos }
        }
    }
    
    
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let orientation: CGImagePropertyOrientation = cameraPosition == .front ? .leftMirrored : .right
        analyzeFrame(pixelBuffer: pixelBuffer, orientation: orientation)
    }

    // MARK: Analyze frame
    private func analyzeFrame(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) {
        guard !isResting else { return }
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return }
            let points = try observation.recognizedPoints(.all)

            updateBodyPoints(points)
            let rawResult = analyzeSquatPosture(points)

            if rawResult.issue == .notVisible {
                notVisibleFrames += 1
                if notVisibleFrames >= 8 { DispatchQueue.main.async { self.postureResult = rawResult } }
                return
            } else { notVisibleFrames = 0 }

            var smoothed = smoothResult(rawResult)
            updatePhaseAndReps(smoothedResult: smoothed)

            if smoothed.issue == lastIssue { stableIssueFrames += 1 }
            else { stableIssueFrames = 0; lastIssue = smoothed.issue }
            if stableIssueFrames < 3 { smoothed.issue = postureResult.issue }

            updateFormAlert(result: smoothed)
            DispatchQueue.main.async { self.postureResult = smoothed }
        } catch { print(error) }
    }

    private func speakFormCue(result: SquatResult) {
        guard currentPhase == .descending || currentPhase == .bottom else { return }
        let now = Date()
        guard now.timeIntervalSince(lastSpeechTime) > 3.0 else { return }
        var cue: String? = nil
        if !result.spineOk      { cue = "Keep your back straight" }
        else if !result.ankleOk { cue = "Knees too far forward" }
        else if !result.hipOk   { cue = "Lower your hips" }
        if let text = cue, result.issue != lastSpokenIssue {
            lastSpokenIssue = result.issue; lastSpeechTime = now
            let u = AVSpeechUtterance(string: text); u.rate = 0.5; u.volume = 0.9
            DispatchQueue.main.async { self.speechSynth.speak(u) }
        }
    }

    private func speakRepCount(_ count: Int) {
        let u = AVSpeechUtterance(string: "\(count)"); u.rate = 0.55; u.volume = 1.0
        DispatchQueue.main.async { self.speechSynth.speak(u) }
    }

    private func speakText(_ text: String) {
        let u = AVSpeechUtterance(string: text); u.rate = 0.5; u.volume = 1.0
        DispatchQueue.main.async { self.speechSynth.speak(u) }
    }

    private func updateFormAlert(result: SquatResult) {
        guard currentPhase == .descending || currentPhase == .bottom else {
            DispatchQueue.main.async { self.showFormAlert = false }
            return
        }
        var message: String? = nil
        if !result.spineOk      { message = "Keep Your Back Straight!" }
        else if !result.ankleOk { message = "Knees Too Far Forward!" }
        else if !result.hipOk   { message = "Lower Your Hips More!" }

        if let msg = message {
            fireWatchNotification(title: "⚠️ Fix Your Form", body: msg)
        }

        DispatchQueue.main.async {
            if let msg = message {
                self.formAlertMessage = msg; self.showFormAlert = true
                self.alertTimer?.invalidate()
                self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                    DispatchQueue.main.async { self.showFormAlert = false }
                }
            } else { self.showFormAlert = false }
        }
    }

    // MARK: Phase & rep logic (original preserved exactly)
    private func updatePhaseAndReps(smoothedResult: SquatResult) {
        let kneeAngle = smoothedResult.kneeAngle
        let prev      = lastKneeAngle
        var nextPhase = currentPhase
        var addRep    = false

        if currentPhase == .descending || currentPhase == .bottom || currentPhase == .ascending {
            if !smoothedResult.spineOk { spineErrorFrames += 1 } else { spineErrorFrames = 0 }
            if !smoothedResult.ankleOk { ankleErrorFrames += 1 } else { ankleErrorFrames = 0 }
            if !smoothedResult.hipOk   { hipErrorFrames   += 1 } else { hipErrorFrames   = 0 }
            if spineErrorFrames >= 3 { hadSpineError = true }
            if ankleErrorFrames >= 3 { hadAnkleError = true }
            if hipErrorFrames   >= 3 { hadHipError   = true }
            if !smoothedResult.kneeOk && currentPhase == .bottom { hadKneeError = true }
        }

        if kneeAngle < 145 && prev > kneeAngle && !depthReached {
            nextPhase = .descending; squatStarted = true
        }

        if kneeAngle < minKneeAngle { minKneeAngle = kneeAngle }

        if kneeAngle <= 90 {
            validDepthFrames += 1
            if validDepthFrames >= 5 { depthReached = true }
        } else { validDepthFrames = 0 }

        let startedRising = depthReached && kneeAngle > (minKneeAngle + 4)
        if startedRising && !bottomReached {
            validBottomFrames += 1
            if validBottomFrames >= 3 { nextPhase = .bottom; bottomReached = true }
        } else if !depthReached { validBottomFrames = 0 }

        if bottomReached && kneeAngle > (prev + 2) && kneeAngle < 152 { nextPhase = .ascending }

        if squatStarted && kneeAngle >= 152 {
            validStandingFrames += 1
            if validStandingFrames >= 2 {
                if depthReached {
                    let formWasGood = !hadAnkleError && !hadSpineError && !hadHipError
                    if formWasGood {
                        addRep = true
                        triggerGoodRepFeedback(score: smoothedResult.postureScore)
                    } else {
                        triggerBadRepFeedback()
                    }
                } else {
                    triggerBadRepFeedback()
                }
                nextPhase = .standing; bottomReached = false; depthReached = false
                squatStarted = false; validStandingFrames = 0; validBottomFrames = 0
                minKneeAngle = 180; validDepthFrames = 0
                spineErrorFrames = 0; ankleErrorFrames = 0; hipErrorFrames = 0
                hadSpineError = false; hadHipError = false; hadAnkleError = false; hadKneeError = false
            }
        } else if kneeAngle < 145 { validStandingFrames = 0 }

        lastKneeAngle = kneeAngle
        let scoreSnapshot = smoothedResult.postureScore

        DispatchQueue.main.async {
            if addRep {
                self.reps += 1
                self.repsInCurrentSet += 1
                self.totalRepsAllTime += 1
                self.speakRepCount(self.repsInCurrentSet)
                WatchConnectivityManager.shared.sendRepUpdate(
                    exercise: "Squat", repsInSet: self.repsInCurrentSet,
                    targetReps: self.targetReps, currentSet: self.currentSet,
                    totalSets: self.targetSets, formScore: scoreSnapshot,
                    feedback: scoreSnapshot >= 85 ? "Good form!" : "Keep it clean")

                if self.targetReps > 0 && self.repsInCurrentSet >= self.targetReps {
                    if self.currentSet < self.targetSets {
                        self.speakText("Set \(self.currentSet) complete! Rest now.")
                        self.startRestTimer()
                        self.currentSet += 1
                        self.repsInCurrentSet = 0
                    } else {
                        self.speakText("Workout complete! Great job!")
                        self.fireWatchNotification(
                            title: "🎉 Workout Complete!",
                            body:  "You finished all \(self.targetSets) sets. Great job!"
                        )
                    }
                }

                let record = RepRecord(repNumber: self.totalRepsAllTime,
                                       score: scoreSnapshot, isGood: true, timestamp: Date())
                self.repHistory.append(record)
                self.updateScoreStats()
            }

            self.currentPhase = nextPhase
            switch nextPhase {
            case .standing:   self.phaseText = "Standing";         self.phaseColor = .white
            case .descending: self.phaseText = "Going Down";       self.phaseColor = .yellow
            case .bottom:     self.phaseText = "Perfect Depth ✅"; self.phaseColor = .green
            case .ascending:  self.phaseText = "Coming Up";        self.phaseColor = .blue
            }
        }
    }

    private func updateScoreStats() {
        goodReps = repHistory.filter { $0.isGood }.count
        badReps  = repHistory.filter { !$0.isGood }.count
        if !repHistory.isEmpty {
            averageScore = repHistory.map { $0.score }.reduce(0,+) / repHistory.count
            bestRepScore = repHistory.map { $0.score }.max() ?? 0
        }
    }

    private func startRestTimer() {
        restSecondsLeft = restDuration; isResting = true
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            DispatchQueue.main.async {
                self.restSecondsLeft -= 1
                if self.restSecondsLeft <= 0 {
                    t.invalidate(); self.isResting = false
                    self.resetSquatState(); self.speakText("Go!")
                }
            }
        }
    }

    private func triggerGoodRepFeedback(score: Int) {
        DispatchQueue.main.async {
            self.showGoodRepFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { self.showGoodRepFlash = false }
        }
    }

    private func triggerBadRepFeedback() {
        var reasons: [String] = []
        if hadSpineError  { reasons.append("Back not straight") }
        if hadAnkleError  { reasons.append("Knees too forward") }
        if hadHipError    { reasons.append("Hips too high") }
        if reasons.isEmpty { reasons.append("Improper Depth") }
        let message = "⚠️ Rep Not Counted\n" + reasons.joined(separator: " • ")

        if hadSpineError       { speakText("Keep your back straight") }
        else if hadAnkleError  { speakText("Knees too far forward") }
        else if hadHipError    { speakText("Lower your hips") }
        else                   { speakText("Improper Depth") }

        fireWatchNotification(title: "❌ You Did It Wrong!", body: reasons.joined(separator: " • "))

        DispatchQueue.main.async {
            self.badRepMessage = message
            let record = RepRecord(repNumber: self.totalRepsAllTime + 1,
                                   score: 0, isGood: false, timestamp: Date())
            self.repHistory.append(record)
            self.totalRepsAllTime += 1
            self.updateScoreStats()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.badRepMessage = nil }
        }
    }

    func fireWatchNotification(title: String, body: String) {
        let key = "\(title)"
        let now = Date()
        if let last = lastNotifTime[key], now.timeIntervalSince(last) < notifCooldown { return }
        lastNotifTime[key] = now
        NotificationManager.shared.send(title: title, body: body)
        WatchConnectivityManager.shared.sendFormAlert(exercise: "Squat", issue: "\(title): \(body)")
    }

    // MARK: Posture analysis (original preserved exactly)
    private func analyzeSquatPosture(
        _ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    ) -> SquatResult {
        var result = SquatResult()
        let useLeft = betterSide(points)
        result.trackedLeftSide = useLeft

        let shoulderKey: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let hipKey:      VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let kneeKey:     VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee     : .rightKnee
        let ankleKey:    VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle    : .rightAnkle

        for joint in [shoulderKey, hipKey, kneeKey, ankleKey] {
            guard let p = points[joint], p.confidence > 0.2 else {
                result.issue = .notVisible; return result
            }
        }

        let shoulder = points[shoulderKey]!.location
        let hip      = points[hipKey]!.location
        let knee     = points[kneeKey]!.location
        let ankle    = points[ankleKey]!.location

        result.kneeAngle     = calculateAngle(first: hip,      middle: knee, last: ankle)
        result.hipAngle      = calculateAngle(first: shoulder, middle: hip,  last: knee)
        let rawAtan          = atan2(shoulder.y - hip.y, shoulder.x - hip.x) * 180 / .pi
        let torsoAngle       = abs(90.0 - abs(rawAtan))
        result.spineAngle    = torsoAngle
        result.kneeToeOffset = knee.x - ankle.x

        let isSquatting = result.kneeAngle < 160
        guard isSquatting else {
            result.kneeOk = true; result.hipOk = true
            result.spineOk = true; result.ankleOk = true
            result.issue = .ready; result.postureScore = 100
            return result
        }

        result.ankleOk = abs(result.kneeToeOffset) <= 0.15

        switch currentPhase {
        case .standing:
            result.kneeOk = true; result.hipOk = true; result.spineOk = true
        case .descending:
            result.kneeOk = true; result.hipOk = true
            result.spineOk = torsoAngle >= 0 && torsoAngle <= 55
        case .bottom:
            result.kneeOk  = result.kneeAngle >= 50 && result.kneeAngle <= 90
            result.hipOk   = result.hipAngle  >= 30 && result.hipAngle  <= 100
            result.spineOk = torsoAngle >= 20 && torsoAngle <= 55
        case .ascending:
            result.kneeOk = true; result.hipOk = true
            result.spineOk = true; result.ankleOk = true
        }

        var score = 100
        if currentPhase != .ascending {
            if !result.kneeOk  { score -= 30 }
            if !result.hipOk   { score -= 20 }
            if !result.spineOk { score -= 30 }
            if !result.ankleOk { score -= 20 }
        }
        result.postureScore = max(score, 0)

        if currentPhase == .ascending    { result.issue = .correct }
        else if !result.spineOk          { result.issue = .backNotStraight }
        else if !result.ankleOk          { result.issue = .kneesOverToes }
        else if !result.hipOk            { result.issue = .hipTooHigh }
        else if !result.kneeOk           { result.issue = .kneesNotDeep }
        else                             { result.issue = .correct }

        return result
    }

    // MARK: Helpers
    private func betterSide(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> Bool {
        let lShoulder: Float = points[.leftShoulder]?.confidence ?? 0
        let lHip:      Float = points[.leftHip]?.confidence      ?? 0
        let lKnee:     Float = points[.leftKnee]?.confidence     ?? 0
        let lAnkle:    Float = points[.leftAnkle]?.confidence    ?? 0
        let rShoulder: Float = points[.rightShoulder]?.confidence ?? 0
        let rHip:      Float = points[.rightHip]?.confidence      ?? 0
        let rKnee:     Float = points[.rightKnee]?.confidence     ?? 0
        let rAnkle:    Float = points[.rightAnkle]?.confidence    ?? 0
        return (lShoulder+lHip+lKnee+lAnkle) >= (rShoulder+rHip+rKnee+rAnkle)
    }

    private func updateBodyPoints(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var mapped: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (joint, point) in points where point.confidence > 0.3 {
            mapped[joint] = CGPoint(x: point.location.x, y: 1 - point.location.y)
        }
        pointsBuffer.append(mapped)
        if pointsBuffer.count > 6 { pointsBuffer.removeFirst() }
        var smoothed: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        let uniqueJoints = Set(pointsBuffer.flatMap { $0.keys })
        for joint in uniqueJoints {
            let positions = pointsBuffer.compactMap { $0[joint] }
            guard !positions.isEmpty else { continue }
            let n = CGFloat(positions.count)
            smoothed[joint] = CGPoint(x: positions.map(\.x).reduce(0,+)/n,
                                      y: positions.map(\.y).reduce(0,+)/n)
        }
        DispatchQueue.main.async { self.bodyPoints = smoothed }
    }

    private func calculateAngle(first: CGPoint, middle: CGPoint, last: CGPoint) -> Double {
        let a = atan2(first.y - middle.y, first.x - middle.x)
        let b = atan2(last.y  - middle.y, last.x  - middle.x)
        var angle = abs((a - b) * 180 / .pi)
        if angle > 180 { angle = 360 - angle }
        return angle
    }

    private func smoothResult(_ result: SquatResult) -> SquatResult {
        frameBuffer.append(result)
        if frameBuffer.count > 8 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        var smoothed = result
        smoothed.kneeAngle    = frameBuffer.map(\.kneeAngle).reduce(0,+)  / n
        smoothed.hipAngle     = frameBuffer.map(\.hipAngle).reduce(0,+)   / n
        smoothed.spineAngle   = frameBuffer.map(\.spineAngle).reduce(0,+) / n
        smoothed.postureScore = Int(Double(frameBuffer.map(\.postureScore).reduce(0,+)) / n)
        smoothed.trackedLeftSide = result.trackedLeftSide
        return smoothed
    }
}

//UNIT TEst
