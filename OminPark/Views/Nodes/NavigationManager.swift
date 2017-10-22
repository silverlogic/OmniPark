//
//  NavigationManager.swift
//  OminPark
//
//  Created by Vasilii Muravev on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import ARKit

let hallDuration: TimeInterval = 2.0

class NavigationManager {
    
    // MARK: - Singleton
    static let shared = NavigationManager()
    
    
    // MARK: - Public Instance Methods
    func arrowsForNavigation() -> [ArrowNode] {
        var nodes: [ArrowNode] = []
        for _ in 0..<10 {
            nodes.append(ArrowNode())
        }
        return nodes
    }
    
    func run(_ arrows: [ArrowNode]) {
        guard arrows.count > 0 else { return }
        let interval = hallDuration / Double(arrows.count)
        let moveAction = SCNAction.move(by: SCNVector3(0.2, 0, 0), duration: hallDuration)
        for (i, arrow) in arrows.enumerated() {
            let waitAction = SCNAction.wait(duration: interval * Double(i))
            let moveBackAction = SCNAction.move(to: arrow.position, duration: 0.0)
            let actions = SCNAction.sequence([moveAction, moveBackAction])
            let infiniteActions = SCNAction.sequence([waitAction, SCNAction.repeatForever(actions)])
            arrow.runAction(infiniteActions)
        }
    }
}
