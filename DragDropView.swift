//
//  DragDropView.swift
//  GIF
//
//  Created by zhangxi on 7/1/16.
//  Copyright © 2016 zhangxi.me. All rights reserved.
//

import Cocoa

protocol DragDropViewDelegate : NSObjectProtocol {
    func receivedFiles(_ file:String)
    func receivedErrorType(_ file:String)
}


class DragDropView: NSView {

    weak var delegate:DragDropViewDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        //enableDragDrop()
    }
    
    
    override func awakeFromNib() {
        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }


    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let sourceDragMask = sender.draggingSourceOperationMask()
        let pboard = sender.draggingPasteboard()
        
        if pboard.availableType(from: [NSPasteboard.PasteboardType.fileURL]) == NSPasteboard.PasteboardType.fileURL {
            if sourceDragMask.rawValue & NSDragOperation.generic.rawValue != 0 {
                return NSDragOperation.link
            }
        }
        
        return NSDragOperation()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if let pasteboard = sender.draggingPasteboard().propertyList(forType: NSPasteboard.PasteboardType.fileURL) as? NSArray {
            if let path = pasteboard[0] as? String {
                
                if let suffix = (path as NSString).lastPathComponent.components(separatedBy: ".").last
            {
                if suffix.lowercased() == "vob"
                {
                    self.delegate?.receivedErrorType(path)
                }
            }
                self.delegate?.receivedFiles(path)
                return true
//                if let suffix = (path as NSString).lastPathComponent.componentsSeparatedByString(".").last
//                {
//                    self.delegate?.receivedFiles(path)
//                    return true
//                    if suffix == "mov" || suffix == "MOV"
//                    {
//                        self.delegate?.receivedFiles(path)
//                        return true
//                    }else
//                    {
//                        self.delegate?.receivedErrorType(path)
//                    }
//                }
            }
        }
        
        
        
        return false
    }
    
}
