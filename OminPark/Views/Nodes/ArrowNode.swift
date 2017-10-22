//
//  ArrowNode.swift
//  OminPark
//
//  Created by Vasilii Muravev on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import SceneKit

class ArrowNode: BaseNode {
    
    // MARK: - Initializers
    override init() {
        super.init()
        let width: CGFloat = 0.01
        let subNode = SCNNode()
        addChildNode(subNode)
        let plane = SCNPlane(width: width, height: width * 0.602)
        plane.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "icon-arrow")
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles = SCNVector3(CGFloat.pi * -0.5, 0.0, 0.0)
        subNode.addChildNode(planeNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
