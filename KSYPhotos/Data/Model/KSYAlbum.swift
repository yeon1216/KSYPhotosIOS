//
//  KSYAlbum.swift
//  KSYPhotos
//
//  Created by ksy on 7/10/24.
//

import Foundation

struct KSYAlbum: Equatable, Identifiable {
    let id: String
    let title: String
    let firstMedia: KSYMedia?
    let totalCount: Int
    let type: KSYAlbumType
    
    init(id: String, title: String?, firstMedia: KSYMedia?, totalCount: Int, type: KSYAlbumType) {
        self.id = id
        self.title = title ?? "no title"
        self.firstMedia = firstMedia
        self.totalCount = totalCount
        self.type = type
    }
    
    enum KSYAlbumType: Int {
        case album, smartAlbum
    }
    
}
