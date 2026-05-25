//
//  ExerciseFormViews.swift
//  FitnessAI
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
import Vision
import Combine

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
                // ── NEW improved views from AllExerciseViews.swift ──────────
                case "Bodyweight Squat":  SquatCameraView()        // ContentView quality
                case "Plank":             PlankCameraView2()       // improved + crash-safe
                case "Push-Up":           PushUpCameraView2()      // improved + crash-safe
                case "Reverse Lunge":     LungeCameraView2()       // improved + crash-safe
                case "Glute Bridge":      GBCameraView()           // improved + crash-safe
                case "High Knees":        HKCameraView()           // improved + crash-safe
                case "Mountain Climber":  MountainClimberCameraView() // existing
                default:                  SquatCameraView()        // safe fallback
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

enum PlankIssue: String {
    case correct      = "✅ Perfect Plank"
    case hipSagging   = "❌ Raise Your Hips"
    case hipPiking    = "❌ Lower Your Hips"
    case neckCraned   = "❌ Keep Neck Neutral"
    case detecting    = "🔍 Detecting..."
    case notVisible   = "📷 Full Body Not Visible"
}

struct PlankResult {
    var issue: PlankIssue = .detecting
    var postureScore: Int = 100
    var bodyAngle: Double = 180      // shoulder→hip→ankle — should be ~170-180 (straight line)
    var neckAngle: Double = 0        // shoulder→neck deviation
    var hipHeight: Double = 0        // relative hip position
    var bodyOk  = true
    var neckOk  = true
}

final class PlankViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = PlankResult()
    @Published var holdSeconds = 0
    @Published var isHolding = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    private var holdTimer: Timer?
    private var frameBuffer: [PlankResult] = []
    private var stableFrames = 0
    private var lastIssue: PlankIssue = .detecting
    private var alertTimer: Timer?

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { return }
            DispatchQueue.global(qos: .userInitiated).async { self.setupCamera() }
        }
    }
    func stop() { session.stopRunning(); holdTimer?.invalidate() }
    func resetHold() {
        DispatchQueue.main.async {
            self.holdSeconds = 0; self.isHolding = false
            self.holdTimer?.invalidate()
        }
    }
    func switchCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); return }
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
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "plankQueue"))
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration(); session.startRunning()
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let orientation: CGImagePropertyOrientation = cameraPosition == .front ? .leftMirrored : .right
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        do {
            try handler.perform([request])
            guard let obs = request.results?.first else { return }
            let pts = try obs.recognizedPoints(.all)
            DispatchQueue.main.async { self.bodyPoints = mappedPoints(pts) }
            analyzeFrame(pts)
        } catch {}
    }
    private func analyzeFrame(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var r = PlankResult()
        let lPlConf: Float = (points[.leftShoulder]?.confidence ?? 0) + (points[.leftHip]?.confidence ?? 0) + (points[.leftAnkle]?.confidence ?? 0)
        let rPlConf: Float = (points[.rightShoulder]?.confidence ?? 0) + (points[.rightHip]?.confidence ?? 0) + (points[.rightAnkle]?.confidence ?? 0)
        let useLeft = lPlConf >= rPlConf
        let shK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let hpK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip : .rightHip
        let anK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle : .rightAnkle
        let nkK: VNHumanBodyPoseObservation.JointName = .neck

        for j in [shK, hpK, anK] {
            guard let p = points[j], p.confidence > 0.35 else { r.issue = .notVisible; DispatchQueue.main.async { self.result = r }; return }
        }
        let sh = points[shK]!.location
        let hp = points[hpK]!.location
        let an = points[anK]!.location
        // body line angle: hip should be between shoulder and ankle height-wise
        r.bodyAngle = calcAngle(first: sh, middle: hp, last: an)
        r.hipHeight = hp.y  // normalized 0-1

        // Neck angle
        if let nk = points[nkK], nk.confidence > 0.3 {
            let neckPt = nk.location
            let shoulderToHip = atan2(hp.y - sh.y, hp.x - sh.x)
            let shoulderToNeck = atan2(neckPt.y - sh.y, neckPt.x - sh.x)
            r.neckAngle = abs((shoulderToNeck - shoulderToHip) * 180 / .pi)
            r.neckOk = r.neckAngle < 35
        } else { r.neckOk = true }

        // Body line: angle close to 180 = straight plank
        // Below 160 = hip sagging, above 200 = piking
        r.bodyOk = r.bodyAngle >= 158 && r.bodyAngle <= 200

        var score = 100
        if !r.bodyOk  { score -= 40 }
        if !r.neckOk  { score -= 20 }
        r.postureScore = max(score, 0)

        if r.bodyAngle < 158        { r.issue = .hipSagging }
        else if r.bodyAngle > 200   { r.issue = .hipPiking }
        else if !r.neckOk           { r.issue = .neckCraned }
        else                        { r.issue = .correct }

        // Smooth
        frameBuffer.append(r)
        if frameBuffer.count > 6 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        var sm = r
        sm.bodyAngle = frameBuffer.map { $0.bodyAngle }.reduce(0, +) / n
        sm.neckAngle = frameBuffer.map { $0.neckAngle }.reduce(0, +) / n
        sm.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0, +)) / n)

        // Hold timer
        // Run FormRuleEngine for additional threshold-based checks
        if let ruleMsg = ruleEngineAlert(joints: self.bodyPoints, exercise: .plank) {
            self.fireAlert(ruleMsg)
        }

        let isGoodForm = sm.issue == .correct
        DispatchQueue.main.async {
            self.result = sm
            if isGoodForm && !self.isHolding {
                self.isHolding = true
                self.holdTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    DispatchQueue.main.async { self.holdSeconds += 1 }
                }
            } else if !isGoodForm && self.isHolding {
                self.isHolding = false
                self.holdTimer?.invalidate()
            }
            // Alert
            if sm.issue == .hipSagging { self.fireAlert("Hips Dropping — Squeeze Glutes!") }
            else if sm.issue == .hipPiking { self.fireAlert("Hips Too High — Lower Down!") }
            else if sm.issue == .neckCraned { self.fireAlert("Look Down — Keep Neck Neutral!") }
            else { self.showAlert = false }
        }
    }
    private func fireAlert(_ msg: String) {
        alertMessage = msg; showAlert = true
        alertTimer?.invalidate()
        alertTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
            DispatchQueue.main.async { self.showAlert = false }
        }
    }
}

