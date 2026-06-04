//
//  AllExerciseViews.swift
//  Praxio
//
//  Same architecture as SquatCameraView — per-joint skeleton coloring,
//  phase-aware angle analysis, bad-rep detection, 3 angle cards,
//  stable-frame smoothing, form alert banners.
//
//  Exercises: Push-Up, Lunge, Glute Bridge, Mountain Climber, High Knees, Plank
//

import SwiftUI
import Combine
import AVFoundation
import Vision

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PUSH-UP
// ─────────────────────────────────────────────────────────────────────────────



// ─────────────────────────────────────────────────────────────────────────────
// MARK: - LUNGE
// ─────────────────────────────────────────────────────────────────────────────

enum LungeIssue2: String {
    case correct         = "✅ Good Lunge"
    case kneeOverToe     = "❌ Front Knee Too Far"
    case notDeep         = "❌ Lower Back Knee More"
    case torsoLean       = "❌ Keep Torso Upright"
    case detecting       = "🔍 Detecting..."
    case notVisible      = "📷 Full Body Not Visible"
}

enum LungePhase2 { case standing, stepping, bottom, returning }

struct LungePostureResult {
    var issue: LungeIssue2 = .detecting
    var postureScore: Int = 100
    var frontKneeAngle: Double = 180   // hip-knee-ankle — target ~90° at bottom
    var backKneeAngle: Double = 90
    var torsoAngle: Double = 90
    var kneeToeOffset: Double = 0
    var trackedLeftSide = true
    var kneeOk  = true
    var torsoOk = true
    var depthOk = true
}

final class LungeViewModel2: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "fitspire.lunge.session", qos: .userInitiated)
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = LungePostureResult()
    @Published var reps = 0
    @Published var phase: LungePhase2 = .standing
    @Published var phaseText = "Standing"; @Published var phaseColor: Color = .white
    private var bgPhase2: LungePhase2 = .standing
    @Published var showAlert = false; @Published var alertMessage = ""
    @Published var showBadRep = false; @Published var badRepReason = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    private var isConfiguring = false
    private var frameBuffer: [LungePostureResult] = []
    private var lastKnee: Double = 180
    private var bottomReached = false; private var repStarted = false
    private var validBottomFrames = 0; private var validStandFrames = 0
    private var kneeErrorFrames = 0; private var hadKneeError = false
    private var stableFrames = 0; private var lastIssue: LungeIssue2 = .detecting
    private var alertTimer: Timer?

    func start() { AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in guard granted else { return }; self?.sessionQueue.async { self?.setup() } } }
    func stop() {
        DispatchQueue.global(qos: .background).async { [weak self] in self?.session.stopRunning() }
    }
    func resetReps() { DispatchQueue.main.async { self.reps = 0; self.bottomReached = false; self.repStarted = false; self.validBottomFrames = 0; self.validStandFrames = 0; self.hadKneeError = false; self.kneeErrorFrames = 0 } }

    func switchCamera() {
        sessionQueue.async {
            let pos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.isConfiguring = true
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(inp); self.session.commitConfiguration()
            self.session.startRunning()
            self.isConfiguring = false
            DispatchQueue.main.async { self.cameraPosition = pos }
        }
    }

    private func setup() {
        session.stopRunning()
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        session.sessionPreset = .high
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let inp = try? AVCaptureDeviceInput(device: dev), session.canAddInput(inp) else { return }
        session.addInput(inp)
        let out = AVCaptureVideoDataOutput()
        out.setSampleBufferDelegate(self, queue: DispatchQueue(label: "lungeQueue2"))
        out.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(out) { session.addOutput(out) }
        session.commitConfiguration()
        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sb: CMSampleBuffer, from conn: AVCaptureConnection) {
        guard let pxBuf = CMSampleBufferGetImageBuffer(sb) else { return }
        let orient: CGImagePropertyOrientation = cameraPosition == .front ? .leftMirrored : .right
        let req = VNDetectHumanBodyPoseRequest()
        let h = VNImageRequestHandler(cvPixelBuffer: pxBuf, orientation: orient)
        do {
            try h.perform([req])
            guard let obs = req.results?.first else { return }
            let pts = try obs.recognizedPoints(.all)
            updatePoints(pts)
            var raw = analyze(pts)
            if raw.issue == .notVisible { DispatchQueue.main.async { self.result = raw }; return }
            frameBuffer.append(raw)
            if frameBuffer.count > 8 { frameBuffer.removeFirst() }
            let n = Double(frameBuffer.count)
            raw.frontKneeAngle = frameBuffer.map { $0.frontKneeAngle }.reduce(0,+) / n
            raw.torsoAngle     = frameBuffer.map { $0.torsoAngle     }.reduce(0,+) / n
            raw.postureScore   = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)
            updatePhase(raw)
            if raw.issue == lastIssue { stableFrames += 1 } else { stableFrames = 0; lastIssue = raw.issue }
            if stableFrames < 3 { raw.issue = result.issue }
            showFormAlert(raw)
            DispatchQueue.main.async { self.result = raw }
        } catch {}
    }

    private func analyze(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> LungePostureResult {
        var r = LungePostureResult()
        let lConf: Float = (pts[.leftHip]?.confidence ?? 0) + (pts[.leftKnee]?.confidence ?? 0) + (pts[.leftAnkle]?.confidence ?? 0)
        let rConf: Float = (pts[.rightHip]?.confidence ?? 0) + (pts[.rightKnee]?.confidence ?? 0) + (pts[.rightAnkle]?.confidence ?? 0)
        let useLeft = lConf >= rConf; r.trackedLeftSide = useLeft
        let shK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let hpK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let knK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee     : .rightKnee
        let anK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle    : .rightAnkle
        for j in [hpK, knK, anK] { guard let p = pts[j], p.confidence > 0.35 else { r.issue = .notVisible; return r } }
        guard let hp = pts[hpK]?.location, let kn = pts[knK]?.location, let an = pts[anK]?.location else {
            r.issue = .notVisible; return r
        }
        r.frontKneeAngle = lungeAngle(hp, kn, an)
        r.kneeToeOffset  = kn.x - an.x    // how far knee is past ankle
        r.kneeOk         = abs(r.kneeToeOffset) <= 0.15
        if let sh = pts[shK], sh.confidence > 0.3 {
            let torso = abs(atan2(sh.location.y - hp.y, sh.location.x - hp.x) * 180 / .pi)
            r.torsoAngle = torso
            r.torsoOk    = torso >= 60
        } else { r.torsoOk = true }
        r.depthOk = r.frontKneeAngle <= 105 || phase != .bottom
        var score = 100
        if !r.kneeOk  { score -= 35 }
        if !r.torsoOk { score -= 30 }
        r.postureScore = max(score, 0)
        if !r.torsoOk  { r.issue = .torsoLean }
        else if !r.kneeOk { r.issue = .kneeOverToe }
        else { r.issue = .correct }
        return r
    }

    private func updatePhase(_ r: LungePostureResult) {
        if bgPhase2 == .stepping || bgPhase2 == .bottom {
            kneeErrorFrames = !r.kneeOk ? kneeErrorFrames + 1 : 0
            if kneeErrorFrames >= 3 { hadKneeError = true }
        }
        if r.frontKneeAngle < 150 && r.frontKneeAngle < lastKnee { repStarted = true }
        if repStarted && r.frontKneeAngle <= 105 { validBottomFrames += 1; if validBottomFrames >= 3 { bottomReached = true } } else { validBottomFrames = 0 }
        if repStarted && r.frontKneeAngle >= 150 {
            validStandFrames += 1
            if validStandFrames >= 2 && bottomReached {
                if hadKneeError { DispatchQueue.main.async { self.badRepReason = "Front knee tracked past toes"; self.showBadRep = true; DispatchQueue.main.asyncAfter(deadline: .now()+2.5) { self.showBadRep = false } } }
                else { DispatchQueue.main.async { self.reps += 1 } }
                bottomReached = false; repStarted = false; validBottomFrames = 0; validStandFrames = 0; hadKneeError = false; kneeErrorFrames = 0
            }
        } else { validStandFrames = 0 }
        lastKnee = r.frontKneeAngle
        DispatchQueue.main.async {
            if r.frontKneeAngle <= 105 { self.phase = .bottom; self.bgPhase2 = .bottom; self.phaseText = "Deep ✅"; self.phaseColor = .green }
            else if r.frontKneeAngle < 150 { self.phase = .stepping; self.bgPhase2 = .stepping; self.phaseText = "Stepping Back"; self.phaseColor = .yellow }
            else { self.phase = .standing; self.bgPhase2 = .standing; self.phaseText = "Standing"; self.phaseColor = .white }
        }
    }

    private func showFormAlert(_ r: LungePostureResult) {
        guard bgPhase2 == .stepping || bgPhase2 == .bottom else { DispatchQueue.main.async { self.showAlert = false }; return }
        var msg: String? = nil
        if !r.kneeOk  { msg = "Step Back Further — Knee Over Toes!" }
        else if !r.torsoOk { msg = "Keep Chest Up — Don't Lean Forward!" }
        DispatchQueue.main.async {
            if let m = msg { self.alertMessage = m; self.showAlert = true; self.alertTimer?.invalidate(); self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in DispatchQueue.main.async { self.showAlert = false } } }
            else { self.showAlert = false }
        }
    }

    private func updatePoints(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var m: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (j, p) in pts where p.confidence > 0.3 { m[j] = CGPoint(x: p.location.x, y: 1 - p.location.y) }
        DispatchQueue.main.async { self.bodyPoints = m }
    }

    private func lungeAngle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let ab = atan2(a.y - b.y, a.x - b.x); let cb = atan2(c.y - b.y, c.x - b.x)
        var ang = abs((ab - cb) * 180 / .pi); if ang > 180 { ang = 360 - ang }; return ang
    }
}

