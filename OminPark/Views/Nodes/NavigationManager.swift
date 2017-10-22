//
//  NavigationManager.swift
//  OminPark
//
//  Created by Vasilii Muravev on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import ARKit

let hallDuration: TimeInterval = 12.0

class NavigationManager {
    
    // MARK: - Singleton
    static let shared = NavigationManager()
    
    
    // MARK: - Public Instance Methods
    func arrowsForNavigation() -> [ArrowNode] {
        var nodes: [ArrowNode] = []
        for _ in 0..<40 {
            nodes.append(ArrowNode())
        }
        return nodes
    }
    
    func run(_ arrows: [ArrowNode]) {
        guard arrows.count > 0 else { return }
        let interval = hallDuration / Double(arrows.count)
        for (i, arrow) in arrows.enumerated() {
            let waitAction = SCNAction.wait(duration: interval * Double(i))
            let actions = SCNAction.sequence([waitAction, navigateAnimation(arrow.position, arrow.eulerAngles)])
            arrow.runAction(actions)
        }
    }
    
    func navigateAnimation(_ initialPosition: SCNVector3, _ initialAngles: SCNVector3) -> SCNAction {
        let firstStop = SCNVector3(0.2, 0.0, 0.0)
        let secondStop = SCNVector3(0.0, 0.0, -0.2)
        let thirdStop = SCNVector3(-0.2, 0.0, 0.0)
//        let firstStop = initialPosition + SCNVector3(0.2, 0.0, 0.0)
//        let secondStop = firstStop + SCNVector3(0.0, 0.0, 0.2)
//        let thirdStop = secondStop + SCNVector3(-0.2, 0.0, 0.0)

        let stop1Action = SCNAction.move(by: firstStop, duration: hallDuration / 3.0)
        let stop2Action = SCNAction.move(by: secondStop, duration: hallDuration / 3.0)
        let stop3Action = SCNAction.move(by: thirdStop, duration: hallDuration / 3.0)
        let firstTurn = SCNAction.rotateBy(x: 0.0, y: CGFloat.pi * 0.5, z: 0.0, duration: 0.5)
        let secondTurn = SCNAction.rotateBy(x: 0.0, y: CGFloat.pi * 0.5, z: 0.0, duration: 0.5)
        
        let secondLine = SCNAction.group([stop2Action, firstTurn])
        let thirdLine = SCNAction.group([stop3Action, secondTurn])
        
        let navActions = SCNAction.sequence([stop1Action, secondLine, thirdLine])
        
        
        let moveBackAction = SCNAction.move(to: initialPosition, duration: 0.0)
        let rotateBackAction = SCNAction.rotateTo(x: CGFloat(initialAngles.x), y: CGFloat(initialAngles.y), z: CGFloat(initialAngles.z), duration: 0.0)
        let actions = SCNAction.sequence([navActions, moveBackAction, rotateBackAction])
        return SCNAction.repeatForever(actions)
    }
}

