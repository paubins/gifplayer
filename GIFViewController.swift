//
//  ViewController.swift
//  GIF
//
//  Created by zhangxi on 7/1/16.
//  Copyright © 2016 zhangxi.me. All rights reserved.
//

import Cocoa
import Foundation


class GIFViewController: NSViewController {
    
    
    func showError(_ msg:String)
    {
        let alert = NSAlert()
        alert.messageText = msg
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil )
    }
    func showErrorFile()
    {
        let alert = NSAlert()
        alert.messageText = "Error,only mov file can be accepted."
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil )
    }
    func receivedErrorType(_ file:String)
    {
        let alert = NSAlert()
        alert.messageText = "Error,only video file can be accepted."
        alert.addButton(withTitle: "OK")
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil )
    }
}

