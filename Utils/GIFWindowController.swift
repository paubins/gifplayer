//
//  GIFController.swift
//  GifPlayer
//
//  Created by Patrick Aubin on 1/14/22.
//  Copyright © 2022 com.paubins.GifPlayer. All rights reserved.
//

import Foundation
import CoreImage
import AppKit

enum GIFAction {
    case rewind
    case fastForward
    case slowDown
    case speedUp
    case larger
    case smaller
    case larger1px
    case smaller1px
    case increaseAlpha
    case decreaseAlpha
    case moveUp
    case moveDown
    case moveRight
    case moveLeft
    case actualSize
    case clone
    case save((()->()), (()->()))
    case play
}

extension NSImage {
    func resizedCopy( w: CGFloat, h: CGFloat) -> NSImage {
        let destSize = NSMakeSize(w, h)
        let newImage = NSImage(size: destSize)
        
        newImage.lockFocus()
        
        self.draw(in: NSRect(origin: .zero, size: destSize),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: CGFloat(1)
        )
        
        newImage.unlockFocus()
        
        guard let data = newImage.tiffRepresentation,
              let result = NSImage(data: data)
        else { return NSImage() }
        
        return result
    }
}

class ViewController : NSViewController {
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var mainTextField: NSTextField!
    
    func toggleLoading(message: String) {
        self.mainTextField.stringValue = message
        self.progressBar.startAnimation(nil)
    }
}

class GIF {
    var name:String?
    var animationImages:[CGImage]?
    var size:NSSize = .zero
}

class GIFManager {
    var gifs:[GIF] = []
    static let shared = GIFManager()
    
    let loadingViewController:NSWindowController = {
        let windowController = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "LoadingWindow") as! NSWindowController
        return windowController
    }()
    
    
    func getIndex(for gif: String) -> Int {
        let indexes = gifs.enumerated().filter({ $0.element.name == gif }).map({ $0.offset })
        if indexes.count == 1 {
            return indexes[0]
        }
        return -1
    }
    
    func convertToGIF(url: URL) {
        GIFManager.shared.showLoader(message: "Converting GIF...")
        NSGIF.createGIFfromURL(url, withFrameCount: Int32(15), delayTime: 1/100, loopCount: 0) { url in
            GIFManager.shared.hideLoader()
            if let url = url {
                GIFManager.shared.powerLoadGIF(url: url)
            }
        }
    }
    
    func powerLoadGIF(url: URL) {
        GIFManager.shared.showLoader(message: "Loading GIF...")
        let windowController = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "MainWindowController") as! CustomWindowController
        windowController.shouldCascadeWindows = true
        
        if let window = windowController.window as? GIFWindow {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(NSWindow.StyleMask.fullSizeContentView)
            windowController.keyPressCallback = { action in
                window.parseAction(action: action)
            }
        }
        
        (windowController.window as! GIFWindow).loadGIF(gifFileName: url) {
            guard let window = windowController.window as? GIFWindow else {
                return
            }
            
            if let contentView = window.contentView!.subviews.first, let pixelBuffer = window.getNextImage() {
                let width = window.frame.size.width * NSScreen.main!.backingScaleFactor
                let height = window.frame.size.height * NSScreen.main!.backingScaleFactor

                (contentView as! MetalView).create(coords: [CGPoint(x: width, y: height),
                                                              CGPoint(x: 0, y: height),
                                                              CGPoint(x: 0, y: 0),
                                                              CGPoint(x: width, y: height),
                                                              CGPoint(x: 0, y: 0),
                                                              CGPoint(x: width, y: 0)])
                (contentView as! MetalView).replace(with: .image(pixelBuffer))
                
            }
            window.orderFrontRegardless()
            GIFManager.shared.hideLoader()
        } timerCallback: {
            guard let window = windowController.window as? GIFWindow,
                  let contentView = window.contentView,
                  let metalView = contentView.subviews.first as? MetalView,
                  let pixelBuffer = window.getNextImage() else {
                      return
                  }
            metalView.replace(with: .image(pixelBuffer))
        }
    }
    
    func showLoader(message: String) {
        DispatchQueue.main.async { [self] in
            if let window = self.loadingViewController.window  {
                let viewController = (window.contentViewController as! ViewController)
                viewController.toggleLoading(message: message)
                window.orderFrontRegardless()
            }
        }
    }
    
    func hideLoader() {
        DispatchQueue.main.async { [self] in
            if let window = self.loadingViewController.window  {
                let viewController = (window.contentViewController as! ViewController)
                viewController.toggleLoading(message: "")
                window.orderOut(self)
            }
        }
    }
}

