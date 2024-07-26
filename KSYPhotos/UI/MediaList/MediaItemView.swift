//
//  MediaItemView.swift
//  KSYPhotos
//
//  Created by ksy on 7/13/24.
//

import SwiftUI
import ComposableArchitecture
import AVFoundation
import Photos

@Reducer
struct MediaItem {
    struct State: Equatable, Identifiable {
        let id: String
        var media: KSYMedia
        var smallThumbnail: UIImage? = nil
        var detailThumbnail: UIImage? = nil
        var error: String? = nil
        var loading = false
        var player: AVPlayer? = nil
    }
    
    enum Action {
        case onAppear(KSYMedia?)
        case fetchSmallThumbnail(KSYMedia)
        case doneFetchSmallThumbnail(TaskResult<GetThumbnailResDto>)
        case fetchDetailThumbnail(KSYMedia, CGSize, Bool)
        case doneFetchDetailThumbnail(TaskResult<GetThumbnailResDto>)
        case mediaItemTapped(KSYMedia)
        case loadVideo(PHAsset)
        case doneLoadVideo(TaskResult<AVPlayer?>)
    }
    
    @Dependency(\.mediaService) var mediaService
    private enum CancelID { case fetchSmallThumbnail, fetchThumbnail, loadVideo }
    
    private func playVideo(asset: PHAsset) async -> AVPlayer? {
        if let avAsset = await PHImageManager.default().requestAVAssetAsync(forVideo: asset, options: nil) {
            let playerItem = AVPlayerItem(asset: avAsset)
            return AVPlayer(playerItem: playerItem)
        }
        return nil
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .onAppear(ksyMedia):
                if ksyMedia == nil {
                    return .none
                } else {
                    return .send(.fetchSmallThumbnail(ksyMedia!))
                }
            case let .fetchSmallThumbnail(ksyMedia):
                state.loading = true
                return .run { send in
                    await send(
                        .doneFetchSmallThumbnail(
                            TaskResult { try await self.mediaService.getThumbnail(ksyMedia, CGSize(width: 10, height: 10), false) }
                        )
                    )
                }
                .cancellable(id: CancelID.fetchSmallThumbnail)
            case let .doneFetchSmallThumbnail(.failure(error)):
                state.loading = false
                state.error = error.localizedDescription
                return .none
            case let .doneFetchSmallThumbnail(.success(response)):
                state.loading = false
                if response.isPermission {
                    state.smallThumbnail = response.thumbnail
                } else {
                    state.error = "사진 접근 권한이 없습니다"
                }
                return .none
            case let .fetchDetailThumbnail(ksyMedia, targetSize, accessIcloud):
                return .run { send in
                    await send(
                        .doneFetchDetailThumbnail(
                            TaskResult { try await self.mediaService.getThumbnail(ksyMedia, targetSize, accessIcloud) }
                        )
                    )
                }
                .cancellable(id: CancelID.fetchThumbnail)
            case let .doneFetchDetailThumbnail(.failure(error)):
                state.error = error.localizedDescription
                return .none
            case let .doneFetchDetailThumbnail(.success(response)):
                if response.isPermission {
                    if response.thumbnail != nil {
                        state.smallThumbnail = nil
                        state.detailThumbnail = response.thumbnail
                        state.media.isLocallyAvailable = true
                    }
                } else {
                    state.error = "사진 접근 권한이 없습니다"
                }
                return .none
            case .mediaItemTapped:
                return .none
            case let .loadVideo(asset):
                state.loading = true
                return .run { send in
                    await send(
                        .doneLoadVideo(
                            TaskResult { await self.playVideo(asset: asset) }
                        )
                    )
                }
                .cancellable(id: CancelID.loadVideo)
            case let .doneLoadVideo(.failure(error)):
                state.loading = false
                state.error = "비디오 로드 실패 \(error)"
                return .none
            case let .doneLoadVideo(.success(player)):
                state.loading = false
                if player == nil {
                    state.error = "비디오 로드 실패"
                } else {
                    state.player = player
                    state.player?.play()
                }
                return .none
            }
        }
    }
}

