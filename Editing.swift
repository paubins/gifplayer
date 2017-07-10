//
//  Editing.swift
//  GifPlayer
//
//  Created by Patrick Aubin on 7/9/17.
//  Copyright © 2017 com.paubins.GifPlayer. All rights reserved.
//

import Foundation

class Editing: NSTextField {
    
    private let commandKey = NSEventModifierFlags.command.rawValue
    private let commandShiftKey = NSEventModifierFlags.command.rawValue | NSEventModifierFlags.shift.rawValue
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEventType.keyDown {
            if (event.modifierFlags.rawValue & NSEventModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return true }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return true }
                case "z":
                    if NSApp.sendAction(Selector(("undo:")), to:nil, from:self) { return true }
                case "a":
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return true }
                default:
                    break
                }
            }
            else if (event.modifierFlags.rawValue & NSEventModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector(("redo:")), to:nil, from:self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
