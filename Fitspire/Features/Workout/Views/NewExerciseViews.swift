//
//  NewExerciseViews.swift
//  Fitspire
//
//  Created by Navyashree Byregowda on 03/06/2026.
//

import SwiftUI
import AVFoundation
import Vision
import Combine

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
// ─────────────────────────────────────────────────────────────────────────────
// MARK: - GLUTE BRIDGE V2
// Side-on camera. Tracks hip extension, knee angle, spine.
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
// MARK: - MOUNTAIN CLIMBER
// Side-on. Tracks plank position + knee drive height.
// ─────────────────────────────────────────────────────────────────────────────

enum MCIssueV2: String {
    case correct    = "✅ Good Form — Keep Going!"
    case hipSag     = "❌ Keep Hips Level"
    case hipPike    = "❌ Lower Your Hips"
    case detecting  = "🔍 Detecting..."
    case notVisible = "📷 Full Body Not Visible"
}

struct MCResultV2 {
    var issue: MCIssueV2 = .detecting
    var postureScore: Int = 100
    var bodyAngle: Double = 180
    var kneeHeight: Double = 0
    var trackedLeftSide = true
    var bodyOk = true
}

final class MCViewModelV2: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "fitspire.mc.session", qos: .userInitiated)
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = MCResultV2()
    @Published var reps = 0
    @Published var phaseText = "Plank"; @Published var phaseColor: Color = .white
    @Published var showAlert = false; @Published var alertMessage = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    private var frameBuffer: [MCResultV2] = []
    private var lastKneeH: Double = 0
    private var kneePeaks = 0
    private var alertTimer: Timer?

    func start() { AVCaptureDevice.requestAccess(for: .video) { [weak self] g in guard g else { return }; self?.sessionQueue.async { self?.setup() } } }
    func stop() { sessionQueue.async { [weak self] in self?.session.stopRunning() } }
    func resetReps() { DispatchQueue.main.async { self.reps = 0; self.kneePeaks = 0 } }
    func switchCamera() {
        sessionQueue.async {
            let pos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); return }
            self.session.addInput(inp); self.session.commitConfiguration()
            self.session.startRunning()
            DispatchQueue.main.async { self.cameraPosition = pos }
        }
    }
    private func setup() {
        session.stopRunning(); session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }; session.outputs.forEach { session.removeOutput($0) }
        session.sessionPreset = .high
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let inp = try? AVCaptureDeviceInput(device: dev), session.canAddInput(inp) else { return }
        session.addInput(inp)
        let out = AVCaptureVideoDataOutput()
        out.setSampleBufferDelegate(self, queue: DispatchQueue(label: "mcQ"))
        out.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(out) { session.addOutput(out) }
        session.commitConfiguration(); session.startRunning()
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sb: CMSampleBuffer, from conn: AVCaptureConnection) {
        guard let px = CMSampleBufferGetImageBuffer(sb) else { return }
        let req = VNDetectHumanBodyPoseRequest()
        try? VNImageRequestHandler(cvPixelBuffer: px, orientation: cameraPosition == .front ? .leftMirrored : .right).perform([req])
        guard let obs = req.results?.first, let pts = try? obs.recognizedPoints(.all) else { return }
        updatePoints(pts)
        var raw = analyze(pts)
        if raw.issue == .notVisible { DispatchQueue.main.async { self.result = raw }; return }
        frameBuffer.append(raw); if frameBuffer.count > 6 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        raw.bodyAngle = frameBuffer.map { $0.bodyAngle }.reduce(0,+) / n
        raw.kneeHeight = frameBuffer.map { $0.kneeHeight }.reduce(0,+) / n
        raw.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)
        // Count reps: knee drive detection
        if raw.kneeHeight > lastKneeH + 0.06 && lastKneeH < 0.03 {
            kneePeaks += 1
            DispatchQueue.main.async { self.reps = self.kneePeaks / 2 }
        }
        lastKneeH = raw.kneeHeight
        let ph = raw.kneeHeight > 0.05 ? "Knee Drive ✅" : "Plank"
        let pc: Color = raw.kneeHeight > 0.05 ? .green : .white
        DispatchQueue.main.async { self.result = raw; self.phaseText = ph; self.phaseColor = pc }
        if !raw.bodyOk {
            DispatchQueue.main.async {
                self.alertMessage = raw.bodyAngle < 158 ? "Keep Hips Up — Don't Sag!" : "Lower Hips — Too High!"
                self.showAlert = true
                self.alertTimer?.invalidate()
                self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                    DispatchQueue.main.async { self.showAlert = false }
                }
            }
        } else { DispatchQueue.main.async { self.showAlert = false } }
    }
    private func analyze(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> MCResultV2 {
        var r = MCResultV2()
        let lC: Float = (pts[.leftShoulder]?.confidence ?? 0) + (pts[.leftHip]?.confidence ?? 0)
        let rC: Float = (pts[.rightShoulder]?.confidence ?? 0) + (pts[.rightHip]?.confidence ?? 0)
        let ul = lC >= rC; r.trackedLeftSide = ul
        let shK: VNHumanBodyPoseObservation.JointName = ul ? .leftShoulder : .rightShoulder
        let hpK: VNHumanBodyPoseObservation.JointName = ul ? .leftHip : .rightHip
        let anK: VNHumanBodyPoseObservation.JointName = ul ? .leftAnkle : .rightAnkle
        let knK: VNHumanBodyPoseObservation.JointName = ul ? .leftKnee : .rightKnee
        guard let sh = pts[shK], sh.confidence > 0.4,
              let hp = pts[hpK], hp.confidence > 0.4,
              let an = pts[anK], an.confidence > 0.4 else { r.issue = .notVisible; return r }
        r.bodyAngle = vAngle2(sh.location, hp.location, an.location)
        r.bodyOk = r.bodyAngle >= 155 && r.bodyAngle <= 205
        if let kn = pts[knK], kn.confidence > 0.3 {
            r.kneeHeight = hp.location.y - kn.location.y
        }
        var score = 100; if !r.bodyOk { score -= 45 }
        r.postureScore = max(score, 0)
        r.issue = !r.bodyOk ? (r.bodyAngle < 155 ? .hipSag : .hipPike) : .correct
        return r
    }
    private func updatePoints(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var m: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (j,p) in pts where p.confidence > 0.3 { m[j] = CGPoint(x: p.location.x, y: 1-p.location.y) }
        DispatchQueue.main.async { self.bodyPoints = m }
    }
    private func vAngle2(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let ab = atan2(a.y-b.y, a.x-b.x); let cb = atan2(c.y-b.y, c.x-b.x)
        var ang = abs((ab-cb) * 180.0 / Double.pi); if ang > 180 { ang = 360-ang }; return ang
    }
}