struct LungeSkeletonOverlay2: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let result: LungePostureResult
    var body: some View { lungeSkeletonBody }
    @ViewBuilder private var lungeSkeletonBody: some View {
        GeometryReader { geo in ZStack { lungeBones(geo: geo); lungeJoints(geo: geo) } }
    }
    private var hp: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftHip      : .rightHip }
    private var kn: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftKnee     : .rightKnee }
    private var an: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftAnkle    : .rightAnkle }
    private var sh: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftShoulder : .rightShoulder }
    @ViewBuilder private func lungeBones(geo: GeometryProxy) -> some View {
        lLine(sh, hp, geo, ok: result.torsoOk)
        lLine(hp, kn, geo, ok: result.kneeOk)
        lLine(kn, an, geo, ok: result.kneeOk)
    }
    @ViewBuilder private func lLine(_ j1: VNHumanBodyPoseObservation.JointName, _ j2: VNHumanBodyPoseObservation.JointName, _ geo: GeometryProxy, ok: Bool) -> some View {
        if let p1 = bodyPoints[j1], let p2 = bodyPoints[j2] {
            Path { p in p.move(to: CGPoint(x: p1.x*geo.size.width, y: p1.y*geo.size.height)); p.addLine(to: CGPoint(x: p2.x*geo.size.width, y: p2.y*geo.size.height)) }
            .stroke(ok ? Color.green : Color.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
    @ViewBuilder private func lungeJoints(geo: GeometryProxy) -> some View {
        ForEach([sh, hp, kn, an], id: \.self) { j in
            if let pt = bodyPoints[j] {
                let ok = (j == sh) ? result.torsoOk : result.kneeOk
                Circle().fill(ok ? Color.green : Color.red).frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                    .position(x: pt.x*geo.size.width, y: pt.y*geo.size.height)
            }
        }
    }
}

struct LungeCameraView2: View {
    @StateObject private var vm = LungeViewModel2()
    var body: some View { lungeContent }
    @ViewBuilder private var lungeContent: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            LungeSkeletonOverlay2(bodyPoints: vm.bodyPoints, result: vm.result).ignoresSafeArea()
            VStack {
                lungeTopBar; Spacer()
                if vm.showAlert { FormAlertBanner(message: vm.alertMessage).transition(.move(edge: .top).combined(with: .opacity)) }
                Spacer(); lungeBottomPanel
            }
            if vm.showBadRep { BadRepOverlay(reason: vm.badRepReason) }
        }
        .onAppear { vm.start() }.onDisappear { vm.stop() }
        .animation(.spring(response: 0.4), value: vm.showAlert)
    }
    private var lungeTopBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) { Text("Lunge AI").font(.title2.bold()).foregroundColor(.white); Text("Real-Time Form Check").font(.caption).foregroundColor(.white.opacity(0.7)) }
            Spacer()
            Button { vm.switchCamera() } label: { Image(systemName: "camera.rotate").font(.title2).foregroundColor(.white).padding(12).background(Color.white.opacity(0.2)).clipShape(Circle()) }
            ExScoreRing(score: vm.result.postureScore)
        }
        .padding().background(.black.opacity(0.65)).cornerRadius(20).padding()
    }
    private var lungeBottomPanel: some View {
        VStack(spacing: 18) {
            Text(vm.result.issue.rawValue).font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                AngleCard(title: "Front Knee", angle: vm.result.frontKneeAngle, isOk: vm.result.depthOk,  idealRange: "< 105°")
                AngleCard(title: "Torso",      angle: vm.result.torsoAngle,     isOk: vm.result.torsoOk,  idealRange: "> 60°")
                AngleCard(title: "Knee Align", angle: abs(vm.result.kneeToeOffset)*100, isOk: vm.result.kneeOk, idealRange: "< 15°")
            }
            HStack(spacing: 50) {
                VStack { Text("\(vm.reps)").font(.system(size: 50, weight: .bold)).foregroundColor(.white); Text("REPS").foregroundColor(.white.opacity(0.7)) }
                VStack { Text(vm.phaseText).font(.title3.bold()).foregroundColor(vm.phaseColor); Text("PHASE").foregroundColor(.white.opacity(0.7)) }
                Button { vm.resetReps() } label: { VStack { Image(systemName: "arrow.counterclockwise").font(.title2).foregroundColor(.white); Text("RESET").foregroundColor(.white.opacity(0.7)) } }
            }
        }
        .padding().background(.black.opacity(0.75)).cornerRadius(22).padding()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - GLUTE BRIDGE
