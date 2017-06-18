//
//  AppDelegate.swift
//  GifPlayer
//
//  Created by Patrick Aubin on 6/10/17.
//  Copyright © 2017 com.paubins.GifPlayer. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var fileToOpen:String = ""
    var windowControllers:[NSWindowController] = []
    let dockMenu = NSMenu()
    
    @IBOutlet weak var createGifMenuItem: NSMenuItem!
    @IBOutlet weak var recordMenuItem: NSMenuItem!
    @IBOutlet weak var stopMenuItem: NSMenuItem!
    
    let createGIFWindowController:NSWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "CreateGIFWindowController") as! NSWindowController
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if(self.fileToOpen != "") {
            self.displayWindow(filename: self.fileToOpen)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(newGIFRecorded),
                                               name: Notification.Name(rawValue: "newGIFRecorded"), object: nil)
        
        self.createGifMenuItem.isEnabled = true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
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
            self.displayWindow(filename: filename)
        }
        
        return true
    }
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        return self.dockMenu
    }
    
    func displayWindow(filename: String) {
        let windowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "MainWindowController") as! NSWindowController
        
        let viewController:ViewController = windowController.contentViewController as! ViewController
        
        viewController.filename = filename as NSString
        
        viewController.image = NSImage(byReferencingFile: filename)!
//        viewController.imageView.loadGIF(gifFileName: filename)
        viewController.imageView.image = viewController.image
        
        let menuItem:NSMenuItem = self.dockMenu.addItem(withTitle: filename, action: #selector(viewController.showWindow), keyEquivalent: "P")
        menuItem.target = viewController
        
        self.windowControllers.append(windowController)
        
        let notification = Notification(name: Notification.Name(rawValue: "GIFOpened"),
                                        object: filename as AnyObject, userInfo: nil)
        
        NotificationCenter.default.post(notification)
        
        let window:FOTWindow = windowController.window as! FOTWindow
        
        window.menuItem = menuItem
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(NSWindowStyleMask.fullSizeContentView)
        
        var windowRect:NSRect = window.frame
        windowRect.size = viewController.image.size
        
        window.setFrame(windowRect, display: true, animate: true)
        
        window.makeKeyAndOrderFront(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowClosed),
                                               name: NSNotification.Name.NSWindowWillClose, object: window)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowBecameKey),
                                               name: NSNotification.Name.NSWindowDidBecomeKey, object: window)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResignKey),
                                               name: NSNotification.Name.NSWindowDidResignKey, object: window)
        
        window.menuItem.state = NSOnState
        
    }
    
    func newGIFRecorded(sender: Notification) {
        let path:String = sender.object as! String
        self.displayWindow(filename: path)
    }
    
    func windowBecameKey(sender: Notification) {
        let window:FOTWindow = sender.object as! FOTWindow
        if(self.dockMenu.index(of: window.menuItem) >= 0) {
            window.menuItem.state = NSOnState
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

        createGIFWindowController.window?.makeKeyAndOrderFront(self)
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
                self.displayWindow(filename: path.path)
            }
        }
    }
    
    @IBAction func cloneCurrentGIFWindow(_ sender: Any) {
        let viewController:ViewController = (self.windowControllers.last?.contentViewController as? ViewController)!
        self.displayWindow(filename: viewController.filename as String)
    }
    
    @IBAction func quit(_ sender: Any) {
        NSLog("Exit")
        NSApplication.shared().terminate(nil)
    }
    
    func windowClosed(sender: Notification) {
        let window:FOTWindow = sender.object as! FOTWindow
        
        if(self.dockMenu.index(of: window.menuItem) >= 0) {
            self.dockMenu.removeItem(window.menuItem)
            
            let windowIndex = self.windowControllers.index(of: window.windowController!)
            self.windowControllers.remove(at: windowIndex!)
        }
        
        if(self.windowControllers.count > 0) {
            self.windowControllers.last?.window?.makeKey()
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

