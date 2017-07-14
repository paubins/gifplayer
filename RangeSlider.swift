//
//  RangeSlider.swift
//  GIF
//
//  Created by 张玺 on 7/3/16.
//  Copyright © 2016 zhangxi.me. All rights reserved.
//

import Cocoa
import Foundation
protocol RangeSliderDelegate : NSObjectProtocol
{
    func didSelectFrame(_ index:Int)
    func didSelectRange(_ start:Int,end:Int)
}

class RangeSlider: NSView {
    
    weak var delegate : RangeSliderDelegate?
    
    var enabled:Bool = true{
        didSet{
            durationLine.layer?.backgroundColor = enabled ? blue : gray
            leftLabel.textColor = enabled ? NSColor.black : NSColor.gray
            rightLabel.textColor = enabled ? NSColor.black : NSColor.gray
            if enabled == false
            {
                self.reset()
                leftLabel.stringValue = "--:--"
                rightLabel.stringValue = "--:--"
            }
        }
    }
    var track:NSTrackingRectTag?
    var leftLabel : NSTextField!
    var rightLabel : NSTextField!
    
    var frames : Int = 0
    var durationTime : TimeInterval = 0{
        didSet{
            self.endTime = durationTime
            rightLabel.stringValue = self.timeString(endTime)
        }
    }
    var begin : NSImageView!
    var end   : NSImageView!
    
    var startTime: TimeInterval = 0.0
    var endTime : TimeInterval = 0.0
    
    var line:NSView!
    var durationLine:NSView!
    

    let blue = NSColor(red: 45.0/255.0, green: 146.0/255.0, blue: 1, alpha: 1).cgColor
    let gray = NSColor(red: 184.0/255.0, green: 184.0/255.0, blue: 184.0/255.0, alpha: 1).cgColor
    let dotSize = CGSize(width: 14, height: 14)
    let leftSpace:CGFloat  = 20
    let rightSpace:CGFloat = 20
    
    let labelWidth:CGFloat  = 60
    let labelHeight:CGFloat = 20
    var timeWidth:CGFloat!
    
    override func hitTest(_ aPoint: NSPoint) -> NSView? {
        if enabled
        {
            return super.hitTest(aPoint)
        }else
        {
            return nil
        }
    }
    func reset()
    {
        let lineFrame = NSMakeRect(leftSpace,labelHeight+dotSize.height/2-1.5,self.bounds.size.width-leftSpace-rightSpace,3)
        line.frame = lineFrame
        durationLine.frame = lineFrame
        
        
        let beginFrame = NSMakeRect(leftSpace,labelHeight,dotSize.width,dotSize.height)
        let endFrame   = NSMakeRect(self.bounds.size.width-rightSpace-dotSize.width,labelHeight,dotSize.width,dotSize.height)
        begin.frame = beginFrame
        end.frame = endFrame
        
        
        
        leftLabel.frame = NSMakeRect(begin.frame.origin.x + dotSize.width/2 - labelWidth/2, 0, labelWidth, 20)
        leftLabel.stringValue = "00:00"
        rightLabel.frame = NSMakeRect(end.frame.origin.x + dotSize.width/2 - labelWidth/2, 0, labelWidth, 20)
        
        
        self.startTime = 0
        self.endTime = durationTime
        rightLabel.stringValue = self.timeString(endTime)
    }
    
    
    required init?(coder: NSCoder) {
        
        super.init(coder: coder)
        //self.enabled = true
        
        timeWidth = self.bounds.size.width - leftSpace - rightSpace
        
        let lineFrame = NSMakeRect(leftSpace,labelHeight+dotSize.height/2-1.5,self.bounds.size.width-leftSpace-rightSpace,3)
        line = NSView(frame:lineFrame)
        line.wantsLayer = true
        line.layer?.backgroundColor = gray
        self.addSubview(line)
        
        durationLine = NSView(frame:lineFrame)
        durationLine.wantsLayer = true
        durationLine.layer?.backgroundColor = blue
        self.addSubview(durationLine)
        
        
    
        let beginFrame = NSMakeRect(leftSpace,labelHeight,dotSize.width,dotSize.height)
        let endFrame   = NSMakeRect(self.bounds.size.width-rightSpace-dotSize.width,labelHeight,dotSize.width,dotSize.height)
        begin = NSImageView(frame: beginFrame)
        end   = NSImageView(frame: endFrame)
        
        begin.wantsLayer = true
        end.wantsLayer = true
        
        begin.image = NSImage(named:"dot")
        end.image = NSImage(named:"dot")
        
        
        
        leftLabel = label()
        leftLabel.frame = NSMakeRect(begin.frame.origin.x + dotSize.width/2 - labelWidth/2, 0, labelWidth, 20)
        leftLabel.stringValue = "--:--"
        self.addSubview(leftLabel)
        
        rightLabel = label()
        rightLabel.frame = NSMakeRect(end.frame.origin.x + dotSize.width/2 - labelWidth/2, 0, labelWidth, 20)
        rightLabel.stringValue = "--:--"
        self.addSubview(rightLabel)
        
        //self.addSubview(begin)
        //self.addSubview(end)
        
        
        self.addSubview(begin, positioned: .above, relativeTo: nil)
        self.addSubview(end, positioned: .above, relativeTo: nil)
        
    }
    func label()-> NSTextField
    {
        let l = NSTextField(frame: NSMakeRect(0,0,0,0))
        l.alignment = NSTextAlignment.center
        l.font = NSFont.systemFont(ofSize: 12)
        l.drawsBackground = false
        l.isEditable = false
        l.isSelectable = false
        l.isBezeled = false
        return l
    }
    var dragedDot:NSView?
    
    
    override func mouseDown(with theEvent: NSEvent) {

        let p = self.convert(theEvent.locationInWindow, from: nil)
    
        
        if begin.frame.contains(p)
        {
            dragedDot = begin
        }
        
        if end.frame.contains(p)
        {
            dragedDot = end
        }
        
        
        //Swift.print(p)
        
        
    }
    var lastRange:(start:Int,end:Int)?
    var lastFrame:Int?
    
