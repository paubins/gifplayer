//
//  AppDelegate.swift
//  GifPlayer
//
//  Created by Patrick Aubin on 6/10/17.
//  Copyright © 2017 com.paubins.GifPlayer. All rights reserved.
//

import Cocoa
import WebKit
import KeyboardShortcuts

let thumbPath  = NSHomeDirectory() + "/Documents/thumb"
let folderPath  = NSHomeDirectory() + "/Documents"

extension KeyboardShortcuts.Name {
    static let rewind = Self("rewind", default: .init(.r, modifiers: [.command, .option]))
    static let fastForward = Self("fastForward", default: .init(.f, modifiers: [.command, .option]))
    static let slowDown = Self("slowDown", default: .init(.p, modifiers: [.command, .option]))
    static let speedUp = Self("speedUp", default: .init(.u, modifiers: [.command, .option]))
    static let larger = Self("larger", default: .init(.equal, modifiers: [.command, .option]))
    static let smaller = Self("smaller", default: .init(.minus, modifiers: [.command, .option]))
    static let larger1px = Self("larger1px", default: .init(.rightBracket, modifiers: [.command, .option]))
    static let smaller1px = Self("smaller1px", default: .init(.leftBracket, modifiers: [.command, .option]))
    static let increaseAlpha = Self("increaseAlpha", default: .init(.m, modifiers: [.command, .option]))
    static let decreaseAlpha = Self("decreaseAlpha", default: .init(.n, modifiers: [.command, .option]))
    static let moveUp = Self("moveUp", default: .init(.upArrow, modifiers: [.command, .option]))
    static let moveDown = Self("moveDown", default: .init(.downArrow, modifiers: [.command, .option]))
    static let moveRight = Self("moveRight", default: .init(.rightArrow, modifiers: [.command, .option]))
    static let moveLeft = Self("moveLeft", default: .init(.leftArrow, modifiers: [.command, .option]))
    static let actualSize = Self("actualSize", default: .init(.a, modifiers: [.command, .option]))
    static let clone = Self("clone", default: .init(.d, modifiers: [.command, .option]))
}

extension KeyboardShortcuts.Name: CaseIterable {
    public static let allCases: [Self] = [
        .rewind,
        .fastForward,
        .slowDown,
        .speedUp,
        .larger,
        .smaller,
        .larger1px,
        .smaller1px,
        .increaseAlpha,
        .decreaseAlpha,
        .moveUp,
        .moveDown,
        .moveRight,
        .moveLeft,
        .actualSize,
        .clone
    ]
}

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
    
    lazy var settingsWindowController:NSWindowController = {
        let windowController = NSStoryboard(name: "Main", bundle: nil)
            .instantiateController(withIdentifier: "KeyboardShortcutWindowController") as! NSWindowController
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

        KeyboardShortcuts.onKeyDown(for: .larger) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.moveWindow(widthOffset: 1.1)
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .smaller) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.moveWindow(widthOffset: 0.9)
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .larger1px) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.moveWindow(widthOffsetExact: 1.0, heightOffsetExact: 1.0)
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .smaller1px) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.moveWindow(widthOffsetExact: -1.0, heightOffsetExact: -1.0)
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .increaseAlpha) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.increaseAlpha()
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .decreaseAlpha) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.decreaseAlpha()
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .moveUp) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.moveWindow(yOffset: 10)
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .moveDown) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.moveWindow(yOffset: -10)
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .moveRight) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.moveWindow(xOffset: 10)
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .moveLeft) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.moveWindow(xOffset: -10)
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .actualSize) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.resetWindow()
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .clone) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.clone()
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .slowDown) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.slowDown()
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .speedUp) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.speedUp()
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .rewind) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.rewind()
            }
        }
        
        KeyboardShortcuts.onKeyDown(for: .fastForward) {
            if let window = NSApplication.shared.keyWindow as? GIFWindow {
                window.forward()
            }
        }
    }
    
    @IBAction func openSettings(_ sender: Any) {
        if let window = self.settingsWindowController.window {
            window.orderFrontRegardless()
        }
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

final class PreferencesViewController: NSViewController {
    
    @IBOutlet weak var mainStackView: NSStackView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if self.mainStackView.arrangedSubviews.count == KeyboardShortcuts.Name.allCases.count {
            return
        }
        
        KeyboardShortcuts.Name.allCases.map { element in
            print(element)
            KeyboardShortcuts.enable(element)
            let label = NSTextField(string: "Keyboard shortcut")
            
            switch element {
            case .slowDown:
                label.stringValue = "Slow Down"
            case .speedUp:
                label.stringValue = "Speed Up"
            case .rewind:
                label.stringValue = "Rewind"
            case .larger:
                label.stringValue = "Make Window Larger"
            case .larger1px:
                label.stringValue = "Make Window Larger by 1px"
            case .smaller:
                label.stringValue = "Make Window Smaller"
            case .smaller1px:
                label.stringValue = "Make Window Smaller by 1px"
            case .actualSize:
                label.stringValue = "Make Window Actual Size"
            case .moveLeft:
                label.stringValue = "Move Window Left"
            case .moveUp:
                label.stringValue = "Move Window Up"
            case .moveDown:
                label.stringValue = "Move Window Down"
            case .moveRight:
                label.stringValue = "Move Window Right"
            case .decreaseAlpha:
                label.stringValue = "Decrease Alpha"
            case .increaseAlpha:
                label.stringValue = "Increase Alpha"
            case .clone:
                label.stringValue = "Clone Window"
            case .fastForward:
                label.stringValue = "Fast Forward"
            default:
                break
            }
            
            label.isBezeled = false
            label.isEditable = false
            label.backgroundColor = .clear
            label.sizeToFit()
            label.widthAnchor.constraint(equalToConstant: 300).isActive = true
            label.translatesAutoresizingMaskIntoConstraints = false
            
            let stackView:NSStackView = NSStackView(views: [
                label,
                KeyboardShortcuts.RecorderCocoa(for: element)
            ])
            print(element.defaultShortcut)
            stackView.orientation = .horizontal
            self.mainStackView.addArrangedSubview(stackView)
        }
        
    }
}