struct PlankCameraView: View {
    @StateObject private var vm = PlankViewModel()
    var body: some View { plankUI }
    @ViewBuilder private var plankUI: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            SimpleSkeleton(bodyPoints: vm.bodyPoints, joints: [.leftShoulder,.rightShoulder,.leftHip,.rightHip,.leftAnkle,.rightAnkle], isOk: vm.result.bodyOk)
                .ignoresSafeArea()
            VStack {
                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Plank AI").font(.title2.bold()).foregroundColor(.white)
                        Text("Hold — Breathe Steady").font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Button { vm.switchCamera() } label: {
                        Image(systemName: "camera.rotate").font(.title2).foregroundColor(.white)
                            .padding(12).background(Color.white.opacity(0.2)).clipShape(Circle())
                    }
                    ScoreRing(score: vm.result.postureScore)
                }
                .padding().background(.black.opacity(0.65)).cornerRadius(20).padding()
                Spacer()
                if vm.showAlert { LiveFormBanner(message: vm.alertMessage).transition(.move(edge: .top).combined(with: .opacity)) }
                Spacer()
                // Bottom panel
                VStack(spacing: 18) {
                    Text(vm.result.issue.rawValue).font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
                    HStack(spacing: 12) {
                        LiveAngleCard(title: "Body Line", angle: vm.result.bodyAngle, isOk: vm.result.bodyOk, idealRange: "158°-200°")
                        LiveAngleCard(title: "Neck", angle: vm.result.neckAngle, isOk: vm.result.neckOk, idealRange: "< 35°")
                    }
                    HStack(spacing: 50) {
                        VStack {
                            Text(timeString(vm.holdSeconds)).font(.system(size: 46, weight: .bold)).foregroundColor(.white)
                            Text("HOLD").foregroundColor(.white.opacity(0.7))
                        }
                        VStack {
                            Image(systemName: vm.isHolding ? "checkmark.circle.fill" : "pause.circle")
                                .font(.title).foregroundColor(vm.isHolding ? .green : .yellow)
                            Text(vm.isHolding ? "HOLDING" : "FIX FORM").font(.caption.bold()).foregroundColor(.white.opacity(0.7))
                        }
                        Button { vm.resetHold() } label: {
                            VStack {
                                Image(systemName: "arrow.counterclockwise").font(.title2).foregroundColor(.white)
                                Text("RESET").foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
                .padding().background(.black.opacity(0.75)).cornerRadius(22).padding()
            }
        }
        .onAppear { vm.start() }.onDisappear { vm.stop() }
        .animation(.spring(response: 0.4), value: vm.showAlert)
    }
    func timeString(_ s: Int) -> String { String(format: "%d:%02d", s/60, s%60) }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PUSH-UP
// ─────────────────────────────────────────────────────────────────────────────

enum PushUpIssue: String {
    case correct      = "✅ Perfect Push-Up"
    case notDeepEnough = "❌ Go Lower"
    case hipSagging   = "❌ Keep Hips Level"
    case elbowsFlared = "❌ Tuck Your Elbows"
    case detecting    = "🔍 Detecting..."
    case notVisible   = "📷 Full Body Not Visible"
}

enum PushUpPhase { case up, descending, bottom, ascending }

struct PushUpResult {
    var issue: PushUpIssue = .detecting
    var postureScore: Int = 100
    var elbowAngle: Double = 180    // should reach < 90 at bottom
    var bodyAngle: Double = 180     // shoulder-hip-ankle straightness
    var elbowOk = true
    var bodyOk  = true
}

final class PushUpViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = PushUpResult()
    @Published var reps = 0
    @Published var phase: PushUpPhase = .up
    @Published var phaseText = "Up"
    @Published var phaseColor: Color = .white
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showBadRepFlash = false
    @Published var badRepReason = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    private var frameBuffer: [PushUpResult] = []
    private var lastElbow: Double = 180
    private var bottomReached = false
    private var repStarted = false
    private var validBottomFrames = 0
    private var validTopFrames = 0
    private var hadBodyError = false
    private var bodyErrorFrames = 0
    private var alertTimer: Timer?

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { return }
            DispatchQueue.global(qos: .userInitiated).async { self.setupCamera() }
        }
    }
    func stop() { session.stopRunning() }
    func resetReps() {
        DispatchQueue.main.async {
            self.reps = 0; self.bottomReached = false; self.repStarted = false
            self.phase = .up; self.phaseText = "Up"; self.phaseColor = .white
            self.validBottomFrames = 0; self.validTopFrames = 0
            self.hadBodyError = false; self.bodyErrorFrames = 0
        }
    }
    func switchCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); return }
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
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "pushupQueue"))
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration(); session.startRunning()
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
        var r = PushUpResult()
        let lConf: Float = (points[.leftShoulder]?.confidence ?? 0) + (points[.leftElbow]?.confidence ?? 0) + (points[.leftWrist]?.confidence ?? 0)
        let rConf: Float = (points[.rightShoulder]?.confidence ?? 0) + (points[.rightElbow]?.confidence ?? 0) + (points[.rightWrist]?.confidence ?? 0)
        let useLeft = lConf >= rConf
        let shK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let elK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftElbow    : .rightElbow
        let wrK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftWrist    : .rightWrist
        let hpK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let anK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle    : .rightAnkle
        for j in [shK, elK, wrK] {
            guard let p = points[j], p.confidence > 0.35 else { r.issue = .notVisible; DispatchQueue.main.async { self.result = r }; return }
        }
        let sh = points[shK]!.location
        let el = points[elK]!.location
        let wr = points[wrK]!.location
        r.elbowAngle = calcAngle(first: sh, middle: el, last: wr)
        // Body line check
        if let hp = points[hpK], hp.confidence > 0.3, let an = points[anK], an.confidence > 0.3 {
            r.bodyAngle = calcAngle(first: sh, middle: hp.location, last: an.location)
            r.bodyOk = r.bodyAngle >= 155
        } else { r.bodyOk = true }

        r.elbowOk = (r.elbowAngle <= 100) || phase == .up  // only check at bottom
        var score = 100
        if !r.bodyOk  { score -= 35 }
        r.postureScore = max(score, 0)

        // Smooth
        frameBuffer.append(r)
        if frameBuffer.count > 7 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        var sm = r
        sm.elbowAngle = frameBuffer.map { $0.elbowAngle }.reduce(0, +) / n
        sm.bodyAngle  = frameBuffer.map { $0.bodyAngle  }.reduce(0, +) / n
        sm.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0, +)) / n)

        updatePhase(sm)

        if !sm.bodyOk { bodyErrorFrames += 1 } else { bodyErrorFrames = 0 }
        if bodyErrorFrames >= 3 { hadBodyError = true }

        if sm.elbowAngle < 145 && sm.elbowAngle < lastElbow { repStarted = true }
        if repStarted && sm.elbowAngle <= 95 {
            validBottomFrames += 1
            if validBottomFrames >= 3 { bottomReached = true }
        } else if sm.elbowAngle > 155 && repStarted {
            validTopFrames += 1
            if validTopFrames >= 2 && bottomReached {
                if hadBodyError {
                    DispatchQueue.main.async {
                        self.badRepReason = "Keep hips level — don't sag"
                        self.showBadRepFlash = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.showBadRepFlash = false }
                    }
                } else {
                    DispatchQueue.main.async { self.reps += 1 }
                }
                bottomReached = false; repStarted = false
                validBottomFrames = 0; validTopFrames = 0; hadBodyError = false; bodyErrorFrames = 0
            }
        } else { validTopFrames = 0 }

        if !sm.bodyOk && (phase == .descending || phase == .bottom) {
            fireAlert("Keep Hips Level — Squeeze Core!")
        } else { DispatchQueue.main.async { self.showAlert = false } }

        lastElbow = sm.elbowAngle
        // FormRuleEngine: elbow flare + hip drop thresholds
        if sm.issue == .correct, let ruleMsg = ruleEngineAlert(joints: self.bodyPoints, exercise: .pushUp) {
            fireAlert(ruleMsg)
        }
        if !sm.bodyOk { sm.issue = .hipSagging }
        else if sm.elbowAngle > 140 && phase == .bottom { sm.issue = .notDeepEnough }
        else { sm.issue = .correct }
        DispatchQueue.main.async { self.result = sm }
    }
    private func updatePhase(_ r: PushUpResult) {
        DispatchQueue.main.async {
            if r.elbowAngle <= 95 {
                self.phase = .bottom; self.phaseText = "Deep ✅"; self.phaseColor = .green
            } else if r.elbowAngle < 145 && r.elbowAngle < self.lastElbow {
                self.phase = .descending; self.phaseText = "Going Down"; self.phaseColor = .yellow
            } else if r.elbowAngle >= 155 {
                self.phase = .up; self.phaseText = "Up"; self.phaseColor = .white
            } else if r.elbowAngle > self.lastElbow {
                self.phase = .ascending; self.phaseText = "Pushing Up"; self.phaseColor = .cyan
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
}

struct PushUpCameraView: View {
    @StateObject private var vm = PushUpViewModel()
    var body: some View { pushUpUI }
    @ViewBuilder private var pushUpUI: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            SimpleSkeleton(bodyPoints: vm.bodyPoints,
                           joints: [.leftShoulder,.rightShoulder,.leftElbow,.rightElbow,.leftWrist,.rightWrist,.leftHip,.rightHip],
                           isOk: vm.result.bodyOk && vm.result.elbowOk)
                .ignoresSafeArea()
            VStack {
                pushUpTopBar
                Spacer()
                if vm.showAlert {
                    LiveFormBanner(message: vm.alertMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
                pushUpBottomPanel
            }
            if vm.showBadRepFlash { BadRepFlash(reason: vm.badRepReason) }
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .animation(.spring(response: 0.4), value: vm.showAlert)
    }
    private var pushUpTopBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Push-Up AI").font(.title2.bold()).foregroundColor(.white)
                Text("Real-Time Form Check").font(.caption).foregroundColor(.white.opacity(0.7))
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
    private var pushUpBottomPanel: some View {
        VStack(spacing: 18) {
            Text(vm.result.issue.rawValue).font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                LiveAngleCard(title: "Elbow", angle: vm.result.elbowAngle, isOk: vm.result.elbowOk, idealRange: "< 95°")
                LiveAngleCard(title: "Body Line", angle: vm.result.bodyAngle, isOk: vm.result.bodyOk, idealRange: "> 155°")
            }
            HStack(spacing: 50) {
                VStack {
                    Text("\(vm.reps)").font(.system(size: 50, weight: .bold)).foregroundColor(.white)
                    Text("REPS").foregroundColor(.white.opacity(0.7))
                }
                VStack {
                    Text(vm.phaseText).font(.title3.bold()).foregroundColor(vm.phaseColor)
                    Text("PHASE").foregroundColor(.white.opacity(0.7))
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
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - LUNGE
// ─────────────────────────────────────────────────────────────────────────────

enum LungeIssue: String {
    case correct       = "✅ Good Lunge"
    case kneeOverToe   = "❌ Front Knee Too Far Forward"
    case backNotStraight = "❌ Keep Torso Upright"
    case notDeep       = "❌ Lower Back Knee More"
    case detecting     = "🔍 Detecting..."
    case notVisible    = "📷 Full Body Not Visible"
}

enum LungePhase { case standing, descending, bottom, ascending }

struct LungeResult {
    var issue: LungeIssue = .detecting
    var postureScore: Int = 100
    var kneeAngle: Double = 180
    var hipAngle: Double  = 180
    var torsoAngle: Double = 90
    var kneeOk   = true
    var hipOk    = true
    var torsoOk  = true
}

final class LungeViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = LungeResult()
    @Published var reps = 0
    @Published var phase: LungePhase = .standing
    @Published var phaseText = "Standing"
    @Published var phaseColor: Color = .white
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showBadRepFlash = false
    @Published var badRepReason = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    private var frameBuffer: [LungeResult] = []
    private var lastKnee: Double = 180
    private var bottomReached = false
    private var lungeStarted = false
    private var validBottomFrames = 0
    private var validStandFrames = 0
    private var hadKneeError = false
    private var kneeErrorFrames = 0
    private var alertTimer: Timer?

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { g in
            guard g else { return }
            DispatchQueue.global(qos: .userInitiated).async { self.setupCamera() }
        }
    }
    func stop() { session.stopRunning() }
    func resetReps() {
        DispatchQueue.main.async {
            self.reps = 0; self.bottomReached = false; self.lungeStarted = false
            self.phase = .standing; self.phaseText = "Standing"; self.phaseColor = .white
            self.validBottomFrames = 0; self.validStandFrames = 0
            self.hadKneeError = false; self.kneeErrorFrames = 0
        }
    }
    func switchCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); return }
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
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "lungeQueue"))
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration(); session.startRunning()
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
            r.torsoOk = torso >= 60  // torso should stay upright (> 60° from horizontal)
        } else { r.torsoOk = true }
        r.kneeOk = abs(kn.x - an.x) <= 0.20  // knee shouldn't track past ankle
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
        sm.kneeAngle   = frameBuffer.map { $0.kneeAngle   }.reduce(0,+) / n
        sm.hipAngle    = frameBuffer.map { $0.hipAngle    }.reduce(0,+) / n
        sm.torsoAngle  = frameBuffer.map { $0.torsoAngle  }.reduce(0,+) / n
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
                if hadKneeError {
                    DispatchQueue.main.async {
                        self.badRepReason = "Front knee too far forward"
                        self.showBadRepFlash = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.showBadRepFlash = false }
                    }
                } else {
                    DispatchQueue.main.async { self.reps += 1 }
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

        // FormRuleEngine: knee-over-toe + torso lean thresholds
        if sm.issue == .correct, let ruleMsg = ruleEngineAlert(joints: self.bodyPoints, exercise: .lunge) {
            fireAlert(ruleMsg)
        }
        if !sm.torsoOk   { sm.issue = .backNotStraight }
        else if !sm.kneeOk { sm.issue = .kneeOverToe }
        else if !sm.hipOk  { sm.issue = .notDeep }
        else               { sm.issue = .correct }
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

struct LungeCameraView: View {
    @StateObject private var vm = LungeViewModel()
    var body: some View { lungeUI }
@ViewBuilder private var lungeTopBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Lunge AI").font(.title2.bold()).foregroundColor(.white)
                Text("Real-Time Form Check").font(.caption).foregroundColor(.white.opacity(0.7))
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
    @ViewBuilder private var lungeBottomPanel: some View {
        VStack(spacing: 18) {
            Text(vm.result.issue.rawValue).font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                LiveAngleCard(title: "Knee", angle: vm.result.kneeAngle, isOk: vm.result.hipOk, idealRange: "< 105°")
                LiveAngleCard(title: "Torso", angle: vm.result.torsoAngle, isOk: vm.result.torsoOk, idealRange: "> 60°")
            }
            HStack(spacing: 50) {
                VStack {
                    Text("\(vm.reps)").font(.system(size: 50, weight: .bold)).foregroundColor(.white)
                    Text("REPS").foregroundColor(.white.opacity(0.7))
                }
                VStack {
                    Text(vm.phaseText).font(.title3.bold()).foregroundColor(vm.phaseColor)
                    Text("PHASE").foregroundColor(.white.opacity(0.7))
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
    @ViewBuilder private var lungeUI: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            SimpleSkeleton(bodyPoints: vm.bodyPoints, joints: [.leftHip,.rightHip,.leftKnee,.rightKnee,.leftAnkle,.rightAnkle], isOk: vm.result.kneeOk && vm.result.torsoOk).ignoresSafeArea()
            VStack {
                lungeTopBar
                Spacer()
                if vm.showAlert { LiveFormBanner(message: vm.alertMessage).transition(.move(edge: .top).combined(with: .opacity)) }
                Spacer()
                lungeBottomPanel
            }
            if vm.showBadRepFlash { BadRepFlash(reason: vm.badRepReason) }
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .animation(.spring(response: 0.4), value: vm.showAlert)
    }

}
// ─────────────────────────────────────────────────────────────────────────────
// MARK: - GLUTE BRIDGE
// ─────────────────────────────────────────────────────────────────────────────

enum GluteBridgeIssue: String {
    case correct    = "✅ Perfect Bridge"
    case notHigh    = "❌ Drive Hips Higher"
    case notLevel   = "❌ Keep Hips Level"
    case detecting  = "🔍 Detecting..."
    case notVisible = "📷 Full Body Not Visible"
}

enum BridgePhase { case down, raising, top, lowering }

struct GluteBridgeResult {
    var issue: GluteBridgeIssue = .detecting
    var postureScore: Int = 100
    var hipAngle: Double = 180     // hip extension angle
    var kneeAngle: Double = 90
    var hipOk  = true
    var kneeOk = true
}

final class GluteBridgeViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = GluteBridgeResult()
    @Published var reps = 0
    @Published var phase: BridgePhase = .down
    @Published var phaseText = "Down"
    @Published var phaseColor: Color = .white
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    private var frameBuffer: [GluteBridgeResult] = []
    private var lastHip: Double = 180
    private var topReached = false
    private var repStarted = false
    private var validTopFrames = 0
    private var validDownFrames = 0
    private var alertTimer: Timer?

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { g in
            guard g else { return }
            DispatchQueue.global(qos: .userInitiated).async { self.setupCamera() }
        }
    }
    func stop() { session.stopRunning() }
    func resetReps() {
        DispatchQueue.main.async {
            self.reps = 0; self.topReached = false; self.repStarted = false
            self.phase = .down; self.phaseText = "Down"; self.phaseColor = .white
            self.validTopFrames = 0; self.validDownFrames = 0
        }
    }
    func switchCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); return }
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
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "bridgeQueue"))
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration(); session.startRunning()
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
        var r = GluteBridgeResult()
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
        }
        // At top of bridge: hip angle should be > 160 (hips fully extended = straight body)
        r.hipOk  = r.hipAngle >= 150 || phase != .top
        r.kneeOk = r.kneeAngle >= 80 && r.kneeAngle <= 110

        var score = 100
        if !r.hipOk  { score -= 35 }
        if !r.kneeOk { score -= 20 }
        r.postureScore = max(score, 0)

        frameBuffer.append(r)
        if frameBuffer.count > 7 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        var sm = r
        sm.hipAngle  = frameBuffer.map { $0.hipAngle  }.reduce(0,+) / n
        sm.kneeAngle = frameBuffer.map { $0.kneeAngle }.reduce(0,+) / n
        sm.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)

        // Hip rising (hip angle DECREASING as hips come up)
        if sm.hipAngle < 165 && sm.hipAngle < lastHip { repStarted = true }
        if repStarted && sm.hipAngle <= 155 {
            validTopFrames += 1
            if validTopFrames >= 3 { topReached = true }
        }
        if topReached && sm.hipAngle > lastHip && sm.hipAngle >= 168 {
            validDownFrames += 1
            if validDownFrames >= 2 {
                DispatchQueue.main.async { self.reps += 1 }
                topReached = false; repStarted = false; validTopFrames = 0; validDownFrames = 0
            }
        } else { validDownFrames = 0 }
        lastHip = sm.hipAngle

        DispatchQueue.main.async {
            if sm.hipAngle <= 155 {
                self.phase = .top; self.phaseText = "Top ✅"; self.phaseColor = .green
            } else if sm.hipAngle < 165 && sm.hipAngle < self.lastHip {
                self.phase = .raising; self.phaseText = "Raising"; self.phaseColor = .yellow
            } else {
                self.phase = .down; self.phaseText = "Down"; self.phaseColor = .white
            }
        }

        if !sm.hipOk && phase == .top { fireAlert("Drive Hips Higher — Squeeze Glutes!") }
        else { DispatchQueue.main.async { self.showAlert = false } }

        if sm.issue != .notHigh, let ruleMsg = ruleEngineAlert(joints: self.bodyPoints, exercise: .gluteBridge) {
            fireAlert(ruleMsg)
        }
        if !sm.hipOk { sm.issue = .notHigh } else { sm.issue = .correct }
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

