//
//  ExerciseVideoPlayerView.swift
//  Praxio
//

import SwiftUI
import AVFoundation
import AVKit

struct ExerciseVideoPlayerView: UIViewRepresentable {
    let videoName: String

    func makeUIView(context: Context) -> LoopingPlayerView {
        let view = LoopingPlayerView()
        view.load(videoNamed: videoName)
        return view
    }

    func updateUIView(_ uiView: LoopingPlayerView, context: Context) {
        if uiView.currentVideoName != videoName {
            uiView.load(videoNamed: videoName)
        }
    }
}

final class LoopingPlayerView: UIView {
    private var player:      AVQueuePlayer?
    private var looper:      AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private(set) var currentVideoName: String?

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    func load(videoNamed name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp4") else {
            print("⚠️ ExerciseVideo: '\(name).mp4' not found in bundle")
            return
        }
        currentVideoName = name
        looper?.disableLooping()
        player?.pause()
        playerLayer?.removeFromSuperlayer()

        let item = AVPlayerItem(url: url)
        let qp   = AVQueuePlayer(playerItem: item)
        let loop = AVPlayerLooper(player: qp, templateItem: item)

        qp.isMuted = false
        qp.play()

        let layer             = AVPlayerLayer(player: qp)
        layer.videoGravity    = .resizeAspect
        layer.frame           = bounds
        layer.backgroundColor = UIColor.clear.cgColor

        self.layer.insertSublayer(layer, at: 0)
        playerLayer = layer
        player      = qp
        looper      = loop
    }

    deinit {
        looper?.disableLooping()
        player?.pause()
    }
}

extension HomeExercise {
    var videoFileName: String? {
        switch name {
        case "Plank":             return "plank"
        case "Bodyweight Squat":  return "squat"
        case "Push-Up":           return "pushup"
        case "Reverse Lunge":     return "lunge"
        case "Glute Bridge":      return "glutebridge"
        case "Mountain Climber":  return "mountainclimber"
        case "Burpee":            return "burpee"
        case "Tricep Dip":        return "tricepdip"
        case "High Knees":        return "highknees"
        case "Superman Hold":     return "superman"
        default:                  return nil
        }
    }
}

