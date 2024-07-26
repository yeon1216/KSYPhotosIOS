//
//  MediaService.swift
//  KSYPhotos
//
//  Created by ksy on 7/10/24.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import Photos

struct GetAlbumListResDto: Sendable {
    let isPermission: Bool
    let albums: [KSYAlbum]
}

struct GetMediaListResDto: Sendable {
    let isPermission: Bool
    let medias: [KSYMedia]
}

struct GetThumbnailResDto: Sendable {
    let isPermission: Bool
    let thumbnail: UIImage?
}

struct SaveImageResDto: Sendable {
    let isPermission: Bool
    let success: Bool
}

struct MediaService {
    var getAlbumList: @Sendable () async throws -> GetAlbumListResDto
    var getMedias: @Sendable (KSYAlbum) async throws -> GetMediaListResDto
    var getThumbnail: @Sendable (KSYMedia, CGSize, Bool) async throws -> GetThumbnailResDto
    var getOriginalThumbnail: @Sendable (KSYMedia) async throws -> GetThumbnailResDto
    var saveImage: @Sendable (UIImage) async throws -> SaveImageResDto
}

extension MediaService: DependencyKey {
    static let liveValue = Self(
        getAlbumList: {
            let mediaManager = MediaManager.shared
            let isPermission = await mediaManager.requestAuthorization()
            if isPermission {
                let phCollections = await mediaManager.fetchAlbums()
                var ksyAlbums = [KSYAlbum]()
                for collection in phCollections {
                    let type = if collection.assetCollectionType == .smartAlbum {
                        KSYAlbum.KSYAlbumType.smartAlbum
                    } else {
                        KSYAlbum.KSYAlbumType.album
                    }
                    let fetchResult = await mediaManager.fetchMedia(in: collection)
                    if fetchResult.count > 0 {
                        let firstAsset = fetchResult.first!
                        var firstKsyMedia: KSYMedia? = nil
                        if let type = firstAsset.getKSYMediaType() {
                            firstKsyMedia = KSYMedia(assetIdentifier: firstAsset.localIdentifier, isLocallyAvailable: firstAsset.isLocallyAvailable(), type: type)
                        }
                        var album = KSYAlbum(id: collection.localIdentifier, title: collection.localizedTitle, firstMedia: firstKsyMedia, totalCount: fetchResult.count, type: type)
                        ksyAlbums.append(album)
                    } else {
                        var album = KSYAlbum(id: collection.localIdentifier, title: collection.localizedTitle, firstMedia: nil, totalCount: fetchResult.count, type: type)
                        ksyAlbums.append(album)
                    }
                }
                return GetAlbumListResDto(isPermission: true, albums: ksyAlbums)
            } else {
                return GetAlbumListResDto(isPermission: false, albums: [])
            }
        },
        getMedias: { ksyAlbum in
            let mediaManager = MediaManager.shared
            let isPermission = await mediaManager.requestAuthorization()
            if isPermission {
                if let phAssets = await mediaManager.fetchMedia(in: ksyAlbum.id) {
                    if phAssets.count > 0 {
                        var ksyMedias = [KSYMedia]()
                        for phAsset in phAssets {
                            if let type = phAsset.getKSYMediaType() {
                                let isLocallyAvailable = await mediaManager.isLocallyAvailable(asset: phAsset)
                                let ksyMedia = KSYMedia(assetIdentifier: phAsset.localIdentifier, isLocallyAvailable: isLocallyAvailable, type: type)
                                ksyMedias.append(ksyMedia)
                            }
                        }
                        return GetMediaListResDto(isPermission: true, medias: ksyMedias)
                    } else {
                        return GetMediaListResDto(isPermission: true, medias: [])
                    }
                } else {
                    return GetMediaListResDto(isPermission: true, medias: [])
                }
            } else {
                return GetMediaListResDto(isPermission: false, medias: [])
            }
        },
        getThumbnail: { ksyMedia, targetSize, accessIcloud in
            let mediaManager = MediaManager.shared
            let isPermission = await mediaManager.requestAuthorization()
            if isPermission {
                if let asset = ksyMedia.asset {
                    let thumbnail = await mediaManager.fetchThumbnail(for: asset, targetSize: targetSize, accessIcloud: accessIcloud)
                    return GetThumbnailResDto(isPermission: true, thumbnail: thumbnail)
                } else {
                    return GetThumbnailResDto(isPermission: true, thumbnail: UIImage())
                }
            } else {
                return GetThumbnailResDto(isPermission: false, thumbnail: nil)
            }
        },
        getOriginalThumbnail: { ksyMedia in
            let mediaManager = MediaManager.shared
            let isPermission = await mediaManager.requestAuthorization()
            if isPermission {
                if let asset = ksyMedia.asset {
                    let thumbnail = try await mediaManager.fetchOriginalImage(from: asset)
                    return GetThumbnailResDto(isPermission: true, thumbnail: thumbnail)
                } else {
                    return GetThumbnailResDto(isPermission: true, thumbnail: nil)
                }
            } else {
                return GetThumbnailResDto(isPermission: false, thumbnail: nil)
            }
        },
        saveImage: { uiImage in
            let mediaManager = MediaManager.shared
            let isPermission = await mediaManager.requestAuthorization()
            if isPermission {
                if try await mediaManager.saveImageToPhotos(uiImage) {
                    return SaveImageResDto(isPermission: true, success: false)
                } else {
                    return SaveImageResDto(isPermission: true, success: false)
                }
            } else {
                return SaveImageResDto(isPermission: false, success: false)
            }
        }
    )
}

extension DependencyValues {
    var mediaService: MediaService {
        get { self[MediaService.self] }
        set { self[MediaService.self] = newValue }
    }
}
