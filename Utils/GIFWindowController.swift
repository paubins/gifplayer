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
import VideoToolbox
import Accelerate

let MAX_FRAMES = 800

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
    var pixelBuffers:[CVPixelBuffer]?
    var size:NSSize = .zero
    var isWebm:Bool {
        URL(string: self.name!)!.pathExtension == "webm"
    }
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
        }
        
        (windowController.window as! GIFWindow).loadGIF(gifFileName: url) { windowSize in
            guard let window = windowController.window as? GIFWindow else {
                return
            }
            if window.isWebM {
                if let contentView = window.contentView!.subviews.first, let pixelBuffer = window.getNextPixelBuffer() {
                    let width = window.frame.size.width * NSScreen.main!.backingScaleFactor
                    let height = window.frame.size.height * NSScreen.main!.backingScaleFactor

                    (contentView as! MetalView).create(coords: [CGPoint(x: width, y: height),
                                                                  CGPoint(x: 0, y: height),
                                                                  CGPoint(x: 0, y: 0),
                                                                  CGPoint(x: width, y: height),
                                                                  CGPoint(x: 0, y: 0),
                                                                  CGPoint(x: width, y: 0)])
                    (contentView as! MetalView).replace(with: .yuvBuffer(pixelBuffer, false))
                }
            } else {
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
            }
            window.setFrame(NSRect(origin: window.frame.origin, size: windowSize), display: true)
            window.orderFrontRegardless()
            GIFManager.shared.hideLoader()
        } timerCallback: {
            guard let window = windowController.window as? GIFWindow,
                  let contentView = window.contentView,
                  let metalView = contentView.subviews.first as? MetalView else {
                      return
                  }
            
            if window.isWebM {
                let pixelBuffer = window.getNextPixelBuffer()
                metalView.replace(with: .yuvBuffer(pixelBuffer, false))
            } else {
                if let pixelBuffer = window.getNextImage() {
                    metalView.replace(with: .image(pixelBuffer))
                }
                
            }
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
    
    func downloadFile(url: URL, completion: @escaping ((URL?)->()) ) {
        GIFManager.shared.showLoader(message: "Downloading file...")
        let downloadTask = URLSession.shared.downloadTask(with: url) {
            urlOrNil, responseOrNil, errorOrNil in
            // check for and handle errors:
            // * errorOrNil should be nil
            // * responseOrNil should be an HTTPURLResponse with statusCode in 200..<299
            
            guard let fileURL = urlOrNil else { return }
            do {
                let documentsURL = try
                    FileManager.default.url(for: .documentDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: false)
                let savedURL = documentsURL.appendingPathComponent(url.lastPathComponent)
                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                completion(savedURL)
            } catch {
                print ("file error: \(error)")
            }
            DispatchQueue.main.async {
                GIFManager.shared.hideLoader()
            }
        }
        downloadTask.resume()
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
    
    private var animationBuffers:[CVPixelBuffer]? {
        if let animationImages = GIFManager.shared.gifs[self.gifIndex].pixelBuffers {
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
    
    var isWebM:Bool {
        GIFManager.shared.gifs[self.gifIndex].isWebm
    }
    
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
    
    func getNextPixelBuffer() -> CVPixelBuffer? {
        if let animationImages = animationBuffers {
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
    
    func pause() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func play() {
        
    }
    
    func currentDelay() -> TimeInterval {
        return self.timer!.timeInterval
    }
    
    func loadGIF(gifFileName:URL, completion:((NSSize)->())? = nil, timerCallback:(()->())?=nil) {
        self.timerCallback = timerCallback
        
        var windowSize:NSSize = .zero
        let gifIndex = GIFManager.shared.getIndex(for: gifFileName.absoluteString)
        if gifIndex < 0 {
            let newGIF = GIF()
            switch gifFileName.pathExtension {
            case "gif":
                let sizeAndImages =  self.fromGif(resourceName: gifFileName)
                newGIF.animationImages = sizeAndImages.0
                newGIF.size = sizeAndImages.1
            case "webm":
                let sizeAndImages =  self.fromWebm(resourceName: gifFileName)
                newGIF.pixelBuffers = sizeAndImages.0
                newGIF.size = sizeAndImages.1
                break
            default:
                print("unknown")
            }
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
                completion(windowSize)
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
        let imageCount = min(CGImageSourceGetCount(source), MAX_FRAMES)
        self.maxFrameCount = min(imageCount, MAX_FRAMES)
        
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
    
    func chooseFolderLocation(completion: (String?)->()) {
        let dialog = NSOpenPanel();

        dialog.title                   = "Choose where we should store your GIF.";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseFiles = false;
        dialog.canChooseDirectories = true;

        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url

            if (result != nil) {
                let path: String = result!.path
                completion(path)
            }
        } else {
            // User clicked on "Cancel"
            completion(nil)
            return
        }
    }
    
    func saveGIF(savingBeganHandler: @escaping (()->()), savingEndedHandler:@escaping (()->()) ) {
        savingBeganHandler()
        self.getSize { [self] size in
            if self.isWebM {
                guard let animationBuffers = animationBuffers else {
                    return
                }
                
                self.chooseFolderLocation { path in
                    guard let path = path else {
                        return
                    }
                    
                    DispatchQueue(label: "save-webm").async {
                        NSImage.animatedGif(from: animationBuffers, size: size, path: path)
                        savingEndedHandler()
                    }
                }
            } else {
                self.chooseFolderLocation { path in
                    guard let path = path else {
                        return
                    }
                    
                    DispatchQueue(label: "gifSave").async { [self] in
                        guard let animationImages = animationImages else {
                            return
                        }
                        
                        let fileURL: URL? = NSURL(string: path)?.appendingPathComponent("\(GIFManager.shared.gifs[self.gifIndex].name!).gif")
                        let destinationURL = NSURL(fileURLWithPath: fileURL!.absoluteString)
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
        }
    }
    
    func fromWebm(resourceName: URL) -> ([CVPixelBuffer]?, NSSize){
        var images:[CVPixelBuffer] = []
        let viewController = GlkVideoViewController()
        viewController.fileToPlay = resourceName.absoluteURL.path
        GIFManager.shared.showLoader(message: "Loading WebM...")
        var size:NSSize = .zero
        viewController.loadFile { pixelBuffer in
            if size == .zero, let pixelBuffer = pixelBuffer {
                size = NSSize(width: CVPixelBufferGetWidth(pixelBuffer),
                              height: CVPixelBufferGetHeight(pixelBuffer))
            }
            
            if pixelBuffer != nil {
                print(pixelBuffer!)
                images.append(pixelBuffer!)
            }
        }
        viewController.playFile()
        GIFManager.shared.hideLoader()
        return (images, CGSize(width: size.width, height: size.height))
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
    
    func clone() {
        if let urlString = GIFManager.shared.gifs[self.gifIndex].name,
           let url = URL(string: urlString) {
            GIFManager.shared.powerLoadGIF(url: url)
        }
    }
    
    func save() {
        self.saveGIF {
            GIFManager.shared.showLoader(message: "Saving GIF...")
        } savingEndedHandler: {
            GIFManager.shared.hideLoader()
        }
    }
}

class GIFWindowController : NSWindowController {

    override func awakeFromNib() {
        super.awakeFromNib()
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions" : true])
        if let window = self.window {
            let contentView:MCDragAndDropImageView = window.contentView as! MCDragAndDropImageView
            contentView.delegate = self
        }
    }
}


extension GIFWindowController : MCDragAndDropImageViewDelegate {
    func parse(url: URL) {
        if url.pathExtension == "mp4" ||  url.pathExtension == "mov"{
            GIFManager.shared.convertToGIF(url: url)
        } else if url.pathExtension == "webm" {
            print("about to load webm")
            GIFManager.shared.powerLoadGIF(url: url)
        } else {
            GIFManager.shared.powerLoadGIF(url: url)
        }
    }
    
    func dragAndDropImageViewDidDrop(pasteboard:NSPasteboard) {
        let url:URL = NSURL(from: pasteboard)! as URL
        if url.absoluteString.hasPrefix("http") && ["mp4", "mov", "webm", "gif"].contains(obj: url.pathExtension){
            GIFManager.shared.downloadFile(url: url) { url in
                if let url = url {
                    DispatchQueue.main.async {
                        self.parse(url: url)
                    }
                } else {
                    print("unable to download")
                }
            }
        } else {
            self.parse(url: url)
        }
    }
}

class CustomWindowController : NSWindowController {
    
    var keyPressCallback:((GIFAction)->())?
    
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
        default:
            print("idk")
        }
    }
}

// MARK: - Helper

func *(size: NSSize, scale: CGFloat) -> NSSize {
    return NSMakeSize(size.width * scale, size.height * scale)
}

extension NSImage {
    static func animatedGif(from images: [CVPixelBuffer], size: NSSize, path: String) {
        let fileProperties: CFDictionary = [
            kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0],
            kCGImagePropertyGIFHasGlobalColorMap as String: true,
            kCGImagePropertyColorModel as String: kCGImagePropertyColorModelRGB as String
        ]  as CFDictionary
            
        let frameProperties: CFDictionary = [kCGImagePropertyGIFDictionary as String: [(kCGImagePropertyGIFDelayTime as String): 1.0]] as CFDictionary
        
        let fileURL: URL? = URL(fileURLWithPath: path).appendingPathComponent("animated.gif")
        
        if let url = fileURL as CFURL? {
            if let destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, images.count, nil) {
                CGImageDestinationSetProperties(destination, fileProperties)
                for image in images {
                    var _vtpt_ref:VTPixelTransferSession?
                    let _ = VTPixelTransferSessionCreate(allocator: kCFAllocatorDefault, pixelTransferSessionOut: &_vtpt_ref)
                    var converted_frame:CVPixelBuffer?
                    CVPixelBufferCreate(kCFAllocatorDefault,
                                        Int(size.width), Int(size.height),
                                        kCVPixelFormatType_32BGRA,
                                        nil,
                                        &converted_frame)
                    
                    if let _vtpt_ref = _vtpt_ref, let converted_frame = converted_frame {
                        VTPixelTransferSessionTransferImage(_vtpt_ref, from: image, to: converted_frame)
                        var cgImage:CGImage?
                        VTCreateCGImageFromCVPixelBuffer(converted_frame, options: nil, imageOut: &cgImage)
                        CGImageDestinationAddImage(destination, cgImage!, frameProperties)
                    }
                    
                }
                if !CGImageDestinationFinalize(destination) {
                    print("Failed to finalize the image destination")
                }
                print("Url = \(fileURL)")
            }
        }
    }
}

extension Array {
     func contains<T>(obj: T) -> Bool where T: Equatable {
         return !self.filter({$0 as? T == obj}).isEmpty
     }
 }
