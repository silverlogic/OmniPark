//
//  SCNNode+Extension.swift
//  OminPark
//
//  Created by Vasilii Muravev on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import SceneKit

extension SCNNode {
    func look(at pointOfView: SCNNode, offset: SCNVector3?) {
        let constraint = SCNLookAtConstraint(target: pointOfView)
        constraint.isGimbalLockEnabled = true
        if let offset = offset {
            constraint.targetOffset = offset
        }
        constraints = [constraint]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak constraint] in
            constraint?.influenceFactor = 0.03
        }
    }
    
    func parentOfType<T: SCNNode>() -> T? {
        var node: SCNNode! = self
        repeat {
            if let node = node as? T { return node }
            node = node?.parent
        } while node != nil
        return nil
    }
    
    func performAction(_ independent: Bool = false) {
        var node: SCNNode! = self
        repeat {
            if let actionNode = node as? ActionNodeProtocol,
                let action = actionNode.action {
                action(node)
                if !independent { break }
            }
            node = node?.parent
        } while node != nil
    }
}

