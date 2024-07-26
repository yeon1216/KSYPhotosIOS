//
//  UIKitUtils.swift
//  KSYPhotos
//
//  Created by ksy on 7/10/24.
//

import Foundation
import UIKit

//let screenScale = UIScreen.main.scale
//let screenW = UIScreen.main.bounds.size.width
//let screenH = UIScreen.main.bounds.size.height
//var statusBarHeight: CGFloat = 44
//var navigationBarHeight: CGFloat = 56
//var topEdge: CGFloat = 88
//var bottomEdge: CGFloat = 34


//func calculateSafeAreaSize() async {
//    guard let window = await appUIWindow() else {
//    statusBarHeight = 20
//        bottomEdge = 0
//        return
//    }
//    if let height = await window.windowScene?.statusBarManager?.statusBarFrame.height {
//        statusBarHeight = height
//    } else {
//        if await UIDevice.current.hasNotch() {
//            statusBarHeight = 44
//        } else {
//            statusBarHeight = 20
//        }
//    }
//
//    if #available(iOS 11.0, *) {
//        bottomEdge = await window.safeAreaInsets.bottom
//    }
//}
//
//extension UIDevice {
//    func hasNotch() async -> Bool {
//        if #available(iOS 11.0, *), let keyWindow = await appUIWindow() {
//            return keyWindow.safeAreaInsets.top > 20
//        }
//        return false
//    }
//}
//
//@MainActor
//func appUIWindow(_ asKeyWindow: Bool = false) async -> UIWindow? {
//    let scenes = UIApplication.shared.connectedScenes
//    let scene = asKeyWindow ? scenes.filter({ $0.activationState == .foregroundActive}).first : scenes.first
//    
//    guard let winScene = scene as? UIWindowScene else {
//        return nil
//    }
//    
//    return asKeyWindow ? winScene.windows.first : winScene.windows.filter({ $0.isKeyWindow }).first
//}