struct GluteBridgeCameraView: View {
    @StateObject private var vm = GluteBridgeViewModel()
    var body: some View { gluteBridgeUI }
    @ViewBuilder private var gluteTopBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Glute Bridge AI").font(.title2.bold()).foregroundColor(.white)
                Text("Drive Those Hips!").font(.caption).foregroundColor(.white.opacity(0.7))
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
    @ViewBuilder private var gluteBottomPanel: some View {
        VStack(spacing: 18) {
            Text(vm.result.issue.rawValue).font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                LiveAngleCard(title: "Hip Ext.", angle: vm.result.hipAngle, isOk: vm.result.hipOk, idealRange: "< 155°")
                LiveAngleCard(title: "Knee", angle: vm.result.kneeAngle, isOk: vm.result.kneeOk, idealRange: "80°-110°")
            }
            HStack(spacing: 50) {
                VStack {
                    Text("\(vm.reps)").font(.system(size: 50, weight: .bold)).foregroundColor(.white)
                    Text("REPS").foregroundColor(.white.opacity(0.7))
                }
                VStack {
                    Text(vm.phaseText).font(.title3.bold()).foregroundColor(vm.phaseColor)
                    Text("PHASE").foregroundColor(.white.opacity(0.7))
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
    @ViewBuilder private var gluteBridgeUI: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            SimpleSkeleton(bodyPoints: vm.bodyPoints, joints: [.leftHip,.rightHip,.leftKnee,.rightKnee,.leftAnkle,.rightAnkle,.leftShoulder,.rightShoulder], isOk: vm.result.hipOk).ignoresSafeArea()
            VStack {
                gluteTopBar
                Spacer()
                if vm.showAlert { LiveFormBanner(message: vm.alertMessage).transition(.move(edge: .top).combined(with: .opacity)) }
                Spacer()
                gluteBottomPanel
            }
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .animation(.spring(response: 0.4), value: vm.showAlert)
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
    func stop() { session.stopRunning() }
    func resetReps() { DispatchQueue.main.async { self.reps = 0; self.driveCount = 0 } }
    func switchCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); return }
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
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
            SimpleSkeleton(bodyPoints: vm.bodyPoints, joints: [.leftShoulder,.rightShoulder,.leftHip,.rightHip,.leftKnee,.rightKnee,.leftAnkle,.rightAnkle], isOk: vm.result.hipOk).ignoresSafeArea()
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

enum HighKneesIssue: String {
    case correct    = "✅ Great Knees!"
    case notHighEnough = "❌ Lift Knees Higher"
    case leaningBack   = "❌ Keep Torso Upright"
    case detecting  = "🔍 Detecting..."
    case notVisible = "📷 Full Body Not Visible"
}

struct HighKneesResult {
    var issue: HighKneesIssue = .detecting
    var postureScore: Int = 100
    var kneeHeight: Double = 0   // relative knee height vs hip
    var torsoAngle: Double = 90
    var kneeOk  = true
    var torsoOk = true
}

final class HighKneesViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = HighKneesResult()
    @Published var reps = 0
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    private var frameBuffer: [HighKneesResult] = []
    private var lastKneeHeight: Double = 0
    private var alertTimer: Timer?
    private var kneeLiftCount = 0

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { g in
            guard g else { return }
            DispatchQueue.global(qos: .userInitiated).async { self.setupCamera() }
        }
    }
    func stop() { session.stopRunning() }
    func resetReps() { DispatchQueue.main.async { self.reps = 0; self.kneeLiftCount = 0 } }
    func switchCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); return }
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
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "hkQueue"))
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration(); session.startRunning()
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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
        var r = HighKneesResult()
        let leftConf  = (points[.leftHip]?.confidence ?? 0) + (points[.leftKnee]?.confidence ?? 0)
        let rightConf = (points[.rightHip]?.confidence ?? 0) + (points[.rightKnee]?.confidence ?? 0)
        let useLeft   = leftConf >= rightConf
        let shK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let hpK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let knK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee     : .rightKnee

        for j in [hpK, knK] {
            guard let p = points[j], p.confidence > 0.35 else { r.issue = .notVisible; DispatchQueue.main.async { self.result = r }; return }
        }
        let hp = points[hpK]!.location, kn = points[knK]!.location
        // Knee height relative to hip: positive = knee above hip
        r.kneeHeight = hp.y - kn.y   // in Vision coords, y increases downward, so higher knee = smaller y
        r.kneeOk = r.kneeHeight >= 0.05  // knee should reach at least to hip height

        if let sh = points[shK], sh.confidence > 0.3 {
            let torso = abs(atan2(sh.location.y - hp.y, sh.location.x - hp.x) * 180 / .pi)
            r.torsoAngle = torso
            r.torsoOk = torso >= 55
        } else { r.torsoOk = true }

        var score = 100
        if !r.kneeOk  { score -= 30 }
        if !r.torsoOk { score -= 25 }
        r.postureScore = max(score, 0)

        frameBuffer.append(r)
        if frameBuffer.count > 5 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        var sm = r
        sm.kneeHeight = frameBuffer.map { $0.kneeHeight }.reduce(0,+) / n
        sm.torsoAngle = frameBuffer.map { $0.torsoAngle }.reduce(0,+) / n
        sm.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)

        // Count: knee peak then return
        if sm.kneeHeight > lastKneeHeight + 0.04 && lastKneeHeight < 0.02 {
            kneeLiftCount += 1
            DispatchQueue.main.async { self.reps = self.kneeLiftCount / 2 }
        }
        lastKneeHeight = sm.kneeHeight

        if !sm.kneeOk  { fireAlert("Lift Knees To Hip Height!") }
        else if !sm.torsoOk { fireAlert("Don't Lean Back — Stay Upright!") }
        else { DispatchQueue.main.async { self.showAlert = false } }

        if sm.issue == .correct, let ruleMsg = ruleEngineAlert(joints: self.bodyPoints, exercise: .highKnees) {
            fireAlert(ruleMsg)
        }
        if !sm.torsoOk  { sm.issue = .leaningBack }
        else if !sm.kneeOk { sm.issue = .notHighEnough }
        else               { sm.issue = .correct }
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

