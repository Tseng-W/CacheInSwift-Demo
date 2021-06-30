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
  }

  @IBOutlet var imageView: UIImageView!
  @IBOutlet var segmentedControl: UISegmentedControl!
  @IBOutlet var resultLabel: UILabel!
  @IBOutlet var sizeLabel: UILabel!
  @IBOutlet var sizeSegementedControl: UISegmentedControl! {
    didSet {
      switchCacheSize(sender: sizeSegementedControl)
    }
  }
  @IBOutlet var cacheTypeControl: UISegmentedControl!

  let bigImageUrl = URL(string: "https://i.pinimg.com/originals/df/80/f3/df80f367ffb8669baeabcd5564f1b638.jpg")!
  let smallImageUrl = URL(string: "https://images-na.ssl-images-amazon.com/images/I/51f-7KjjFeL._SX317_BO1,204,203,200_.jpg")!

  let imageCache = Cache<String, UIImage>()

  override func viewDidLoad() {
    super.viewDidLoad()

    sizeSegementedControl.addTarget(self, action: #selector(switchCacheSize(sender:)), for: .valueChanged)
    cacheTypeControl.addTarget(self, action: #selector(switchCacheSize(sender:)), for: .valueChanged)

    print("Cache path: \(NSHomeDirectory())")
  }

  @IBAction func downloadImage(_ sender: UIButton) {
    let url = sender.tag == 0 ? smallImageUrl : bigImageUrl
    switch CacheType(rawValue: segmentedControl.selectedSegmentIndex) {
    case .noCache:
      loadImage(url: url, isCache: false) { [weak self] image in
        self?.imageView.image = image
      }
    case .URLSession:
      loadImage(url: url, isCache: true) { [weak self] image in
        self?.imageView.image = image
      }
    case .kingfisher:
      loadImageWithKingfisher(url: url)
    case .NSCache:
      let startTime = CFAbsoluteTimeGetCurrent()
      if let image = imageCache[url.absoluteString] {
        imageView.image = image
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        output("Time elapsed for \(#function): \(timeElapsed) s.")
      } else {
        loadImage(url: url, isCache: true) { [weak self] image in
          self?.imageView.image = image
          self?.imageCache[url.absoluteString] = image
          let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
          self?.output("Time elapsed for \(#function): \(timeElapsed) s.")
        }
      }
    default:
      break
    }
  }

  // Without cache (Swift original)
  private func loadImage(url: URL, isCache: Bool, completion: @escaping (UIImage?) -> Void) {
    let startTime = CFAbsoluteTimeGetCurrent()
    let configuration = URLSessionConfiguration.default
    configuration.requestCachePolicy = isCache ? .returnCacheDataElseLoad : .reloadIgnoringLocalCacheData
    let session = URLSession(configuration: configuration)

    self.imageView.image = nil

    let task = session.dataTask(with: url) { (data, response, error) in
      if let data = data,
         let image = UIImage(data: data) {

        DispatchQueue.main.async { [weak self] in
          completion(image)
          let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
          self?.output("Time elapsed for \(#function): \(timeElapsed) s.")
        }
      }
    }
    task.resume()
  }

  private func loadImageWithKingfisher(url: URL) {
    let startTime = CFAbsoluteTimeGetCurrent()
    self.imageView.image = nil

    KingfisherManager.shared.retrieveImage(with: url) { [weak self] result in
      let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

      switch result {
      case .success(let kfResult):
        self?.imageView.image = kfResult.image
        self?.output("Time elapsed for \(#function): \(timeElapsed) s.")
      case .failure(_):
        self?.output("Time elapsed for \(#function): \(timeElapsed) s.")
      }
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
    print("URLCache.shared.memoryCapacity: \(URLCache.shared.memoryCapacity)")
    print("URLCache.shared.diskCapacity: \(URLCache.shared.diskCapacity)")
  }

  private func output(_ text: String) {
    resultLabel.isHidden = false
    resultLabel.text = text
    print(text)
  }
}
