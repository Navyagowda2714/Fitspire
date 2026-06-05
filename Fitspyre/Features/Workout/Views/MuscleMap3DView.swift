//
//  MuscleMapView.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 17/05/2026.
//

//
//  MuscleMap3DView.swift
//  Praxio
//
//  Full 3D human body built entirely from SceneKit primitives.
//  No external assets required — every muscle group is an SCNNode.
//
//  Features:
//  • Drag to rotate 360° on Y axis
//  • Auto-slow spin when idle
//  • Primary muscles → lime glow
//  • Secondary muscles → teal glow
//  • Inactive → dark blue-grey
//  • Tap any muscle to see its name
//  • Smooth camera animation on appear
//

import SwiftUI
import SceneKit

// MARK: - SwiftUI wrapper

struct MuscleMap3DView: View {
    let exercise: HomeExercise
    @State private var tappedMuscle: String? = nil
    @State private var scene: SCNScene? = nil

    private var activation: MuscleActivation { exercise.muscleActivation }

    var body: some View {
        ZStack {
            // ── 3D Scene ───────────────────────────────────────────────────
            BodySceneView(
                activation: activation,
                tappedMuscle: $tappedMuscle,
                scene: $scene
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // ── Tapped muscle name label ───────────────────────────────────
            if let name = tappedMuscle {
                VStack {
                    Spacer()
                    Text(name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color(hex: "E8FF5A"))
                        .clipShape(Capsule())
                        .shadow(color: Color(hex: "E8FF5A").opacity(0.5), radius: 10)
                        .padding(.bottom, 16)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.3), value: tappedMuscle)
                }
            }

            // ── Drag hint ─────────────────────────────────────────────────
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "rotate.3d")
                            .font(.system(size: 10))
                        Text("Drag to rotate")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(8)
                }
                Spacer()
            }
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0B1520"), Color(hex: "0D1A2B")],
                startPoint: .top, endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        )
    }
}

// MARK: - SCNView wrapper

struct BodySceneView: UIViewRepresentable {
    let activation: MuscleActivation
    @Binding var tappedMuscle: String?
    @Binding var scene: SCNScene?

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false  // custom gesture

        let scene = BodySceneBuilder.buildScene(activation: activation)
        scnView.scene = scene
        // Drag gesture for Y-axis rotation
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        scnView.addGestureRecognizer(pan)

        // Tap to identify muscle
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tap)

        context.coordinator.scnView = scnView
        context.coordinator.tappedMuscle = $tappedMuscle

        // Auto-spin
        context.coordinator.startAutoSpin()

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject {
        weak var scnView: SCNView?
        var tappedMuscle: Binding<String?>?
        private var lastPanX: Float = 0
        private var autoSpinTimer: Timer?
        private var idleTimer: Timer?
        private var isPanning = false

        func startAutoSpin() {
            guard let body = scnView?.scene?.rootNode.childNode(withName: "body", recursively: false) else { return }
            let spin = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0.005, z: 0, duration: 0.016))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                body.runAction(spin, forKey: "autoSpin")
            }
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let body = scnView?.scene?.rootNode.childNode(withName: "body", recursively: false) else { return }
            switch gesture.state {
            case .began:
                isPanning = true
                body.removeAction(forKey: "autoSpin")
                idleTimer?.invalidate()
                lastPanX = Float(gesture.translation(in: scnView).x)
            case .changed:
                let x = Float(gesture.translation(in: scnView).x)
                let delta = (x - lastPanX) * 0.01
                body.eulerAngles.y += delta
                lastPanX = x
            case .ended, .cancelled:
                isPanning = false
                idleTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
                    self?.startAutoSpin()
                }
            default: break
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = scnView else { return }
            let pt = gesture.location(in: scnView)
            let hits = scnView.hitTest(pt, options: [.searchMode: SCNHitTestSearchMode.closest.rawValue])
            if let hit = hits.first, let name = hit.node.name, !name.isEmpty, name != "body" {
                DispatchQueue.main.async { [weak self] in
                    self?.tappedMuscle?.wrappedValue = name
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.tappedMuscle?.wrappedValue = nil
                    }
                }
            }
        }
    }
}

// MARK: - Scene builder

enum BodySceneBuilder {