struct HighKneesCameraView: View {
    @StateObject private var vm = HighKneesViewModel()
    var body: some View { highKneesUI }
    @ViewBuilder private var hkTopBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("High Knees AI").font(.title2.bold()).foregroundColor(.white)
                Text("Drive Knees to Hip Height").font(.caption).foregroundColor(.white.opacity(0.7))
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
    @ViewBuilder private var hkBottomPanel: some View {
        VStack(spacing: 18) {
            Text(vm.result.issue.rawValue).font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
            LiveAngleCard(title: "Torso", angle: vm.result.torsoAngle, isOk: vm.result.torsoOk, idealRange: "> 55°")
            HStack(spacing: 50) {
                VStack {
                    Text("\(vm.reps)").font(.system(size: 50, weight: .bold)).foregroundColor(.white)
                    Text("REPS").foregroundColor(.white.opacity(0.7))
                }
                VStack {
                    Text(vm.result.kneeOk ? "Great ✅" : "Fix Form").font(.title3.bold()).foregroundColor(vm.result.kneeOk ? Color.green : Color.red)
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
    @ViewBuilder private var highKneesUI: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            SimpleSkeleton(bodyPoints: vm.bodyPoints, joints: [.leftHip,.rightHip,.leftKnee,.rightKnee,.leftAnkle,.rightAnkle], isOk: vm.result.kneeOk && vm.result.torsoOk).ignoresSafeArea()
            VStack {
                hkTopBar
                Spacer()
                if vm.showAlert { LiveFormBanner(message: vm.alertMessage).transition(.move(edge: .top).combined(with: .opacity)) }
                Spacer()
                hkBottomPanel
            }
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
        .animation(.spring(response: 0.4), value: vm.showAlert)
    }

}
// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SHARED SKELETON OVERLAY
// ─────────────────────────────────────────────────────────────────────────────

struct SimpleSkeleton: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let joints: [VNHumanBodyPoseObservation.JointName]
    let isOk: Bool

    private let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.nose, .neck), (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.neck, .root), (.root, .leftHip), (.root, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
    ]

    // Split into sub-views to avoid type-check timeout
    var body: some View { skeletonCanvas }

    @ViewBuilder private var skeletonCanvas: some View {
        GeometryReader { geo in
            ZStack {
                bonesLayer(geo: geo)
                jointsLayer(geo: geo)
            }
        }
    }

    @ViewBuilder private func bonesLayer(geo: GeometryProxy) -> some View {
        ForEach(Array(connections.enumerated()), id: \.offset) { _, conn in
            boneView(conn: conn, geo: geo)
        }
    }

    @ViewBuilder private func boneView(
        conn: (VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName),
        geo: GeometryProxy
    ) -> some View {
        if let p1 = bodyPoints[conn.0], let p2 = bodyPoints[conn.1] {
            let start = CGPoint(x: p1.x * geo.size.width, y: p1.y * geo.size.height)
            let end   = CGPoint(x: p2.x * geo.size.width, y: p2.y * geo.size.height)
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(isOk ? Color.green : Color.red,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round))
        }
    }

