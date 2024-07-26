//
//  KSYPhotosApp.swift
//  KSYPhotos
//
//  Created by ksy on 7/9/24.
//

import SwiftUI
import ComposableArchitecture

@main
struct KSYPhotosApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(
                store: Store(
                    initialState: Root.State(
                        path: StackState([
                            .screenSplash(Splash.State())
                        ])
                    )
                ) {
                    Root()
                }
            )
        }
    }
}
