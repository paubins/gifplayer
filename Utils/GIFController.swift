//
//  GIFController.swift
//  GifPlayer
//
//  Created by Patrick Aubin on 1/14/22.
//  Copyright © 2022 com.paubins.GifPlayer. All rights reserved.
//

import Foundation
import CoreImage

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
    
    func getIndex(for gif: String) -> Int {
        let indexes = gifs.enumerated().filter({ $0.element.name == gif }).map({ $0.offset })
        if indexes.count == 1 {
            return indexes[0]
        }
        return -1
    }
}

class GIFWindow {
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
    
    private var completion:((CustomWindowController)->())?
    private var timerCallback:((CustomWindowController)->())?
    
    var windowController:CustomWindowController?
    
    func getSize(completion: @escaping ((NSSize) -> ())) {
        DispatchQueue.main.async { [self] in
            if let windowController = windowController,
                let window = windowController.window {
                completion(window.frame.size)
            }
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
                    if let windowController = self.windowController {
                        timerCallback(windowController)
                    }
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
                    if let windowController = self.windowController {
                        timerCallback(windowController)
                    }
                }
            }
        })
    }
    
    func currentDelay() -> TimeInterval {
        return self.timer!.timeInterval
    }
    
    func loadGIF(gifFileName:URL, completion:((CustomWindowController)->())? = nil, timerCallback:((CustomWindowController)->())?=nil) {
        self.completion = completion
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
                if self.windowController == nil {
                    self.windowController = self.retrieveWindowForDisplay(size: windowSize)
                    self.windowController!.keyPressCallback = { action in
                        self.parseAction(action: action)
                    }
                }
                if let windowController = self.windowController {
                    completion(windowController)
                }
            }
        }
        
        self.timer = Timer.scheduledTimer(withTimeInterval: self.defaultInterval, repeats: true, block: { timer in
            if let timerCallback = timerCallback {
                DispatchQueue.main.async {
                    if let windowController = self.windowController {
                        timerCallback(windowController)
                    }
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
            print(self.gifIndex)
            if let urlString = GIFManager.shared.gifs[self.gifIndex].name,
               let url = URL(string: urlString) {
                GIFController.shared.powerLoadGIF(url: url)
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
                                timerCallback(windowController)
                            }
                        }
                    }
                })
            }
            break
        }
    }
}

class GIFController : NSObject {
    var screenRect:NSRect! {
        return (self.topMostWindow?.frame)!
    }
    
    static let shared = GIFController()
    let dockMenu = NSMenu()
    