struct MountainClimberCameraViewV2: View {
    @StateObject private var vm = MCViewModelV2()
    var body: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            SimpleSkeletonOverlay(bodyPoints: vm.bodyPoints, isOk: vm.result.bodyOk).ignoresSafeArea()
            VStack {
                topBar(title: "Mountain Climber AI", subtitle: "Drive Knees In!")
                Spacer()
                if vm.showAlert { FormAlertBannerV2(message: vm.alertMessage) }
                Spacer()
                bottomPanel(
                    issue: vm.result.issue.rawValue,
                    cards: [
                        ("Body Line", vm.result.bodyAngle, vm.result.bodyOk, "155°-205°"),
                        ("Knee Drive", vm.result.kneeHeight*100, vm.result.kneeHeight > 0.04, "> 4%"),
                        ("Form", Double(vm.result.postureScore), vm.result.postureScore >= 70, "> 70")
                    ],
                    reps: vm.reps, phase: vm.phaseText, phaseColor: vm.phaseColor,
                    score: vm.result.postureScore, onReset: { vm.resetReps() }, onFlip: { vm.switchCamera() }
                )
            }
        }
        .onAppear { vm.start() }.onDisappear { vm.stop() }.navigationBarHidden(true)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - BURPEE
// Side-on. Tracks plank → squat → jump phases.
// ─────────────────────────────────────────────────────────────────────────────

enum BurpeeIssueV2: String {
    case correct    = "✅ Good Burpee!"
    case hipSag     = "❌ Keep Hips Level in Plank"
    case notDeep    = "❌ Squat Deeper"
    case detecting  = "🔍 Detecting..."
    case notVisible = "📷 Full Body Not Visible"
}

struct BurpeeResultV2 {
    var issue: BurpeeIssueV2 = .detecting
    var postureScore: Int = 100
    var kneeAngle: Double = 180
    var bodyAngle: Double = 180
    var trackedLeftSide = true
    var bodyOk = true; var kneeOk = true
}

