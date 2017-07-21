//
//  AppDelegate.swift
//  GifPlayer
//
//  Created by Patrick Aubin on 6/10/17.
//  Copyright © 2017 com.paubins.GifPlayer. All rights reserved.
//

import Cocoa
import Fabric
import Crashlytics
import JFImageSavePanel
import WebKit

let thumbPath  = NSHomeDirectory() + "/Documents/thumb"
let folderPath  = NSHomeDirectory() + "/Documents/gif"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var saveButton: NSMenuItem!
    @IBOutlet weak var stopButtonMenuItem: NSMenuItem!
    @IBOutlet weak var playButtonMenuItem: NSMenuItem!
    
    @IBOutlet weak var optionsMenu: NSMenuItem!
    @IBOutlet weak var windowMenu: NSMenuItem!
    
    @IBOutlet weak var installScreensaver: NSMenuItem!
    @IBOutlet weak var submitFeedback: NSMenuItem!
    var gifPaths:[String] = []
    
    var fileToOpen:String = ""
    var windowControllers:[WindowController] = []
    let dockMenu = NSMenu()
    
    @IBOutlet weak var createGifMenuItem: NSMenuItem!
    @IBOutlet weak var recordMenuItem: NSMenuItem!
    @IBOutlet weak var stopMenuItem: NSMenuItem!
    @IBOutlet weak var cloneGIFMenuItem: NSMenuItem!
    
    var editWindowController:NSWindowController!
    
    var newWindow:NSWindow!
    var openWindow:NSWindow!
    
    var createGIFWindowController:NSWindowController!
    
    let feedbackWindowController:NSWindowController = NSWindowController()
    
    let openGIFWindowController:NSWindowController = NSWindowController()
    
    let pasteboardWatcher:PasteboardWatcher = PasteboardWatcher(fileKinds: ["gif"])
    
    var mainTouchBarWindowContoller:WindowController!
    
    var viewController:ViewController! {
        for windowController in self.windowControllers {
            if(windowController.window?.isKeyWindow)! {
                let viewController:ViewController = windowController.contentViewController as! ViewController
                return viewController
            }
        }
        
        return nil
    }
    
    var window:FOTWindow! {
        for windowController in self.windowControllers {
            if(windowController.window?.isKeyWindow)! {
                return windowController.window as! FOTWindow
            }
        }
        
        return nil
    }
    
    func currentGIFDelay() -> (Int, Double) {
        let gifsicle:Gifsicle = Gifsicle()
        
        let (numberOfFrames, _, frameDelay) = gifsicle.getGifsicleInfo(inputImage: viewController.filename as String)
        
        return (numberOfFrames, frameDelay)
    }
    
    func changeSpeed(filePath: String, speed: Double){
        let gifsicle:Gifsicle = Gifsicle()
        
        gifsicle.runGifsicle(inputImage: filePath,
                             resizeTo: nil,
                             optimize: 0,
                             framesToDrop: nil,
                             limitColors: 0,
                             delay: speed,
                             trimmedFrames: nil,
                             outputPath: filePath)
    }
    
    func dropOddFrames(filePath: String, totalFrames: Int) -> String {
        let gifsicle:Gifsicle = Gifsicle()
        
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("gif")
        
        var framesToDrop:[Int] = []
        
        for var i in 0...totalFrames {
            if (i % 2 != 0) {
                framesToDrop.append(i)
            }
        }
        
        gifsicle.runGifsicle(inputImage: filePath,
                             resizeTo: nil,
                             optimize: 0,
                             framesToDrop: framesToDrop,
                             limitColors: 0,
                             delay: nil,
                             trimmedFrames: nil,
                             outputPath: outputURL.path)
        
        return outputURL.path
    }
    
    @IBAction func speedUp(_ sender: Any) {
        print("speeding up")

        let (numberOfFrames, frameDelay) = self.currentGIFDelay()
        self.changeSpeed(filePath: viewController.filename as String, speed: Double(frameDelay-0.1) * 100.0)
        
        print(frameDelay-0.1)
        
        viewController.filename = viewController.filename
        viewController.image = NSImage(byReferencingFile: viewController.filename as String)!
        viewController.imageView.animates = true
        viewController.imageView.image = viewController.image
    }
    
    @IBAction func slowDown(_ sender: Any) {
        print("slow down")
        
        let (numberOfFrames, frameDelay) = self.currentGIFDelay()
        self.changeSpeed(filePath: viewController.filename as String, speed: Double(frameDelay+0.1) * 100.0)
        
        print(frameDelay+0.1)
        
        viewController.filename = viewController.filename
        viewController.image = NSImage(byReferencingFile: viewController.filename as String)!
        viewController.imageView.animates = true
        viewController.imageView.image = viewController.image
    }
    
    
    var loadNewGifWindowController:NSWindowController = {
        let newWindow:NSWindow = NSWindow(contentRect: NSMakeRect(0, 0, 250, 250), styleMask: [.borderless], backing: .buffered, defer: false)
        
        newWindow.isOpaque = false
        newWindow.center()
        newWindow.isMovableByWindowBackground = true
        newWindow.backgroundColor = NSColor.clear
        
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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        
        let fm   = FileManager.default
        
        do{
            try fm.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            try fm.createDirectory(atPath: thumbPath, withIntermediateDirectories: true, attributes: nil)
        }catch
        {
        }
        
        self.optionsMenu.isHidden = true
        
        Fabric.with([Crashlytics.self])
        
        self.editWindowController = NSStoryboard(name: "Edit", bundle: nil).instantiateController(withIdentifier: "GIFEditor") as! NSWindowController
        
        //self.editWindowController.window?.makeKeyAndOrderFront(self.editWindowController.window)
        
        NSApp.servicesProvider = self
        
        self.pasteboardWatcher.delegate = self
//        self.pasteboardWatcher.startPolling()
        
        windowMenu.isHidden = true
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions" : true])
        
        if(self.fileToOpen != "") {
            let _ = self.displayWindow(filename: self.fileToOpen)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(newGIFRecorded),
                                               name: Notification.Name(rawValue: "newGIFRecorded"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(changeWindow),
                                               name: Notification.Name(rawValue: "OpenPreviousWindow"), object: nil)
    
        NotificationCenter.default.addObserver(self, selector: #selector(changeWindow),
                                               name: Notification.Name(rawValue: "CloneCurrentWindow"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(changeWindow),
                                               name: Notification.Name(rawValue: "OpenNextWindow"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(changeWindow),
                                               name: Notification.Name(rawValue: "CloseWindowFromTouchBar"), object: nil)
        
        let contentView:MCDragAndDropImageView = self.loadNewGifWindowController.window!.contentView as! MCDragAndDropImageView
        contentView.delegate = self
        
        self.loadNewGifWindowController.window?.makeKeyAndOrderFront(self.loadNewGifWindowController.window)

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
        for gifPath in self.gifPaths {
            try? FileManager.default.removeItem(atPath: gifPath)
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        if(self.windowControllers.count > 0) {
            self.windowControllers.last?.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        self.fileToOpen = filename

        if (sender.isActive) {
            let _ = self.displayWindow(filename: filename)
        }
        
        return true
    }
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        return self.dockMenu
    }
    
    func changeWindow(sender: Notification) {
        assert(Thread.isMainThread)
        
        let windowController:WindowController = sender.object as! WindowController
        let viewController:ViewController = windowController.contentViewController as! ViewController
        let windowIndex = self.windowControllers.index(of: windowController)
        
        switch sender.name {
        case Notification.Name("OpenPreviousWindow"):
            let previousIndex = self.windowControllers.index(before: windowIndex!)
            if (previousIndex >= 0) {
                self.windowControllers[previousIndex].window?.makeKey()
                self.windowControllers[previousIndex].window?.orderFront(self)
                NSApp.activate(ignoringOtherApps: true)
                print(previousIndex)
                print("previous")
            }
            break
        case Notification.Name("CloneCurrentWindow"):
            print("cloning")
            let newWindowController = self.displayWindow(filename: viewController.filename as String)
            newWindowController.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
            break
        case Notification.Name("OpenNextWindow"):
            let nextWindowIndex = self.windowControllers.index(after: windowIndex!)
            if(0 < nextWindowIndex && nextWindowIndex < self.windowControllers.count) {
                self.windowControllers[nextWindowIndex].window?.makeKey()
                self.windowControllers[nextWindowIndex].window?.orderFront(self)
                NSApp.activate(ignoringOtherApps: true)
                print(nextWindowIndex)
                print("next")
            }
            
            print(nextWindowIndex)
            
            break
        case Notification.Name("CloseWindowFromTouchBar"):
            let nextWindowIndex = self.windowControllers.index(after: windowIndex!)
            if(0 < nextWindowIndex && nextWindowIndex < self.windowControllers.count) {
                self.windowControllers[nextWindowIndex].window?.makeKey()
                self.windowControllers[nextWindowIndex].window?.orderFront(self)
                NSApp.activate(ignoringOtherApps: true)
                print(nextWindowIndex)
                print("next")
            }
            windowController.close()

            break
        default:
            print("invalid")
        }
        
    }
    
    @IBAction func playGIF(_ sender: Any) {
        for windowController in self.windowControllers {
            if(windowController.window?.isKeyWindow)! {
                let viewController:ViewController = windowController.contentViewController as! ViewController
                if(viewController.imageView.animates) {
                    viewController.imageView.animates = false
                }
                
                viewController.imageView.animates = true
                
                windowController.window?.makeKey()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @IBAction func stopGIF(_ sender: Any) {
        for windowController in self.windowControllers {
            if(windowController.window?.isKeyWindow)! {
                let viewController:ViewController = windowController.contentViewController as! ViewController
                viewController.imageView.animates = false
                
                windowController.window?.makeKey()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @IBAction func installScreensaver(_ sender: Any) {
        let screensaverPath = Bundle.main.url(forResource: "AnimatedGif", withExtension: "saver")
        NSWorkspace.shared().open(screensaverPath!)
    }
//    imageView.downloadImageFromURL("https://www.google.com/images/logo.gif")
    
    var timer:Timer!
    
    func displayWindow(filename: String) -> NSWindowController {
        let windowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "MainWindowController") as! NSWindowController
        
        windowController.shouldCascadeWindows = true
        windowMenu.isHidden = false
        
        let viewController:ViewController = windowController.contentViewController as! ViewController
        
        viewController.filename = filename as NSString
        
        let imageSize:CGSize!
        
        if (filename.contains("http")) {
            viewController.imageView.frame = NSRect(x:0, y:0, width: 300, height: 300)
            viewController.imageView.downloadImageFromURL(filename, errorImage: NSImage(named: "errorstop.png"), usesSpinningWheel: true)
            imageSize = CGSize(width: 300, height: 300)
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { (timer) in
                if (!viewController.imageView.isLoadingImage) {
                    let imageSize = (viewController.imageView.image?.size)!
                    viewController.imageView.frame = NSRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
//                    let NSRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
                    let windowSize = windowController.window?.frame.origin
                    let newWindowSize = NSRect(x: (windowSize?.x)!, y: (windowSize?.y)!, width: imageSize.width, height: imageSize.height)
                    windowController.window?.setFrame(newWindowSize, display: true, animate: true)
                    
                    self.timer.invalidate()
                    self.timer = nil
                }
            })
            
            self.timer.fire()
        } else {
            viewController.image = NSImage(byReferencingFile: filename)!
            //viewController.imageView.loadGIF(gifFileName: URL(fileURLWithPath: filename))
            viewController.imageView.animates = true
            viewController.imageView.image = viewController.image
            imageSize = (viewController.imageView.image?.size)!
        }

        let menuItem:NSMenuItem = self.dockMenu.addItem(withTitle: filename, action: #selector(viewController.showWindow), keyEquivalent: "P")
        menuItem.target = viewController
        
        let notification = Notification(name: Notification.Name(rawValue: "GIFOpened"),
                                        object: filename as AnyObject, userInfo: nil)
        
        NotificationCenter.default.post(notification)
        
        self.windowControllers.append(windowController as! WindowController)
        
        let window:FOTWindow = windowController.window as! FOTWindow
        window.delegate = self
        
        window.menuItem = menuItem
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(NSWindowStyleMask.fullSizeContentView)
        
        var windowRect:NSRect = window.frame
        windowRect.size = imageSize
        
        window.setFrame(windowRect, display: true, animate: true)
        
        let topLeftPoint:NSPoint = (self.windowControllers.last?.window?.frame.origin)!
        
        window.cascadeTopLeft(from: NSPoint(x: topLeftPoint.x + 30, y: topLeftPoint.y + 30))
        window.makeKeyAndOrderFront(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowClosed),
                                               name: NSNotification.Name.NSWindowWillClose, object: window)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowBecameKey),
                                               name: NSNotification.Name.NSWindowDidBecomeKey, object: window)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResignKey),
                                               name: NSNotification.Name.NSWindowDidResignKey, object: window)
        
        window.menuItem.state = NSOnState
    
        return windowController
    }
    
    @IBAction func cloneGIFWindow(_ sender: Any) {
        for windowController in self.windowControllers {
            if(windowController.window?.isKeyWindow)! {
                let viewController:ViewController = windowController.contentViewController as! ViewController
                let newWindowController = self.displayWindow(filename: viewController.filename as String)
                newWindowController.window?.makeKey()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func newGIFRecorded(sender: Notification) {
        let path:String = sender.object as! String
        let windowController:WindowController = self.displayWindow(filename: path) as! WindowController
        windowController.unsavedGIF = true
        gifPaths.append(path)
        
        self.createGIFWindowController.close()
        self.createGIFWindowController = nil
        self.createGIFWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "CreateGIFWindowController") as! NSWindowController
    }
    
    
    @IBAction func saveGIF(_ sender: Any) {
        var viewController:ViewController? = nil
        var mainWindowController:WindowController? = nil
        var filepath = ""
        
        for windowController in self.windowControllers {
            if(windowController.window?.isKeyWindow)! {
                mainWindowController = windowController
                viewController = windowController.contentViewController as? ViewController
                filepath = viewController?.filename! as! String
            }
        }

        let panel:NSSavePanel = NSSavePanel()
        
        panel.setFrameUsingName("Save GIF")
        panel.message = "Save the recorded GIF"
        panel.allowsOtherFileTypes = false
        panel.canCreateDirectories = false
        panel.allowedFileTypes = ["gif"]
        panel.beginSheetModal(for: (mainWindowController?.window!)!) { (result) in
            let path = panel.url?.path
            if (result == NSFileHandlingPanelOKButton) {
                let size = mainWindowController?.window?.frame.size
//                let data = try? NSData(contentsOfFile: filepath) as Data
//                GIFResizer.resizeGIF(data!, fileURL: panel.url!, maxEdgeSize: Double((size?.width)!))
                
                let gifsicle = Gifsicle()
                gifsicle.runGifsicle(inputImage: filepath, resizeTo: size,
                                     optimize: 0,
                                     framesToDrop: nil,
                                     limitColors: 0,
                                     delay: nil,
                                     trimmedFrames: nil,
                                     outputPath: (panel.url?.path)!)

                mainWindowController?.close()
//                try? FileManager.default.copyItem(atPath: filepath, toPath: path!)
            }
        }
        
    }
    
    @IBAction func closeWindow(_ sender: Any) {
        for windowController in self.windowControllers {
            if(windowController.window?.isKeyWindow)! {
                windowController.window?.close()
            }
        }
    }
    
    func windowBecameKey(sender: Notification) {
        let window:FOTWindow = sender.object as! FOTWindow
        if(self.dockMenu.index(of: window.menuItem) >= 0) {
            window.menuItem.state = NSOnState
            
            for windowController in self.windowControllers {
                if(windowController.window == window && windowController.unsavedGIF) {
                    break
                }
            }
        }
    }
    
    func windowDidResignKey(sender: Notification) {
        let window:FOTWindow = sender.object as! FOTWindow
        if(self.dockMenu.index(of: window.menuItem) >= 0) {
            window.menuItem.state = NSOffState
        }
    }
    
    private func openFiles() -> [URL] {
        let fileTypes:[String] = ["gif"]
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = fileTypes

        let result: Int = panel.runModal()
        if result == NSModalResponseOK {
            return panel.urls
        }
        
        return []
    }
    
    private func openMovieFiles() -> [URL] {
        let fileTypes:[String] = ["mp4"]
        
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = fileTypes
        
        let result: Int = panel.runModal()
        if result == NSModalResponseOK {
            return panel.urls
        }
        
        return []
    }
    
    @IBAction func openCreateGIFWindow(_ sender: Any) {
        self.createGIFWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "CreateGIFWindowController") as! NSWindowController
        
        self.createGIFWindowController.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func showAllGIFs(_ sender: Any) {
        for windowController in self.windowControllers {
            windowController.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @IBAction func openGIFs(_ sender: Any) {
        let paths: [URL] = openFiles()
        if !paths.isEmpty {
            for (_, path) in paths.enumerated() {
                let _ = self.displayWindow(filename: path.path)
            }
        }
    }
    
    @IBAction func openMovieFilesFromFileSystem(_ sender: Any) {
        
        let viewController:GIFConverterViewController = GIFConverterViewController()
        let paths: [URL] = self.openMovieFiles()
        if !paths.isEmpty {
            for (_, path) in paths.enumerated() {
                viewController.convertFile(path.path)
            }
        }
    }
    
    @IBAction func cloneCurrentGIFWindow(_ sender: Any) {
        let viewController:ViewController = (self.windowControllers.last?.contentViewController as? ViewController)!
        let _ = self.displayWindow(filename: viewController.filename as String)
    }
    
    @IBAction func quit(_ sender: Any) {
        NSLog("Exit")
        NSApplication.shared().terminate(nil)
    }
    
    func windowClosed(sender: Notification) {
        let window:FOTWindow = sender.object as! FOTWindow
    
        if(self.dockMenu.index(of: window.menuItem) >= 0) {
            self.dockMenu.removeItem(window.menuItem)
            
            let windowIndex = self.windowControllers.index(of: window.windowController! as! WindowController)
            self.windowControllers.remove(at: windowIndex!)
        }
        
        if(self.windowControllers.count > 0) {
            self.windowControllers.last?.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        } else {
            self.loadNewGifWindowController.window?.makeKeyAndOrderFront(loadNewGifWindowController.window)
            windowMenu.isHidden = true
        }
    }
    
    var textField:Editing!
    
    func createOpenWindow() {
        if openWindow == nil {
            openWindow = NSWindow(contentRect: NSMakeRect(0, 0, NSScreen.main()!.frame.midX, NSScreen.main()!.frame.midY + 150), styleMask: [.closable, .titled], backing: .buffered, defer: false)
            
            openWindow.title = "Open from website"
            openWindow.isOpaque = false
            openWindow.center()
            openWindow.isMovableByWindowBackground = true

            let mainView = NSView(frame: NSMakeRect(0, 0, NSScreen.main()!.frame.midX, NSScreen.main()!.frame.midY + 150))
            mainView.translatesAutoresizingMaskIntoConstraints = false
            self.textField = Editing(labelWithString: "https://media4.giphy.com/media/3o7TKDa4TeqnpmXc6Q/giphy.gif")
            self.textField.translatesAutoresizingMaskIntoConstraints = false
            self.textField.isEditable = true
            self.textField.isEnabled = true
            self.textField.drawsBackground = true
            self.textField.isSelectable = true
            self.textField.delegate = self
            
            let gestureRecognizer:NSClickGestureRecognizer = NSClickGestureRecognizer(target: self, action: #selector(clicked))
            self.textField.addGestureRecognizer(gestureRecognizer)
            
            let button:NSButton = NSButton(title: "Open GIF!", target: self, action: #selector(openGIFFromURL))
            button.translatesAutoresizingMaskIntoConstraints = false
            
            mainView.addSubview(button)
            mainView.addSubview(textField)
            
            mainView.widthAnchor.constraint(equalToConstant: 450).isActive = true
            mainView.heightAnchor.constraint(equalToConstant: 100).isActive = true
            
            textField.leftAnchor.constraint(equalTo: mainView.leftAnchor, constant: 50).isActive = true
            textField.rightAnchor.constraint(equalTo: mainView.rightAnchor, constant: -50).isActive = true
            textField.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 30).isActive = true
            
            button.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 10).isActive = true
            button.centerXAnchor.constraint(equalTo: mainView.centerXAnchor).isActive = true

            openWindow.contentView = mainView
            
            openGIFWindowController.window = openWindow
        }
    }
    
    func openGIFFromURL() {
        if (self.textField != nil) && self.textField.stringValue != "" {
            self.openGIFWindowController.close()
            let _ = self.displayWindow(filename: self.textField.stringValue)
        }
    }
    
    func createNewWindow() {
        if newWindow == nil {
            newWindow = NSWindow(contentRect: NSMakeRect(0, 0, NSScreen.main()!.frame.midX, NSScreen.main()!.frame.midY + 150), styleMask: [.closable, .titled], backing: .buffered, defer: false)
            
            newWindow.title = "Feedback"
            newWindow.isOpaque = false
            newWindow.center()
            newWindow.isMovableByWindowBackground = true
            newWindow.backgroundColor = NSColor(calibratedHue: 0, saturation: 1.0, brightness: 0, alpha: 0.7)
            
            
            let webView = WebView(frame: NSMakeRect(0, 0, NSScreen.main()!.frame.midX, NSScreen.main()!.frame.midY))
            webView.mainFrameURL = Bundle.main.url(forResource: "index", withExtension: "html")?.absoluteString
            
            newWindow.contentView = webView
            
            feedbackWindowController.window = newWindow
        }
    }
    
    @IBAction func openGIFDialog(_ sender: Any) {
        self.createOpenWindow()
        openWindow.makeKeyAndOrderFront(openWindow)
    }
    
    @IBAction func submitFeedback(_ sender: Any) {
        self.createNewWindow()
        newWindow.makeKeyAndOrderFront(newWindow)
    }
    
    // MARK: Menu items
    @IBAction func menuItemLoad(sender: AnyObject?) {
        NotificationCenter.default.post(name: GIFMakerViewController.menuItemImportNotificationName, object: self.viewController.filename)
        self.editWindowController.window?.makeKeyAndOrderFront(self.editWindowController.window)
    }
    
    @IBAction func menuItemExport(sender: AnyObject?) {
        NotificationCenter.default.post(name: GIFMakerViewController.menuItemExportNotificationName, object: nil)
    }
    
    @IBAction func menuItemAddFrame(sender: AnyObject?) {
        NotificationCenter.default.post(name: GIFMakerViewController.menuItemAddFrameNotificationName, object: nil)
    }
    
    @IBAction func menuItemReset(sender: AnyObject?) {
        NotificationCenter.default.post(name: GIFMakerViewController.menuItemResetNotificationName, object: nil)
    }
    
    @IBAction func menuItemPreview(sender: AnyObject?) {
        NotificationCenter.default.post(name: GIFMakerViewController.menuItemPreviewNotificationName, object: nil)
    }
    
    @IBAction func menuItemEdit(sender: AnyObject?) {
        NotificationCenter.default.post(name: GIFMakerViewController.menuItemEditNotificationName, object: nil)
    }
}

extension AppDelegate : PasteboardWatcherDelegate {
    func newlyCopiedUrlObtained(copiedUrl: NSURL) {
        self.displayWindow(filename: copiedUrl.absoluteString!)
    }
}

extension AppDelegate : NSWindowDelegate {
    func windowShouldClose(_ sender: Any) -> Bool {
//        let currentWindow = sender as! FOTWindow
//        var viewController:ViewController? = nil
//        var mainWindowController:WindowController? = nil
//
//        var filepath = ""
//
//        if (!(currentWindow.windowController as! WindowController).unsavedGIF) {
//            return true
//        }
//
//        for windowController in self.windowControllers {
//            if(windowController.window?.isKeyWindow)! {
//                mainWindowController = windowController
//                viewController = windowController.contentViewController as? ViewController
//                filepath = viewController?.filename! as! String
//            }
//        }
//
//        let panel:NSSavePanel = NSSavePanel()
//
//        panel.setFrameUsingName("Save GIF")
//        panel.message = "Save the recorded GIF"
//        panel.allowsOtherFileTypes = false
//        panel.canCreateDirectories = false
//        panel.allowedFileTypes = ["gif"]
//        panel.beginSheetModal(for: (mainWindowController?.window!)!) { (result) in
//            let path = panel.url?.path
//            if (result == NSFileHandlingPanelOKButton) {
//                try? FileManager.default.copyItem(atPath: filepath, toPath: path!)
//                mainWindowController?.close()
//            }
//        }
        
        return true
    }
    
    func clicked(gestureRecognizer: NSClickGestureRecognizer) {
        self.textField.selectText(nil)
    }
}

extension AppDelegate : NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSText.paste(_:)) {
            textView.string = "yo"
        }
        
        return true
    }
}


fileprivate enum ArrowTag: Int {
    case up = 20
    case left = 21
    case right = 22
    case down = 23
}

// MARK: - Hotkeys

extension AppDelegate {
    
    @IBAction func actualSize(_ sender: AnyObject?) {
        let image = viewController.imageView.image!
        window.resize(to: image.size, animated: true)
    }
    
    @IBAction func makeLarger(_ sender: AnyObject) {
        var size = window.frame.size
        size = size * 1.1
        window.resize(to: size, animated: true)
    }
    
    @IBAction func makeSmaller(_ sender: AnyObject) {
        var size = window.frame.size
        size = size * 0.9
        window.resize(to: size, animated: true)
    }
    
    @IBAction func makeLargerOnePixel(_ sender: AnyObject) {
        var size = window.frame.size
        size.width += 1
        size.height += 1
        window.resize(to: size, animated: true)
    }
    
    @IBAction func makeSmallerOnePixel(_ sender: AnyObject) {
        var size = window.frame.size
        size.width -= 1
        size.height -= 1
        window.resize(to: size, animated: true)
    }
    
    @IBAction func increaseTransparency(_ sender: AnyObject) {
        var alpha = window.alphaValue
        alpha -= 0.1
        window.alphaValue = max(alpha, 0.05)
        window.fullContentView.previousAlphaValue = window.alphaValue
    }
    
    @IBAction func reduceTransparency(_ sender: AnyObject) {
        var alpha = window.alphaValue
        alpha += 0.1
        window.alphaValue = min(alpha, 1.0)
        window.fullContentView.previousAlphaValue = window.alphaValue
    }
    
    @IBAction func toggleLockWindow(_ sender: AnyObject) {
        let menuItem = sender as! NSMenuItem
        if menuItem.title == "Lock" {
            menuItem.title  = "Unlock"
            window.isMovable = false
            window.ignoresMouseEvents = true
            window.level = Int(CGWindowLevelForKey(.maximumWindow))
        } else {
            menuItem.title  = "Lock"
            window.isMovable = true
            window.ignoresMouseEvents = false
            window.level = Int(CGWindowLevelForKey(.normalWindow))
        }
        
//        viewController.lockIconImageView.isHidden = window.isMovable || isLockIconHiddenWhileLocked
    }
    
    @IBAction func toggleLockIconVisibility(_ sender: AnyObject) {
        let menuItem = sender as! NSMenuItem
        menuItem.state = menuItem.state == NSOnState ? NSOffState : NSOnState
//        isLockIconHiddenWhileLocked = menuItem.state == NSOnState
    }
    
    @IBAction func moveAround(_ sender: AnyObject) {
        let menuItem = sender as! NSMenuItem
        
        guard let arrow = ArrowTag(rawValue: menuItem.tag) else {
            return
        }
        
        if (window == nil) {
            return
        }
        
        switch arrow {
        case .up:
            window.move(by: CGPoint(x: 0, y: 1))
        case .left:
            window.move(by: CGPoint(x: -1, y: 0))
        case .right:
            window.move(by: CGPoint(x: 1, y: 0))
        case .down:
            window.move(by: CGPoint(x: 0, y: -1))
        }
    }
}

extension AppDelegate : MCDragAndDropImageViewDelegate {
    func dragAndDropImageViewDidDrop(pasteboard:NSPasteboard) {
        let url:URL = NSURL(from: pasteboard)! as URL
        self.displayWindow(filename: url.path)
    }
}

// MARK: - Helper

func appDelegate() -> AppDelegate {
    return NSApp.delegate as! AppDelegate
}

func *(size: NSSize, scale: CGFloat) -> NSSize {
    return NSMakeSize(size.width * scale, size.height * scale)
}