// ─────────────────────────────────────────────────────────────────────────────

enum GBIssue: String {
    case correct    = "✅ Perfect Bridge"
    case notHigh    = "❌ Drive Hips Higher"
    case kneesDrift = "❌ Keep Knees Together"
    case detecting  = "🔍 Detecting..."
    case notVisible = "📷 Full Body Not Visible"
}

enum GBPhase { case down, raising, top, lowering }

struct GBPostureResult {
    var issue: GBIssue = .detecting
    var postureScore: Int = 100
    var hipAngle: Double = 180        // shoulder→hip→knee — target < 155° at top (fully extended)
    var kneeAngle: Double = 90
    var hipHeight: Double = 0
    var trackedLeftSide = true
    var hipOk   = true
    var kneeOk  = true
}

final class GBViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "fitspire.gb.session", qos: .userInitiated)
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = GBPostureResult()
    @Published var reps = 0
    @Published var phase: GBPhase = .down
    @Published var phaseText = "Down"; @Published var phaseColor: Color = .white
    private var bgPhaseGB: GBPhase = .down
    @Published var showAlert = false; @Published var alertMessage = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    private var isConfiguring = false
    private var frameBuffer: [GBPostureResult] = []
    private var lastHip: Double = 180
    private var topReached = false; private var repStarted = false
    private var validTopFrames = 0; private var validDownFrames = 0
    private var alertTimer: Timer?

    func start() { AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in guard granted else { return }; self?.sessionQueue.async { self?.setup() } } }
    func stop() {
        DispatchQueue.global(qos: .background).async { [weak self] in self?.session.stopRunning() }
    }
    func resetReps() { DispatchQueue.main.async { self.reps = 0; self.topReached = false; self.repStarted = false; self.validTopFrames = 0; self.validDownFrames = 0 } }

    func switchCamera() {
        sessionQueue.async {
            let pos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.isConfiguring = true
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(inp); self.session.commitConfiguration()
            self.session.startRunning()
            self.isConfiguring = false
            DispatchQueue.main.async { self.cameraPosition = pos }
        }
    }

    private func setup() {
        session.stopRunning()
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        session.sessionPreset = .high
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let inp = try? AVCaptureDeviceInput(device: dev), session.canAddInput(inp) else { return }
        session.addInput(inp)
        let out = AVCaptureVideoDataOutput()
        out.setSampleBufferDelegate(self, queue: DispatchQueue(label: "gbQueue"))
        out.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(out) { session.addOutput(out) }
        session.commitConfiguration()
        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sb: CMSampleBuffer, from conn: AVCaptureConnection) {
        guard let pxBuf = CMSampleBufferGetImageBuffer(sb) else { return }
        let orient: CGImagePropertyOrientation = cameraPosition == .front ? .leftMirrored : .right
        let req = VNDetectHumanBodyPoseRequest()
        let h = VNImageRequestHandler(cvPixelBuffer: pxBuf, orientation: orient)
        do {
            try h.perform([req])
            guard let obs = req.results?.first else { return }
            let pts = try obs.recognizedPoints(.all)
            updatePoints(pts)
            var raw = analyze(pts)
            if raw.issue == .notVisible { DispatchQueue.main.async { self.result = raw }; return }
            frameBuffer.append(raw)
            if frameBuffer.count > 8 { frameBuffer.removeFirst() }
            let n = Double(frameBuffer.count)
            raw.hipAngle  = frameBuffer.map { $0.hipAngle  }.reduce(0,+) / n
            raw.kneeAngle = frameBuffer.map { $0.kneeAngle }.reduce(0,+) / n
            raw.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)
            updatePhase(raw)
            showFormAlert(raw)
            DispatchQueue.main.async { self.result = raw }
        } catch {}
    }

    private func analyze(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> GBPostureResult {
        var r = GBPostureResult()
        let lConf: Float = (pts[.leftHip]?.confidence ?? 0) + (pts[.leftKnee]?.confidence ?? 0) + (pts[.leftAnkle]?.confidence ?? 0)
        let rConf: Float = (pts[.rightHip]?.confidence ?? 0) + (pts[.rightKnee]?.confidence ?? 0) + (pts[.rightAnkle]?.confidence ?? 0)
        let useLeft = lConf >= rConf; r.trackedLeftSide = useLeft
        let shK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let hpK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let knK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee     : .rightKnee
        let anK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle    : .rightAnkle
        for j in [hpK, knK, anK] { guard let p = pts[j], p.confidence > 0.35 else { r.issue = .notVisible; return r } }
        guard let hp = pts[hpK]?.location, let kn = pts[knK]?.location, let an = pts[anK]?.location else {
            r.issue = .notVisible; return r
        }
        r.kneeAngle = gbAngle(hp, kn, an)
        r.kneeOk = r.kneeAngle >= 75 && r.kneeAngle <= 115
        if let sh = pts[shK], sh.confidence > 0.3 {
            r.hipAngle = gbAngle(sh.location, hp, kn)
            r.hipHeight = hp.y
            r.hipOk = r.hipAngle <= 155 || phase != .top
        } else { r.hipOk = true }
        var score = 100
        if !r.hipOk  { score -= 40 }
        if !r.kneeOk { score -= 25 }
        r.postureScore = max(score, 0)
        if !r.hipOk  { r.issue = .notHigh }
        else { r.issue = .correct }
        return r
    }

    private func updatePhase(_ r: GBPostureResult) {
        if r.hipAngle < 165 && r.hipAngle < lastHip { repStarted = true }
        if repStarted && r.hipAngle <= 155 { validTopFrames += 1; if validTopFrames >= 3 { topReached = true } } else { validTopFrames = 0 }
        if topReached && r.hipAngle > lastHip && r.hipAngle >= 168 {
            validDownFrames += 1
            if validDownFrames >= 2 { DispatchQueue.main.async { self.reps += 1 }; topReached = false; repStarted = false; validTopFrames = 0; validDownFrames = 0 }
        } else { validDownFrames = 0 }
        lastHip = r.hipAngle
        DispatchQueue.main.async {
            if r.hipAngle <= 155 { self.phase = .top; self.bgPhaseGB = .top; self.phaseText = "Top ✅"; self.phaseColor = .green }
            else if r.hipAngle < 165 && r.hipAngle < self.lastHip { self.phase = .raising; self.bgPhaseGB = .raising; self.phaseText = "Raising"; self.phaseColor = .yellow }
            else { self.phase = .down; self.bgPhaseGB = .down; self.phaseText = "Down"; self.phaseColor = .white }
        }
    }

    private func showFormAlert(_ r: GBPostureResult) {
        guard bgPhaseGB == .top else { DispatchQueue.main.async { self.showAlert = false }; return }
        var msg: String? = nil
        if !r.hipOk { msg = "Drive Hips Higher — Squeeze Your Glutes!" }
        DispatchQueue.main.async {
            if let m = msg { self.alertMessage = m; self.showAlert = true; self.alertTimer?.invalidate(); self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in DispatchQueue.main.async { self.showAlert = false } } }
            else { self.showAlert = false }
        }
    }

    private func updatePoints(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var m: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (j, p) in pts where p.confidence > 0.3 { m[j] = CGPoint(x: p.location.x, y: 1 - p.location.y) }
        DispatchQueue.main.async { self.bodyPoints = m }
    }

    private func gbAngle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let ab = atan2(a.y - b.y, a.x - b.x); let cb = atan2(c.y - b.y, c.x - b.x)
        var ang = abs((ab - cb) * 180 / .pi); if ang > 180 { ang = 360 - ang }; return ang
    }
}

