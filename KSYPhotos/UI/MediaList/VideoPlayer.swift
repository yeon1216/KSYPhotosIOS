//
//  VideoPlayer.swift
//  KSYPhotos
//
//  Created by ksy on 7/16/24.
//

import SwiftUI
import AVKit
//import Photos

struct VideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}