    @ViewBuilder private func jointsLayer(geo: GeometryProxy) -> some View {
        ForEach(Array(bodyPoints.keys), id: \.self) { joint in
            jointDot(joint: joint, geo: geo)
        }
    }

    @ViewBuilder private func jointDot(
        joint: VNHumanBodyPoseObservation.JointName,
        geo: GeometryProxy
    ) -> some View {
        if let pt = bodyPoints[joint] {
            Circle()
                .fill(isOk ? Color.green : Color.red)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                .position(x: pt.x * geo.size.width, y: pt.y * geo.size.height)
        }
    }
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SQUAT — Full implementation from ContentView.swift
// Better angle analysis, per-joint skeleton coloring, bad-rep detection.
// ─────────────────────────────────────────────────────────────────────────────

// MARK: - Squat posture issue
enum SquatIssue: String {
    case correct         = "✅ Perfect Squat"
    case kneesNotDeep    = "❌ Go Lower"
    case backNotStraight = "❌ Keep Back Straight"
    case hipTooHigh      = "❌ Lower Your Hips"
    case kneesOverToes   = "❌ Knees Too Forward"
    case detecting       = "🔍 Detecting..."
    case notVisible      = "📷 Full Body Not Visible"
}

// MARK: - Squat phase
enum SquatPhase { case standing, descending, bottom, ascending }

// MARK: - Posture result
struct PostureResult {
    var issue: SquatIssue = .detecting
    var postureScore: Int = 100
    var kneeAngle: Double = 180
    var hipAngle: Double = 180
    var spineAngle: Double = 0
    var kneeToeOffset: Double = 0
    var trackedLeftSide: Bool = true
    var kneeOk  = true
    var hipOk   = true
    var spineOk = true
    var ankleOk = true
    var formIsValid: Bool { kneeOk && hipOk && spineOk && ankleOk }
}

// MARK: - Squat Camera View
struct SquatCameraView: View {
    @StateObject private var viewModel = SquatViewModel()
    var body: some View { squatContent }