struct GBSkeletonOverlay: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let result: GBPostureResult
    var body: some View { gbSkeletonBody }
    @ViewBuilder private var gbSkeletonBody: some View {
        GeometryReader { geo in ZStack { gbBones(geo: geo); gbJoints(geo: geo) } }
    }
    private var sh: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftShoulder : .rightShoulder }
    private var hp: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftHip      : .rightHip }
    private var kn: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftKnee     : .rightKnee }
    private var an: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftAnkle    : .rightAnkle }
    @ViewBuilder private func gbBones(geo: GeometryProxy) -> some View {
        gbLine(sh, hp, geo, ok: result.hipOk)
        gbLine(hp, kn, geo, ok: result.hipOk)
        gbLine(kn, an, geo, ok: result.kneeOk)
    }
    @ViewBuilder private func gbLine(_ j1: VNHumanBodyPoseObservation.JointName, _ j2: VNHumanBodyPoseObservation.JointName, _ geo: GeometryProxy, ok: Bool) -> some View {
        if let p1 = bodyPoints[j1], let p2 = bodyPoints[j2] {
            Path { p in p.move(to: CGPoint(x: p1.x*geo.size.width, y: p1.y*geo.size.height)); p.addLine(to: CGPoint(x: p2.x*geo.size.width, y: p2.y*geo.size.height)) }
            .stroke(ok ? Color.green : Color.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
    @ViewBuilder private func gbJoints(geo: GeometryProxy) -> some View {
        ForEach([sh, hp, kn, an], id: \.self) { j in
            if let pt = bodyPoints[j] {
                let ok = (j == kn || j == an) ? result.kneeOk : result.hipOk
                Circle().fill(ok ? Color.green : Color.red).frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                    .position(x: pt.x*geo.size.width, y: pt.y*geo.size.height)
            }
        }
    }
}

struct GBCameraView: View {
    @StateObject private var vm = GBViewModel()
    var body: some View { gbContent }
    @ViewBuilder private var gbContent: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            GBSkeletonOverlay(bodyPoints: vm.bodyPoints, result: vm.result).ignoresSafeArea()
            VStack {
                gbTopBar; Spacer()
                if vm.showAlert { FormAlertBanner(message: vm.alertMessage).transition(.move(edge: .top).combined(with: .opacity)) }
                Spacer(); gbBottomPanel
            }
        }
        .onAppear { vm.start() }.onDisappear { vm.stop() }
        .animation(.spring(response: 0.4), value: vm.showAlert)
    }
    private var gbTopBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) { Text("Glute Bridge AI").font(.title2.bold()).foregroundColor(.white); Text("Drive Those Hips!").font(.caption).foregroundColor(.white.opacity(0.7)) }
            Spacer()
            Button { vm.switchCamera() } label: { Image(systemName: "camera.rotate").font(.title2).foregroundColor(.white).padding(12).background(Color.white.opacity(0.2)).clipShape(Circle()) }
            ExScoreRing(score: vm.result.postureScore)
        }
        .padding().background(.black.opacity(0.65)).cornerRadius(20).padding()
    }
    private var gbBottomPanel: some View {
        VStack(spacing: 18) {
            Text(vm.result.issue.rawValue).font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                AngleCard(title: "Hip Ext.",  angle: vm.result.hipAngle,  isOk: vm.result.hipOk,  idealRange: "< 155°")
                AngleCard(title: "Knee",      angle: vm.result.kneeAngle, isOk: vm.result.kneeOk, idealRange: "75°-115°")
                AngleCard(title: "Height",    angle: vm.result.hipHeight * 100, isOk: vm.result.hipOk, idealRange: "Max")
            }
            HStack(spacing: 50) {
                VStack { Text("\(vm.reps)").font(.system(size: 50, weight: .bold)).foregroundColor(.white); Text("REPS").foregroundColor(.white.opacity(0.7)) }
                VStack { Text(vm.phaseText).font(.title3.bold()).foregroundColor(vm.phaseColor); Text("PHASE").foregroundColor(.white.opacity(0.7)) }
                Button { vm.resetReps() } label: { VStack { Image(systemName: "arrow.counterclockwise").font(.title2).foregroundColor(.white); Text("RESET").foregroundColor(.white.opacity(0.7)) } }
            }
        }
        .padding().background(.black.opacity(0.75)).cornerRadius(22).padding()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PLANK
