//
//  SplashView.swift
//  KSYPhotos
//
//  Created by ksy on 7/9/24.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct Splash {
    struct State: Equatable {
        var loading = false
    }
    
    enum Action {
        case onAppear
        case splashDone
    }
    
    @Dependency(\.continuousClock) var clock
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            return .run { send in
                await send(.splashDone)
            }
        case .splashDone:
            return .none
        }
        
    }
    
}

struct SplashView: View {
    
    let store: StoreOf<Splash>
    @State private var appeared = false
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                Color.nenioWhite.ignoresSafeArea(.all)
                Image("ic_nenio_characters")
                    .renderingMode(.original)
                    .resizable()
                    .frame(width: 184, height: 172.8)
                    .onAppear {
                        guard !appeared else { return }
                        appeared = true
                        viewStore.send(.onAppear)
                    }
            }
            .ignoresSafeArea(.all)
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    SplashView(
        store: Store(initialState: Splash.State())
        {
            Splash()
        }
    )
}
