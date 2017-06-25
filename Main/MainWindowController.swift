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
    
    let viewController:MainViewController = self.contentViewController as! MainViewController
    viewController.setup()
    
    NotificationCenter.default.addObserver(self, selector: #selector(windowDidMove),
                                           name: NSNotification.Name.NSWindowDidMove, object: nil)
  }
    
    func windowDidMove(sender: Notification) {
        let viewController:MainViewController = self.contentViewController as! MainViewController
        viewController.setup()
    }
}
