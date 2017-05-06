//
//  UIImageExtension.swift
//  Cover Tube
//
//  Created by June Suh on 5/5/17.
//  Copyright © 2017 CoverTuber. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    /*
     Scales image proportionally
     Credit: https://stackoverflow.com/questions/2025319/scale-image-in-an-uibutton-to-aspectfit
     Changed objective c code to swift code
     */
    func imageByScalingProportion (toSize targetSize : CGSize) -> UIImage? {
        var sourceImage : UIImage? = self
        if sourceImage == nil {
            return nil
        }
        
        var newImage : UIImage? = nil
        let imageSize = sourceImage!.size
        let width = imageSize.width
        let height = imageSize.height
        
        let targetWidth = targetSize.width
        let targetHeight = targetSize.height
        
        var scaledWidth = targetWidth
        var scaledHeight = targetHeight
        var thumbnailPoint = CGPoint.zero
        
        if !__CGSizeEqualToSize(imageSize, targetSize)
        {
            let widthFactor = targetWidth / width
            let heightFactor = targetHeight / height
            
            var scaledFactor = widthFactor < heightFactor ? widthFactor : heightFactor
            
            scaledWidth = widthFactor * scaledFactor
            scaledHeight = heightFactor * scaledFactor
            
            /* center the image */
            if widthFactor < heightFactor {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5
            } else if widthFactor > heightFactor {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0)
        var thumbnailRect = CGRect.zero
        thumbnailRect.origin = thumbnailPoint
        thumbnailRect.size.width = scaledWidth
        thumbnailRect.size.height = scaledHeight
        
        sourceImage!.draw(in: thumbnailRect)
        
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if newImage == nil {
            print("could not scale image")
            return nil
        }
        
        return newImage
        
    }
    
}
