//
//  ViewController.swift
//  OminPark
//
//  Created by Emanuel  Guerrero on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController {
    
    // MARK: - @IBOutlets
    @IBOutlet var sceneView: ARSCNView!
    
    
    // MARK: - Public Instance Attributes
    let planeHeight: CGFloat = 0.001
    var anchors: [ARAnchor] = []
    var nodes: [SCNNode] = []
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        fillUpDemoNodes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}


// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return nil
        }
        let node = SCNNode()
        let planeGeometry = SCNBox(width: CGFloat(planeAnchor.extent.x), height: planeHeight, length: CGFloat(planeAnchor.extent.z), chamferRadius: 0.0)
        planeGeometry.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.3)
        planeGeometry.firstMaterial?.specular.contents = UIColor.white
        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, Float(planeHeight / 2), planeAnchor.center.z)
        //since SCNPlane is vertical, needs to be rotated -90 degrees on X axis to make a plane
        //planeNode.transform = SCNMatrix4MakeRotation(Float(-CGFloat.pi/2), 1, 0, 0)
        node.addChildNode(planeNode)
        anchors.append(planeAnchor)
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, anchors.contains(planeAnchor) else {
            return
        }
        guard let planeNode = node.childNodes.first else {
            return
        }
        
        planeNode.position = SCNVector3Make(planeAnchor.center.x, Float(planeHeight / 2), planeAnchor.center.z)
        if let plane = planeNode.geometry as? SCNBox {
            plane.width = CGFloat(planeAnchor.extent.x)
            plane.length = CGFloat(planeAnchor.extent.z)
            plane.height = planeHeight
        }
    }
}


// MARK: - ARSessionDelegate
extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.global(qos: .userInteractive).async { [unowned self] in
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .right, options: [:])
            do {
                try imageRequestHandler.perform([self.textRecognishionRequest(frame)])
            } catch {
                print(error)
            }
        }
    }
}


