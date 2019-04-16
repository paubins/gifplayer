//
//  Priview.swift
//  GIF
//
//  Created by 张玺 on 7/2/16.
//  Copyright © 2016 zhangxi.me. All rights reserved.
//

import Cocoa
protocol PriviewDelegate :NSObjectProtocol
{
    func didClose()
}
class Priview: NSView {

    weak var delegate:PriviewDelegate?
    
    var images:[String]!
        {
        didSet{
            self.frameIndex = 0
        }
    }
    var frameIndex:Int = 0
        {
        didSet{
            if images == nil
            {
                return
            }
            if frameIndex < self.images.count
            {
                Swift.print(frameIndex)
                Swift.print(self.images[frameIndex])
                previewImage.image = NSImage(contentsOfFile: self.images[frameIndex])
            }
        }
    }
    
    var previewImage:NSImageView!
    
    var backView = NSView(frame:NSMakeRect(0,0,0,0))
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
     
        //backView.layer?.backgroundColor = NSColor.blackColor().CGColor
        //backView.frame = self.bounds
        //self.addSubview(backView)
        
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.black.cgColor
        
        previewImage = NSImageView(frame: self.bounds)
        previewImage.wantsLayer = true
        self.addSubview(previewImage)
        
        let frame = NSMakeRect(self.bounds.size.width - 50,self.bounds.size.height - 50,40,40)
        let close = NSButton(frame: frame)
        close.bezelStyle = .disclosure
        close.isBordered = false
        //close.layer?.backgroundColor = NSColor.clearColor().CGColor
        close.image = NSImage(named: NSImage.Name(rawValue: "close"))
        //close.wantsLayer = true
        close.target = self
        close.action = #selector(self.close)
        self.addSubview(close)
        
    }
    @objc func close()
    {
        self.isHidden = true
        delegate?.didClose()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