    // Colours
    static let primary   = UIColor(red: 0.91, green: 1.00, blue: 0.35, alpha: 1)  // lime
    static let secondary = UIColor(red: 0.11, green: 0.62, blue: 0.46, alpha: 1)  // teal
    static let inactive  = UIColor(red: 0.10, green: 0.19, blue: 0.31, alpha: 1)  // dark blue
    static let skin      = UIColor(red: 0.14, green: 0.24, blue: 0.38, alpha: 1)  // body silhouette

    static func buildScene(activation: MuscleActivation) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        // ── Camera ───────────────────────────────────────────────────────
        let camNode = SCNNode()
        camNode.camera = SCNCamera()
        camNode.camera?.fieldOfView = 50
        camNode.position = SCNVector3(0, 0, 3.8)
        scene.rootNode.addChildNode(camNode)

        // ── Lighting ─────────────────────────────────────────────────────
        let ambient = SCNNode(); ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light!.color = UIColor(white: 0.4, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let front = SCNNode(); front.light = SCNLight()
        front.light!.type = .directional
        front.light!.color = UIColor(white: 0.8, alpha: 1)
        front.eulerAngles = SCNVector3(-0.3, 0, 0)
        scene.rootNode.addChildNode(front)

        let fill = SCNNode(); fill.light = SCNLight()
        fill.light!.type = .directional
        fill.light!.color = UIColor(white: 0.3, alpha: 1)
        fill.eulerAngles = SCNVector3(0.3, .pi, 0)
        scene.rootNode.addChildNode(fill)

        // ── Body root (all muscles attach here, rotates together) ────────
        let body = SCNNode(); body.name = "body"
        scene.rootNode.addChildNode(body)

        // Build the body parts
        addHead(to: body)
        addNeck(to: body)
        addTorso(to: body, activation: activation)
        addShoulders(to: body, activation: activation)
        addArms(to: body, activation: activation)
        addHips(to: body, activation: activation)
        addLegs(to: body, activation: activation)
        addCalves(to: body, activation: activation)

        // Intro animation: body rises from below
        body.position = SCNVector3(0, -3, 0)
        body.opacity = 0
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.8
        body.position = SCNVector3(0, 0.1, 0)
        body.opacity = 1
        SCNTransaction.commit()

        return scene
    }

    // MARK: Colour helper

    static func color(for region: MuscleRegion, activation: MuscleActivation) -> UIColor {
        if activation.primary.contains(region)   { return primary }
        if activation.secondary.contains(region) { return secondary }
        return inactive
    }

