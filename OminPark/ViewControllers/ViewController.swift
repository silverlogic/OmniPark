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
    var notShowingMap = true
    var nodes: [SCNNode] = []
    var currentGesture: ARGesture?
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        // @TODO: Debug turned off
//        sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        fillUpDemoNodes()
        ParkingSpotManager.shared.fetchParkingSpots()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
//        if notShowingMap {
//            showMapView()
//            notShowingMap = false
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}


// MARK: UIResponder Methods
extension ViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchEnded)
        guard let touchLocation = touches.first?.location(in: sceneView) else { return }
        let results = sceneView.hitTest(touchLocation, options: [.boundingBoxOnly: true])
        guard let result = results.first else { return }
        currentGesture = ARGesture.startGestureFromTouches(touches, sceneView, result.node)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchMoved)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchEnded)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        currentGesture = currentGesture?.updateGestureFromTouches(touches, .touchCancelled)
    }
}


// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
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
        DispatchQueue.main.async { [unowned self] in
            guard result.count > 1,
                let tl = result.filter({ $0.characterBoxes?.count == 8 }).first,
                let tr = result.filter({ $0.characterBoxes?.count == 14 }).first else {
                print("WRONG TEXT")
                return
            }
            guard let positionTl = self.position(for: self.getTextRect(from: tl.characterBoxes!), from: frame),
                  let positionTr = self.position(for: self.getTextRect(from: tr.characterBoxes!), from: frame) else {
                print("WRONG POSITION")
                return
            }
            if (positionTl - positionTr).length() > 0.1 || (positionTl - positionTr).length() < 0.04 {
                return
            }
            let angle = (positionTr.flatPoint() - positionTl.flatPoint()).angle() - CGFloat.pi * 0.01
            let node = self.nodes[0]
            if node.position == SCNVector3Zero {
                node.position = positionTl
                node.eulerAngles = SCNVector3(0, angle, 0)
                self.sceneView.scene.rootNode.addChildNode(node)
            } else {
                let duration: TimeInterval = 1.0
                let moveAction = SCNAction.move(to: positionTl, duration: duration)
                let rotateAction = SCNAction.rotateTo(x: 0, y: angle, z: 0, duration: duration)
                node.runAction(SCNAction.group([moveAction, rotateAction]))
            }
            print("found!!! \((positionTl - positionTr).length())")
        }
    }
    
    func position(for textRect: TextRect, from frame: ARFrame) -> SCNVector3? {
        let point = CGPoint(x: 1 - (textRect.yMin + (textRect.yMax - textRect.yMin) / 2.0), y: 1 - (textRect.xMin + (textRect.xMax - textRect.xMin) / 2.0))
        return frame.existingPlanePoint(for: point)?.position()
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
    
    func showMapView() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mapViewController = storyboard.instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
        present(mapViewController, animated: true, completion: nil)
    }
}


// MARK: - ARKit Stuff
fileprivate extension ViewController {
    func fillUpDemoNodes() {
        let parkingArea = SCNBox(width: 0.5, height: planeHeight, length: 0.5, chamferRadius: 0)
        parkingArea.firstMaterial?.diffuse.contents = UIColor.clear
        let node = SCNNode(geometry: parkingArea)
        nodes.append(node)
        let arrows = NavigationManager.shared.arrowsForNavigation()
        arrows.forEach { arrow in
            arrow.position = arrow.position + SCNVector3(-0.065, 0.001, 0.26)
            node.addChildNode(arrow)
        }
        NavigationManager.shared.run(arrows)
        drawParkingSpaces(node)
    }
    
    func drawParkingSpaces(_ node: SCNNode) {
        let parkingLots: [(SCNVector3, CGFloat, LotType)] = [
            (SCNVector3(0.24, 0.0, 0.02), CGFloat.pi * 0.5, .unavailable),
            (SCNVector3(0.24, 0.0, -0.105), CGFloat.pi * 0.5, .unavailable),
            (SCNVector3(0.035, 0.0, -0.235), CGFloat.pi, .unavailable),
            (SCNVector3(-0.045, 0.0, -0.235), CGFloat.pi, .available),
            (SCNVector3(-0.25, 0.0, 0.05), -CGFloat.pi * 0.5, .unavailable),
            (SCNVector3(-0.25, 0.0, 0.13), -CGFloat.pi * 0.5, .available),
        ]
        parkingLots.forEach { (position, angle, type) in
            let parkingLot = ParkingLotNode(type)
            parkingLot.position = position
            parkingLot.eulerAngles = SCNVector3(0.0, angle, 0.0)
            node.addChildNode(parkingLot)
            parkingLot.action = { [weak self] node in
                guard parkingLot.type == .available else { return }
                self?.showParkingMeter(for: parkingLot)
            }
        }
    }
    
    func showParkingMeter(for parkingLot: ParkingLotNode) {
        let meter = MeterNode()
        meter.position = SCNVector3(0.0, 0.4, 0.0)
        meter.eulerAngles = SCNVector3(0.0, CGFloat.pi, 0.0)
        meter.parkingLot = parkingLot
        let meterSubNode = SCNNode()
        meterSubNode.addChildNode(meter)
        nodes[0].addChildNode(meterSubNode)
        meterSubNode.look(at: sceneView.pointOfView!, offset: SCNVector3(0.0, -0.6, 0.0))
        meter.buttonNode.action = { _ in
            meter.isHidden = true
        }
    }
}
