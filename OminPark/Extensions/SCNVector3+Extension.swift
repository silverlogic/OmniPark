//
//  SCNVector3+Extension.swift
//  OminPark
//
//  Created by Vasilii Muravev on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import SceneKit

enum PointType {
    case horizontal
    case vertical
}

extension SCNVector3 {
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
    
    func distanceFromVector(_ vector: SCNVector3) -> Float {
        return (self - vector).length()
    }
    
    func flatPoint(_ type: PointType = .horizontal) -> CGPoint {
        switch type {
        case .horizontal:
            return CGPoint(x: CGFloat(x), y: CGFloat(z))
        case .vertical:
            return CGPoint(x: CGFloat(x), y: CGFloat(y))
        }
    }
}


// MARK: - Operator Overloads
func - (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
}


func + (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
}

func * (lhs: SCNVector3, rhs: Float) -> SCNVector3 {
    return SCNVector3Make(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
}

func == (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
}

func != (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
    return !(lhs == rhs)
}

