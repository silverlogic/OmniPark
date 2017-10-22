//
//  OfferNode.swift
//  OmniPark
//
//  Created by Vasilii Muravev on 10/22/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import SceneKit

class OfferNode: BaseNode {
    
    // MARK: - Initializers
    init(_ image: UIImage) {
        super.init()
        setup(image)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Private Instance Methods
    fileprivate func setup(_ image: UIImage) {
        let infoRotationNode = SCNNode()
        addChildNode(infoRotationNode)
        
        let tubeParentNode = SCNNode()
        tubeParentNode.eulerAngles = SCNVector3(-CGFloat.pi * 0.5, 0.0, 0.0)
        infoRotationNode.addChildNode(tubeParentNode)
        
        let tubeNode = SCNNode()
        let spin = CABasicAnimation(keyPath: "rotation")
        spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: 0.0))
        spin.toValue = NSValue(scnVector4: SCNVector4(x: 0.0, y: 1.0, z: 0.0, w: Float.pi * 2.0))
        spin.duration = 14.0
        spin.repeatCount = .infinity
        tubeNode.addAnimation(spin, forKey: "spin around")
        
        let tubeGeometry = SCNTube(innerRadius: 0.16, outerRadius: 0.2, height: 0.04)
        tubeGeometry.materials = [
            SCNMaterial(color: .white),
            SCNMaterial(color: .white),
            SCNMaterial(color: UIColor.colorFromHexValue(0xf2ca17)),
            SCNMaterial(color: .white),
        ]
        tubeGeometry.materials[2].diffuse.contentsTransform = SCNMatrix4MakeScale(1.0, -1.0, 1.0);
        tubeGeometry.materials[2].diffuse.wrapT = .repeat;
        tubeGeometry.radialSegmentCount *= 2
        tubeNode.geometry = tubeGeometry
        tubeParentNode.addChildNode(tubeNode)
        
        let infoParentNode = SCNNode()
        infoParentNode.eulerAngles = SCNVector3(0.0, CGFloat.pi, 0.0)
        infoRotationNode.addChildNode(infoParentNode)
        let infoNode = SCNNode()
        
        let infoGeometry = SCNPlane(width: 0.3, height: 0.3)
        infoGeometry.materials = [SCNMaterial(image: image)]
        infoNode.geometry = infoGeometry
        infoParentNode.addChildNode(infoNode)
    }
}
