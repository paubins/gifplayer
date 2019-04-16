//
//  ViewController.swift
//  GifPlayer
//
//  Created by Patrick Aubin on 6/10/17.
//  Copyright © 2017 com.paubins.GifPlayer. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    var image:NSImage!
    var filename:NSString!
    var editedFilename:NSString!
    var active:Bool = false
    
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    
    var textView: NSTextView = NSTextView() // REMOVE
    
    let imageView:ImageView = {
        let imageView:ImageView = ImageView()
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleAxesIndependently
        imageView.animates = false
        imageView.canDrawSubviewsIntoLayer = false
        
        return imageView
    }()

    var widthConstraint:NSLayoutConstraint!
    var heightConstraint:NSLayoutConstraint!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(OSX 10.12.2, *) {
            // Opt-out of text completion in this simplified version.
            if ((NSClassFromString("NSTouchBar")) != nil) {
                self.textView.isAutomaticTextCompletionEnabled = false
            }
        } else {
            // Fallback on earlier versions
        }
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        let window:NSWindow = NSApplication.shared.windows.last!
        window.isMovableByWindowBackground = true
        
        self.view.window?.isMovableByWindowBackground = true
        self.imageView.window?.isMovableByWindowBackground = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(respondToWindowResize), name: NSWindow.didResizeNotification, object: window)

        self.view.addSubview(self.imageView)
        
        window.contentView?.translatesAutoresizingMaskIntoConstraints = false
        window.contentView?.heightAnchor.constraint(equalToConstant: (self.imageView.image?.size.height)!).isActive = true
        window.contentView?.widthAnchor.constraint(equalToConstant: (self.imageView.image?.size.width)!).isActive = true

        var topConstraint = self.imageView.topAnchor.constraint(equalTo: self.view.topAnchor)
        topConstraint.isActive = true
        topConstraint.priority = NSLayoutConstraint.Priority(rawValue: 300)
        
        topConstraint = self.imageView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        topConstraint.isActive = true
        topConstraint.priority = NSLayoutConstraint.Priority(rawValue: 300)
        
        topConstraint = self.imageView.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        topConstraint.isActive = true
        topConstraint.priority = NSLayoutConstraint.Priority(rawValue: 300)
        
        topConstraint = self.imageView.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        topConstraint.isActive = true
        topConstraint.priority = NSLayoutConstraint.Priority(rawValue: 300)
        
        self.widthConstraint = self.imageView.widthAnchor.constraint(equalToConstant: window.frame.size.width)
        self.heightConstraint = self.imageView.heightAnchor.constraint(equalToConstant: window.frame.size.height)
        
        self.widthConstraint.isActive = true
        self.heightConstraint.isActive = true

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @objc func respondToWindowResize(notification: NSNotification) {
        let window:NSWindow = notification.object as! NSWindow
        self.imageView.frame = window.frame
        
        self.widthConstraint.constant = window.frame.size.width
        self.heightConstraint.constant = window.frame.size.height
    }

    func resizeImage(image:NSImage, maxSize:NSSize) -> NSImage {
        var ratio:Float = 0.0
        let imageWidth = Float(image.size.width)
        let imageHeight = Float(image.size.height)
        let maxWidth = Float(maxSize.width)
        let maxHeight = Float(maxSize.height)
        
        // Get ratio (landscape or portrait)
        if (imageWidth > imageHeight) {
            // Landscape    
            ratio = maxWidth / imageWidth;
        }
        else {
            // Portrait
            ratio = maxHeight / imageHeight;
        }
        
        // Calculate new size based on the ratio
        let newWidth = imageWidth * ratio
        let newHeight = imageHeight * ratio
        
        // Create a new NSSize object with the newly calculated size
        let newSize:NSSize = NSSize(width: Int(newWidth), height: Int(newHeight))
        
        // Cast the NSImage to a CGImage
        var imageRect:CGRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        
        // Create NSImage from the CGImage using th@objc e new size
        let imageWithNewSize = NSImage(cgImage: imageRef!, size: newSize)
        
        // Return the new image
        return imageWithNewSize
    }
    
    @objc func showWindow(menuItem: NSMenuItem) {
        self.view.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
//        menuItem.state = NSOnState
    }
    
    func creatSearchableItem() {
        
    }

    override func mouseEntered(with event: NSEvent) {
        self.active = true
    }
    
    override func mouseExited(with event: NSEvent) {
        self.active = false
    }
    
    func speedUp() {
        self.imageView.speedUp()
    }
    
    func slowDown() {
        self.imageView.slowDown()
    }
    
    func currentDelay() -> TimeInterval {
        return self.imageView.currentDelay()
    }
    
    var timer:Timer!
    var alert:AXAlert!
    
    func download(url: String, completionHandler: @escaping (Bool, CGSize) -> ()) {
        self.imageView.frame = NSRect(x:0, y:0, width: 300, height: 300)
        self.imageView.downloadImageFromURL(url, errorImage: NSImage(named: NSImage.Name(rawValue: "errorstop.png")),
                                                      usesSpinningWheel: true)
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { (timer) in
            if (!self.imageView.isLoadingImage) {
                let imageSize = (self.imageView.image?.size)!
                
                self.imageView.frame = NSRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
                
                self.timer.invalidate()
                self.timer = nil

                completionHandler(self.imageView.loadGIF(data: self.imageView.imageDownloadData!), imageSize)
            }
        })
        
        self.timer.fire()
    }
}