class GIFWindow : NSWindow {
    private var gifIndex:Int = 0
    
    private var animationImages:[CGImage]? {
        if let animationImages = GIFManager.shared.gifs[self.gifIndex].animationImages {
            return animationImages
        }
        return nil
    }
    
    private var imageSize:NSSize {
        return GIFManager.shared.gifs[self.gifIndex].size
    }
    
    private var timer:Timer?
    private var currFrameCount:Int = 0
    private var maxFrameCount:Int = 29
    private var defaultInterval = 0.05
    
    private var timerCallback:(()->())?
    
    func getSize(completion: @escaping ((NSSize) -> ())) {
        DispatchQueue.main.async { [self] in
            completion(frame.size)
        }
    }
    
    func getNextImage() -> CGImage? {
        if let animationImages = animationImages {
            let image = animationImages[self.currFrameCount]
            if animationImages.count == self.currFrameCount+1 {
                self.currFrameCount = 0
            } else {
                self.currFrameCount += 1
            }
            return image
        }
        return nil
    }
    
    func rewind() {
        if (0 < currFrameCount) {
            currFrameCount -= 1
        }
        else {
            currFrameCount = FIRST_FRAME;
        }
    }
    
    func forward() {
        if (currFrameCount < maxFrameCount-1) {
            currFrameCount += 1
        }
        else {
            currFrameCount = FIRST_FRAME;
        }
    }
    
    func speedUp() {
        if timer != nil {
            if let timer = timer {
                timer.invalidate()
            }
            timer = nil
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: self.defaultInterval * 0.5, repeats: true, block: { [self] timer in
            if let timerCallback = timerCallback {
                DispatchQueue.main.async {
                    timerCallback()
                }
            }
        })
    }
    
    func slowDown() {
        if timer != nil {
            if let timer = timer {
                timer.invalidate()
            }
            timer = nil
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: self.defaultInterval * 2.0, repeats: true, block: { [self] timer in
            if let timerCallback = timerCallback {
                DispatchQueue.main.async {
                    timerCallback()
                }
            }
        })
    }
    
    func currentDelay() -> TimeInterval {
        return self.timer!.timeInterval
    }
    
    func loadGIF(gifFileName:URL, completion:(()->())? = nil, timerCallback:(()->())?=nil) {
        self.timerCallback = timerCallback
        
        var windowSize:NSSize = .zero
        let gifIndex = GIFManager.shared.getIndex(for: gifFileName.absoluteString)
        if gifIndex < 0 {
            let newGIF = GIF()
            let sizeAndImages =  self.fromGif(resourceName: gifFileName)
            newGIF.animationImages = sizeAndImages.0
            newGIF.size = sizeAndImages.1
            newGIF.name = gifFileName.absoluteString
            windowSize = newGIF.size
            // store the images
            GIFManager.shared.gifs += [newGIF]
            self.gifIndex = GIFManager.shared.gifs.count-1
        } else {
            self.gifIndex = gifIndex
            windowSize = GIFManager.shared.gifs[self.gifIndex].size
        }
        
        if let completion = completion {
            DispatchQueue.main.async {
                completion()
            }
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: self.defaultInterval, repeats: true, block: { timer in
            if let timerCallback = timerCallback {
                DispatchQueue.main.async {
                    timerCallback()
                }
            }
        })
    }
    
    func retrieveWindowForDisplay(size: NSSize) -> CustomWindowController? {
        let windowController = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "MainWindowController") as! CustomWindowController
        windowController.shouldCascadeWindows = true
        