final class BurpeeViewModelV2: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "fitspire.burpee.session", qos: .userInitiated)
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = BurpeeResultV2()
    @Published var reps = 0
    @Published var phaseText = "Standing"; @Published var phaseColor: Color = .white
    @Published var showAlert = false; @Published var alertMessage = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    private var frameBuffer: [BurpeeResultV2] = []
    private var lastKnee: Double = 180
    private var plankDetected = false
    private var squatDetected = false
    private var jumpDetected = false
    private var alertTimer: Timer?

    func start() { AVCaptureDevice.requestAccess(for: .video) { [weak self] g in guard g else { return }; self?.sessionQueue.async { self?.setup() } } }
    func stop() { sessionQueue.async { [weak self] in self?.session.stopRunning() } }
    func resetReps() { DispatchQueue.main.async { self.reps = 0; self.plankDetected = false; self.squatDetected = false; self.jumpDetected = false } }
    func switchCamera() {
        sessionQueue.async {
            let pos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); return }
            self.session.addInput(inp); self.session.commitConfiguration()
            self.session.startRunning()
            DispatchQueue.main.async { self.cameraPosition = pos }
        }
    }
    private func setup() {
        session.stopRunning(); session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }; session.outputs.forEach { session.removeOutput($0) }
        session.sessionPreset = .high
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let inp = try? AVCaptureDeviceInput(device: dev), session.canAddInput(inp) else { return }
        session.addInput(inp)
        let out = AVCaptureVideoDataOutput()
        out.setSampleBufferDelegate(self, queue: DispatchQueue(label: "burpeeQ"))
        out.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(out) { session.addOutput(out) }
        session.commitConfiguration(); session.startRunning()
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sb: CMSampleBuffer, from conn: AVCaptureConnection) {
        guard let px = CMSampleBufferGetImageBuffer(sb) else { return }
        let req = VNDetectHumanBodyPoseRequest()
        try? VNImageRequestHandler(cvPixelBuffer: px, orientation: cameraPosition == .front ? .leftMirrored : .right).perform([req])
        guard let obs = req.results?.first, let pts = try? obs.recognizedPoints(.all) else { return }
        updatePoints(pts)
        var raw = analyze(pts)
        if raw.issue == .notVisible { DispatchQueue.main.async { self.result = raw }; return }
        frameBuffer.append(raw); if frameBuffer.count > 6 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        raw.kneeAngle = frameBuffer.map { $0.kneeAngle }.reduce(0,+) / n
        raw.bodyAngle = frameBuffer.map { $0.bodyAngle }.reduce(0,+) / n
        raw.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)
        // Rep state machine: standing → plank → squat → jump → standing
        var phase = "Standing"
        var phaseC: Color = .white
        if raw.bodyAngle >= 158 && raw.kneeAngle >= 155 { // plank position
            if !plankDetected { plankDetected = true }
            phase = "Plank ✅"; phaseC = .cyan
        }
        if plankDetected && raw.kneeAngle <= 110 { // squat position
            if !squatDetected { squatDetected = true }
            phase = "Squat ✅"; phaseC = .green
        }
        if squatDetected && raw.kneeAngle >= 155 && raw.bodyAngle < 155 { // standing/jump
            if !jumpDetected {
                jumpDetected = true
                DispatchQueue.main.async { self.reps += 1 }
                plankDetected = false; squatDetected = false; jumpDetected = false
            }
            phase = "Jump! ✅"; phaseC = .yellow
        }
        DispatchQueue.main.async { self.result = raw; self.phaseText = phase; self.phaseColor = phaseC }
        lastKnee = raw.kneeAngle
    }
    private func analyze(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> BurpeeResultV2 {
        var r = BurpeeResultV2()
        let lC: Float = (pts[.leftShoulder]?.confidence ?? 0) + (pts[.leftHip]?.confidence ?? 0) + (pts[.leftKnee]?.confidence ?? 0)
        let rC: Float = (pts[.rightShoulder]?.confidence ?? 0) + (pts[.rightHip]?.confidence ?? 0) + (pts[.rightKnee]?.confidence ?? 0)
        let ul = lC >= rC; r.trackedLeftSide = ul
        let shK: VNHumanBodyPoseObservation.JointName = ul ? .leftShoulder : .rightShoulder
        let hpK: VNHumanBodyPoseObservation.JointName = ul ? .leftHip : .rightHip
        let knK: VNHumanBodyPoseObservation.JointName = ul ? .leftKnee : .rightKnee
        let anK: VNHumanBodyPoseObservation.JointName = ul ? .leftAnkle : .rightAnkle
        guard let sh = pts[shK], sh.confidence > 0.35,
              let hp = pts[hpK], hp.confidence > 0.35,
              let kn = pts[knK], kn.confidence > 0.35 else { r.issue = .notVisible; return r }
        if let an = pts[anK], an.confidence > 0.3 {
            r.kneeAngle = bAngle(hp.location, kn.location, an.location)
        }
        r.bodyAngle = bAngle(sh.location, hp.location, kn.location)
        r.bodyOk = r.bodyAngle >= 155 || r.kneeAngle < 140
        var score = 100; if !r.bodyOk { score -= 30 }
        r.postureScore = max(score, 0)
        r.issue = !r.bodyOk ? .hipSag : .correct
        return r
    }
    private func updatePoints(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var m: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (j,p) in pts where p.confidence > 0.3 { m[j] = CGPoint(x: p.location.x, y: 1-p.location.y) }
        DispatchQueue.main.async { self.bodyPoints = m }
    }
    private func bAngle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let ab = atan2(a.y-b.y, a.x-b.x); let cb = atan2(c.y-b.y, c.x-b.x)
        var ang = abs((ab-cb) * 180.0 / Double.pi); if ang > 180 { ang = 360-ang }; return ang
    }
}

struct BurpeeCameraViewV2: View {
    @StateObject private var vm = BurpeeViewModelV2()
    var body: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            SimpleSkeletonOverlay(bodyPoints: vm.bodyPoints, isOk: vm.result.bodyOk).ignoresSafeArea()
            VStack {
                topBar(title: "Burpee AI", subtitle: "Plank → Squat → Jump!")
                Spacer()
                if vm.showAlert { FormAlertBannerV2(message: vm.alertMessage) }
                Spacer()
                bottomPanel(
                    issue: vm.result.issue.rawValue,
                    cards: [
                        ("Knee", vm.result.kneeAngle, vm.result.kneeOk, "< 110°"),
                        ("Body", vm.result.bodyAngle, vm.result.bodyOk, "> 155°"),
                        ("Form", Double(vm.result.postureScore), vm.result.postureScore >= 70, "> 70")
                    ],
                    reps: vm.reps, phase: vm.phaseText, phaseColor: vm.phaseColor,
                    score: vm.result.postureScore, onReset: { vm.resetReps() }, onFlip: { vm.switchCamera() }
                )
            }
        }
        .onAppear { vm.start() }.onDisappear { vm.stop() }.navigationBarHidden(true)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - TRICEP DIP
