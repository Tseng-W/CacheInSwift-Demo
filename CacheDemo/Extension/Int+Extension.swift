//
//  Int+Extension.swift
//  CacheDemo
//
//  Created by 曾問 on 2021/6/30.
//

import UIKit

extension Int {
  func byteToMb() -> CGFloat {
    return CGFloat(self) / 1024.0 / 1024.0
  }
}
