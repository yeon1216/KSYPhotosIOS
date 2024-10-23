//
//  VideoPlayerService.swift
//  KSYPhotos
//
//  Created by BOBBY.KIM on 9/25/24.
//

import AVFoundation
import Photos

struct VideoPlayerService {
    static func playVideo(asset: PHAsset) async -> AVPlayer? {
        if let avAsset = await PHImageManager.default().requestAVAssetAsync(forVideo: asset, options: nil) {
            let playerItem = AVPlayerItem(asset: avAsset)
            return AVPlayer(playerItem: playerItem)
        }
        return nil
    }
}
