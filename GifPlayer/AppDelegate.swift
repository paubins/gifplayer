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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var saveButton: NSMenuItem!
    @IBOutlet weak var stopButtonMenuItem: NSMenuItem!
    @IBOutlet weak var playButtonMenuItem: NSMenuItem!
    
    @IBOutlet weak var windowMenu: NSMenuItem!
    
    @IBOutlet weak var submitFeedback: NSMenuItem!
    var gifPaths:[String] = []
    
    var fileToOpen:String = ""
    var windowControllers:[WindowController] = []
    let dockMenu = NSMenu()
    
    @IBOutlet weak var createGifMenuItem: NSMenuItem!
    @IBOutlet weak var recordMenuItem: NSMenuItem!
    @IBOutlet weak var stopMenuItem: NSMenuItem!
    @IBOutlet weak var cloneGIFMenuItem: NSMenuItem!
    
    var newWindow:NSWindow!
    
    var createGIFWindowController:NSWindowController!
    
    let pasteboardWatcher:PasteboardWatcher = PasteboardWatcher(fileKinds: ["gif"])
    
    var mainTouchBarWindowContoller:WindowController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Fabric.with([Crashlytics.self])
        
        self.pasteboardWatcher.delegate = self
        self.pasteboardWatcher.startPolling()
        
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
    
//    imageView.downloadImageFromURL("https://www.google.com/images/logo.gif")
    
    func displayWindow(filename: String) -> NSWindowController {
        let windowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "MainWindowController") as! NSWindowController
        
        windowController.shouldCascadeWindows = true
        windowMenu.isHidden = false
        
        let viewController:ViewController = windowController.contentViewController as! ViewController
        
        viewController.filename = filename as NSString
        
        if (filename.contains("http")) {
            viewController.imageView.downloadImageFromURL(filename, usesSpinningWheel: true)
        } else {
            viewController.image = NSImage(byReferencingFile: filename)!
            //viewController.imageView.loadGIF(gifFileName: URL(fileURLWithPath: filename))
            viewController.imageView.animates = true
            viewController.imageView.image = viewController.image
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
        windowRect.size = (viewController.imageView.image?.size)!
        
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
                try? FileManager.default.copyItem(atPath: filepath, toPath: path!)
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
            windowMenu.isHidden = true
        }
    }
    
    let feedbackWindowController:NSWindowController = NSWindowController()
    
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
    
    @IBAction func submitFeedback(_ sender: Any) {
        self.createNewWindow()
        newWindow.makeKeyAndOrderFront(newWindow)
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
}
