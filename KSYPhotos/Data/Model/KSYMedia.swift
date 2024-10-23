//
//  KSYMedia.swift
//  KSYPhotos
//
//  Created by ksy on 7/10/24.
//

import Foundation
import Photos

struct KSYMedia: Equatable {
    let assetIdentifier: String
    var isLocallyAvailable: Bool
    var type: KSYMediaType
    
    var asset: PHAsset? {
        get {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
            return assets.firstObject
        }
    }
    
    enum KSYMediaType: Int {
        case image = 0, video
    }
}
