//
//  CGPoint+Extension.swift
//  OminPark
//
//  Created by Vasilii Muravev on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import UIKit
import SceneKit

extension CGPoint {
    init(_ vector: SCNVector3) {
        x = CGFloat(vector.x)
        y = CGFloat(vector.y)
    }
    
    func normalized(for size: CGSize) -> CGPoint {
        if size.width == 0 || size.height == 0 {
            return CGPoint.zero
        }
        return CGPoint(x: x / size.width, y: y / size.height)
    }
    
    func length() -> CGFloat {
        return sqrt(x * x + y * y)
    }
    
    func angle() -> CGFloat {
        guard x != 0 else { return 0.0 }
        let angle = atan(y / x)
        return CGFloat.pi * (x > 0 ? 0.5 : 1.5) - angle
    }
}


// MARK: - Operator Overloads
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func += (left: inout CGPoint, right: CGPoint) {
    left = left + right
}

func -= (left: inout CGPoint, right: CGPoint) {
    left = left - right
}

func / (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x / right, y: left.y / right)
}

func * (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x * right, y: left.y * right)
}

func * (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x * right.x, y: left.y * right.y)
}

func /= (left: inout CGPoint, right: CGFloat) {
    left = left / right
}

func *= (left: inout CGPoint, right: CGFloat) {
    left = left * right
}

