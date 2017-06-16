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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if(self.fileToOpen != "") {
            self.displayWindow(filename: self.fileToOpen)
        }
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
        
        viewController.image = NSImage(byReferencingFile: filename)!
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
        
        window.makeKeyAndOrderFront(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowClosed),
                                               name: NSNotification.Name.NSWindowWillClose, object: window)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowBecameKey),
                                               name: NSNotification.Name.NSWindowDidBecomeKey, object: window)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResignKey),
                                               name: NSNotification.Name.NSWindowDidResignKey, object: window)
        
        window.menuItem.state = NSOnState
        
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

    
    @IBAction func openGIFs(_ sender: Any) {
        let paths: [URL] = openFiles()
        if !paths.isEmpty {
            for (_, path) in paths.enumerated() {
                print(path.path)
                self.displayWindow(filename: path.path)
            }
        }
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

