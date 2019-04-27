//
//  Saver.swift
//  GifCapture
//
//  Created by Khoa Pham on 02/03/2017.
//  Copyright © 2017 Fantageek. All rights reserved.
//

import Foundation
import NSGIF

class Saver {

  typealias Completion = (URL?) -> Void

  func save(videoUrl: URL, completion: @escaping Completion) {

    NSGIF.optimalGIFfromURL(videoUrl, loopCount: 0) { [weak self] (url) in
      self?.copy(url: url, completion: completion)
    }
  }

  func copy(url: URL?, completion: @escaping Completion) {
    guard let url = url else {
      completion(nil)
      return
    }

    defer {
      removeFile(at: url)
    }

    do {
      let gifUrl = self.gifUrl()
      try FileManager.default.copyItem(at: url, to: gifUrl)
      completion(gifUrl)
    } catch {
      completion(nil)
    }
  }

  func gifUrl() -> URL {
    let tempGIFUrl = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("gif")

    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
    
    _ = formatter.string(from: Date())
    
    // This returns a URL? even though it is an NSURL class method
   // return  NSURL.fileURL(withPathComponents: [documentsURL.path, dateString])!.appendingPathExtension("gif")
    return tempGIFUrl
  }

  func removeFile(at url: URL) {
    try? FileManager.default.removeItem(at: url)
  }
}
