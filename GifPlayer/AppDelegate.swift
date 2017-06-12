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
    
    func removeWindow() {
        
    }
    
    func windowClosed(sender: Notification) {
        let window:FOTWindow = sender.object as! FOTWindow
        
        if(self.dockMenu.index(of: window.menuItem) >= 0) {
            self.dockMenu.removeItem(window.menuItem)
        }
    }
    
    func displayWindow(filename: String) {
        let windowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "MainWindowController") as! NSWindowController
        
        let viewController:ViewController = windowController.contentViewController as! ViewController
        
        viewController.image = NSImage(byReferencingFile: filename)!
        viewController.imageView.image = viewController.image
        
        let menuItem:NSMenuItem = self.dockMenu.addItem(withTitle: filename, action: #selector(viewController.showWindow), keyEquivalent: "P")
        menuItem.target = viewController
        
        self.windowControllers.append(windowController)
        
        NotificationCenter.default.addObserver(self, selector: #selector(windowClosed),
                                               name: NSNotification.Name.NSWindowWillClose, object: nil)
        
        let notification = Notification(name: Notification.Name(rawValue: "GIFOpened"),
                                        object: filename as AnyObject, userInfo: nil)
        
        NotificationCenter.default.post(notification)
        
        let window:FOTWindow = windowController.window as! FOTWindow
        
        window.menuItem = menuItem
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(NSWindowStyleMask.fullSizeContentView)
        
        window.makeKeyAndOrderFront(self)
    }
}