// ─────────────────────────────────────────────────────────────────────────────

enum PlankIssue2: String {
    case correct    = "✅ Perfect Plank — Hold It!"
    case hipSag     = "❌ Hips Dropping — Raise Them!"
    case hipPike    = "❌ Hips Too High — Lower Them!"
    case neckCrane  = "❌ Look Down — Neutral Neck!"
    case detecting  = "🔍 Detecting..."
    case notVisible = "📷 Full Body Not Visible"
}

struct PlankPostureResult {
    var issue: PlankIssue2 = .detecting
    var postureScore: Int = 100
    var bodyAngle: Double = 180       // shoulder→hip→ankle — 160-200 = flat plank
    var neckAngle: Double = 0
    var trackedLeftSide = true
    var bodyOk = true; var neckOk = true
}

final class PlankViewModel2: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "fitspire.plank.session", qos: .userInitiated)
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = PlankPostureResult()
    @Published var holdSeconds = 0
    @Published var isHolding = false
    @Published var showAlert = false; @Published var alertMessage = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    private var isConfiguring = false
    private var frameBuffer: [PlankPostureResult] = []
    private var holdTimer: Timer?
    private var alertTimer: Timer?

    func start() { AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in guard granted else { return }; self?.sessionQueue.async { self?.setup() } } }
    func stop() {
        sessionQueue.async { [weak self] in self?.session.stopRunning() }
        DispatchQueue.main.async { self.holdTimer?.invalidate(); self.alertTimer?.invalidate() }
    }
    func resetHold() { DispatchQueue.main.async { self.holdSeconds = 0; self.isHolding = false; self.holdTimer?.invalidate() } }

    func switchCamera() {
        sessionQueue.async {
            let pos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.isConfiguring = true
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(inp); self.session.commitConfiguration()
            self.session.startRunning()
            self.isConfiguring = false
            DispatchQueue.main.async { self.cameraPosition = pos }
        }
    }

    private func setup() {
        session.stopRunning()
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        session.sessionPreset = .high
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let inp = try? AVCaptureDeviceInput(device: dev), session.canAddInput(inp) else { return }
        session.addInput(inp)
        let out = AVCaptureVideoDataOutput()
        out.setSampleBufferDelegate(self, queue: DispatchQueue(label: "plankQueue2"))
        out.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(out) { session.addOutput(out) }
        session.commitConfiguration()
        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sb: CMSampleBuffer, from conn: AVCaptureConnection) {
        guard let pxBuf = CMSampleBufferGetImageBuffer(sb) else { return }
        let orient: CGImagePropertyOrientation = cameraPosition == .front ? .leftMirrored : .right
        let req = VNDetectHumanBodyPoseRequest()
        let h = VNImageRequestHandler(cvPixelBuffer: pxBuf, orientation: orient)
        do {
            try h.perform([req])
            guard let obs = req.results?.first else { return }
            let pts = try obs.recognizedPoints(.all)
            updatePoints(pts)
            var raw = analyze(pts)
            if raw.issue == .notVisible { DispatchQueue.main.async { self.result = raw }; return }
            frameBuffer.append(raw)
            if frameBuffer.count > 8 { frameBuffer.removeFirst() }
            let n = Double(frameBuffer.count)
            raw.bodyAngle  = frameBuffer.map { $0.bodyAngle  }.reduce(0,+) / n
            raw.neckAngle  = frameBuffer.map { $0.neckAngle  }.reduce(0,+) / n
            raw.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)
            let isGood = raw.issue == .correct
            DispatchQueue.main.async {
                self.result = raw
                if isGood && !self.isHolding {
                    self.isHolding = true
                    self.holdTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in DispatchQueue.main.async { self?.holdSeconds += 1 } }
                    RunLoop.main.add(self.holdTimer!, forMode: .common)
                } else if !isGood && self.isHolding {
                    self.isHolding = false; self.holdTimer?.invalidate()
                }
            }
            showFormAlert(raw)
        } catch {}
    }

    private func analyze(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> PlankPostureResult {
        var r = PlankPostureResult()
        let lConf: Float = (pts[.leftShoulder]?.confidence ?? 0) + (pts[.leftHip]?.confidence ?? 0) + (pts[.leftAnkle]?.confidence ?? 0)
        let rConf: Float = (pts[.rightShoulder]?.confidence ?? 0) + (pts[.rightHip]?.confidence ?? 0) + (pts[.rightAnkle]?.confidence ?? 0)
        let useLeft = lConf >= rConf; r.trackedLeftSide = useLeft
        let shK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        let hpK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip      : .rightHip
        let anK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftAnkle    : .rightAnkle
        for j in [shK, hpK, anK] { guard let p = pts[j], p.confidence > 0.35 else { r.issue = .notVisible; return r } }
        guard let sh = pts[shK]?.location, let hp = pts[hpK]?.location, let an = pts[anK]?.location else {
            r.issue = .notVisible; return r
        }
        r.bodyAngle = plankAngle(sh, hp, an)
        r.bodyOk    = r.bodyAngle >= 158 && r.bodyAngle <= 200
        if let nk = pts[.neck], nk.confidence > 0.3 {
            let neckDev = abs(atan2(nk.location.y - sh.y, nk.location.x - sh.x) -
                              atan2(hp.y - sh.y, hp.x - sh.x)) * 180 / .pi
            r.neckAngle = neckDev; r.neckOk = neckDev < 35
        } else { r.neckOk = true }
        var score = 100
        if !r.bodyOk { score -= 45 }
        if !r.neckOk { score -= 20 }
        r.postureScore = max(score, 0)
        if r.bodyAngle < 158      { r.issue = .hipSag }
        else if r.bodyAngle > 200 { r.issue = .hipPike }
        else if !r.neckOk         { r.issue = .neckCrane }
        else                      { r.issue = .correct }
        return r
    }

    private func showFormAlert(_ r: PlankPostureResult) {
        var msg: String? = nil
        if r.issue == .hipSag    { msg = "Hips Dropping — Squeeze Glutes & Core!" }
        else if r.issue == .hipPike  { msg = "Hips Too High — Lower Them Down!" }
        else if r.issue == .neckCrane { msg = "Look Down — Keep Neck Neutral!" }
        DispatchQueue.main.async {
            if let m = msg { self.alertMessage = m; self.showAlert = true; self.alertTimer?.invalidate(); self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in DispatchQueue.main.async { self.showAlert = false } } }
            else { self.showAlert = false }
        }
    }

    private func updatePoints(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var m: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (j, p) in pts where p.confidence > 0.3 { m[j] = CGPoint(x: p.location.x, y: 1 - p.location.y) }
        DispatchQueue.main.async { self.bodyPoints = m }
    }

    private func plankAngle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let ab = atan2(a.y - b.y, a.x - b.x); let cb = atan2(c.y - b.y, c.x - b.x)
        var ang = abs((ab - cb) * 180 / .pi); if ang > 180 { ang = 360 - ang }; return ang
    }
}

