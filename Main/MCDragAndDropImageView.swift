//
//  MCDragAndDropImageView.swift
//  LayerX
//
//  Created by Michael Chen on 2015/10/26.
//  Copyright © 2015年 Michael Chen. All rights reserved.
//

import Cocoa

protocol MCDragAndDropImageViewDelegate: class {
    func dragAndDropImageViewDidDrop(pasteboard:NSPasteboard)
}

class MCDragAndDropImageView: NSView {

	weak var delegate: MCDragAndDropImageViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        if #available(OSX 10.13, *) {
            registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL] as! [NSPasteboard.PasteboardType])
        } else {
            // Fallback on earlier versions
        }
        self.backgroundColor = .black
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
	override var mouseDownCanMoveWindow:Bool {
		return true
	}
}

// MARK: - NSDraggingSource

extension MCDragAndDropImageView: NSDraggingSource {

	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {

		if (NSImage.canInit(with: sender.draggingPasteboard())) {
			let sourceDragMask = sender.draggingSourceOperationMask()
			let pboard = sender.draggingPasteboard()

            if #available(OSX 10.13, *) {
                if pboard.availableType(from: [NSPasteboard.PasteboardType.fileURL]) == NSPasteboard.PasteboardType.fileURL {
                    if sourceDragMask.rawValue & NSDragOperation.copy.rawValue != 0 {
                        return NSDragOperation.copy
                    }
                }
            } else {
                // Fallback on earlier versions
            }
		}

		return NSDragOperation()
	}

	override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
		return NSImage.canInit(with: sender.draggingPasteboard())
	}

	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		if (NSImage.canInit(with: sender.draggingPasteboard())) {
            delegate?.dragAndDropImageViewDidDrop(pasteboard: sender.draggingPasteboard())
		}

		return true
	}

	func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
		switch context {
		case .outsideApplication: return NSDragOperation()
		case .withinApplication: return .copy
		}
	}
}
