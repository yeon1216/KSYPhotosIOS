//
//  ImageCropper.swift
//  KSYPhotos
//
//  Created by ksy on 7/15/24.
//

import Mantis
import SwiftUI

struct ImageCropper: UIViewControllerRepresentable {
    
    var image: UIImage?
    var transformation: Transformation?
    var didCrop: (CropViewTransform, UIImage) -> Void = { _, _ in }
    var cancelCrop: (UIImage) -> Void = { _ in }
    var getCropViewController: (CropViewController) -> Void = { _ in }
    
    class Coordinator: CropViewControllerDelegate {
        var parent: ImageCropper
        
        init(_ parent: ImageCropper) {
            self.parent = parent
        }
        
        func cropViewControllerDidCrop(_ cropViewController: Mantis.CropViewController, cropped: UIImage, transformation: Transformation, cropInfo: CropInfo) {
            
            var cropViewTransform = CropViewTransform()
            cropViewTransform.offset = transformation.offset
            cropViewTransform.rotation = transformation.rotation
            cropViewTransform.scale = transformation.scale
            cropViewTransform.manualZoomed = transformation.manualZoomed
            cropViewTransform.initialMaskFrame = transformation.initialMaskFrame
            cropViewTransform.maskFrame = transformation.maskFrame
            cropViewTransform.cropWorkbenchViewBounds = transformation.cropWorkbenchViewBounds
            
            parent.didCrop(cropViewTransform, cropped)
        }
        
        func cropViewControllerDidCancel(_ cropViewController: Mantis.CropViewController, original: UIImage) {
            parent.cancelCrop(original)
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = makeKmAssetMakerImageCropper(context: context)
        self.getCropViewController(viewController as! CropViewController)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
}



extension ImageCropper {
    
    func makeKmAssetMakerImageCropper(context: Context) -> UIViewController {
        var config = Mantis.Config()
        

        if self.transformation != nil {
            config.cropViewConfig.presetTransformationType = .presetInfo(info: self.transformation!)
        }
        
        config.showAttachedCropToolbar = false
        config.cropViewConfig.backgroundColor = .black.withAlphaComponent(0.4)
        config.cropViewConfig.cropShapeType = .rect//.heart(maskOnly: false)
        config.presetFixedRatioType = .canUseMultiplePresetFixedRatio()
        config.cropViewConfig.rotationControlViewHeight = 0
        config.cropViewConfig.showAttachedRotationControlView = false
        config.cropToolbarConfig.mode = .embedded
        let cropViewController = Mantis.cropViewController(
            image: image!,
            config: config
        )
        cropViewController.delegate = context.coordinator
        return cropViewController
    }
    
}

struct CropViewTransform: Equatable {
    var offset: CGPoint = .zero
    var rotation: CGFloat = .zero
    var scale: CGFloat = 1
    var manualZoomed: Bool = false
    var initialMaskFrame: CGRect = .zero
    var maskFrame: CGRect = .zero
    var cropWorkbenchViewBounds: CGRect = .zero
}