struct PlankSkeletonOverlay2: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let result: PlankPostureResult
    var body: some View { plankSkeletonBody }
    @ViewBuilder private var plankSkeletonBody: some View {
        GeometryReader { geo in ZStack { plankBones(geo: geo); plankJoints(geo: geo) } }
    }
    private var sh: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftShoulder : .rightShoulder }
    private var hp: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftHip      : .rightHip }
    private var an: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftAnkle    : .rightAnkle }
    @ViewBuilder private func plankBones(geo: GeometryProxy) -> some View {
        plankLine(sh, hp, geo, ok: result.bodyOk)
        plankLine(hp, an, geo, ok: result.bodyOk)
    }
    @ViewBuilder private func plankLine(_ j1: VNHumanBodyPoseObservation.JointName, _ j2: VNHumanBodyPoseObservation.JointName, _ geo: GeometryProxy, ok: Bool) -> some View {
        if let p1 = bodyPoints[j1], let p2 = bodyPoints[j2] {
            Path { p in p.move(to: CGPoint(x: p1.x*geo.size.width, y: p1.y*geo.size.height)); p.addLine(to: CGPoint(x: p2.x*geo.size.width, y: p2.y*geo.size.height)) }
            .stroke(ok ? Color.green : Color.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
    @ViewBuilder private func plankJoints(geo: GeometryProxy) -> some View {
        ForEach([sh, hp, an], id: \.self) { j in
            if let pt = bodyPoints[j] {
                Circle().fill(result.bodyOk ? Color.green : Color.red).frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                    .position(x: pt.x*geo.size.width, y: pt.y*geo.size.height)
            }
        }
    }
}

struct PlankCameraView2: View {
    @StateObject private var vm = PlankViewModel2()
    var body: some View { plankContent }
    @ViewBuilder private var plankContent: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            PlankSkeletonOverlay2(bodyPoints: vm.bodyPoints, result: vm.result).ignoresSafeArea()
            VStack {
                plankTopBar2; Spacer()
                if vm.showAlert { FormAlertBanner(message: vm.alertMessage).transition(.move(edge: .top).combined(with: .opacity)) }
                Spacer(); plankBottomPanel2
            }
        }
        .onAppear { vm.start() }.onDisappear { vm.stop() }
        .animation(.spring(response: 0.4), value: vm.showAlert)
    }
    private var plankTopBar2: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) { Text("Plank AI").font(.title2.bold()).foregroundColor(.white); Text("Hold — Breathe Steady").font(.caption).foregroundColor(.white.opacity(0.7)) }
            Spacer()
            Button { vm.switchCamera() } label: { Image(systemName: "camera.rotate").font(.title2).foregroundColor(.white).padding(12).background(Color.white.opacity(0.2)).clipShape(Circle()) }
            ExScoreRing(score: vm.result.postureScore)
        }
        .padding().background(.black.opacity(0.65)).cornerRadius(20).padding()
    }
    private var plankBottomPanel2: some View {
        VStack(spacing: 18) {
            Text(vm.result.issue.rawValue).font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                AngleCard(title: "Body Line", angle: vm.result.bodyAngle, isOk: vm.result.bodyOk, idealRange: "158°-200°")
                AngleCard(title: "Neck",      angle: vm.result.neckAngle, isOk: vm.result.neckOk, idealRange: "< 35°")
                VStack(spacing: 5) {
                    Text("FORM").font(.caption).foregroundColor(.white.opacity(0.7))
                    Image(systemName: vm.result.bodyOk ? "checkmark.circle.fill" : "xmark.circle.fill").font(.title2).foregroundColor(vm.result.bodyOk ? .green : .red)
                    Text(vm.result.bodyOk ? "✅ OK" : "Fix!").font(.caption2).foregroundColor(vm.result.bodyOk ? .green : .red)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 10).background(vm.result.bodyOk ? Color.green.opacity(0.15) : Color.red.opacity(0.15)).cornerRadius(12)
            }
            HStack(spacing: 50) {
                VStack { Text(timeStr(vm.holdSeconds)).font(.system(size: 46, weight: .bold)).foregroundColor(.white); Text("HOLD").foregroundColor(.white.opacity(0.7)) }
                VStack {
                    Image(systemName: vm.isHolding ? "checkmark.circle.fill" : "pause.circle").font(.title).foregroundColor(vm.isHolding ? .green : .yellow)
                    Text(vm.isHolding ? "HOLDING" : "FIX FORM").font(.caption.bold()).foregroundColor(.white.opacity(0.7))
                }
                Button { vm.resetHold() } label: { VStack { Image(systemName: "arrow.counterclockwise").font(.title2).foregroundColor(.white); Text("RESET").foregroundColor(.white.opacity(0.7)) } }
            }
        }
        .padding().background(.black.opacity(0.75)).cornerRadius(22).padding()
    }
    private func timeStr(_ s: Int) -> String { String(format: "%d:%02d", s/60, s%60) }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - HIGH KNEES
