//
//  PHAsset+Extension.swift
//  KSYPhotos
//
//  Created by ksy on 7/15/24.
//

import Photos
import AVFoundation

extension PHImageManager {
    func requestAVAssetAsync(forVideo asset: PHAsset, options: PHVideoRequestOptions?) async -> AVAsset? {
        await withCheckedContinuation { continuation in
            self.requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                continuation.resume(returning: avAsset)
            }
        }
    }
}

extension PHAsset {
    
    func getKSYMediaType() -> KSYMedia.KSYMediaType? {
        return if self.mediaType == .image {
            KSYMedia.KSYMediaType.image
        } else if self.mediaType == .video {
            KSYMedia.KSYMediaType.video
        } else {
            nil
        }
    }
    
    func isLocallyAvailable() -> Bool {
        let resource = PHAssetResource.assetResources(for: self).first
        return resource?.value(forKey: "locallyAvailable") as? Bool ?? false
    }
    
}
