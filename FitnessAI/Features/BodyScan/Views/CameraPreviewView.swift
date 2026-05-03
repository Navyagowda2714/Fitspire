import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black

        let previewLayer = cameraManager.makePreviewLayer()
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first
            as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}