// Side-on. Tracks elbow bend angle.
// ─────────────────────────────────────────────────────────────────────────────

enum TricepDipIssue: String {
    case correct    = "✅ Perfect Dip!"
    case notDeep    = "❌ Go Deeper — Bend Elbows More"
    case flaring    = "❌ Keep Elbows Behind You"
    case detecting  = "🔍 Detecting..."
    case notVisible = "📷 Full Body Not Visible"
}

struct TricepDipResult {
    var issue: TricepDipIssue = .detecting
    var postureScore: Int = 100
    var elbowAngle: Double = 180
    var trackedLeftSide = true
    var elbowOk = true; var depthOk = true
}

final class TricepDipViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "fitspire.tricdip.session", qos: .userInitiated)
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = TricepDipResult()
    @Published var reps = 0
    @Published var phaseText = "Up"; @Published var phaseColor: Color = .white
    @Published var showAlert = false; @Published var alertMessage = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    private var frameBuffer: [TricepDipResult] = []
    private var lastElbow: Double = 180
    private var bottomReached = false; private var repStarted = false
    private var validBottomFrames = 0; private var validTopFrames = 0
    private var alertTimer: Timer?

    func start() { AVCaptureDevice.requestAccess(for: .video) { [weak self] g in guard g else { return }; self?.sessionQueue.async { self?.setup() } } }
    func stop() { sessionQueue.async { [weak self] in self?.session.stopRunning() } }
    func resetReps() { DispatchQueue.main.async { self.reps = 0; self.bottomReached = false; self.repStarted = false; self.validBottomFrames = 0; self.validTopFrames = 0 } }
    func switchCamera() {
        sessionQueue.async {
            let pos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); return }
            self.session.addInput(inp); self.session.commitConfiguration()
            self.session.startRunning()
            DispatchQueue.main.async { self.cameraPosition = pos }
        }
    }
    private func setup() {
        session.stopRunning(); session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }; session.outputs.forEach { session.removeOutput($0) }
        session.sessionPreset = .high
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let inp = try? AVCaptureDeviceInput(device: dev), session.canAddInput(inp) else { return }
        session.addInput(inp)
        let out = AVCaptureVideoDataOutput()
        out.setSampleBufferDelegate(self, queue: DispatchQueue(label: "tricepQ"))
        out.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(out) { session.addOutput(out) }
        session.commitConfiguration(); session.startRunning()
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sb: CMSampleBuffer, from conn: AVCaptureConnection) {
        guard let px = CMSampleBufferGetImageBuffer(sb) else { return }
        let req = VNDetectHumanBodyPoseRequest()
        try? VNImageRequestHandler(cvPixelBuffer: px, orientation: cameraPosition == .front ? .leftMirrored : .right).perform([req])
        guard let obs = req.results?.first, let pts = try? obs.recognizedPoints(.all) else { return }
        updatePoints(pts)
        var raw = analyze(pts)
        if raw.issue == .notVisible { DispatchQueue.main.async { self.result = raw }; return }
        frameBuffer.append(raw); if frameBuffer.count > 8 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        raw.elbowAngle = frameBuffer.map { $0.elbowAngle }.reduce(0,+) / n
        raw.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)
        // Rep counting
        if raw.elbowAngle < 155 { repStarted = true }
        if repStarted && raw.elbowAngle <= 95 { validBottomFrames += 1; if validBottomFrames >= 3 { bottomReached = true } } else { validBottomFrames = 0 }
        if bottomReached && raw.elbowAngle >= 155 {
            validTopFrames += 1
            if validTopFrames >= 2 { DispatchQueue.main.async { self.reps += 1 }; bottomReached = false; repStarted = false; validBottomFrames = 0; validTopFrames = 0 }
        } else { validTopFrames = 0 }
        lastElbow = raw.elbowAngle
        let ph = raw.elbowAngle <= 95 ? "Deep ✅" : raw.elbowAngle < 155 ? "Dipping" : "Up"
        let pc: Color = raw.elbowAngle <= 95 ? .green : raw.elbowAngle < 155 ? .yellow : .white
        DispatchQueue.main.async { self.result = raw; self.phaseText = ph; self.phaseColor = pc }
        if !raw.elbowOk && raw.elbowAngle > 95 && repStarted {
            DispatchQueue.main.async {
                self.alertMessage = "Bend Elbows to 90° — Go Deeper!"
                self.showAlert = true
                self.alertTimer?.invalidate()
                self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                    DispatchQueue.main.async { self.showAlert = false }
                }
            }
        }
    }
    private func analyze(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> TricepDipResult {
        var r = TricepDipResult()
        let lC: Float = (pts[.leftShoulder]?.confidence ?? 0) + (pts[.leftElbow]?.confidence ?? 0) + (pts[.leftWrist]?.confidence ?? 0)
        let rC: Float = (pts[.rightShoulder]?.confidence ?? 0) + (pts[.rightElbow]?.confidence ?? 0) + (pts[.rightWrist]?.confidence ?? 0)
        let ul = lC >= rC; r.trackedLeftSide = ul
        let shK: VNHumanBodyPoseObservation.JointName = ul ? .leftShoulder : .rightShoulder
        let elK: VNHumanBodyPoseObservation.JointName = ul ? .leftElbow : .rightElbow
        let wrK: VNHumanBodyPoseObservation.JointName = ul ? .leftWrist : .rightWrist
        guard let sh = pts[shK], sh.confidence > 0.35,
              let el = pts[elK], el.confidence > 0.35,
              let wr = pts[wrK], wr.confidence > 0.35 else { r.issue = .notVisible; return r }
        r.elbowAngle = tAngle(sh.location, el.location, wr.location)
        r.elbowOk = r.elbowAngle <= 95
        r.depthOk = r.elbowAngle <= 95
        var score = 100; if !r.elbowOk { score -= 35 }
        r.postureScore = max(score, 0)
        r.issue = !r.elbowOk ? .notDeep : .correct
        return r
    }
    private func updatePoints(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var m: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (j,p) in pts where p.confidence > 0.3 { m[j] = CGPoint(x: p.location.x, y: 1-p.location.y) }
        DispatchQueue.main.async { self.bodyPoints = m }
    }
    private func tAngle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let ab = atan2(a.y - b.y, a.x - b.x)
        let cb = atan2(c.y - b.y, c.x - b.x)
        var ang = abs((ab - cb) * 180.0 / Double.pi)
        if ang > 180 { ang = 360 - ang }
        return ang
    }
}

