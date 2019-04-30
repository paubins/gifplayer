//
//  GIFLoader.swift
//  GifPlayer
//
//  Created by Patrick Aubin on 11/7/18.
//  Copyright © 2018 com.paubins.GifPlayer. All rights reserved.
//

import Foundation

class GIFLoader {
    var gifRep:NSBitmapImageRep!
    var maxFrameCount:Int = 29
    
    var currFrameCount:Int = 0
    
    var animationImages:[Data] = []
    var frameStore:FrameStore!
    
    var image:NSImage! = nil
    var filename:URL! = nil

    
    public static func loadGIF(image:NSImage, gifFileName:URL?) -> GIFLoader? {
        let gifLoader:GIFLoader = GIFLoader()
        gifLoader.image = image
        
        if (gifFileName != nil) {
            gifLoader.filename = gifFileName
        }
        
        gifLoader.gifRep = (gifLoader.image.representations[FIRST_FRAME] as! NSBitmapImageRep)
        let frameCount = gifLoader.gifRep.value(forProperty: NSBitmapImageRep.PropertyKey.frameCount) == nil ? 1 : gifLoader.gifRep.value(forProperty: NSBitmapImageRep.PropertyKey.frameCount);
        
        if let maxFrameCount = frameCount {
            gifLoader.maxFrameCount = maxFrameCount as! Int
            gifLoader.currFrameCount = FIRST_FRAME
            
            for frame in 0 ..< gifLoader.maxFrameCount {
                gifLoader.gifRep.setProperty(NSBitmapImageRep.PropertyKey.currentFrame, withValue: frame)
                
                let data = gifLoader.gifRep.bitmapData
                let size = gifLoader.gifRep.bytesPerPlane
                // copy the bitmap data into an NSData object, that can be save transferred to animateOneFrame
                let imgData:Data = NSData(bytes: data, length: size) as Data
                gifLoader.animationImages.append(imgData)//.compressed(using: Compression.lz4)!)
            }
            
            return gifLoader
        }
        
        return nil
    }
}