// MARK: - Vision Stuff
fileprivate extension ViewController {
    func textRecognishionRequest(_ frame: ARFrame) -> VNRequest {
        let textRequest = VNDetectTextRectanglesRequest { [weak self] (request, error) in
            guard let strongSelf = self else { return }
            strongSelf.detectTextHandler(request: request, error: error, frame: frame)
        }
        textRequest.reportCharacterBoxes = true
        return textRequest
    }
    
    func detectTextHandler(request: VNRequest, error: Error?, frame: ARFrame) {
        guard let result = request.results as? [VNTextObservation] else {
            print("no result")
            return
        }
        DispatchQueue.main.async() { [unowned self] in
            self.sceneView.layer.sublayers?.removeAll()
            result.forEach({ region in
                self.highlightWord(box: region, frame: frame)
                region.characterBoxes?.forEach(self.highlightLetters)
            })
        }
        DispatchQueue.main.async { [unowned self] in
            guard result.count > 3,
                let tl = result.filter({ $0.characterBoxes?.count == 9 }).first,
                let tr = result.filter({ $0.characterBoxes?.count == 11 }).first else {
//                let bl = result.filter({ $0.characterBoxes?.count == 6 }).first,
//                let br = result.filter({ $0.characterBoxes?.count == 7 }).first else {
                return
            }
            let steps: [SCNNode: VNTextObservation] = [
                self.nodes[1]: tl,
                self.nodes[2]: tr,
//                self.nodes[3]: bl,
//                self.nodes[4]: br,
            ]
//            steps.forEach({
//                guard let position = self.position(for: self.getTextRect(from: $0.value.characterBoxes!), from: frame) else { return }
//                $0.key.position = position
//            })
            guard let positionTl = self.position(for: self.getTextRect(from: tl.characterBoxes!), from: frame),
                let positionTr = self.position(for: self.getTextRect(from: tr.characterBoxes!), from: frame) else { return }
//                let positionBl = self.position(for: self.getTextRect(from: bl.characterBoxes!), from: frame),
//                let positionBr = self.position(for: self.getTextRect(from: br.characterBoxes!), from: frame) else { return }
            let angle = (positionTr.flatPoint() - positionTl.flatPoint()).angle()
            let node = self.nodes[0]
            if self.nodes[0].position == SCNVector3Zero {
                node.position = positionTl
            } else {
                let moveAction = SCNAction.move(to: positionTl, duration: 2)
                node.runAction(moveAction)
            }
            node.eulerAngles = SCNVector3(0, angle, 0)
            print("found!!!")
        }
    }
    
    func position(for textRect: TextRect, from frame: ARFrame) -> SCNVector3? {
        let point = CGPoint(x: 1 - (textRect.yMin + (textRect.yMax - textRect.yMin) / 2.0), y: 1 - (textRect.xMin + (textRect.xMax - textRect.xMin) / 2.0))
        guard let position = frame.existingPlanePoint(for: point)?.position() else { return nil }
        print(point)
        return position
    }
    
    struct TextRect {
        var xMax: CGFloat
        var xMin: CGFloat
        var yMax: CGFloat
        var yMin: CGFloat
    }
    
    func getTextRect(from boxes: [VNRectangleObservation]) -> TextRect {
        var textRect = TextRect(xMax: 10000.0, xMin: 0.0, yMax: 10000.0, yMin: 0.0)
        for char in boxes {
            if char.bottomLeft.x < textRect.xMax {
                textRect.xMax = char.bottomLeft.x
            }
            if char.bottomRight.x > textRect.xMin {
                textRect.xMin = char.bottomRight.x
            }
            if char.bottomRight.y < textRect.yMax {
                textRect.yMax = char.bottomRight.y
            }
            if char.topRight.y > textRect.yMin {
                textRect.yMin = char.topRight.y
            }
        }
        return textRect
    }
    
    func highlightWord(box: VNTextObservation, frame: ARFrame) {
        guard let boxes = box.characterBoxes else {
            return
        }
        let textRect = getTextRect(from: boxes)
        
        let xCord = textRect.xMax * sceneView.frame.size.width
        let yCord = (1 - textRect.yMin) * sceneView.frame.size.height
        let width = (textRect.xMin - textRect.xMax) * sceneView.frame.size.width
        let height = (textRect.yMin - textRect.yMax) * sceneView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor
        sceneView.layer.addSublayer(outline)
//        let node: SCNNode
//        switch boxes.count {
//        case 4: //top left
//            node = nodes[1]
//        case 5: //top right
//            node = nodes[2]
//        case 6: //bottom left
//            node = nodes[3]
//        case 7: //bottom right
//            node = nodes[4]
//        default:
//            return
//        }
//        let point = CGPoint(x: 1 - (minY + (maxY - minY) / 2.0), y: 1 - (minX + (maxX - minX) / 2.0))
////        node = nodes[4]
////        let point = CGPoint(x: 0.75, y: 0.25)
//        guard let position = frame.existingPlanePoint(for: point) else { return }
//        print(point)
////        node.removeFromParentNode()
//        node.position = position.position()
////        let rootNode = sceneView.node(for: anchor)
////        rootNode?.addChildNode(node)
    }
    
    func highlightLetters(_ box: VNRectangleObservation) {
        let xCord = box.topLeft.x * sceneView.frame.size.width
        let yCord = (1 - box.topLeft.y) * sceneView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * sceneView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * sceneView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 1.0
        outline.borderColor = UIColor.blue.cgColor
        
        sceneView.layer.addSublayer(outline)
    }
}


// MARK: - ARKit Stuff
fileprivate extension ViewController {
    func fillUpDemoNodes() {
        let parkingSpace = SCNBox(width: 0.5, height: planeHeight, length: 0.5, chamferRadius: 0)
        parkingSpace.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.8)
        parkingSpace.firstMaterial?.specular.contents = UIColor.white
        let node = SCNNode(geometry: parkingSpace)
        nodes.append(node)
        sceneView.scene.rootNode.addChildNode(node)
        let arrows = NavigationManager.shared.arrowsForNavigation()
        arrows.forEach { arrow in
            arrow.position = arrow.position + SCNVector3(0, 0.01, 0)
            arrow.eulerAngles = SCNVector3(0.0, CGFloat.pi * 1.5, 0.0)
            node.addChildNode(arrow)
        }
        NavigationManager.shared.run(arrows)
        for _ in 0..<4 {
            let pinNode = SCNSphere(radius: 0.005)
            pinNode.firstMaterial?.diffuse.contents = UIColor.red.withAlphaComponent(0.8)
            pinNode.firstMaterial?.specular.contents = UIColor.white
            let node = SCNNode(geometry: pinNode)
            nodes.append(node)
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
}
