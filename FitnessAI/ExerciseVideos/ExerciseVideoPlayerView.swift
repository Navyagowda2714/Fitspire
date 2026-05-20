//
//  ExerciseVideoPlayerView.swift
//  FitnessAI
//
//  Created by Navyashree Byregowda on 17/05/2026.
//


import SwiftUI
import AVFoundation
import AVKit

// MARK: - Seamless looping video player

struct ExerciseVideoPlayerView: UIViewRepresentable {
    let videoName: String   // filename without extension, e.g. "plank"
    var showsControls: Bool = false

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

// MARK: - UIView subclass that owns the player and looper

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
            print("⚠️ ExerciseVideo: '\(name).mp4' not found in bundle — using fallback animation")
            return
        }

        currentVideoName = name

        // Tear down previous player
        looper?.disableLooping()
        player?.pause()
        playerLayer?.removeFromSuperlayer()

        // Build new looping player
        let item   = AVPlayerItem(url: url)
        let qp     = AVQueuePlayer(playerItem: item)
        let loop   = AVPlayerLooper(player: qp, templateItem: item)

        qp.isMuted = true   // silent demo — no audio needed
        qp.play()

        let layer            = AVPlayerLayer(player: qp)
        layer.videoGravity   = .resizeAspect   // letterbox — keep proportions
        layer.frame          = bounds
        layer.backgroundColor = UIColor.clear.cgColor

        self.layer.insertSublayer(layer, at: 0)
        playerLayer   = layer
        player        = qp
        looper        = loop
    }

    deinit {
        looper?.disableLooping()
        player?.pause()
    }
}

// MARK: - Exercise → video filename mapping

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