struct TricepDipCameraView: View {
    @StateObject private var vm = TricepDipViewModel()
    var body: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            SimpleSkeletonOverlay(bodyPoints: vm.bodyPoints, isOk: vm.result.elbowOk).ignoresSafeArea()
            VStack {
                topBar(title: "Tricep Dip AI", subtitle: "Elbows to 90° — Drive Up!")
                Spacer()
                if vm.showAlert { FormAlertBannerV2(message: vm.alertMessage) }
                Spacer()
                bottomPanel(
                    issue: vm.result.issue.rawValue,
                    cards: [
                        ("Elbow", vm.result.elbowAngle, vm.result.elbowOk, "< 95°"),
                        ("Depth", vm.result.elbowAngle, vm.result.depthOk, "< 95°"),
                        ("Score", Double(vm.result.postureScore), vm.result.postureScore >= 70, "> 70")
                    ],
                    reps: vm.reps, phase: vm.phaseText, phaseColor: vm.phaseColor,
                    score: vm.result.postureScore, onReset: { vm.resetReps() }, onFlip: { vm.switchCamera() }
                )
            }
        }
        .onAppear { vm.start() }.onDisappear { vm.stop() }.navigationBarHidden(true)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HIGH KNEES V2
// Front-facing. Tracks knee height relative to hip.
// ─────────────────────────────────────────────────────────────────────────────

enum HKIssueV2: String {
    case correct       = "✅ Great Knees!"
    case notHigh       = "❌ Lift Knees to Hip Height"
    case leaningBack   = "❌ Keep Torso Upright"
    case detecting     = "🔍 Detecting..."
    case notVisible    = "📷 Full Body Not Visible"
}

struct HKResultV2 {
    var issue: HKIssueV2 = .detecting
    var postureScore: Int = 100
    var kneeHeight: Double = 0
    var torsoAngle: Double = 90
    var trackedLeftSide = true
    var kneeOk = true; var torsoOk = true
}

