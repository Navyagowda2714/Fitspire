//
//  CameraManager.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 01/05/2026.
//
//
//  CameraManager.swift
//  Fitspyre
//
//  Created by Navyashree Byregowda on 01/05/2026.
//

import AVFoundation
import Combine

// @preconcurrency: tells Swift 6 strict-concurrency checker this protocol predates
// the concurrency model. Suppresses the false-positive "call to main-actor-isolated method"
// warning when CameraManager (nonisolated captureOutput) calls the delegate.
// The conforming LivePoseViewModel extension explicitly marks the method `nonisolated`.
@preconcurrency
protocol CameraManagerDelegate: AnyObject, Sendable {
    nonisolated func cameraManager(_ manager: CameraManager,
                       didOutput pixelBuffer: CVPixelBuffer)
}

final class CameraManager: NSObject, ObservableObject {
    nonisolated(unsafe) weak var delegate: CameraManagerDelegate?

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    @Published var isRunning: Bool = false
    @Published var permissionGranted: Bool = false

    var previewLayer: AVCaptureVideoPreviewLayer?

    override init() {
        super.init()
        checkPermission()
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted { self?.setupSession() }
                }
            }
        default:
            permissionGranted = false
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()

            guard let currentInput = self.session.inputs.first
                    as? AVCaptureDeviceInput else {
                self.session.commitConfiguration()
                return
            }

            let newPosition: AVCaptureDevice.Position =
                currentInput.device.position == .back ? .front : .back

            guard
                let newDevice = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: newPosition
                ),
                let newInput = try? AVCaptureDeviceInput(device: newDevice)
            else {
                self.session.commitConfiguration()
                return
            }

            self.session.removeInput(currentInput)

            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
            }

            self.session.commitConfiguration()
        }
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard
                let device = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .back
                ),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)

            self.videoOutput.setSampleBufferDelegate(
                self,
                queue: DispatchQueue(label: "video.output.queue")
            )
            self.videoOutput.alwaysDiscardsLateVideoFrames = true

            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
            }

            if let connection = self.videoOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }
            }

            self.session.commitConfiguration()
        }
    }

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isRunning = false }
        }
    }

    func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.previewLayer = layer
        return layer
    }
}

/*
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Capture delegate reference immediately to avoid data race on optional access
        let d = delegate
        d?.cameraManager(self, didOutput: sampleBuffer)
    }
}
*/
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        delegate?.cameraManager(self, didOutput: pixelBuffer)
    }
}
