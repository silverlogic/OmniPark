//
//  ARFrame+Extension.swift
//  OminPark
//
//  Created by Vasilii Muravev on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import ARKit

extension ARFrame {
    func featurePoint(for normalizedPoint: CGPoint) -> matrix_float4x4? {
        let x = normalizedPoint.x
        let y = normalizedPoint.y
        if x < 0.0 || x > 1.0 || y < 0.0 || y > 1.0 {
            return nil
        }
        guard let testResult = hitTest(normalizedPoint, types: .featurePoint).first else {
            return nil
        }
        return testResult.worldTransform
    }
    
    func existingPlanePoint(for normalizedPoint: CGPoint) -> matrix_float4x4? {
        let x = normalizedPoint.x
        let y = normalizedPoint.y
        if x < 0.0 || x > 1.0 || y < 0.0 || y > 1.0 {
            return nil
        }
        guard let testResult = hitTest(normalizedPoint, types: [.existingPlaneUsingExtent]).first else {
            return nil
        }
        return testResult.worldTransform
    }
}
