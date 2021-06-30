//
//  Double+Extension.swift
//  CacheDemo
//
//  Created by 曾問 on 2021/6/30.
//

import UIKit

extension Double {
  func rounding(toDecimal decimal: Int) -> Double {
    let numberOfDigits = pow(10.0, Double(decimal))
    return (self * numberOfDigits).rounded(.toNearestOrAwayFromZero) / numberOfDigits
  }
}