struct MediaItemView: View {
    
    let store: StoreOf<MediaItem>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                if viewStore.loading {
                    loadingView
                } else {
                    ZStack {
                        if viewStore.smallThumbnail == nil && viewStore.detailThumbnail == nil {
                            Image(systemName: "photo")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(.gray600)
                        }
                        if viewStore.smallThumbnail != nil {
                            Image(uiImage: viewStore.smallThumbnail!)
                                .resizable()
                                .renderingMode(.original)
                                .onAppear {
                                    viewStore.send(.fetchDetailThumbnail(viewStore.media, CGSize(width: 100, height: 100), false))
                                }
                        }
                        if viewStore.detailThumbnail != nil {
                            Image(uiImage: viewStore.detailThumbnail!)
                                .resizable()
                                .renderingMode(.original)
                        }
                    }
                    .overlay(content: {
                        if !viewStore.media.isLocallyAvailable {
                            VStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    Spacer()
                                    ZStack {
                                        Image(systemName: "icloud.fill")
                                            .resizable()
                                            .renderingMode(.template)
                                            .foregroundColor(.gray600)
                                            .frame(width: 24, height: 24)
                                    }
                                    .frame(width: 44, height: 44)
                                }
                                Spacer()
                            }
                        }
                    })
                }
            }
            .frame(width: 100, height: 100)
            .onAppear {
                viewStore.send(.onAppear(viewStore.media))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewStore.send(.mediaItemTapped(viewStore.media))
            }
        }
    }
    
    var loadingView: some View {
        VStack(spacing: 0) {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
}

struct MediaDetailItemView: View {
    
    let store: StoreOf<MediaItem>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            GeometryReader { geo in
                let geoW = geo.size.width
                ZStack {
                    Color.clear.ignoresSafeArea(.all)
                    if viewStore.loading {
                        loadingView
                    } else {
                        if viewStore.media.type == .video {
                            if viewStore.player != nil {
                                ZStack {
                                    VideoPlayer(player: viewStore.player!)
                                        .disabled(true)
                                }
                            }
                        } else {
                            ZStack {
                                if viewStore.smallThumbnail == nil && viewStore.detailThumbnail == nil {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .renderingMode(.template)
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.gray600)
                                }
                                if viewStore.smallThumbnail != nil {
                                    Image(uiImage: viewStore.smallThumbnail!)
                                        .resizable()
                                        .renderingMode(.original)
                                        .aspectRatio(contentMode: .fit)
                                }
                                if viewStore.detailThumbnail != nil {
                                    Image(uiImage: viewStore.detailThumbnail!)
                                        .resizable()
                                        .renderingMode(.original)
                                        .aspectRatio(contentMode: .fit)
                                }
                            }
                            .overlay(content: {
                                if !viewStore.media.isLocallyAvailable {
                                    VStack(spacing: 0) {
                                        HStack(spacing: 0) {
                                            Spacer()
                                            ZStack {
                                                Image(systemName: "icloud.fill")
                                                    .resizable()
                                                    .renderingMode(.template)
                                                    .foregroundColor(.gray600)
                                                    .frame(width: 24, height: 24)
                                            }
                                            .frame(width: 44, height: 44)
                                        }
                                        Spacer()
                                    }
                                }
                            })
                        }
                    }
                }
                .tag(viewStore.id)
                .frame(maxWidth: .infinity)
                .onAppear {
                    if viewStore.media.type == .video {
                        if let asset = viewStore.media.asset {
                            viewStore.send(.loadVideo(asset))
                        }
                    } else {
                        if viewStore.detailThumbnail == nil {
                            viewStore.send(.fetchDetailThumbnail(viewStore.media, CGSize(width: geoW, height: geoW), true))
                        }
                    }
                }
                .onDisappear {
                    if viewStore.media.type == .video && viewStore.player != nil {
                        viewStore.player?.pause()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewStore.send(.mediaItemTapped(viewStore.media))
                }
            }
        }
    }
    
    var loadingView: some View {
        VStack(spacing: 0) {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
}