    static func material(_ color: UIColor, emission: UIColor? = nil) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents   = color
        m.specular.contents  = UIColor.white
        m.shininess          = 0.25
        m.lightingModel      = .phong
        if let e = emission {
            m.emission.contents = e
        }
        return m
    }

    static func node(geometry: SCNGeometry, name: String, position: SCNVector3,
                     color: UIColor, eulerAngles: SCNVector3 = .init(0,0,0)) -> SCNNode {
        let emiss: UIColor? = (color == primary || color == secondary)
            ? color.withAlphaComponent(0.25) : nil
        geometry.materials = [material(color, emission: emiss)]
        let n = SCNNode(geometry: geometry)
        n.name = name
        n.position = position
        n.eulerAngles = eulerAngles
        return n
    }

    // MARK: - Body parts

    static func addHead(to body: SCNNode) {
        let head = SCNSphere(radius: 0.16)
        body.addChildNode(node(geometry: head, name: "", position: SCNVector3(0, 1.62, 0), color: skin))
    }

    static func addNeck(to body: SCNNode) {
        let neck = SCNCylinder(radius: 0.055, height: 0.14)
        body.addChildNode(node(geometry: neck, name: "", position: SCNVector3(0, 1.42, 0), color: skin))
    }

    static func addTorso(to body: SCNNode, activation: MuscleActivation) {
        // Chest (pecs) — left + right
        for side: Float in [-1, 1] {
            let pec = SCNCapsule(capRadius: 0.095, height: 0.18)
            let c = color(for: .chest, activation: activation)
            body.addChildNode(node(geometry: pec, name: "Chest",
                position: SCNVector3(side * 0.11, 1.18, 0.04),
                color: c, eulerAngles: SCNVector3(0, 0, Float.pi/2 * -side * 0.3)))
        }

        // Abs (3 rows × 2 cols)
        let absC = color(for: .abs, activation: activation)
        for row in 0..<3 {
            for side: Float in [-1, 1] {
                let ab = SCNBox(width: 0.085, height: 0.085, length: 0.06, chamferRadius: 0.02)
                body.addChildNode(node(geometry: ab, name: "Abs",
                    position: SCNVector3(side * 0.06, 0.92 - Float(row) * 0.1, 0.07),
                    color: absC))
            }
        }

        // Obliques
        let oblC = color(for: .obliques, activation: activation)
        for side: Float in [-1, 1] {
            let obl = SCNCapsule(capRadius: 0.05, height: 0.28)
            body.addChildNode(node(geometry: obl, name: "Obliques",
                position: SCNVector3(side * 0.18, 0.93, 0.02),
                color: oblC, eulerAngles: SCNVector3(0, 0, side * 0.28)))
        }

        // Traps (back)
        let trapC = color(for: .traps, activation: activation)
        let trap = SCNBox(width: 0.38, height: 0.20, length: 0.05, chamferRadius: 0.04)
        body.addChildNode(node(geometry: trap, name: "Traps",
            position: SCNVector3(0, 1.22, -0.07), color: trapC))

        // Lats (back wings)
        let latC = color(for: .lats, activation: activation)
        for side: Float in [-1, 1] {
            let lat = SCNCapsule(capRadius: 0.07, height: 0.32)
            body.addChildNode(node(geometry: lat, name: "Lats",
                position: SCNVector3(side * 0.20, 1.0, -0.06),
                color: latC, eulerAngles: SCNVector3(0, 0, side * 0.5)))
        }

        // Lower back / erectors
        let lbC = color(for: .lowerBack, activation: activation)
        for side: Float in [-1, 1] {
            let lb = SCNCapsule(capRadius: 0.042, height: 0.30)
            body.addChildNode(node(geometry: lb, name: "Lower Back",
                position: SCNVector3(side * 0.07, 0.70, -0.07), color: lbC))
        }

        // Core / spine silhouette
        let spine = SCNCylinder(radius: 0.12, height: 0.55)
        let spineMat = material(skin.withAlphaComponent(0.4))
        spine.materials = [spineMat]
        let spineNode = SCNNode(geometry: spine); spineNode.name = ""
        spineNode.position = SCNVector3(0, 0.95, 0); body.addChildNode(spineNode)
    }

    static func addShoulders(to body: SCNNode, activation: MuscleActivation) {
        let shC = color(for: .frontShoulders, activation: activation)
        let rsC = color(for: .rearShoulders, activation: activation)
        for side: Float in [-1, 1] {
            // Front delt
            let fd = SCNSphere(radius: 0.085)
            body.addChildNode(node(geometry: fd, name: "Front Shoulders",
                position: SCNVector3(side * 0.26, 1.24, 0.04), color: shC))
            // Rear delt
            let rd = SCNSphere(radius: 0.075)
            body.addChildNode(node(geometry: rd, name: "Rear Shoulders",
                position: SCNVector3(side * 0.26, 1.24, -0.05), color: rsC))
        }
    }

    static func addArms(to body: SCNNode, activation: MuscleActivation) {
        let bicC = color(for: .biceps,  activation: activation)
        let triC = color(for: .triceps, activation: activation)
        let faC  = color(for: .forearms, activation: activation)

        for side: Float in [-1, 1] {
            // Upper arm (bicep front, tricep back)
            let bic = SCNCapsule(capRadius: 0.052, height: 0.28)
            body.addChildNode(node(geometry: bic, name: "Biceps",
                position: SCNVector3(side * 0.34, 1.04, 0.03), color: bicC,
                eulerAngles: SCNVector3(0, 0, side * 0.18)))

            let tri = SCNCapsule(capRadius: 0.048, height: 0.28)
            body.addChildNode(node(geometry: tri, name: "Triceps",
                position: SCNVector3(side * 0.34, 1.04, -0.04), color: triC,
                eulerAngles: SCNVector3(0, 0, side * 0.18)))

            // Forearm
            let fa = SCNCapsule(capRadius: 0.038, height: 0.26)
            body.addChildNode(node(geometry: fa, name: "Forearms",
                position: SCNVector3(side * 0.40, 0.72, 0.01), color: faC,
                eulerAngles: SCNVector3(0, 0, side * 0.25)))
        }
    }

    static func addHips(to body: SCNNode, activation: MuscleActivation) {
        let hfC  = color(for: .hipFlexors, activation: activation)
        let glC  = color(for: .glutes, activation: activation)

        // Hip flexor (front)
        let hf = SCNBox(width: 0.28, height: 0.14, length: 0.08, chamferRadius: 0.03)
        body.addChildNode(node(geometry: hf, name: "Hip Flexors",
            position: SCNVector3(0, 0.56, 0.05), color: hfC))

        // Glutes (back, two lobes)
        for side: Float in [-1, 1] {
            let gl = SCNSphere(radius: 0.10)
            body.addChildNode(node(geometry: gl, name: "Glutes",
                position: SCNVector3(side * 0.10, 0.53, -0.09), color: glC))
        }
    }

    static func addLegs(to body: SCNNode, activation: MuscleActivation) {
        let qC = color(for: .quads,     activation: activation)
        let hC = color(for: .hamstrings, activation: activation)

        for side: Float in [-1, 1] {
            // Quad (front thigh)
            let quad = SCNCapsule(capRadius: 0.085, height: 0.40)
            body.addChildNode(node(geometry: quad, name: "Quads",
                position: SCNVector3(side * 0.12, 0.23, 0.04), color: qC))

            // Hamstring (back thigh)
            let ham = SCNCapsule(capRadius: 0.075, height: 0.38)
            body.addChildNode(node(geometry: ham, name: "Hamstrings",
                position: SCNVector3(side * 0.12, 0.22, -0.05), color: hC))

            // Knee cap silhouette
            let kn = SCNSphere(radius: 0.055)
            body.addChildNode(node(geometry: kn, name: "",
                position: SCNVector3(side * 0.12, 0.0, 0.06), color: skin))
        }
    }

    static func addCalves(to body: SCNNode, activation: MuscleActivation) {
        let cvC = color(for: .calves, activation: activation)
        let shC = color(for: .shins,  activation: activation)

        for side: Float in [-1, 1] {
            // Calf (back)
            let calf = SCNCapsule(capRadius: 0.055, height: 0.30)
            body.addChildNode(node(geometry: calf, name: "Calves",
                position: SCNVector3(side * 0.12, -0.26, -0.02), color: cvC))

            // Shin (front)
            let shin = SCNCapsule(capRadius: 0.035, height: 0.26)
            body.addChildNode(node(geometry: shin, name: "Shins",
                position: SCNVector3(side * 0.12, -0.26, 0.05), color: shC))

            // Foot silhouette
            let foot = SCNBox(width: 0.07, height: 0.04, length: 0.14, chamferRadius: 0.02)
            body.addChildNode(node(geometry: foot, name: "",
                position: SCNVector3(side * 0.12, -0.46, 0.04), color: skin))
        }
    }
}

