//
//  ViewController.swift
//  GIF
//
//  Created by zhangxi on 7/1/16.
//  Copyright © 2016 zhangxi.me. All rights reserved.
//

import Cocoa
import Foundation


class GIFConverterViewController: GIFViewController,DragDropViewDelegate,RangeSliderDelegate,NSTextFieldDelegate {
    
    @IBOutlet weak var preview: Priview!
    @IBOutlet weak var bg: NSImageView!
    @IBOutlet weak var dragView: DragDropView!
    
  
    
    @IBOutlet weak var rangeSlider: RangeSlider!
    @IBOutlet weak var slider: NSSlider!
    
    
    @IBOutlet weak var quality: NSPopUpButton!
    @IBOutlet weak var fps: NSPopUpButton!
    
    let c:ZXConverter = ZXConverter()
    
    @IBOutlet weak var indicator: NSProgressIndicator!
    
    
    @IBOutlet weak var widthLabel: NSTextField!
    @IBOutlet var heightLabel: NSTextField!
    
    
    
    override func controlTextDidChange(_ obj: Notification) {
        
        if gif == nil
        {
            return
        }
        
        if let textField = obj.object as? NSTextField
        {
            let value = CGFloat(textField.floatValue)
            print(value)
            
            
            if lock
            {
                if textField == widthLabel
                {
                    heightLabel.integerValue = Int(value * gif!.size.height / gif!.size.width)
                }else
                {
                    widthLabel.integerValue  = Int(value * gif!.size.width / gif!.size.height)
                }
            }
            
            gif?.wantSize = CGSize(width: CGFloat(widthLabel.floatValue), height: CGFloat(heightLabel.floatValue))
            
    
            
        }
    }
    

    
    var lock:Bool = true{
        didSet{
            self.lockButton.image = NSImage(named: (lock == true) ? "lock" : "unlock")
        }
    }
    
    
    @IBOutlet weak var lockButton: NSButton!
    
    @IBAction func clickLock(_ sender: NSButton) {
        self.lock = !self.lock
    }

    
    var gif : GIF?
    
    func loadFile(_ file: String)
    {
        
        let c = ZXConverter()
        
        self.startLoading()
        
        c.loadGIF(file) { (gif,error) in
            
            print(gif)
            
            let info = gif.valid()
            if info.valid
            {
                self.gif = gif
                self.startLoading()
                self.showPreview(gif)
                self.configOptions(gif)
            }else
            {
                self.showError(info.error)
            }
        }
        
    }
    
    func convertFile(_ file: String)
    {
        let theGIF  = GIF()
        
        theGIF.path = file
        theGIF.fps = 12
        theGIF.quality = Quality.normal
        

        bg.image = NSImage(named: "loading")
        indicator.isHidden = false
        indicator.startAnimation(nil)
        
        c.convert(theGIF, complete: { (success,path) in
            
            if success
            {
                self.save(path!)
            }else
            {
                self.showErrorFile()
            }
            self.stopLoading()
        })

    }
    
    func receivedFiles(_ file: String)
    {
        convertFile(file)
    }
    
    func configOptions(_ gif:GIF)
    {
        self.widthLabel.stringValue = String(format:"%0.f",gif.size.width)
        self.heightLabel.stringValue = String(format:"%0.f",gif.size.height)
    }
    
    func showPreview(_ gif:GIF)
    {
        self.preview.isHidden = false
        self.preview.images = gif.thumb
        

        self.rangeSlider.durationTime = gif.duration
        self.rangeSlider.frames = gif.thumb.count - 1
        self.rangeSlider.reset()
        
    }
    
    func startLoading()
    {
        bg.image = NSImage(named: "loading")
        indicator.isHidden = false
        indicator.startAnimation(nil)
    }
    func stopLoading()
    {
        self.bg.image = NSImage(named: "bg")
        self.indicator.isHidden = true
        self.indicator.stopAnimation(nil)
    }

    

//    func showError(msg:String)
//    {
//        let alert = NSAlert()
//        alert.messageText = msg
//        alert.addButtonWithTitle("OK")
//        alert.beginSheetModalForWindow(self.view.window!, completionHandler: nil )
//    }
//    func showErrorFile()
//    {
//        let alert = NSAlert()
//        alert.messageText = "Error,only mov file can be accepted."
//        alert.addButtonWithTitle("OK")
//        alert.beginSheetModalForWindow(self.view.window!, completionHandler: nil )
//    }
//    func receivedErrorType(file:String)
//    {
//        let alert = NSAlert()
//        alert.messageText = "Error,only video file can be accepted."
//        alert.addButtonWithTitle("OK")
//        
//        alert.beginSheetModalForWindow(self.view.window!, completionHandler: nil )
//    }
    
    func save(_ file:String)
    {
        Swift.print(file)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = (file as NSString).lastPathComponent
        panel.begin { (result) in
            
            if result == NSFileHandlingPanelOKButton
            {
                let fm  = FileManager.default
                if let url = panel.url
                {
                    if let path:String = url.path {
                        do {
                        try fm.copyItem(atPath: file, toPath: path)
                        }catch{}
                    }
                }
                
            }
        }
    }

    func didSelectRange(_ start: Int, end: Int) {
        print("\(start)  ...   \(end)")
    }
    func didSelectFrame(_ index: Int) {
        self.preview.frameIndex = index
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dragView.delegate = self
        self.indicator.isHidden = true
        self.rangeSlider.delegate = self
        self.preview.isHidden = true
        
        self.fps.selectItem(withTag: 12)
        self.quality.selectItem(withTag: 1)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            
        }
    }
    
    
}

