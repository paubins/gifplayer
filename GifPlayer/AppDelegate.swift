//
//  AppDelegate.swift
//  GifPlayer
//
//  Created by Patrick Aubin on 6/10/17.
//  Copyright © 2017 com.paubins.GifPlayer. All rights reserved.
//

import Cocoa
import WebKit

let thumbPath  = NSHomeDirectory() + "/Documents/thumb"
let folderPath  = NSHomeDirectory() + "/Documents"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var gifPaths:[String] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let fm   = FileManager.default
        do{
            try fm.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            try fm.createDirectory(atPath: thumbPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            
        }
        
        NSApp.servicesProvider = self

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        for gifPath in self.gifPaths {
            try? FileManager.default.removeItem(atPath: gifPath)
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
//        GIFController.shared.activateWindows()
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {

    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        guard application.isActive else { return }
        GIFController.shared.openFiles(urls: urls)
    }
    
    func application(_ application: NSApplication, openFile filename: String) -> Bool {
        guard application.isActive else { return false }
        GIFController.shared.openFile(file: filename)
        return true
    }
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        return GIFController.shared.dockMenu
    }
 

}
