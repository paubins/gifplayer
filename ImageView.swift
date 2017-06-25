//
//  ImageView.swift
//  GifPlayer
//
//  Created by Patrick Aubin on 6/11/17.
//  Copyright © 2017 com.paubins.GifPlayer. All rights reserved.
//

import Foundation
import Cocoa

class ImageView : DKAsyncImageView {
    
    override var mouseDownCanMoveWindow:Bool {
        return true
    }
}
