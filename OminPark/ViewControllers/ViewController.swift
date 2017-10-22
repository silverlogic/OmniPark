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
    var visionRequests: [VNRequest] = []
    let planeHeight: CGFloat = 0.001
    var anchors: [ARAnchor] = []
    var notShowingMap = true
    
    
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
        setupVisionRequests()
        ParkingSpotManager.shared.fetchParkingSpots()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
        if notShowingMap {
            showMapView()
            notShowingMap = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
        DispatchQueue.global(qos: .userInteractive).async {
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .right, options: [:])
            do {
                try imageRequestHandler.perform(self.visionRequests)
            } catch {
                print(error)
            }
        }
    }
}


// MARK: - Vision Stuff
fileprivate extension ViewController {
    func setupVisionRequests() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: detectTextHandler)
        textRequest.reportCharacterBoxes = true
        self.visionRequests = [textRequest]
    }
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let result = request.results as? [VNTextObservation] else {
            print("no result")
            return
        }
        DispatchQueue.main.async() { [unowned self] in
            self.sceneView.layer.sublayers?.removeAll()
            result.forEach({ region in
                self.highlightWord(box: region)
                region.characterBoxes?.forEach(self.highlightLetters)
            })
        }
    }
    
    func highlightWord(box: VNTextObservation) {
        guard let boxes = box.characterBoxes else {
            return
        }
        
        var maxX: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var maxY: CGFloat = 9999.0
        var minY: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < maxX {
                maxX = char.bottomLeft.x
            }
            if char.bottomRight.x > minX {
                minX = char.bottomRight.x
            }
            if char.bottomRight.y < maxY {
                maxY = char.bottomRight.y
            }
            if char.topRight.y > minY {
                minY = char.topRight.y
            }
        }
        
        let xCord = maxX * sceneView.frame.size.width
        let yCord = (1 - minY) * sceneView.frame.size.height
        let width = (minX - maxX) * sceneView.frame.size.width
        let height = (minY - maxY) * sceneView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor
        
        sceneView.layer.addSublayer(outline)
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
    
    func showMapView() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mapViewController = storyboard.instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
        present(mapViewController, animated: true, completion: nil)
    }
}