final class HKViewModelV2: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "fitspire.hkv2.session", qos: .userInitiated)
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = HKResultV2()
    @Published var reps = 0
    @Published var showAlert = false; @Published var alertMessage = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .front
    private var frameBuffer: [HKResultV2] = []
    private var lastKneeH: Double = 0
    private var kneePeaks = 0
    private var alertTimer: Timer?

    func start() { AVCaptureDevice.requestAccess(for: .video) { [weak self] g in guard g else { return }; self?.sessionQueue.async { self?.setup() } } }
    func stop() { sessionQueue.async { [weak self] in self?.session.stopRunning() } }
    func resetReps() { DispatchQueue.main.async { self.reps = 0; self.kneePeaks = 0 } }
    func switchCamera() {
        sessionQueue.async {
            let pos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); return }
            self.session.addInput(inp); self.session.commitConfiguration()
            self.session.startRunning()
            DispatchQueue.main.async { self.cameraPosition = pos }
        }
    }
    private func setup() {
        session.stopRunning(); session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }; session.outputs.forEach { session.removeOutput($0) }
        session.sessionPreset = .high
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let inp = try? AVCaptureDeviceInput(device: dev), session.canAddInput(inp) else { return }
        session.addInput(inp)
        let out = AVCaptureVideoDataOutput()
        out.setSampleBufferDelegate(self, queue: DispatchQueue(label: "hkV2Q"))
        out.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(out) { session.addOutput(out) }
        session.commitConfiguration(); session.startRunning()
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sb: CMSampleBuffer, from conn: AVCaptureConnection) {
        guard let px = CMSampleBufferGetImageBuffer(sb) else { return }
        let req = VNDetectHumanBodyPoseRequest()
        try? VNImageRequestHandler(cvPixelBuffer: px, orientation: cameraPosition == .front ? .leftMirrored : .right).perform([req])
        guard let obs = req.results?.first, let pts = try? obs.recognizedPoints(.all) else { return }
        updatePoints(pts)
        var raw = analyze(pts)
        if raw.issue == .notVisible { DispatchQueue.main.async { self.result = raw }; return }
        frameBuffer.append(raw); if frameBuffer.count > 5 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        raw.kneeHeight = frameBuffer.map { $0.kneeHeight }.reduce(0,+) / n
        raw.torsoAngle = frameBuffer.map { $0.torsoAngle }.reduce(0,+) / n
        raw.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)
        if raw.kneeHeight > lastKneeH + 0.04 && lastKneeH < 0.01 {
            kneePeaks += 1
            DispatchQueue.main.async { self.reps = self.kneePeaks / 2 }
        }
        lastKneeH = raw.kneeHeight
        DispatchQueue.main.async { self.result = raw }
        if !raw.kneeOk || !raw.torsoOk {
            let msg = !raw.torsoOk ? "Stay Upright — Don't Lean Back!" : "Lift Knees to Hip Height!"
            DispatchQueue.main.async {
                self.alertMessage = msg; self.showAlert = true
                self.alertTimer?.invalidate()
                self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                    DispatchQueue.main.async { self.showAlert = false }
                }
            }
        } else { DispatchQueue.main.async { self.showAlert = false } }
    }
    private func analyze(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> HKResultV2 {
        var r = HKResultV2()
        let lC: Float = (pts[.leftHip]?.confidence ?? 0) + (pts[.leftKnee]?.confidence ?? 0)
        let rC: Float = (pts[.rightHip]?.confidence ?? 0) + (pts[.rightKnee]?.confidence ?? 0)
        let ul = lC >= rC; r.trackedLeftSide = ul
        let hpK: VNHumanBodyPoseObservation.JointName = ul ? .leftHip : .rightHip
        let knK: VNHumanBodyPoseObservation.JointName = ul ? .leftKnee : .rightKnee
        let shK: VNHumanBodyPoseObservation.JointName = ul ? .leftShoulder : .rightShoulder
        guard let hp = pts[hpK], hp.confidence > 0.4,
              let kn = pts[knK], kn.confidence > 0.4 else { r.issue = .notVisible; return r }
        r.kneeHeight = hp.location.y - kn.location.y
        r.kneeOk = r.kneeHeight >= 0.05
        if let sh = pts[shK], sh.confidence > 0.3 {
            let t = abs(atan2(sh.location.y - hp.location.y, sh.location.x - hp.location.x) * 180 / .pi)
            r.torsoAngle = t; r.torsoOk = t >= 55
        } else { r.torsoOk = true }
        var score = 100; if !r.kneeOk { score -= 35 }; if !r.torsoOk { score -= 30 }
        r.postureScore = max(score, 0)
        r.issue = !r.torsoOk ? .leaningBack : !r.kneeOk ? .notHigh : .correct
        return r
    }
    private func updatePoints(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var m: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (j,p) in pts where p.confidence > 0.3 { m[j] = CGPoint(x: p.location.x, y: 1-p.location.y) }
        DispatchQueue.main.async { self.bodyPoints = m }
    }
}

struct HighKneesCameraViewV2: View {
    @StateObject private var vm = HKViewModelV2()
    var body: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            SimpleSkeletonOverlay(bodyPoints: vm.bodyPoints, isOk: vm.result.kneeOk).ignoresSafeArea()
            VStack {
                topBar(title: "High Knees AI", subtitle: "Drive Knees to Hip Height!")
                Spacer()
                if vm.showAlert { FormAlertBannerV2(message: vm.alertMessage) }
                Spacer()
                bottomPanel(
                    issue: vm.result.issue.rawValue,
                    cards: [
                        ("Torso", vm.result.torsoAngle, vm.result.torsoOk, "> 55°"),
                        ("Knee H.", vm.result.kneeHeight*100, vm.result.kneeOk, "> 5%"),
                        ("Score", Double(vm.result.postureScore), vm.result.postureScore >= 70, "> 70")
                    ],
                    reps: vm.reps, phase: vm.result.kneeOk ? "Hip High ✅" : "Higher!",
                    phaseColor: vm.result.kneeOk ? .green : .red,
                    score: vm.result.postureScore, onReset: { vm.resetReps() }, onFlip: { vm.switchCamera() }
                )
            }
        }
        .onAppear { vm.start() }.onDisappear { vm.stop() }.navigationBarHidden(true)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SUPERMAN HOLD
// Prone (face down). Tracks back extension using shoulder/hip heights.
// ─────────────────────────────────────────────────────────────────────────────

enum SupermanIssue: String {
    case correct    = "✅ Perfect Superman — Hold!"
    case notHigh    = "❌ Lift Higher — Squeeze Your Back!"
    case detecting  = "🔍 Detecting..."
    case notVisible = "📷 Full Body Not Visible"
}

struct SupermanResult {
    var issue: SupermanIssue = .detecting
    var postureScore: Int = 100
    var liftHeight: Double = 0
    var backAngle: Double = 0
    var trackedLeftSide = true
    var liftOk = false
}