// MARK: - Integration view (drop-in replacement for AnatomicalMuscleMapView)

struct Muscle3DTargetsView: View {
    let exercise: HomeExercise

    private var activation: MuscleActivation { exercise.muscleActivation }

    var body: some View {
        VStack(spacing: 14) {
            // 3D body
            MuscleMap3DView(exercise: exercise)
                .frame(height: 360)

            // Legend
            HStack(spacing: 24) {
                legendItem(Color(hex: "E8FF5A"), "Primary")
                legendItem(Color(hex: "1D9E75"), "Secondary")
                legendItem(Color(hex: "1E3050"), "Inactive")
            }

            // Muscle name pills
            if !activation.primary.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PRIMARY").font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: "E8FF5A").opacity(0.7))
                        .padding(.horizontal, 4)
                    ScrollView(Axis.Set.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(activation.primary.map { $0.rawValue }, id: \.self) { name in
                                Text(name).font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Color(hex: "E8FF5A")).clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            if !activation.secondary.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("SECONDARY").font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: "1D9E75").opacity(0.7))
                        .padding(.horizontal, 4)
                    ScrollView(Axis.Set.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(activation.secondary.map { $0.rawValue }, id: \.self) { name in
                                Text(name).font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Color(hex: "1D9E75")).clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private func legendItem(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 18, height: 10)
            Text(label).font(.system(size: 11)).foregroundStyle(Color.white.opacity(0.4))
        }
    }
}
