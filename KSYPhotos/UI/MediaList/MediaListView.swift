//
//  MediaListView.swift
//  KSYPhotos
//
//  Created by ksy on 7/11/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct MediaList {
    struct State: Equatable {
        var loading = false
        var error: String? = nil
        var album: KSYAlbum
        var mediaList: IdentifiedArrayOf<MediaItem.State> = []
        var viewMode: MediaListViewMode = .list
        var selectedMediaId: String = ""
        var selectedMedia: KSYMedia? = nil
        @PresentationState var destination: Destination.State?
    }
    
    enum MediaListViewMode: Int {
        case list = 0, detail, detailMedia
    }
    
    enum Action {
        case onAppear(KSYAlbum)
        case fetchMedias(KSYAlbum)
        case doneFetchMedias(TaskResult<GetMediaListResDto>)
        case backIconTapped
        case closeIconTapped
        case mediaList(IdentifiedActionOf<MediaItem>)
        case changeSelectedMediaId(String)
        case changeIsPresentedEditMediaSheet(Bool)
        case editIconTapped
        case destination(PresentationAction<Destination.Action>)
    }
    
    @Reducer
    struct Destination {
        enum State: Equatable {
            case fullScreenCover(EditMedia.State)
        }
        enum Action {
            case fullScreenCover(EditMedia.Action)
        }
        var body: some ReducerOf<Self> {
            Scope(state: \.fullScreenCover, action: \.fullScreenCover) {
                EditMedia()
            }
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.mediaService) var mediaService
    private enum CancelID { case fetchMedias }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .onAppear(album):
                return .send(.fetchMedias(album))
            case let .fetchMedias(album):
                state.loading = true
                return .run { send in
                    await send(
                        .doneFetchMedias(
                            TaskResult { try await self.mediaService.getMedias(album) }
                        )
                    )
                }
                .cancellable(id: CancelID.fetchMedias)
            case let .doneFetchMedias(.failure(error)):
                state.loading = false
                state.error = error.localizedDescription
                return .none
            case let .doneFetchMedias(.success(response)):
                state.loading = false
                if response.isPermission {
                    state.selectedMediaId = response.medias[0].assetIdentifier
                    for media in response.medias {
                        let albumItem = MediaItem.State(id: media.assetIdentifier, media: media)
                        state.mediaList.append(albumItem)
                    }
                } else {
                    state.error = "사진 접근 권한이 없습니다"
                }
                return .none
            case .backIconTapped:
                return .run { _ in
                    await self.dismiss()
                }
            case .closeIconTapped:
                withAnimation {
                    state.viewMode = .list
                }
                return .none
            case let .mediaList(action):
                switch action {
                case let .element(id: _, action: .mediaItemTapped(media)):
                    print("tap media \(media.assetIdentifier)")
                    if state.viewMode == .list {
                        state.viewMode = .detail
                        state.selectedMediaId = media.assetIdentifier
                        state.selectedMedia = media
                    } else if state.viewMode == .detail {
                        state.viewMode = .detailMedia
                    } else if state.viewMode == .detailMedia {
                        state.viewMode = .detail
                    }
                    return .none
                default:
                    return .none
                }
            case let .changeSelectedMediaId(id):
                print("changeSelectedMediaId \(id)")
                state.selectedMediaId = id
                state.selectedMedia = state.mediaList.first { $0.id == id }?.media
                return .none
            case .changeIsPresentedEditMediaSheet:
                return .none
            case .editIconTapped:
                state.destination = .fullScreenCover(EditMedia.State(media: state.selectedMedia!))
                return .none
            case .destination:
              return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination()
        }
        .forEach(\.mediaList, action: \.mediaList) {
            MediaItem()
        }
    }
    
}

struct MediaListView: View {
    