// ─────────────────────────────────────────────────────────────────────────────

enum HKIssue: String {
    case correct      = "✅ Great Knees!"
    case notHighEnough = "❌ Lift Knees Higher"
    case leaningBack  = "❌ Keep Torso Upright"
    case detecting    = "🔍 Detecting..."
    case notVisible   = "📷 Full Body Not Visible"
}

struct HKPostureResult {
    var issue: HKIssue = .detecting
    var postureScore: Int = 100
    var kneeHeight: Double = 0
    var torsoAngle: Double = 90
    var trackedLeftSide = true
    var kneeOk  = true
    var torsoOk = true
}

final class HKViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "fitspire.hk.session", qos: .userInitiated)
    @Published var bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    @Published var result = HKPostureResult()
    @Published var reps = 0
    @Published var showAlert = false; @Published var alertMessage = ""
    @Published var cameraPosition: AVCaptureDevice.Position = .back

    private var isConfiguring = false
    private var frameBuffer: [HKPostureResult] = []
    private var lastKneeHeight: Double = 0
    private var kneeLiftCount = 0
    private var alertTimer: Timer?

    func start() { AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in guard granted else { return }; self?.sessionQueue.async { self?.setup() } } }
    func stop() {
        DispatchQueue.global(qos: .background).async { [weak self] in self?.session.stopRunning() }
    }
    func resetReps() { DispatchQueue.main.async { self.reps = 0; self.kneeLiftCount = 0 } }

    func switchCamera() {
        sessionQueue.async {
            let pos: AVCaptureDevice.Position = self.cameraPosition == .front ? .back : .front
            self.isConfiguring = true
            self.session.beginConfiguration()
            if let old = self.session.inputs.first { self.session.removeInput(old) }
            guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: pos),
                  let inp = try? AVCaptureDeviceInput(device: dev), self.session.canAddInput(inp)
            else { self.session.commitConfiguration(); self.isConfiguring = false; return }
            self.session.addInput(inp); self.session.commitConfiguration()
            self.session.startRunning()
            self.isConfiguring = false
            DispatchQueue.main.async { self.cameraPosition = pos }
        }
    }

    private func setup() {
        session.stopRunning()
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        session.sessionPreset = .high
        guard let dev = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let inp = try? AVCaptureDeviceInput(device: dev), session.canAddInput(inp) else { return }
        session.addInput(inp)
        let out = AVCaptureVideoDataOutput()
        out.setSampleBufferDelegate(self, queue: DispatchQueue(label: "hkQueue2"))
        out.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(out) { session.addOutput(out) }
        session.commitConfiguration()
        session.startRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sb: CMSampleBuffer, from conn: AVCaptureConnection) {
        guard let pxBuf = CMSampleBufferGetImageBuffer(sb) else { return }
        let orient: CGImagePropertyOrientation = cameraPosition == .front ? .leftMirrored : .right
        let req = VNDetectHumanBodyPoseRequest()
        let h = VNImageRequestHandler(cvPixelBuffer: pxBuf, orientation: orient)
        do {
            try h.perform([req])
            guard let obs = req.results?.first else { return }
            let pts = try obs.recognizedPoints(.all)
            updatePoints(pts)
            var raw = analyze(pts)
            if raw.issue == .notVisible { DispatchQueue.main.async { self.result = raw }; return }
            frameBuffer.append(raw)
            if frameBuffer.count > 5 { frameBuffer.removeFirst() }
            let n = Double(frameBuffer.count)
            raw.kneeHeight = frameBuffer.map { $0.kneeHeight }.reduce(0,+) / n
            raw.torsoAngle = frameBuffer.map { $0.torsoAngle }.reduce(0,+) / n
            raw.postureScore = Int(Double(frameBuffer.map { $0.postureScore }.reduce(0,+)) / n)
            // Count reps: knee peak detection
            if raw.kneeHeight > lastKneeHeight + 0.04 && lastKneeHeight < 0.02 {
                kneeLiftCount += 1
                DispatchQueue.main.async { self.reps = self.kneeLiftCount / 2 }
            }
            lastKneeHeight = raw.kneeHeight
            showFormAlert(raw)
            DispatchQueue.main.async { self.result = raw }
        } catch {}
    }

    private func analyze(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> HKPostureResult {
        var r = HKPostureResult()
        let lConf: Float = (pts[.leftHip]?.confidence ?? 0) + (pts[.leftKnee]?.confidence ?? 0)
        let rConf: Float = (pts[.rightHip]?.confidence ?? 0) + (pts[.rightKnee]?.confidence ?? 0)
        let useLeft = lConf >= rConf; r.trackedLeftSide = useLeft
        let hpK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftHip   : .rightHip
        let knK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftKnee  : .rightKnee
        let shK: VNHumanBodyPoseObservation.JointName = useLeft ? .leftShoulder : .rightShoulder
        for j in [hpK, knK] { guard let p = pts[j], p.confidence > 0.35 else { r.issue = .notVisible; return r } }
        guard let hp = pts[hpK]?.location, let kn = pts[knK]?.location else {
            r.issue = .notVisible; return r
        }
        // Knee height relative to hip (positive = knee ABOVE hip)
        r.kneeHeight = hp.y - kn.y
        r.kneeOk = r.kneeHeight >= 0.05
        if let sh = pts[shK], sh.confidence > 0.3 {
            let torso = abs(atan2(sh.location.y - hp.y, sh.location.x - hp.x) * 180 / .pi)
            r.torsoAngle = torso; r.torsoOk = torso >= 55
        } else { r.torsoOk = true }
        var score = 100
        if !r.kneeOk  { score -= 35 }
        if !r.torsoOk { score -= 30 }
        r.postureScore = max(score, 0)
        if !r.torsoOk  { r.issue = .leaningBack }
        else if !r.kneeOk { r.issue = .notHighEnough }
        else              { r.issue = .correct }
        return r
    }

    private func showFormAlert(_ r: HKPostureResult) {
        var msg: String? = nil
        if !r.kneeOk  { msg = "Lift Knees To Hip Height!" }
        else if !r.torsoOk { msg = "Don't Lean Back — Stay Upright!" }
        DispatchQueue.main.async {
            if let m = msg { self.alertMessage = m; self.showAlert = true; self.alertTimer?.invalidate(); self.alertTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in DispatchQueue.main.async { self.showAlert = false } } }
            else { self.showAlert = false }
        }
    }

    private func updatePoints(_ pts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        var m: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        for (j, p) in pts where p.confidence > 0.3 { m[j] = CGPoint(x: p.location.x, y: 1 - p.location.y) }
        DispatchQueue.main.async { self.bodyPoints = m }
    }
}