    @ViewBuilder private var squatContent: some View {
        ZStack {
            ExerciseSessionPreview(session: viewModel.session).ignoresSafeArea()
            SquatSkeletonOverlay(bodyPoints: viewModel.bodyPoints, result: viewModel.postureResult)
                .ignoresSafeArea()
            VStack {
                squatTopBar
                Spacer()
                if viewModel.showFormAlert {
                    FormAlertBanner(message: viewModel.formAlertMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: viewModel.showFormAlert)
                }
                Spacer()
                squatBottomPanel
            }
            if viewModel.showBadRepFlash {
                Color.red.opacity(0.25).ignoresSafeArea().allowsHitTesting(false)
                    .transition(.opacity).animation(.easeOut(duration: 0.3), value: viewModel.showBadRepFlash)
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
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    private var squatTopBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Squat AI").font(.title2.bold()).foregroundColor(.white)
                Text("Real-Time Form Check").font(.caption).foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            Button { viewModel.switchCamera() } label: {
                Image(systemName: "camera.rotate").font(.title2).foregroundColor(.white)
                    .padding(12).background(Color.white.opacity(0.2)).clipShape(Circle())
            }
            ZStack {
                Circle().stroke(Color.white.opacity(0.2), lineWidth: 5).frame(width: 65, height: 65)
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.postureResult.postureScore) / 100)
                    .stroke(squatScoreColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 65, height: 65).rotationEffect(.degrees(-90))
                Text("\(viewModel.postureResult.postureScore)").font(.headline.bold()).foregroundColor(.white)
            }
        }
        .padding().background(.black.opacity(0.65)).cornerRadius(20).padding()
    }

