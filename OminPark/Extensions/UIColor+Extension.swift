//
//  UIColor+Extension.swift
//  OminPark
//
//  Created by Vasilii Muravev on 10/22/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import UIKit

extension UIColor {
    static func colorFromHexValue(_ hexValue: UInt, alpha: CGFloat = 1.0) -> UIColor {
        let redValue = ((CGFloat)((hexValue & 0xFF0000) >> 16)) / 255.0
        let greenValue = ((CGFloat)((hexValue & 0xFF00) >> 8)) / 255.0
        let blueValue = ((CGFloat)(hexValue & 0xFF)) / 255.0
        return UIColor(red: redValue, green: greenValue, blue: blueValue, alpha: alpha)
    }
}