final class SupermanViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "fitspire.superman.session", qos: .userInitiated)
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = SupermanResult()
    @Published var holdSeconds = 0
    @Published var isHolding = false
    @Published var showAlert = false; @Published var alertMessage = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    private var frameBuffer: [SupermanResult] = []
    private var holdTimer: Timer?
    private var alertTimer: Timer?

    func start() { AVCaptureDevice.requestAccess(for: .video) { [weak self] g in guard g else { return }; self?.sessionQueue.async { self?.setup() } } }
    func stop() {
        sessionQueue.async { [weak self] in self?.session.stopRunning() }
        DispatchQueue.main.async { self.holdTimer?.invalidate(); self.alertTimer?.invalidate() }
    }
    func resetHold() { DispatchQueue.main.async { self.holdSeconds = 0; self.isHolding = false; self.holdTimer?.invalidate() } }
    func switchCamera() {
        sessionQueue.async {
            let pos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); return }
            self.session.addInput(inp); self.session.commitConfiguration()
            self.session.startRunning()
            DispatchQueue.main.async { self.cameraPosition = pos }
        }
    }
    private func setup() {
        session.stopRunning(); session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }; session.outputs.forEach { session.removeOutput($0) }
        session.sessionPreset = .high
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let inp = try? AVCaptureDeviceInput(device: dev), session.canAddInput(inp) else { return }
        session.addInput(inp)
        let out = AVCaptureVideoDataOutput()
        out.setSampleBufferDelegate(self, queue: DispatchQueue(label: "supermanQ"))
        out.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(out) { session.addOutput(out) }
        session.commitConfiguration(); session.startRunning()
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sb: CMSampleBuffer, from conn: AVCaptureConnection) {
        guard let px = CMSampleBufferGetImageBuffer(sb) else { return }
        let req = VNDetectHumanBodyPoseRequest()
        try? VNImageRequestHandler(cvPixelBuffer: px, orientation: cameraPosition == .front ? .leftMirrored : .right).perform([req])
        guard let obs = req.results?.first, let pts = try? obs.recognizedPoints(.all) else { return }
        updatePoints(pts)
        var raw = analyze(pts)
        if raw.issue == .notVisible { DispatchQueue.main.async { self.result = raw }; return }
        frameBuffer.append(raw); if frameBuffer.count > 8 { frameBuffer.removeFirst() }
        let n = Double(frameBuffer.count)
        raw.liftHeight = frameBuffer.map { $0.liftHeight }.reduce(0,+) / n
        raw.backAngle = frameBuffer.map { $0.backAngle }.reduce(0,+) / n
        raw.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)
        let isGood = raw.liftOk
        DispatchQueue.main.async {
            self.result = raw
            if isGood && !self.isHolding {
                self.isHolding = true
                self.holdTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                    DispatchQueue.main.async { self?.holdSeconds += 1 }
                }
                RunLoop.main.add(self.holdTimer!, forMode: .common)
            } else if !isGood && self.isHolding {
                self.isHolding = false; self.holdTimer?.invalidate()
            }
        }
        if !raw.liftOk {
            DispatchQueue.main.async {
                self.alertMessage = "Lift Chest and Legs Higher — Squeeze Your Back!"
                self.showAlert = true
                self.alertTimer?.invalidate()
                self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                    DispatchQueue.main.async { self.showAlert = false }
                }
            }
        } else { DispatchQueue.main.async { self.showAlert = false } }
    }
    private func analyze(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> SupermanResult {
        var r = SupermanResult()
        let lC: Float = (pts[.leftShoulder]?.confidence ?? 0) + (pts[.leftHip]?.confidence ?? 0)
        let rC: Float = (pts[.rightShoulder]?.confidence ?? 0) + (pts[.rightHip]?.confidence ?? 0)
        let ul = lC >= rC; r.trackedLeftSide = ul
        let shK: VNHumanBodyPoseObservation.JointName = ul ? .leftShoulder : .rightShoulder
        let hpK: VNHumanBodyPoseObservation.JointName = ul ? .leftHip : .rightHip
        let anK: VNHumanBodyPoseObservation.JointName = ul ? .leftAnkle : .rightAnkle
        guard let sh = pts[shK], sh.confidence > 0.35,
              let hp = pts[hpK], hp.confidence > 0.35 else { r.issue = .notVisible; return r }
        // Superman: shoulder should be lifted above hip level (prone position)
        let shoulderAboveHip = sh.location.y - hp.location.y
        r.liftHeight = shoulderAboveHip
        r.liftOk = shoulderAboveHip > 0.03  // shoulder meaningfully above hip
        if let an = pts[anK], an.confidence > 0.3 {
            r.backAngle = abs(atan2(sh.location.y - an.location.y, sh.location.x - an.location.x) * 180 / .pi)
        }
        r.postureScore = r.liftOk ? 100 : max(50, 100 - Int((0.03 - shoulderAboveHip) * 1000))
        r.issue = r.liftOk ? .correct : .notHigh
        return r
    }
    private func updatePoints(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var m: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (j,p) in pts where p.confidence > 0.3 { m[j] = CGPoint(x: p.location.x, y: 1-p.location.y) }
        DispatchQueue.main.async { self.bodyPoints = m }
    }
}

