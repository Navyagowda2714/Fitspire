//
//  CamerPreviewLayer.swift
//  Fitspire
//
//  Created by Navyashree Byregowda on 01/06/2026.
//

import SwiftUI
import AVFoundation

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.session = session
        return view
    }
    func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    var session: AVCaptureSession? {
        didSet {
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
        }
    }
}