struct HKSkeletonOverlay: View {
    let bodyPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let result: HKPostureResult
    var body: some View { hkSkeletonBody }
    @ViewBuilder private var hkSkeletonBody: some View {
        GeometryReader { geo in ZStack { hkBones(geo: geo); hkJoints(geo: geo) } }
    }
    private var sh: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftShoulder : .rightShoulder }
    private var hp: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftHip      : .rightHip }
    private var kn: VNHumanBodyPoseObservation.JointName { result.trackedLeftSide ? .leftKnee     : .rightKnee }
    @ViewBuilder private func hkBones(geo: GeometryProxy) -> some View {
        hkLine(sh, hp, geo, ok: result.torsoOk)
        hkLine(hp, kn, geo, ok: result.kneeOk)
    }
    @ViewBuilder private func hkLine(_ j1: VNHumanBodyPoseObservation.JointName, _ j2: VNHumanBodyPoseObservation.JointName, _ geo: GeometryProxy, ok: Bool) -> some View {
        if let p1 = bodyPoints[j1], let p2 = bodyPoints[j2] {
            Path { p in p.move(to: CGPoint(x: p1.x*geo.size.width, y: p1.y*geo.size.height)); p.addLine(to: CGPoint(x: p2.x*geo.size.width, y: p2.y*geo.size.height)) }
            .stroke(ok ? Color.green : Color.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
    @ViewBuilder private func hkJoints(geo: GeometryProxy) -> some View {
        ForEach([sh, hp, kn], id: \.self) { j in
            if let pt = bodyPoints[j] {
                let ok = j == sh ? result.torsoOk : result.kneeOk
                Circle().fill(ok ? Color.green : Color.red).frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
                    .position(x: pt.x*geo.size.width, y: pt.y*geo.size.height)
            }
        }
    }
}

struct HKCameraView: View {
    @StateObject private var vm = HKViewModel()
    var body: some View { hkContent }
    @ViewBuilder private var hkContent: some View {
        ZStack {
            ExerciseSessionPreview(session: vm.session).ignoresSafeArea()
            HKSkeletonOverlay(bodyPoints: vm.bodyPoints, result: vm.result).ignoresSafeArea()
            VStack {
                hkTopBar; Spacer()
                if vm.showAlert { FormAlertBanner(message: vm.alertMessage).transition(.move(edge: .top).combined(with: .opacity)) }
                Spacer(); hkBottomPanel
            }
        }
        .onAppear { vm.start() }.onDisappear { vm.stop() }
        .animation(.spring(response: 0.4), value: vm.showAlert)
    }
    private var hkTopBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) { Text("High Knees AI").font(.title2.bold()).foregroundColor(.white); Text("Drive Knees to Hip Height").font(.caption).foregroundColor(.white.opacity(0.7)) }
            Spacer()
            Button { vm.switchCamera() } label: { Image(systemName: "camera.rotate").font(.title2).foregroundColor(.white).padding(12).background(Color.white.opacity(0.2)).clipShape(Circle()) }
            ExScoreRing(score: vm.result.postureScore)
        }
        .padding().background(.black.opacity(0.65)).cornerRadius(20).padding()
    }
    private var hkBottomPanel: some View {
        VStack(spacing: 18) {
            Text(vm.result.issue.rawValue).font(.title2.bold()).foregroundColor(.white).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                AngleCard(title: "Torso",      angle: vm.result.torsoAngle,       isOk: vm.result.torsoOk, idealRange: "> 55°")
                AngleCard(title: "Knee Height",angle: vm.result.kneeHeight * 100, isOk: vm.result.kneeOk,  idealRange: "> 5%")
                VStack(spacing: 5) {
                    Text("DRIVE").font(.caption).foregroundColor(.white.opacity(0.7))
                    Image(systemName: vm.result.kneeOk ? "checkmark.circle.fill" : "xmark.circle.fill").font(.title2).foregroundColor(vm.result.kneeOk ? .green : .red)
                    Text(vm.result.kneeOk ? "Hip High" : "Too Low").font(.caption2).foregroundColor(vm.result.kneeOk ? .green : .red)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 10).background(vm.result.kneeOk ? Color.green.opacity(0.15) : Color.red.opacity(0.15)).cornerRadius(12)
            }
            HStack(spacing: 50) {
                VStack { Text("\(vm.reps)").font(.system(size: 50, weight: .bold)).foregroundColor(.white); Text("REPS").foregroundColor(.white.opacity(0.7)) }
                VStack { Text(vm.result.kneeOk ? "Great ✅" : "Fix Form").font(.title3.bold()).foregroundColor(vm.result.kneeOk ? .green : .red); Text("STATUS").foregroundColor(.white.opacity(0.7)) }
                Button { vm.resetReps() } label: { VStack { Image(systemName: "arrow.counterclockwise").font(.title2).foregroundColor(.white); Text("RESET").foregroundColor(.white.opacity(0.7)) } }
            }
        }
        .padding().background(.black.opacity(0.75)).cornerRadius(22).padding()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - SHARED HELPERS (used by all views above)
// ─────────────────────────────────────────────────────────────────────────────

// Score ring
struct ExScoreRing: View {
    let score: Int
    var color: Color { score >= 80 ? .green : score >= 55 ? .yellow : .red }
    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.2), lineWidth: 5).frame(width: 65, height: 65)
            Circle().trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 65, height: 65).rotationEffect(.degrees(-90))
            Text("\(score)").font(.headline.bold()).foregroundColor(.white)
        }
    }
}

// Bad rep overlay
struct BadRepOverlay: View {
    let reason: String
    var body: some View {
        ZStack {
            Color.red.opacity(0.25).ignoresSafeArea().allowsHitTesting(false)
            VStack {
                Spacer()
                Text("⚠️ Rep Not Counted\n\(reason)")
                    .font(.title3.bold()).foregroundColor(.white).multilineTextAlignment(.center)
                    .padding().background(Color.red.opacity(0.85)).cornerRadius(16).padding(.bottom, 220)
            }
        }
    }
}
