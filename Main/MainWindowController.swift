import AppKit

class MainWindowController: NSWindowController {

  override func windowDidLoad() {
    super.windowDidLoad()

    shouldCascadeWindows = false
    windowFrameAutosaveName = "GifCaptureAutosave"
    
    window?.isOpaque = false
    window?.backgroundColor = NSColor.clear
    
    window?.contentView?.wantsLayer = true
    window?.contentView?.layer?.borderColor = NSColor.gray.cgColor
    window?.contentView?.layer?.borderWidth = 2
    
    window?.toggleMoving(enabled: true)
  }
}
