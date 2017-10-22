//
//  MeterNode.swift
//  OmniPark
//
//  Created by Vasilii Muravev on 10/22/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import SceneKit

class MeterNode: BaseNode {
    
    // MARK: - Public Instance Attributes
    var duration: TimeInterval = 0
    weak var parkingLot: ParkingLotNode!
    fileprivate(set) var buttonNode: BaseNode!

    
    // MARK: - Private Instance Attributes
    fileprivate var arrowNode: BaseNode!
    fileprivate var arrowSubNode: SCNNode!

    
    // MARK: - Initializers
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - Private Instance Methods
fileprivate extension MeterNode {
    func setup() {
        let subNode = SCNNode()
        addChildNode(subNode)
        let radius: CGFloat = 0.2
        let cylinder = SCNCylinder(radius: radius, height: radius * 0.2)
        cylinder.materials = [
            SCNMaterial(color: .colorFromHexValue(0x2a2a6d)),
            SCNMaterial(image: #imageLiteral(resourceName: "icon-meter")),
            SCNMaterial(color: .colorFromHexValue(0x2a2a6d))
        ]
        let cylinderNode = BaseNode(geometry: cylinder)
        cylinderNode.eulerAngles = SCNVector3(0.0, CGFloat.pi * 0.5, 0.0)
        subNode.addChildNode(cylinderNode)
        subNode.eulerAngles = SCNVector3(CGFloat.pi * 0.5, 0.0, 0.0)
        let arrow = SCNPlane(width: radius * 2.0, height: radius * 2.0)
        arrow.materials = [SCNMaterial(image: #imageLiteral(resourceName: "icon-meterarrow"))]
        let arrowNode = BaseNode(geometry: arrow)
        arrowNode.position = SCNVector3(0.0, 0.0, 0.03)
        let arrowSubNode = SCNNode()
        addChildNode(arrowSubNode)
        arrowSubNode.addChildNode(arrowNode)
        self.arrowNode = arrowNode
        self.arrowSubNode = arrowSubNode
        arrowNode.action = { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.duration = strongSelf.duration == 7200.0 ? 0.0 : strongSelf.duration + 900
            strongSelf.updateArrow()
        }
        let acceptButton = SCNPlane(width: radius, height: radius)
        acceptButton.materials = [SCNMaterial(image: #imageLiteral(resourceName: "icon-accept"))]
        let acceptButtonNode = BaseNode(geometry: acceptButton)
        acceptButtonNode.position = SCNVector3(0.0, radius * 2.0, 0.0)
        addChildNode(acceptButtonNode)
        buttonNode = acceptButtonNode
        updateArrow()
    }
    
    func updateArrow() {
        var angle = CGFloat.pi * 0.78
        angle -= CGFloat(duration) * CGFloat.pi / 7200.0
        arrowSubNode.eulerAngles = SCNVector3(0.0, 0.0, angle)
        parkingLot?.type = duration == 0 ? .available : .unavailable
        buttonNode.isHidden = duration == 0
//        if duration >= 7200 {
//
//        } else if duration >= 6300 {
//
//        } else if duration >= 5400 {
//
//        } else if duration >= 4500 {
//
//        } else if duration >= 3600 {
//
//        } else if duration >= 2700 {
//
//        } else if duration >= 1800 {
//
//        } else if duration >= 900 {
//
//        } else {
//
//        }
    }
}

