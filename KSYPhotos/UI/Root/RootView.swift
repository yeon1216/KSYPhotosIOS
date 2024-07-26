//
//  RootView.swift
//  KSYPhotos
//
//  Created by ksy on 7/9/24.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct Root {
    
    struct State: Equatable {
        var path = StackState<Path.State>()
    }
    
    enum Action {
        case goBackToScreen(id: StackElementID)
        case path(StackAction<Path.State, Path.Action>)
        case popToRoot
    }
    
    var body: some Reducer<State, Action> {
        
        Reduce { state, action in
            switch action {
            case let .goBackToScreen(id):
                state.path.pop(to: id)
                return .none
            case .popToRoot:
                state.path.removeAll()
                return .none
            case let .path(pathAction):
                switch pathAction {
                case .element(id: _, action: .screenSplash(.splashDone)):
                    state.path.append(.screenHome())
                    return .none
                case let .element(id: _, action: .screenHome(.albumList(.element(id: _, action: .albumItemTapped(album))))):
                    state.path.append(.screenMediaList(MediaList.State(album: album)))
                    return .none
                default:
                    return .none
                }
            }
        }
        .forEach(\.path, action: /Action.path) {
            Path()
        }
    }
    
    // Navigation Reference
    // Sample App : https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples/CaseStudies
    // Reference : https://www.pointfree.co/blog/posts/106-navigation-tools-come-to-the-composable-architecture
    @Reducer
    struct Path {
        enum State: Equatable {
            case screenSplash(Splash.State = .init())
            case screenHome(Home.State = .init())
            case screenMediaList(MediaList.State)
        }
        
        enum Action {
            case screenSplash(Splash.Action)
            case screenHome(Home.Action)
            case screenMediaList(MediaList.Action)
        }
        
        var body: some Reducer<State, Action> {
            Scope(state: /State.screenSplash, action: /Action.screenSplash) {
                Splash()
            }
            Scope(state: /State.screenHome, action: /Action.screenHome) {
                Home()
            }
            Scope(state: /State.screenMediaList, action: /Action.screenMediaList) {
                MediaList()
            }
        }
    }
    
}


struct RootView: View {
    
    let store: StoreOf<Root>
    
    var body: some View {
        NavigationStackStore(
            self.store.scope(
                state: \.path,
                action: {
                    .path($0)
                }
            )
        ) {
            SplashView(
                store: Store(initialState: Splash.State())
                {
                    Splash()
                }
            )
        } destination: { store in
            switch store {
            case .screenSplash:
                CaseLet(
                    /Root.Path.State.screenSplash,
                     action: Root.Path.Action.screenSplash,
                     then: SplashView.init(store:)
                )
            case .screenHome:
                CaseLet(
                    /Root.Path.State.screenHome,
                     action: Root.Path.Action.screenHome,
                     then: HomeView.init(store:)
                )
            case .screenMediaList:
                CaseLet(
                    /Root.Path.State.screenMediaList,
                    action: Root.Path.Action.screenMediaList,
                    then: { MediaListView(store: $0) }
                )
            }
        }
    }
}
