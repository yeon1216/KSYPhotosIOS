//
//  UIImage+Extension.swift
//  KSYPhotos
//
//  Created by ksy on 7/16/24.
//

import UIKit

extension UIImage {
    func withAlpha(_ alpha: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext(), let cgImage = self.cgImage else {
            UIGraphicsEndImageContext()
            return nil
        }

        let rect = CGRect(origin: .zero, size: self.size)
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -rect.size.height)
        context.setBlendMode(.normal)
        context.setAlpha(alpha)
        context.draw(cgImage, in: rect)

        let imageWithAlpha = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageWithAlpha
    }
}