    private var squatBottomPanel: some View {
        VStack(spacing: 18) {
            Text(viewModel.postureResult.issue.rawValue)
                .font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                AngleCard(title: "Knee",  angle: viewModel.postureResult.kneeAngle,  isOk: viewModel.postureResult.kneeOk,  idealRange: "70°-92°")
                AngleCard(title: "Hip",   angle: viewModel.postureResult.hipAngle,   isOk: viewModel.postureResult.hipOk,   idealRange: "< 110°")
                AngleCard(title: "Back",  angle: viewModel.postureResult.spineAngle, isOk: viewModel.postureResult.spineOk, idealRange: "15°-60°")
            }
            HStack(spacing: 50) {
                VStack {
                    Text("\(viewModel.reps)").font(.system(size: 50, weight: .bold)).foregroundColor(.white)
                    Text("REPS").foregroundColor(.white.opacity(0.7))
                }
                VStack {
                    Text(viewModel.phaseText).font(.title3.bold()).foregroundColor(viewModel.phaseColor)
                    Text("PHASE").foregroundColor(.white.opacity(0.7))
                }
                Button { viewModel.resetReps() } label: {
                    VStack {
                        Image(systemName: "arrow.counterclockwise").font(.title2).foregroundColor(.white)
                        Text("RESET").foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding().background(.black.opacity(0.75)).cornerRadius(22).padding()
    }

    private var squatScoreColor: Color {
        let s = viewModel.postureResult.postureScore
        if s >= 80 { return .green }
        if s >= 55 { return .yellow }
        return .red
    }
}

// MARK: - Form Alert Banner
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

// MARK: - Angle Card
struct AngleCard: View {
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
        .background(isOk ? Color.green.opacity(0.15) : Color.red.opacity(0.15)).cornerRadius(12)
    }
}

// MARK: - Squat Skeleton Overlay
struct SquatSkeletonOverlay: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let result: PostureResult

    var body: some View { squatSkeletonBody }

    @ViewBuilder private var squatSkeletonBody: some View {
        GeometryReader { geo in
            ZStack {
                squatBones(geo: geo)
                squatJoints(geo: geo)
            }
        }
    }

    private var shoulder: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftShoulder : .rightShoulder }
    private var hip:      VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftHip      : .rightHip }
    private var knee:     VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftKnee     : .rightKnee }
    private var ankle:    VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftAnkle    : .rightAnkle }

    @ViewBuilder private func squatBones(geo: GeometryProxy) -> some View {
        squatLine(j1: shoulder, j2: hip,   geo: geo, ok: result.spineOk)
        squatLine(j1: hip,      j2: knee,  geo: geo, ok: result.hipOk)
        squatLine(j1: knee,     j2: ankle, geo: geo, ok: result.ankleOk)
    }

    @ViewBuilder private func squatLine(
        j1: VNHumanBodyPoseObservation.JointName,
        j2: VNHumanBodyPoseObservation.JointName,
        geo: GeometryProxy,
        ok: Bool
    ) -> some View {
        if let p1 = bodyPoints[j1], let p2 = bodyPoints[j2] {
            Path { path in
                path.move(to: CGPoint(x: p1.x * geo.size.width, y: p1.y * geo.size.height))
                path.addLine(to: CGPoint(x: p2.x * geo.size.width, y: p2.y * geo.size.height))
            }
            .stroke(ok ? Color.green : Color.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }

    @ViewBuilder private func squatJoints(geo: GeometryProxy) -> some View {
        ForEach([shoulder, hip, knee, ankle], id: \.self) { joint in
            squatDot(joint: joint, geo: geo)
        }
    }

    @ViewBuilder private func squatDot(
        joint: VNHumanBodyPoseObservation.JointName,
        geo: GeometryProxy
    ) -> some View {
        if let point = bodyPoints[joint] {
            Circle()
                .fill(squatDotColor(for: joint))
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                .position(x: point.x * geo.size.width, y: point.y * geo.size.height)
        }
    }

    private func squatDotColor(for joint: VNHumanBodyPoseObservation.JointName) -> Color {
        switch joint {
        case .leftShoulder, .rightShoulder: return result.spineOk ? .green : .red
        case .leftHip,      .rightHip:      return result.hipOk   ? .green : .red
        case .leftKnee,     .rightKnee:     return result.kneeOk  ? .green : .red
        case .leftAnkle,    .rightAnkle:    return result.ankleOk ? .green : .red
        default:                            return .white
        }
    }
}

// MARK: - Squat View Model
final class SquatViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession()
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var postureResult = PostureResult()
    @Published var reps = 0
    @Published var currentPhase: SquatPhase = .standing
    @Published var phaseText = "Standing"
    @Published var phaseColor: Color = .white
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var showFormAlert = false
    @Published var formAlertMessage = ""
    @Published var showBadRepFlash = false
    @Published var badRepReason = ""

    private var frameBuffer: [PostureResult] = []
    private var lastKneeAngle: Double = 180
    private var bottomReached = false
    private var squatStarted = false
    private var validBottomFrames = 0
    private var validStandingFrames = 0
    private var stableIssueFrames = 0
    private var lastIssue: SquatIssue = .detecting
    private var alertTimer: Timer?
    private var spineErrorFrames = 0
    private var ankleErrorFrames = 0
    private var hipErrorFrames   = 0
    private var hadSpineError = false
    private var hadHipError   = false
    private var hadAnkleError = false
    private var hadKneeError  = false

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { return }
            DispatchQueue.global(qos: .userInitiated).async { self.setupCamera() }
        }
    }
    func stop() { session.stopRunning() }

    func resetReps() {
        DispatchQueue.main.async {
            self.reps = 0; self.bottomReached = false; self.squatStarted = false
            self.currentPhase = .standing; self.phaseText = "Standing"; self.phaseColor = .white
            self.validBottomFrames = 0; self.validStandingFrames = 0
            self.spineErrorFrames = 0; self.ankleErrorFrames = 0; self.hipErrorFrames = 0
            self.hadSpineError = false; self.hadHipError = false
            self.hadAnkleError = false; self.hadKneeError = false
        }
    }

    private func setupCamera() {
        guard !session.isRunning else { return }
        session.beginConfiguration(); session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let input  = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "squatVideoQueue"))
        output.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration(); session.startRunning()
    }

    func switchCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            let newPos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPos),
                  let inp = try? AVCaptureDeviceInput(device: dev),
                  self.session.canAddInput(inp) else { self.session.commitConfiguration(); return }
            self.session.addInput(inp); self.session.commitConfiguration()
            DispatchQueue.main.async { self.cameraPosition = newPos }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let orientation: CGImagePropertyOrientation = cameraPosition == .front ? .leftMirrored : .right
        analyzeFrame(pixelBuffer: pixelBuffer, orientation: orientation)
    }

    private func analyzeFrame(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return }
            let points = try observation.recognizedPoints(.all)
            updateBodyPoints(points)
            let rawResult = analyzeSquatPosture(points)
            if rawResult.issue == .notVisible { DispatchQueue.main.async { self.postureResult = rawResult }; return }
            var smoothed = smoothResult(rawResult)
            updatePhaseAndReps(smoothedResult: smoothed)
            if smoothed.issue == lastIssue { stableIssueFrames += 1 } else { stableIssueFrames = 0; lastIssue = smoothed.issue }
            if stableIssueFrames < 3 { smoothed.issue = postureResult.issue }
            updateFormAlert(result: smoothed)
            DispatchQueue.main.async { self.postureResult = smoothed }
        } catch {}
    }

    private func updateFormAlert(result: PostureResult) {
        guard currentPhase == .descending || currentPhase == .bottom else {
            DispatchQueue.main.async { self.showFormAlert = false }; return
        }
        var message: String? = nil
        if !result.spineOk      { message = "Keep Your Back Straight!" }
        else if !result.ankleOk { message = "Knees Too Far Forward!" }
        else if !result.hipOk   { message = "Lower Your Hips More!" }
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

    private func updatePhaseAndReps(smoothedResult: PostureResult) {
        let kneeAngle = smoothedResult.kneeAngle
        let prev = lastKneeAngle
        var nextPhase = currentPhase
        var addRep = false

        if currentPhase == .descending || currentPhase == .bottom {
            if !smoothedResult.spineOk { spineErrorFrames += 1 } else { spineErrorFrames = 0 }
            if !smoothedResult.ankleOk { ankleErrorFrames += 1 } else { ankleErrorFrames = 0 }
            if !smoothedResult.hipOk   { hipErrorFrames += 1 }   else { hipErrorFrames = 0 }
            if spineErrorFrames >= 3 { hadSpineError = true }
            if ankleErrorFrames >= 3 { hadAnkleError = true }
            if hipErrorFrames   >= 3 { hadHipError   = true }
            if !smoothedResult.kneeOk { hadKneeError = true }
        }
        if kneeAngle < 145 && prev > kneeAngle && !bottomReached { nextPhase = .descending; squatStarted = true }
        validBottomFrames = kneeAngle <= 95 ? validBottomFrames + 1 : 0
        if validBottomFrames >= 3 { nextPhase = .bottom; bottomReached = true }
        if bottomReached && kneeAngle > prev && kneeAngle < 152 { nextPhase = .ascending }
        if squatStarted && kneeAngle >= 152 {
            validStandingFrames += 1
            if validStandingFrames >= 2 {
                if bottomReached {
                    if !hadAnkleError { addRep = true } else { triggerBadRepFeedback() }
                }
                nextPhase = .standing; bottomReached = false; squatStarted = false
                validStandingFrames = 0; validBottomFrames = 0
                spineErrorFrames = 0; ankleErrorFrames = 0; hipErrorFrames = 0
                hadSpineError = false; hadHipError = false; hadAnkleError = false; hadKneeError = false
            }
        } else { validStandingFrames = 0 }
        lastKneeAngle = kneeAngle
        DispatchQueue.main.async {
            if addRep { self.reps += 1 }
            self.currentPhase = nextPhase
            switch nextPhase {
            case .standing:   self.phaseText = "Standing";        self.phaseColor = .white
            case .descending: self.phaseText = "Going Down";      self.phaseColor = .yellow
            case .bottom:     self.phaseText = "Perfect Depth ✅"; self.phaseColor = .green
            case .ascending:  self.phaseText = "Coming Up";       self.phaseColor = .blue
            }
        }
    }

    private func triggerBadRepFeedback() {
        var reasons: [String] = []
        if hadAnkleError { reasons.append("Knees too forward") }
        if hadHipError   { reasons.append("Hips too high") }
        guard !reasons.isEmpty else { DispatchQueue.main.async { self.reps += 1 }; return }
        let reason = reasons.joined(separator: " • ")
        DispatchQueue.main.async {
            self.badRepReason = reason; self.showBadRepFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { self.showBadRepFlash = false }
        }
    }

    private func analyzeSquatPosture(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> PostureResult {
        var result = PostureResult()
        let useLeft = betterSide(points)
        result.trackedLeftSide = useLeft
        let shoulderKey: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let hipKey:      VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let kneeKey:     VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee     : .rightKnee
        let ankleKey:    VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle    : .rightAnkle
        for joint in [shoulderKey, hipKey, kneeKey, ankleKey] {
            guard let p = points[joint], p.confidence > 0.4 else { result.issue = .notVisible; return result }
        }
        let shoulder = points[shoulderKey]!.location
        let hip      = points[hipKey]!.location
        let knee     = points[kneeKey]!.location
        let ankle    = points[ankleKey]!.location
        result.kneeAngle  = squatAngle(first: hip, middle: knee, last: ankle)
        result.hipAngle   = squatAngle(first: shoulder, middle: hip, last: knee)
        let torsoAngle    = abs(atan2(shoulder.y - hip.y, shoulder.x - hip.x) * 180 / .pi)
        result.spineAngle = torsoAngle
        result.kneeToeOffset = knee.x - ankle.x
        let isSquatting = result.kneeAngle < 160
        guard isSquatting else {
            result.kneeOk = true; result.hipOk = true; result.spineOk = true; result.ankleOk = true
            result.issue = .correct; result.postureScore = 100; return result
        }
        result.ankleOk = abs(result.kneeToeOffset) <= 0.18
        result.spineOk = torsoAngle >= 15 && torsoAngle <= 65
        switch currentPhase {
        case .standing, .descending: result.kneeOk = true; result.hipOk = true
        case .bottom:     result.kneeOk = result.kneeAngle <= 92; result.hipOk = result.hipAngle <= 110
        case .ascending:  result.kneeOk = true; result.hipOk = result.hipAngle <= (result.kneeAngle + 35)
        }
        var score = 100
        if !result.kneeOk  { score -= 30 }
        if !result.hipOk   { score -= 20 }
        if !result.spineOk && currentPhase != .ascending { score -= 30 }
        if !result.ankleOk { score -= 20 }
        result.postureScore = max(score, 0)
        if !result.spineOk && currentPhase != .ascending { result.issue = .backNotStraight }
        else if !result.ankleOk { result.issue = .kneesOverToes }
        else if !result.hipOk   { result.issue = .hipTooHigh }
        else if !result.kneeOk  { result.issue = .kneesNotDeep }
        else                    { result.issue = .correct }
        return result
    }

    private func betterSide(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> Bool {
        let lTotal: Float = (points[.leftShoulder]?.confidence  ?? 0) + (points[.leftHip]?.confidence  ?? 0)
                          + (points[.leftKnee]?.confidence      ?? 0) + (points[.leftAnkle]?.confidence ?? 0)
        let rTotal: Float = (points[.rightShoulder]?.confidence ?? 0) + (points[.rightHip]?.confidence ?? 0)
                          + (points[.rightKnee]?.confidence     ?? 0) + (points[.rightAnkle]?.confidence ?? 0)
        return lTotal >= rTotal
    }

    private func updateBodyPoints(_ points: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var mapped: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (joint, point) in points where point.confidence > 0.3 {
            mapped[joint] = CGPoint(x: point.location.x, y: 1 - point.location.y)
        }
        DispatchQueue.main.async { self.bodyPoints = mapped }
    }

    private func squatAngle(first: CGPoint, middle: CGPoint, last: CGPoint) -> Double {
        let a = atan2(first.y - middle.y, first.x - middle.x)
        let b = atan2(last.y  - middle.y, last.x  - middle.x)
        var angle = abs((a - b) * 180 / .pi)
        if angle > 180 { angle = 360 - angle }
        return angle
    }

    private func smoothResult(_ result: PostureResult) -> PostureResult {
        frameBuffer.append(result)
        if frameBuffer.count > 8 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        var smoothed = result
        smoothed.kneeAngle    = frameBuffer.map(\.kneeAngle).reduce(0,+)   / n
        smoothed.hipAngle     = frameBuffer.map(\.hipAngle).reduce(0,+)    / n
        smoothed.spineAngle   = frameBuffer.map(\.spineAngle).reduce(0,+)  / n
        smoothed.postureScore = Int(Double(frameBuffer.map(\.postureScore).reduce(0,+)) / n)
        smoothed.trackedLeftSide = result.trackedLeftSide
        return smoothed
    }
}
