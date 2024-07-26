//
//  Home.swift
//  KSYPhotos
//
//  Created by ksy on 7/10/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct Home {
    struct State: Equatable {
        var loading = false
        var error: String? = nil
        var albumList: IdentifiedArrayOf<AlbumItem.State> = []
    }
    
    enum Action {
        case onAppear
        case fetchAlbums
        case doneFetchAlbums(TaskResult<GetAlbumListResDto>)
        case albumList(IdentifiedActionOf<AlbumItem>)
    }
    
    @Dependency(\.continuousClock) var clock
    @Dependency(\.mediaService) var mediaService
    private enum CancelID { case fetchAlbums }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .send(.fetchAlbums)
            case .fetchAlbums:
                state.loading = true
                return .run { send in
                    await send(
                        .doneFetchAlbums(
                            TaskResult { try await self.mediaService.getAlbumList() }
                        )
                    )
                }
                .cancellable(id: CancelID.fetchAlbums)
            case let .doneFetchAlbums(.failure(error)):
                state.loading = false
                state.error = error.localizedDescription
                return .none
            case let .doneFetchAlbums(.success(response)):
                state.loading = false
                if response.isPermission {
                    for album in response.albums {
                        let albumItem = AlbumItem.State(id: album.id, album: album)
                        state.albumList.append(albumItem)
                    }
                } else {
                    state.error = "사진 접근 권한이 없습니다"
                }
                return .none
            case .albumList:
                return .none
            }
        }
        .forEach(\.albumList, action: \.albumList) {
            AlbumItem()
        }
    }
    
}

struct HomeView: View {
    
    let store: StoreOf<Home>
    @State private var appeared = false
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                Color.nenioWhite.ignoresSafeArea()
                content
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                guard !appeared else { return }
                appeared = true
                viewStore.send(.onAppear)
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
                    albumListView
                        .padding(.horizontal, 16)
                }
            }
        }
    }
    
    var topBar: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack(alignment: .center) {
//                HStack(spacing: 0) {
//                    Spacer()
//                    ZStack {
//                        Image(systemName: "gear")
//                            .resizable()
//                            .renderingMode(.template)
//                            .foregroundColor(Color.gray900)
//                            .frame(width: 18, height: 18)
//                    }
//                    .frame(width: navigationBarHeight, height: navigationBarHeight)
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        // TODO: 설정
//                    }
//                }
                HStack(spacing: 0) {
                    Spacer()
                    Text("앨범")
                        .subTitle1Bold(Color.gray900)
                    Spacer()
                }
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            
        }
    }
    
    var albumListView: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 16) {
                    ForEachStore(self.store.scope(state: \.albumList, action: \.albumList)) { rowStore in
                        AlbumItemView(store: rowStore)
                    }
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
    
    func errorView(error: String) -> some View {
        VStack(spacing: 0) {
            Spacer()
            Text(error)
                .subTitle1Bold(Color.gray900)
            Spacer()
        }
    }
    
}

@Reducer
struct AlbumItem {
    struct State: Equatable, Identifiable {
        let id: String
        let album: KSYAlbum
        var thumbnail: UIImage? = nil
        var error: String? = nil
        var loading = false
    }
    
    enum Action {
        case onAppear(KSYMedia?)
        case fetchThumbnail(KSYMedia)
        case doneFetchThumbnail(TaskResult<GetThumbnailResDto>)
        case albumItemTapped(KSYAlbum)
    }
    
    @Dependency(\.mediaService) var mediaService
    private enum CancelID { case fetchThumbnail }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .onAppear(ksyMedia):
                if ksyMedia == nil {
                    return .none
                } else {
                    return .send(.fetchThumbnail(ksyMedia!))
                }
            case let .fetchThumbnail(ksyMedia):
                state.loading = true
                return .run { send in
                    await send(
                        .doneFetchThumbnail(
                            TaskResult { try await self.mediaService.getThumbnail(ksyMedia, CGSize(width: 100, height: 100), false) }
                        )
                    )
                }
                .cancellable(id: CancelID.fetchThumbnail)
            case let .doneFetchThumbnail(.failure(error)):
                state.loading = false
                state.error = error.localizedDescription
                return .none
            case let .doneFetchThumbnail(.success(response)):
                state.loading = false
                if response.isPermission {
                    state.thumbnail = response.thumbnail
                } else {
                    state.error = "사진 접근 권한이 없습니다"
                }
                return .none
            case .albumItemTapped:
                return .none
            }
        }
    }
}

struct AlbumItemView: View {
    
    let store: StoreOf<AlbumItem>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    if viewStore.album.type == .smartAlbum {
                        HStack(spacing: 4) {
                            HStack(spacing: 8) {
                                Text("Smart")
                                    .chipMedium(Color.purple500)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(height: 24, alignment: .leading)
                            .background(Color(red: 0.34, green: 0.12, blue: 0.98).opacity(0.05))
                            .cornerRadius(4)
                            Spacer()
                        }
                    }
                    Spacer().frame(height: 8)
                    HStack(spacing: 0) {
                        Text(viewStore.album.title)
                            .subTitle2Regular(Color.gray1)
                        Spacer()
                    }
                    Spacer().frame(height: 16)
                    HStack(spacing: 4) {
                        ZStack {
                            if viewStore.thumbnail == nil {
                                Image(systemName: "photo")
                                    .resizable()
                                    .renderingMode(.template)
                                    .foregroundColor(.gray600)
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: 1)
                                    )
                            } else {
                                Image(uiImage: viewStore.thumbnail!)
                                    .resizable()
                                    .renderingMode(.original)
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: 1)
                                    )
                            }
                            ZStack {
                                Circle()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(Color.gray700)
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: 1)
                                    )
                                Image("ic_more")
                                    .resizable()
                                    .renderingMode(.original)
                                    .frame(width: 12, height: 12)
                            }
                            .offset(x: 12, y: 0)
                        }
                        .frame(width: 48, height: 24)
                        HStack(spacing: 0) {
                            Text("\(viewStore.album.totalCount)개")
                                .captionBold(Color.gray700)
                        }
                        Spacer()
                    }
                    Spacer().frame(height: 16)
                }
                Spacer().frame(width: 16)
                VStack(spacing: 0) {
                    Spacer()
                    if viewStore.loading {
                        loadingView
                    } else {
                        if viewStore.thumbnail == nil {
                            Image(systemName: "photo")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(.gray600)
                                .frame(width: 100, height: 100)
                        } else {
                            Image(uiImage: viewStore.thumbnail!)
                                .resizable()
                                .renderingMode(.original)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    Spacer()
                }
                Spacer().frame(width: 16)
            }
            .frame(height: 120)
            .padding(20)
            .background(Color.nenioWhite)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .inset(by: 0.5)
                    .stroke(Color.gray200, lineWidth: 1)
            )
            .onAppear {
                viewStore.send(.onAppear(viewStore.album.firstMedia))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                viewStore.send(.albumItemTapped(viewStore.album))
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


#Preview {
    HomeView(
        store: Store(initialState: Home.State())
        {
            Home()
        }
    )
}