        if let viewController:NSViewController = windowController.contentViewController {
            let window:NSWindow = windowController.window!
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(NSWindow.StyleMask.fullSizeContentView)
            window.setContentSize(size)
        }
        return windowController
    }
    
    func fromGif(resourceName: URL) -> ([CGImage]?, NSSize) {
        let url = resourceName
        guard let gifData = try? Data(contentsOf: url),
              let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else { return (nil, .zero) }
        var images = [CGImage]()
        let imageCount = CGImageSourceGetCount(source)
        self.maxFrameCount = imageCount
        
        let propertiesOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, propertiesOptions) as? [CFString: Any] else {
            return (nil, .zero)
        }

        var size:NSSize?
        if let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
           let height = properties[kCGImagePropertyPixelHeight] as? CGFloat {
            size = NSSize(width: width, height: height)
        }
        
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
        }
        return (images, size!)
    }
    
    func saveGIF(savingBeganHandler: @escaping (()->()), savingEndedHandler:@escaping (()->()) ) {
        savingBeganHandler()
        self.getSize { size in
            DispatchQueue(label: "gifSave").async { [self] in
                guard let animationImages = animationImages else {
                    return
                }
                
                let destinationURL = NSURL(fileURLWithPath: "\(folderPath)/image3.gif")
                let destinationGIF = CGImageDestinationCreateWithURL(destinationURL, kUTTypeGIF, animationImages.count, nil)!
                
                // The final size of your GIF. This is an optional parameter
                var rect = NSMakeRect(0, 0, size.width, size.height)
                
                // This dictionary controls the delay between frames
                // If you don't specify this, CGImage will apply a default delay
                let properties = [
                    (kCGImagePropertyGIFDictionary as String): [(kCGImagePropertyGIFDelayTime as String): 1.0/16.0]
                ]
                
                for img in animationImages {
                    // Convert an NSImage to CGImage, fitting within the specified rect
                    // You can replace `&rect` with nil
                    let newImage = NSImage(cgImage: img, size: rect.size)
                    let cgImage = newImage.resizedCopy(w: rect.width, h: rect.height).cgImage(forProposedRect: &rect, context: nil, hints: nil)!
                    
                    // Add the frame to the GIF image
                    // You can replace `properties` with nil
                    CGImageDestinationAddImage(destinationGIF, cgImage, properties as CFDictionary)
                }
                
                // Write the GIF file to disk
                CGImageDestinationFinalize(destinationGIF)
                print(destinationURL)
                savingEndedHandler()
            }
        }
    }
    
    func moveWindow(widthOffset:CGFloat = 1.0, widthOffsetExact:CGFloat = 0.0,
                    heightOffsetExact:CGFloat = 0.0, xOffset: CGFloat = 0.0, yOffset:CGFloat = 0.0) {
        if let windowController = windowController, let window = windowController.window {
            let newSize = window.frame.size * widthOffset
            let newRect = NSRect(x: window.frame.origin.x + xOffset + widthOffsetExact,
                                 y: window.frame.origin.y + yOffset + heightOffsetExact,
                                 width: newSize.width, height: newSize.height)
            window.setFrame(newRect, display: true, animate: true)
        }
    }
    
    func resetWindow() {
        if let windowController = windowController, let window = windowController.window {
            let newSize = self.imageSize
            let newRect = NSRect(x: window.frame.origin.x, y: window.frame.origin.y,
                                 width: newSize.width, height: newSize.height)
            window.setFrame(newRect, display: true, animate: true)
        }
    }
    
    func decreaseAlpha() {
        if let windowController = windowController, let window = windowController.window {
            window.alphaValue = max(window.alphaValue-0.1, 0.1)
        }
    }
    
    func increaseAlpha() {
        if let windowController = windowController, let window = windowController.window {
            window.alphaValue = min(window.alphaValue+0.1, 1.0)
        }
    }
    
    func parseAction(action: GIFAction) {
        print(action)
        switch action {
        case .rewind:
//            self.rewind()
            break
        case .fastForward:
//            self.forward()
            break
        case .slowDown:
            self.slowDown()
            break
        case .speedUp:
            self.speedUp()
            break
        case .larger:
            self.moveWindow(widthOffset: 1.1)
        case .smaller:
            self.moveWindow(widthOffset: 0.9)
        case .larger1px:
            self.moveWindow(widthOffsetExact: 1.0, heightOffsetExact: 1.0)
        case .smaller1px:
            self.moveWindow(widthOffsetExact: -1.0, heightOffsetExact: -1.0)
        case .increaseAlpha:
            self.increaseAlpha()
        case .decreaseAlpha:
            self.decreaseAlpha()
        case .moveUp:
            self.moveWindow(yOffset: 10)
        case .moveDown:
            self.moveWindow(yOffset: -10)
        case .moveRight:
            self.moveWindow(xOffset: 10)
        case .moveLeft:
            self.moveWindow(xOffset: -10)
        case .actualSize:
            self.resetWindow()
        case .clone:
            if let urlString = GIFManager.shared.gifs[self.gifIndex].name,
               let url = URL(string: urlString) {
                GIFManager.shared.powerLoadGIF(url: url)
            }
            break
        case .save(let saveStarted, let saveEnded):
            self.saveGIF {
                saveStarted()
            } savingEndedHandler: {
                saveEnded()
            }
        case .play:
            if self.timer != nil {
                self.timer!.invalidate()
                self.timer = nil
            } else {
                self.timer = Timer.scheduledTimer(withTimeInterval: self.defaultInterval, repeats: true, block: { timer in
                    DispatchQueue.main.async { [self] in
                        if let windowController = self.windowController {
                            if let timerCallback = self.timerCallback {
                                timerCallback()
                            }
                        }
                    }
                })
            }
            break
        }
    }
}