    let store: StoreOf<MediaList>
    @State private var appeared = false
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                Color.nenioWhite.ignoresSafeArea(.all)
                content
                if viewStore.viewMode == .detail || viewStore.viewMode == .detailMedia {
                    if viewStore.viewMode == .detailMedia {
                        Color.nenioBlack.ignoresSafeArea(.all)
                    } else {
                        Color.nenioWhite.ignoresSafeArea(.all)
                    }
                    detailContent
//                        .transition(.move(edge: .bottom))
                        .transition(.opacity)
                }
            }
            .navigationBarBackButtonHidden(true)
            .animation(.easeInOut(duration: 0.4), value: viewStore.viewMode != MediaList.MediaListViewMode.list)
            .onAppear {
                guard !appeared else { return }
                appeared = true
                viewStore.send(.onAppear(viewStore.album))
            }
            .statusBarHidden(viewStore.viewMode == .detailMedia)
            .fullScreenCover(
                store: self.store.scope(
                    state: \.$destination.fullScreenCover, action: \.destination.fullScreenCover
                )
            ) { store in
                EditMediaView(store: store)
            }
        }
    }
    
    var content: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                topBar
                if viewStore.loading {
                    loadingView
                } else if viewStore.error != nil {
                    errorView(error: viewStore.error!)
                } else {
                    if viewStore.album.totalCount == 0 {
                        noMediaView
                    } else {
                        mediaListView
                    }
                }
            }
        }
    }
    
    var detailContent: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                Color.clear.ignoresSafeArea(.all)
                VStack(spacing: 0) {
                    if viewStore.loading {
                        loadingView
                    } else if viewStore.error != nil {
                        errorView(error: viewStore.error!)
                    } else {
                        if viewStore.album.totalCount == 0 {
                            noMediaView
                        } else {
                            mediaPagerView
                        }
                    }
                }
                if viewStore.viewMode == .detail {
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            detailTopBar
                            Divider()
                        }
                        .background(Color.gray300.opacity(0.8))
                        Spacer()
                    }
                    VStack(spacing: 0) {
                        Spacer()
                        VStack(spacing: 0) {
                            Divider()
                            if viewStore.selectedMedia != nil && viewStore.selectedMedia?.type == .video {
                                HStack(spacing: 0) {
                                    Spacer()
                                    ZStack {
                                        Image(systemName: "video.fill")
                                            .resizable()
                                            .renderingMode(.template)
                                            .foregroundColor(Color.gray900)
                                            .frame(width: 18, height: 18)
                                    }
                                    .frame(width: 56, height: 56)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // TODO: 비디오 재생
                                    }
                                    Spacer()
                                }
                                .frame(height: 56)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .background(Color.gray300.opacity(0.8))
                    }
                }
            }
        }
    }
    
    var noMediaView: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("앨범에 사진 또는 비디오가 없습니다")
                .subTitle2Bold(Color.gray900)
            Spacer()
        }
    }
    
    var mediaListView: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.fixed(100)), GridItem(.fixed(100)), GridItem(.fixed(100))], spacing: 0) {
                        ForEachStore(self.store.scope(state: \.mediaList, action: \.mediaList)) { rowStore in
                            MediaItemView(store: rowStore)
                        }
                    }
                }
            }
        }
    }
    
    var mediaPagerView: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            TabView(
                selection: viewStore.binding(
                    get: \.selectedMediaId,
                    send: { .changeSelectedMediaId($0) }
                )
            ) {
                ForEachStore(self.store.scope(state: \.mediaList, action: \.mediaList)) { rowStore in
                    MediaDetailItemView(store: rowStore)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
    
    var topBar: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack(alignment: .center) {
                HStack(spacing: 0) {
                    ZStack {
                        Image(systemName: "arrow.left")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color.gray900)
                            .frame(width: 18, height: 18)
                    }
                    .frame(width: 56, height: 56)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewStore.send(.backIconTapped)
                    }
                    Spacer()
                }
                HStack(spacing: 0) {
                    Spacer()
                    Text(viewStore.album.title)
                        .subTitle1Bold(Color.gray900)
                    Spacer()
                }
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            
        }
    }
    
    var detailTopBar: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack(alignment: .center) {
                if viewStore.viewMode == .detail {
                    HStack(spacing: 0) {
                        ZStack {
                            Image(systemName: "xmark")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color.gray900)
                                .frame(width: 18, height: 18)
                        }
                        .frame(width: 56, height: 56)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.closeIconTapped)
                        }
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        Spacer()
                        ZStack {
                            Text("편집")
                                .buttonRegular(viewStore.selectedMedia?.type == .image ? Color.purple500 : Color.purple500.opacity(0.25))
                        }
                        .frame(width: 56, height: 56)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewStore.send(.editIconTapped)
                        }
                    }
                }
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            
        }
    }
    
    var loadingView: some View {
        VStack(spacing: 0) {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
    
    func errorView(error: String) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Text(error)
                .subTitle1Bold(Color.gray900)
            Spacer()
        }
    }
}

#Preview {
    MediaListView(
        store: Store(initialState: MediaList.State(album: KSYAlbum(id: "test", title: "test", firstMedia: nil, totalCount: 0, type: .album)))
        {
            MediaList()
        }
    )
}

