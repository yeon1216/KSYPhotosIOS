//
//  MediaManager.swift
//  KSYPhotos
//
//  Created byksy on 7/10/24.
//

import Foundation
import Photos
import SwiftUI

class MediaManager {
    static let shared = MediaManager()
    
    private init() {}
    
    // Request authorization to access photo library
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized, .limited:
                    continuation.resume(returning: true)
                case .denied, .restricted, .notDetermined:
                    continuation.resume(returning: false)
                @unknown default:
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // Fetch all albums from photo library
    func fetchAlbums() async -> [PHAssetCollection] {
        await withCheckedContinuation { continuation in
            var albums = [PHAssetCollection]()
            
            let userAlbumsOptions = PHFetchOptions()
            let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: userAlbumsOptions)
            
            userAlbums.enumerateObjects { (collection, _, _) in
                albums.append(collection)
            }
            
            let smartAlbumsOptions = PHFetchOptions()
            let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: smartAlbumsOptions)
            
            smartAlbums.enumerateObjects { (collection, _, _) in
                albums.append(collection)
            }
            
            continuation.resume(returning: albums)
        }
    }
    
    // Fetch all media assets from a specific album
    func fetchMedia(in album: PHAssetCollection) async -> [PHAsset] {
        await withCheckedContinuation { continuation in
            var mediaAssets = [PHAsset]()
            let assetsFetchOptions = PHFetchOptions()
            let predicate: NSPredicate = NSPredicate(format: "mediaType == %d || mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
            assetsFetchOptions.predicate = predicate
            assetsFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(in: album, options: assetsFetchOptions)
            assets.enumerateObjects { (asset, _, _) in
                mediaAssets.append(asset)
            }
            continuation.resume(returning: mediaAssets)
        }
    }
    
    // Fetch all media assets from a specific album by its local identifier
    func fetchMedia(in albumLocalIdentifier: String) async -> [PHAsset]? {
        await withCheckedContinuation { continuation in
            var mediaAssets = [PHAsset]()
            // Fetch the album using the local identifier
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "localIdentifier == %@", albumLocalIdentifier)
            let albumResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            
            var album: PHAssetCollection? = albumResult.firstObject
            if album == nil {
                let smartAlbumResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: fetchOptions)
                album = smartAlbumResult.firstObject
            }
            guard let unwrappedAlbum = album else {
                continuation.resume(returning: nil)
                return
            }
            // Fetch assets in the album
            let assetsFetchOptions = PHFetchOptions()
            let predicate = NSPredicate(format: "mediaType == %d || mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
            assetsFetchOptions.predicate = predicate
            assetsFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(in: unwrappedAlbum, options: assetsFetchOptions)
            
            assets.enumerateObjects { (asset, _, _) in
                mediaAssets.append(asset)
            }
            
            continuation.resume(returning: mediaAssets)
        }
    }
    
    // Fetch all media assets from photo library
    func fetchAllMedia() async -> [PHAsset] {
        await withCheckedContinuation { continuation in
            var allMediaAssets = [PHAsset]()
            
            let allMediaOptions = PHFetchOptions()
            let allMedia = PHAsset.fetchAssets(with: allMediaOptions)
            
            allMedia.enumerateObjects { (asset, _, _) in
                allMediaAssets.append(asset)
            }
            
            continuation.resume(returning: allMediaAssets)
        }
    }
    
    // Fetch a thumbnail image for a specific asset
    func fetchThumbnail(for asset: PHAsset, targetSize: CGSize, accessIcloud: Bool = false) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let imageManager = PHCachingImageManager()
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = accessIcloud
            
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { (image, _) in
                continuation.resume(returning: image)
            }
        }
    }
    
    func fetchOriginalImage(from asset: PHAsset) async throws -> UIImage? {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true

        return try await withCheckedThrowingContinuation { continuation in
            manager.requestImage(for: asset,
                                 targetSize: PHImageManagerMaximumSize,
                                 contentMode: .aspectFill,
                                 options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
    
    // Fetch the first asset from a specific album
    func fetchFirstAsset(in album: PHAssetCollection) async -> PHAsset? {
        await withCheckedContinuation { continuation in
            let assetsFetchOptions = PHFetchOptions()
            let assets = PHAsset.fetchAssets(in: album, options: assetsFetchOptions)
            
            let firstAsset = assets.firstObject
            
            continuation.resume(returning: firstAsset)
        }
    }
    
    func isLocallyAvailable(asset: PHAsset) async -> Bool {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = false

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { (data, dataUTI, orientation, info) in
                if let info = info, let isInCloud = info[PHImageResultIsInCloudKey] as? Bool {
                    continuation.resume(returning: !isInCloud)
                } else {
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    func saveImageToPhotos(_ uiImage: UIImage) async throws -> Bool {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
            }
            return true
        } catch {
            print("Failed to save the image: \(error)")
            throw MediaError.failSave(description: "사진 저장에 실패했습니다")
        }
    }
    
}

enum MediaError: Error {
    case noPermission(description: String)
    case failSave(description: String)
}
