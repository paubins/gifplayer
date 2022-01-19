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
        
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
	override var mouseDownCanMoveWindow:Bool {
		return true
	}
    
    override func awakeFromNib() {
        self.delegate = self
    }
}

// MARK: - NSDraggingSource

extension MCDragAndDropImageView: NSDraggingSource {

	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {

		if (NSImage.canInit(with: sender.draggingPasteboard)) {
			let sourceDragMask = sender.draggingSourceOperationMask
			let pboard = sender.draggingPasteboard

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
		return NSImage.canInit(with: sender.draggingPasteboard)
	}

	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		if (NSImage.canInit(with: sender.draggingPasteboard)) {
            delegate?.dragAndDropImageViewDidDrop(pasteboard: sender.draggingPasteboard)
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


extension MCDragAndDropImageView : MCDragAndDropImageViewDelegate {
    func dragAndDropImageViewDidDrop(pasteboard:NSPasteboard) {
        let url:URL = NSURL(from: pasteboard)! as URL
        GIFController.shared.windowMenu.isHidden = false
        let gifWindow = GIFWindow()
        gifWindow.loadGIF(gifFileName: url, completion: { windowController in
            if let window = windowController.window {
                if let contentView = window.contentView!.subviews.first, let pixelBuffer = gifWindow.getNextImage() {
                    let width = window.frame.size.width * NSScreen.main!.backingScaleFactor
                    let height = window.frame.size.height * NSScreen.main!.backingScaleFactor
                    print("wh: \(width) \(height)")
                    
                    (contentView as! MetalView).create(coords: [CGPoint(x: width, y: height),
                                                                  CGPoint(x: 0, y: height),
                                                                  CGPoint(x: 0, y: 0),
                                                                  CGPoint(x: width, y: height),
                                                                  CGPoint(x: 0, y: 0),
                                                                  CGPoint(x: width, y: 0)])
                    (contentView as! MetalView).replace(with: .image(pixelBuffer))
                    
                }
                window.orderFrontRegardless()
            }
        }) { windowController in
            if let window = windowController.window {
                if let contentView = window.contentView!.subviews.first, let pixelBuffer = gifWindow.getNextImage() {
                    let width = window.frame.size.width * NSScreen.main!.backingScaleFactor
                    let height = window.frame.size.height * NSScreen.main!.backingScaleFactor
                    print("wh: \(width) \(height)")
                    (contentView as! MetalView).replace(with: .image(pixelBuffer))
                }
            }
        }
        GIFController.shared.gifWindows += [gifWindow]
    }
}
