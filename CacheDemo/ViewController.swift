//
//  ViewController.swift
//  CacheDemo
//
//  Created by 曾問 on 2021/6/28.
//

import UIKit
import Kingfisher

class ViewController: UIViewController {

  enum CacheType: Int {
    case noCache
    case URLSession
    case kingfisher
    case NSCache
    case tempDirectory
  }

  @IBOutlet var imageView: UIImageView!
  @IBOutlet var segmentedControl: UISegmentedControl!
  @IBOutlet var resultLabel: UILabel!
  @IBOutlet var sizeLabel: UILabel!
  @IBOutlet var sizeSegementedControl: UISegmentedControl!
  @IBOutlet var cacheTypeControl: UISegmentedControl!

  let bigImageUrl = URL(string: "https://i.pinimg.com/originals/df/80/f3/df80f367ffb8669baeabcd5564f1b638.jpg")!
  let smallImageUrl = URL(string: "https://images-na.ssl-images-amazon.com/images/I/51f-7KjjFeL._SX317_BO1,204,203,200_.jpg")!

  let imageCache = Cache<String, UIImage>()

  override func viewDidLoad() {
    super.viewDidLoad()

    print("NShome path: \(NSHomeDirectory())")
    print("Default URLcache memory capacity: \(URLCache.shared.memoryCapacity.byteToMb()) MB")
    print("Default URLcache disk capacity: \(URLCache.shared.diskCapacity.byteToMb()) MB")
    print("Current URLcache memory usage: \(URLCache.shared.currentMemoryUsage.byteToMb()) MB")
    print("Current URLcache disk usage: \(URLCache.shared.currentDiskUsage.byteToMb()) MB")

    sizeSegementedControl.addTarget(self, action: #selector(switchCacheSize(sender:)), for: .valueChanged)
    cacheTypeControl.addTarget(self, action: #selector(switchCacheSize(sender:)), for: .valueChanged)

    switchCacheSize(sender: sizeSegementedControl)
  }

  @IBAction func downloadImage(_ sender: UIButton) {
    imageView.image = nil
    let url = sender.tag == 0 ? smallImageUrl : bigImageUrl
    switch CacheType(rawValue: segmentedControl.selectedSegmentIndex) {
    case .tempDirectory:
      loadTempFile(url: url)
    case .noCache:
      loadImage(url: url, isCache: false) { [weak self] _, image in
        self?.imageView.image = image
      }
    case .URLSession:
      loadImage(url: url, isCache: true) { [weak self] _, image in
        self?.imageView.image = image
      }
    case .kingfisher:
      loadImageWithKingfisher(url: url)
    case .NSCache:
      let startTime = CFAbsoluteTimeGetCurrent()
      let dispatchGroup = DispatchGroup()
      if let image = imageCache[url.absoluteString] {
        imageView.image = image
      } else {
        dispatchGroup.enter()
        loadImage(url: url, isCache: true) { [weak self] _, image in
          self?.imageView.image = image
          self?.imageCache[url.absoluteString] = image
          dispatchGroup.leave()
        }
      }

      dispatchGroup.notify(queue: .main) { [weak self] in
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        self?.output("Time elapsed for \(#function): \(timeElapsed.rounding(toDecimal: 4)) s.")
      }
    default:
      break
    }
  }

  // Without cache (Swift original)
  private func loadImage(url: URL, isCache: Bool, isTiming: Bool = true,startTime: Double = CFAbsoluteTimeGetCurrent(), completion: @escaping (Data, UIImage?) -> Void) {
    let configuration = URLSessionConfiguration.default
    configuration.requestCachePolicy = isCache ? .returnCacheDataElseLoad : .reloadIgnoringLocalCacheData
    let session = URLSession(configuration: configuration)

    let task = session.dataTask(with: url) { (data, response, error) in
      if let data = data,
         let image = UIImage(data: data) {

        DispatchQueue.main.async { [weak self] in
          completion(data, image)
          if isTiming {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            self?.output("Time elapsed for \(#function): \(timeElapsed.rounding(toDecimal: 4)) s.")
          }
        }
      }
    }
    task.resume()
  }

  private func loadImageWithKingfisher(url: URL) {
    let startTime = CFAbsoluteTimeGetCurrent()

    KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
      let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

      switch result {
      case .success(let kfResult):
        self?.imageView.image = kfResult.image
        self?.output("Time elapsed for \(#function): \(timeElapsed.rounding(toDecimal: 4)) s.")
      case .failure(_):
        self?.output("Time elapsed for \(#function): \(timeElapsed.rounding(toDecimal: 4)) s.")
      }
    }
  }

  func loadTempFile(url: URL){
    let startTime = CFAbsoluteTimeGetCurrent()
    let group = DispatchGroup()

    let tempDirectory = FileManager.default.temporaryDirectory
    let imageFileUrl = tempDirectory.appendingPathComponent(url.lastPathComponent)

    if FileManager.default.fileExists(atPath: imageFileUrl.path) {
      let image = UIImage(contentsOfFile: imageFileUrl.path)
      imageView.image = image
    } else {
      group.enter()
      loadImage(url: url, isCache: false, isTiming: false) { [weak self] data, image in
        try? data.write(to: imageFileUrl)

        DispatchQueue.main.async {
          self?.imageView.image = image
          group.leave()
        }
      }
    }
    group.notify(queue: .main) {
      let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
      self.output("Time elapsed for \(#function): \(timeElapsed.rounding(toDecimal: 4)) s.")
    }
  }

  @objc private func switchCacheSize(sender: UISegmentedControl) {
    var capacity: Int = 0
    if sizeSegementedControl.selectedSegmentIndex == 0 {
      capacity = 1 * 1024 * 1024
    } else {
      capacity = 500 * 1024 * 1024
    }

    let cacheTypeIndex = cacheTypeControl.selectedSegmentIndex

    URLCache.shared = URLCache(
      memoryCapacity: cacheTypeIndex == 1 ? 0 : capacity,
      diskCapacity: cacheTypeIndex == 0 ? 0 : capacity,
      diskPath: nil)
    URLCache.shared.removeAllCachedResponses()
    print("URLCache.shared.memoryCapacity: \(URLCache.shared.memoryCapacity.byteToMb()) MB")
    print("URLCache.shared.diskCapacity: \(URLCache.shared.diskCapacity.byteToMb()) MB")
  }

  private func output(_ text: String) {
    resultLabel.isHidden = false
    resultLabel.text = text
    print(text)
  }
}
