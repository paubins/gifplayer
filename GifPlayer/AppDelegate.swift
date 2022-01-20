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
    
    lazy var feedbackWindowController:NSWindowController = {
        let windowController = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "FeedbackWindowController") as! NSWindowController
        if let window = windowController.window,
            let contentView = window.contentView as? WKWebView,
            let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            contentView.loadFileURL(url, allowingReadAccessTo: url)
        }
        return windowController
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let fm   = FileManager.default
        do{
            try fm.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            try fm.createDirectory(atPath: thumbPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            
        }
        
        NSApp.servicesProvider = self

    }
    
    @IBAction func submitFeedback(_ sender: Any) {
        if let window = self.feedbackWindowController.window {
            window.orderFrontRegardless()
        }
    }
    
    @IBAction func quit(_ sender: Any) {
        NSApplication.shared.terminate(nil)
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
//        GIFWindowController.shared.openFiles(urls: urls)
    }
    
    func application(_ application: NSApplication, openFile filename: String) -> Bool {
        guard application.isActive else { return false }
//        GIFWindowController.shared.openFile(file: filename)
        return true
    }
}
