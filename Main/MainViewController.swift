//
//  MainViewController.swift
//  GifCapture
//
//  Created by Khoa Pham on 01/03/2017.
//  Copyright © 2017 Fantageek. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {

  @IBOutlet weak var bottomBox: NSBox!
  @IBOutlet weak var widthTextField: NSTextField!
  @IBOutlet weak var heightTextField: NSTextField!
  @IBOutlet weak var recordButton: NSButton!
  @IBOutlet weak var stopButton: NSButton!
  var loadingIndicator: LoadingIndicator!
    
    let saver:Saver = Saver()

  var cameraMan: CameraMan?
  var state: State = .idle {
    didSet {
      DispatchQueue.main.async {
        self.handleStateChanged()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    
  }
    
  func setup() {

    let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    let tempVideoUrl = URL(fileURLWithPath: documents).appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("mov")

    cameraMan = CameraMan(recordFrame(), fileURL: tempVideoUrl)
    cameraMan?.delegate = self
    
    stopButton.isEnabled = false

    loadingIndicator = LoadingIndicator()
    view.addSubview(loadingIndicator)
    Utils.constrain(constraints: [
      loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      loadingIndicator.widthAnchor.constraint(equalToConstant: 100),
      loadingIndicator.heightAnchor.constraint(equalToConstant: 100)
    ])
    
    loadingIndicator.hide()
  }

  override func viewDidLayout() {
    super.viewDidLayout()

    let size = scaleFactorRecordSize()

    widthTextField.stringValue = String(format: "%.0f", size.width)
    heightTextField.stringValue = String(format: "%.0f", size.height)
  }

  // MARK: - Action
  @IBAction func recordButtonTouched(_ sender: NSButton) {
    if case .idle = state {
      state = .start
    } else if case .pause = state{
      cameraMan?.resume()
    } else if case .record = state {
      cameraMan?.pause()
    } else if case .resume = state {
      cameraMan?.pause()
    }
  }

  @IBAction func stopButtonTouched(_ sender: NSButton) {
    cameraMan?.stop()
  }

  // MARK: - Frame

  func recordFrame() -> CGRect {
    guard let window = view.window else {
      return view.frame
    }

    let lineWidth: CGFloat = 2
    let titleHeight: CGFloat = 12
    let someValue: CGFloat = 25

    return CGRect(x: window.frame.origin.x + lineWidth,
                  y: window.frame.origin.y + titleHeight + someValue + lineWidth,
                  width: view.frame.size.width - lineWidth * 2,
                  height: view.frame.size.height - bottomBox.frame.size.height - someValue - lineWidth)
  }

  func scaleFactorRecordSize() -> CGSize {
    let frame = recordFrame()
    let scale = view.window?.screen?.backingScaleFactor ?? 2.0

    return CGSize(width: frame.size.width * scale,
                  height: frame.size.height * scale)
  }

  // MARK: - State

  func handleStateChanged() {
    switch state {
    case .start:
      cameraMan?.record()
    case .record:
      recordButton.title = "Pause"
      toggleStopButton(enabled: true)
      view.window?.toggleMoving(enabled: false)
    case .pause:
      recordButton.title = "Resume"
    case .resume:
      recordButton.title = "Pause"
    case .stop:
      toggleRecordButton(enabled: false)
      toggleStopButton(enabled: false)
      loadingIndicator.show()
    case .finish:
        self.saver.save(videoUrl:  (self.cameraMan?.recordedFile)!) { (url) in
            self.state = .idle
            self.showNotification(path: url!.path)
        }
    case .idle:
      recordButton.title = "Record"
      toggleStopButton(enabled: false)
      toggleRecordButton(enabled: true)
      loadingIndicator.hide()
      view.window?.toggleMoving(enabled: true)
    }
  }

  // MARK: - Notification

  func showNotification(path: String) {
    var notification = Notification.init(name: Notification.Name(rawValue: "newGIFRecorded"))
    notification.object = path
    
    NotificationCenter.default.post(notification)
  }

  // MARK: - Menu Item

  func toggleRecordButton(enabled: Bool) {
    recordButton.isEnabled = enabled
//    (NSApplication.shared().delegate as! AppDelegate).recordMenuItem.isEnabled = enabled
  }

  func toggleStopButton(enabled: Bool) {
    stopButton.isEnabled = enabled
//    (NSApplication.shared().delegate as! AppDelegate).stopMenuItem.isEnabled = enabled
  }

  @IBAction func recordMenuItemTouched(_ sender: NSMenuItem) {
    if case .idle = state {
      state = .start
    }
  }

  @IBAction func stopMenuItemTouched(_ sender: NSMenuItem) {
    cameraMan?.stop()
  }
}

extension MainViewController: CameraManDelegate {

    func cameraMan(_ man: CameraMan, didChange state: State) {
        self.state = state
    }
}