class GIFWindowController : NSWindowController {

    let pasteboardWatcher:PasteboardWatcher = PasteboardWatcher(fileKinds: ["gif", "mp4"])
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.pasteboardWatcher.delegate = self
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions" : true])
        if let window = self.window {
            let contentView:MCDragAndDropImageView = window.contentView as! MCDragAndDropImageView
            contentView.delegate = self
        }
    }
}


extension GIFWindowController : MCDragAndDropImageViewDelegate {
    func dragAndDropImageViewDidDrop(pasteboard:NSPasteboard) {
        let url:URL = NSURL(from: pasteboard)! as URL
        if url.pathExtension == "mp4" {
            GIFManager.shared.convertToGIF(url: url)
        } else {
            GIFManager.shared.powerLoadGIF(url: url)
        }
    }
}

extension GIFWindowController : PasteboardWatcherDelegate {
    func newlyCopiedUrlObtained(copiedUrl: NSURL) {
//        _ = self.displayWindow(filename: copiedUrl.absoluteString!)
    }
}

class CustomWindowController : NSWindowController {
    
    var keyPressCallback:((GIFAction)->())?
    
    override func keyDown(with event: NSEvent) {
        print(event)
        switch event.keyCode {
        case 123:
            break
        default:
            break
        }
    }
    
    override func keyUp(with event: NSEvent) {
        guard let keyPressCallback = keyPressCallback else {
            return
        }

        print(event)
        switch event.keyCode {
        case 1:
            keyPressCallback(.save({
                GIFManager.shared.showLoader(message: "Saving GIF...")
            }, {
                GIFManager.shared.hideLoader()
            }))
        case 2:
            keyPressCallback(.slowDown)
        case 3:
            keyPressCallback(.speedUp)
        case 8:
            keyPressCallback(.clone)
        case 24:
            keyPressCallback(.larger)
        case 27:
            keyPressCallback(.smaller)
        case 43:
            keyPressCallback(.decreaseAlpha)
        case 47:
            keyPressCallback(.increaseAlpha)
        case 49:
            keyPressCallback(.play)
        case 53:
            keyPressCallback(.actualSize)
        case 123:
            keyPressCallback(.moveLeft)
        case 124:
            keyPressCallback(.moveRight)
        case 125:
            keyPressCallback(.moveDown)
        case 126:
            keyPressCallback(.moveUp)
        default:
            print("idk")
        }
    }
}

// MARK: - Helper

func *(size: NSSize, scale: CGFloat) -> NSSize {
    return NSMakeSize(size.width * scale, size.height * scale)
}