struct SupermanCameraView: View {
    @StateObject private var vm = SupermanViewModel()
    private func timeStr(_ s: Int) -> String { String(format: "%d:%02d", s/60, s%60) }
    var body: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            SimpleSkeletonOverlay(bodyPoints: vm.bodyPoints, isOk: vm.result.liftOk).ignoresSafeArea()
            VStack {
                topBar(title: "Superman AI", subtitle: "Lie flat · Side-on camera")
                Spacer()
                if vm.showAlert { FormAlertBannerV2(message: vm.alertMessage) }
                Spacer()
                VStack(spacing: 16) {
                    Text(vm.result.issue.rawValue)
                        .font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
                    HStack(spacing: 12) {
                        AngleCard(title: "Lift", angle: vm.result.liftHeight*100, isOk: vm.result.liftOk, idealRange: "> 3%")
                        AngleCard(title: "Back Angle", angle: vm.result.backAngle, isOk: vm.result.liftOk, idealRange: "Extended")
                        VStack(spacing: 5) {
                            Text("FORM").font(.caption).foregroundColor(.white.opacity(0.7))
                            Image(systemName: vm.result.liftOk ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title2).foregroundColor(vm.result.liftOk ? .green : .red)
                            Text(vm.result.liftOk ? "Lifted ✅" : "Higher!").font(.caption2).foregroundColor(vm.result.liftOk ? .green : .red)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(vm.result.liftOk ? Color.green.opacity(0.15) : Color.red.opacity(0.15)).cornerRadius(12)
                    }
                    HStack(spacing: 50) {
                        VStack {
                            Text(timeStr(vm.holdSeconds)).font(.system(size: 44, weight: .bold)).foregroundColor(.white)
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
        .onAppear { vm.start() }.onDisappear { vm.stop() }.navigationBarHidden(true)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SHARED HELPERS (used by all views above)
// ─────────────────────────────────────────────────────────────────────────────

// Simple two-colour skeleton — green when good, red when bad
struct SimpleSkeletonOverlay: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let joints: [VNHumanBodyPoseObservation.JointName]?   // nil = show all
    let isOk: Bool                                          // renamed from isGood

    init(
        bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint],
        joints: [VNHumanBodyPoseObservation.JointName]? = nil,
        isOk: Bool
    ) {
        self.bodyPoints = bodyPoints
        self.joints = joints
        self.isOk = isOk
    }

    private let bones: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
    ]

    /// Returns only the bones where both endpoints are in the joints filter (if set)
    private var visibleBones: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] {
        guard let joints else { return bones }
        let set = Set(joints)
        return bones.filter { set.contains($0.0) && set.contains($0.1) }
    }

    /// Returns only the points that are in the joints filter (if set)
    private var visiblePoints: [VNHumanBodyPoseObservation.JointName: CGPoint] {
        guard let joints else { return bodyPoints }
        let set = Set(joints)
        return bodyPoints.filter { set.contains($0.key) }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(visibleBones.enumerated()), id: \.offset) { _, bone in
                    if let p1 = bodyPoints[bone.0], let p2 = bodyPoints[bone.1] {
                        Path { path in
                            path.move(to: CGPoint(x: p1.x * geo.size.width,  y: p1.y * geo.size.height))
                            path.addLine(to: CGPoint(x: p2.x * geo.size.width, y: p2.y * geo.size.height))
                        }
                        .stroke(isOk ? Color.green : Color.red,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    }
                }
                ForEach(Array(visiblePoints.keys), id: \.self) { joint in
                    if let pt = visiblePoints[joint] {
                        Circle()
                            .fill(isOk ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                            .position(x: pt.x * geo.size.width, y: pt.y * geo.size.height)
                    }
                }
            }
        }
    }
}

// Shared form alert banner
struct FormAlertBannerV2: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text(message).font(.subheadline.bold()).foregroundColor(.white)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(Color.black.opacity(0.85))
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.orange, lineWidth: 1.5))
        .shadow(color: .orange.opacity(0.4), radius: 8)
        .padding(.horizontal)
    }
}

// Shared top bar
private func topBar(title: String, subtitle: String) -> some View {
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title2.bold()).foregroundColor(.white)
            Text(subtitle).font(.caption).foregroundColor(.white.opacity(0.7))
        }
        Spacer()
    }
    .padding().background(.black.opacity(0.65)).cornerRadius(20).padding()
}

// Shared bottom panel
private func bottomPanel(
    issue: String,
    cards: [(String, Double, Bool, String)],
    reps: Int,
    phase: String,
    phaseColor: Color,
    score: Int,
    onReset: @escaping () -> Void,
    onFlip: @escaping () -> Void
) -> some View {
    VStack(spacing: 16) {
        Text(issue).font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
        HStack(spacing: 10) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                AngleCard(title: card.0, angle: card.1, isOk: card.2, idealRange: card.3)
            }
        }
        HStack(spacing: 40) {
            VStack {
                Text("\(reps)").font(.system(size: 50, weight: .bold)).foregroundColor(.white)
                Text("REPS").foregroundColor(.white.opacity(0.7))
            }
            VStack {
                Text(phase).font(.title3.bold()).foregroundColor(phaseColor)
                Text("PHASE").foregroundColor(.white.opacity(0.7))
            }
            VStack(spacing: 6) {
                Button(action: onFlip) {
                    Image(systemName: "camera.rotate").font(.title2).foregroundColor(.white)
                        .padding(10).background(Color.white.opacity(0.2)).clipShape(Circle())
                }
                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise").font(.title2).foregroundColor(.white)
                }
                Text("RESET").font(.caption2).foregroundColor(.white.opacity(0.6))
            }
        }
    }
    .padding().background(.black.opacity(0.75)).cornerRadius(22).padding()
}
