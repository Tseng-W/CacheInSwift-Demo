//
//  CacheWrapper.swift
//  CacheDemo
//
//  Created by 曾問 on 2021/6/28.
//

import UIKit

final public class Cache<Key: Hashable, Value> {
  private let wrapped = NSCache<WrappedKey, Entry>()
  private let dateProvider: () -> Date // 2
  private let entryLifetime: TimeInterval
  private let keyTracker = KeyTracker() // 3

  weak var delegate: NSCacheDelegate?

  init(dateProvider: @escaping () -> Date = Date.init, // 2 + Dependency Injection
       entryLifetime: TimeInterval = 12 * 60 * 60,
       maximumEbtryCount: Int = 50) {
    self.dateProvider = dateProvider
    self.entryLifetime = entryLifetime
    wrapped.countLimit = maximumEbtryCount // 3
    wrapped.delegate = keyTracker // 3
    wrapped.delegate = delegate
  }

  func insert(_ value: Value, forKey key: Key) {
    let date = dateProvider().addingTimeInterval(entryLifetime) // 2
    let entry = Entry(key: key, value: value, expirationDate: date)
    wrapped.setObject(entry, forKey: WrappedKey(key))
    keyTracker.keys.insert(key)
  }

  func value(forKey key: Key) -> Value? {
//    let entry = wrapped.object(forKey: WrappedKey(key))
//    return entry?.value
    guard let entry = wrapped.object(forKey: WrappedKey(key)) else { return nil }

    guard dateProvider() < entry.expirationDate else {
      removeValue(forKey: key)
      return nil
    }

    return entry.value
  }

  func removeValue(forKey key: Key) {
    wrapped.removeObject(forKey: WrappedKey(key))
  }
}

private extension Cache {
  final class WrappedKey: NSObject {
    let key: Key

    init(_ key: Key) { self.key = key }

    override var hash: Int { return key.hashValue }

    override func isEqual(_ object: Any?) -> Bool {
      guard let value = object as? WrappedKey else {
        return false
      }

      return value.key == key
    }
  }

  final class Entry {
    let key: Key // 3
    let value: Value
    let expirationDate: Date // 2

    init(key: Key, value: Value, expirationDate: Date) {
      self.key = key // 3
      self.value = value
      self.expirationDate = expirationDate // 2
    }
  }
}

extension Cache {
  subscript(key: Key) -> Value? {
    get { return value(forKey: key) }
    set {
      guard let value = newValue else {
        // If nil was assigned using our subscript,
        // then we remove any value for that key:
        removeValue(forKey: key)
        return
      }

      insert(value, forKey: key)
    }
  }
}

private extension Cache {
  final class KeyTracker: NSObject, NSCacheDelegate {
    var keys = Set<Key>()

    func cache(_ cache: NSCache<AnyObject, AnyObject>,
               willEvictObject object: Any) {
      guard let entry = object as? Entry else { return }

      keys.remove(entry.key)
    }
  }
}
