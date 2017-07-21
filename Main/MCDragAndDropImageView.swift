//
//  MCDragAndDropImageView.swift
//  LayerX
//
//  Created by Michael Chen on 2015/10/26.
//  Copyright © 2015年 Michael Chen. All rights reserved.
//

import Cocoa
import Hue

protocol MCDragAndDropImageViewDelegate: class {
    func dragAndDropImageViewDidDrop(pasteboard:NSPasteboard)
}

class MCDragAndDropImageView: NSImageView {

	weak var delegate: MCDragAndDropImageViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        register(forDraggedTypes: NSImage.imageTypes())
        
        
        
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
        
        let gradient = [NSColor(hex: "000"), NSColor(hex: "000"), NSColor(hex: "000")].gradient()
        gradient.cornerRadius = 20

        layer = gradient
	}

	override var mouseDownCanMoveWindow:Bool {
		return true
	}
}

// MARK: - NSDraggingSource

extension MCDragAndDropImageView: NSDraggingSource {

	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {

		if (NSImage.canInit(with: sender.draggingPasteboard())) {
			isHighlighted = true

			setNeedsDisplay()

			let sourceDragMask = sender.draggingSourceOperationMask()
			let pboard = sender.draggingPasteboard()

			if pboard.availableType(from: [NSFilenamesPboardType]) == NSFilenamesPboardType {
				if sourceDragMask.rawValue & NSDragOperation.copy.rawValue != 0 {
					return NSDragOperation.copy
				}
			}
		}

		return NSDragOperation()
	}

	override func draggingExited(_ sender: NSDraggingInfo?) {
		isHighlighted = false
		setNeedsDisplay()
	}

	override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
		isHighlighted = false
		setNeedsDisplay()

		return NSImage.canInit(with: sender.draggingPasteboard())
	}

	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		if (NSImage.canInit(with: sender.draggingPasteboard())) {
//			image = NSImage(pasteboard: )
			delegate?.dragAndDropImageViewDidDrop(pasteboard: sender.draggingPasteboard())
//			setNeedsDisplay()
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