    var newWindow:NSWindow!
    let feedbackWindowController:NSWindowController = NSWindowController()
    let loadingViewController:NSWindowController = {
        let windowController = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "LoadingWindow") as! NSWindowController
        return windowController
    }()
    
    @IBOutlet weak var windowMenu: NSMenuItem!
    @IBOutlet weak var saveButton: NSMenuItem!
    
    var gifWindows:[GIFWindow] = []
    
    let pasteboardWatcher:PasteboardWatcher = PasteboardWatcher(fileKinds: ["gif"])
    
    var topMostWindow:FOTWindow! {
        for gifWindow in self.gifWindows {
            if let windowController = gifWindow.windowController {
                if(windowController.window?.isKeyWindow)! {
                    return windowController.window as? FOTWindow
                }
            }
        }
        return nil
    }
    
    var fileToOpen:String = ""
    
    override init() {
        super.init()
        self.pasteboardWatcher.delegate = self
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions" : true])
        let contentView:MCDragAndDropImageView = self.loadNewGifWindowController.window!.contentView as! MCDragAndDropImageView
        contentView.delegate = self
        self.loadNewGifWindowController.window?.makeKeyAndOrderFront(self.loadNewGifWindowController.window)
    }
    
    @IBAction func minimizeWindow(_ sender: Any) {
        for gifWindow in self.gifWindows {
            if let windowController = gifWindow.windowController {
                if(windowController.window?.isKeyWindow)! {
                    (windowController.window as? FOTWindow)?.toggleFullScreen(self)
                }
            }
        }
    }

    var loadNewGifWindowController:NSWindowController = {
        let newWindow:NSWindow = NSWindow(contentRect: NSMakeRect(0, 0, 250, 250),
                                          styleMask: [.borderless],
                                          backing: .buffered,
                                          defer: false)
        
        newWindow.isOpaque = false
        newWindow.center()
        newWindow.isMovableByWindowBackground = true
        newWindow.backgroundColor = NSColor.black
        
        let imageView:MCDragAndDropImageView = MCDragAndDropImageView(frame: NSMakeRect(0, 0, 250, 250))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer?.cornerRadius = 5
        
        newWindow.contentView = imageView
        newWindow.hasShadow = true
        
        let label:NSTextField = NSTextField(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.stringValue = "Drop GIFs here!"
        label.font = NSFont(name: "VarelaRound-Regular", size: 200)
        label.textColor = NSColor.white

        newWindow.contentView?.addSubview(label)
        
        label.centerXAnchor.constraint(equalTo: (newWindow.contentView?.centerXAnchor)!).isActive = true
        label.centerYAnchor.constraint(equalTo: (newWindow.contentView?.centerYAnchor)!).isActive = true

        return NSWindowController(window: newWindow)
    }()
    
    private func convertToGIF() {
        NSGIF.createGIFfromURL(URL(string: ""), withFrameCount: Int32(15), delayTime: 1/100, loopCount: 0) { (url) in
            
        }
    }
    
    @objc func windowClosed(sender: Notification) {
        let window:FOTWindow = sender.object as! FOTWindow
    
//        if(self.dockMenu.index(of: window.menuItem) >= 0) {
//            self.dockMenu.removeItem(window.menuItem)
//
//            let windowIndex = self.windowControllers.firstIndex(of: window.windowController!)
//            self.windowControllers.remove(at: windowIndex!)
//        }
//
//        if(self.gifWindows.count > 0) {
//            self.windowControllers.last?.window?.makeKey()
//            NSApp.activate(ignoringOtherApps: true)
//        } else {
//            self.loadNewGifWindowController.window?.makeKeyAndOrderFront(loadNewGifWindowController.window)
////            windowMenu.isHidden = true
//        }
    }

    @IBAction func closeWindow(_ sender: Any) {
        for gifWindow in self.gifWindows {
            if let windowController = gifWindow.windowController {
                if(windowController.window?.isKeyWindow)! {
                    windowController.window?.close()
                }
            }
        }
    }
    
    func openFile(file: String) {
        self.fileToOpen = file
//        self.displayWindow(filename: self.fileToOpen)
    }
    
    func openFiles(urls: [URL]) {
        for url in urls {
//            let _ = self.displayWindow(filename: url.path)
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
    
    func createNewWindow() {
        if newWindow == nil {
            newWindow = NSWindow(contentRect: NSMakeRect(0, 0, NSScreen.main!.frame.midX, NSScreen.main!.frame.midY + 150), styleMask: [.closable, .titled], backing: .buffered, defer: false)
            
            newWindow.title = "Feedback"
            newWindow.isOpaque = false
            newWindow.center()
            newWindow.isMovableByWindowBackground = true
            newWindow.backgroundColor = NSColor(calibratedHue: 0, saturation: 1.0, brightness: 0, alpha: 0.7)
            
            
            let webView = WebView(frame: NSMakeRect(0, 0, NSScreen.main!.frame.midX, NSScreen.main!.frame.midY))
            webView.mainFrameURL = Bundle.main.url(forResource: "index", withExtension: "html")?.absoluteString
            
            newWindow.contentView = webView
            
            feedbackWindowController.window = newWindow
        }
    }
    
    @IBAction func submitFeedback(_ sender: Any) {
        self.createNewWindow()
        newWindow.makeKeyAndOrderFront(newWindow)
    }
    
    @IBAction func quit(_ sender: Any) {
        NSLog("Exit")
        NSApplication.shared.terminate(nil)
    }
   
    func powerLoadGIF(url: URL) {
//        self.windowMenu.isHidden = false
        self.showLoader(message: "Loading GIF...")
        let gifWindow = GIFWindow()
        gifWindow.loadGIF(gifFileName: url, completion: { windowController in
            if let window = windowController.window {
                if let contentView = window.contentView!.subviews.first, let pixelBuffer = gifWindow.getNextImage() {
                    let width = window.frame.size.width * NSScreen.main!.backingScaleFactor
                    let height = window.frame.size.height * NSScreen.main!.backingScaleFactor
//                    print("wh: \(width) \(height)")
                    
                    (contentView as! MetalView).create(coords: [CGPoint(x: width, y: height),
                                                                  CGPoint(x: 0, y: height),
                                                                  CGPoint(x: 0, y: 0),
                                                                  CGPoint(x: width, y: height),
                                                                  CGPoint(x: 0, y: 0),
                                                                  CGPoint(x: width, y: 0)])
                    (contentView as! MetalView).replace(with: .image(pixelBuffer))
                    
                }
                window.orderFrontRegardless()
                self.hideLoader()
            }
        }) { windowController in
            if let window = windowController.window {
                if let contentView = window.contentView!.subviews.first, let pixelBuffer = gifWindow.getNextImage() {
                    let width = window.frame.size.width * NSScreen.main!.backingScaleFactor
                    let height = window.frame.size.height * NSScreen.main!.backingScaleFactor
//                    print("wh: \(width) \(height)")
                    (contentView as! MetalView).replace(with: .image(pixelBuffer))
                }
            }
        }
        self.gifWindows += [gifWindow]
    }
}


extension GIFController : MCDragAndDropImageViewDelegate {
    func dragAndDropImageViewDidDrop(pasteboard:NSPasteboard) {
        let url:URL = NSURL(from: pasteboard)! as URL
        self.powerLoadGIF(url: url)
    }
}

extension GIFController : PasteboardWatcherDelegate {
    func newlyCopiedUrlObtained(copiedUrl: NSURL) {
//        _ = self.displayWindow(filename: copiedUrl.absoluteString!)
    }
}
// MARK: - Helper

func *(size: NSSize, scale: CGFloat) -> NSSize {
    return NSMakeSize(size.width * scale, size.height * scale)
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
                GIFController.shared.showLoader(message: "Saving GIF...")
            }, {
                GIFController.shared.hideLoader()
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