    override func mouseDragged(with theEvent: NSEvent) {
        //Swift.print("mouseDragged")
        //Swift.print(theEvent)
        var p = self.convert(theEvent.locationInWindow, from: nil)
        
        if dragedDot != nil
        {
            if p.x < leftSpace + dragedDot!.frame.size.width/2
            {
                p.x = leftSpace + dragedDot!.frame.size.width/2
            }
            if p.x > self.bounds.size.width - rightSpace - dragedDot!.frame.size.width/2
            {
                p.x = self.bounds.size.width - rightSpace - dragedDot!.frame.size.width/2
            }
            //p.x = max(p.x , leftSpace + dragedDot!.frame.size.width/2)
            //p.x = min(p.x , self.bounds.size.width - rightSpace - dragedDot!.frame.size.width/2)
        
            
            var f = dragedDot!.frame
            f.origin.x = p.x - dragedDot!.frame.size.width/2
            //f.origin.y = self.bounds.size.height/2 - dragedDot!.frame.size.height/2
            dragedDot?.frame = f
            
            let minValue = min(begin.frame.origin.x, end.frame.origin.x)
            let maxValue = max(begin.frame.origin.x, end.frame.origin.x)
            
            var durationFrame = durationLine.frame
            durationFrame.origin.x = minValue
            durationFrame.size.width = maxValue - minValue
            durationLine.frame = durationFrame
            
            
            let minTime = ((minValue - leftSpace) / (self.bounds.size.width - dragedDot!.frame.size.width - leftSpace - rightSpace)) * CGFloat(durationTime)
            let maxTime = ((maxValue - leftSpace) / (self.bounds.size.width - dragedDot!.frame.size.width - leftSpace-rightSpace)) * CGFloat(durationTime)
            
            
            
            
            leftLabel.frame = NSMakeRect(begin.frame.origin.x + dotSize.width/2 - labelWidth/2, 0, labelWidth, 20)
            rightLabel.frame = NSMakeRect(end.frame.origin.x + dotSize.width/2 - labelWidth/2, 0, labelWidth, 20)
            
            
            startTime = TimeInterval(minTime)
            endTime   = TimeInterval(maxTime)
            

            


            
            if leftLabel.frame.origin.x < rightLabel.frame.origin.x
            {
                leftLabel.stringValue = self.timeString(min(startTime,endTime))
                rightLabel.stringValue = self.timeString(max(startTime,endTime))
            }else
            {
                leftLabel.stringValue = self.timeString(max(startTime,endTime))
                rightLabel.stringValue = self.timeString(min(startTime,endTime))
            }
            
            
            
            
            let range = (start:Int(minTime),end:Int(maxTime))
            //let frame =  minTime/CGFloat(frames)
            
            
            let percent = (dragedDot!.frame.origin.x-leftSpace)/(self.bounds.size.width - leftSpace - rightSpace - dragedDot!.frame.size.width)
            
            Swift.print(percent)
            
            let index = Int(percent*CGFloat(frames))
            Swift.print(index)
            if lastFrame == nil
            {
                self.delegate?.didSelectFrame(index)
            }else
            {
                if index != self.lastFrame!
                {
                    self.delegate?.didSelectFrame(index)
                }
            }
            self.lastFrame = index
            
            
            
            if lastRange == nil
            {
                self.delegate?.didSelectRange(range.start, end: range.end)
            }else
            {
                if (range.start != lastRange!.start) || (range.end != lastRange!.end)
                {
                    self.delegate?.didSelectRange(range.start, end: range.end)
                }
            }
            lastRange = range
            
        }
    }
    
    func timeString(_ time:TimeInterval) -> String
    {
        let minutes = floor(time/60)
        let seconds = round(time - minutes * 60)
        
        return String(format: "%02.0f:%02.0f",minutes,seconds)
    }
    override func mouseUp(with theEvent: NSEvent) {
        self.dragedDot = nil
    }
    
}
