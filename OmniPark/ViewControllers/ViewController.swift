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
import UserNotifications

class ViewController: UIViewController {
    
    // MARK: - @IBOutlets
    @IBOutlet var sceneView: ARSCNView!
    
    
    // MARK: - Public Instance Attributes
    let planeHeight: CGFloat = 0.001
    var anchors: [ARAnchor] = []
    var notShowingMap = true
    var nodes: [SCNNode] = []
    var currentGesture: ARGesture?
    var meterNode: MeterNode?
    var selectedParkingLot: ParkingSpot?
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.session.delegate = self
        // @TODO: Debug turned off
//        sceneView.showsStatistics = true
//        sceneView.debugOptions = [.showConstraints, .showLightExtents, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
//        sceneView.autoenablesDefaultLighting = true
//        sceneView.automaticallyUpdatesLighting = true
        fillUpDemoNodes()
        ParkingSpotManager.shared.fetchParkingSpots()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if notShowingMap {
            showMapView()
            notShowingMap = false
        }
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
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
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        guard let planeAnchor = anchor as? ARPlaneAnchor else {
//            return nil
//        }
//        let node = SCNNode()
//        let planeGeometry = SCNBox(width: CGFloat(planeAnchor.extent.x), height: planeHeight, length: CGFloat(planeAnchor.extent.z), chamferRadius: 0.0)
//        planeGeometry.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.3)
//        planeGeometry.firstMaterial?.specular.contents = UIColor.white
//        let planeNode = SCNNode(geometry: planeGeometry)
//        planeNode.position = SCNVector3Make(planeAnchor.center.x, -Float(planeHeight / 2), planeAnchor.center.z)
//        //since SCNPlane is vertical, needs to be rotated -90 degrees on X axis to make a plane
//        //planeNode.transform = SCNMatrix4MakeRotation(Float(-CGFloat.pi/2), 1, 0, 0)
//        node.addChildNode(planeNode)
//        anchors.append(planeAnchor)
//        return node
//    }
//
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let planeAnchor = anchor as? ARPlaneAnchor, anchors.contains(planeAnchor) else {
//            return
//        }
//        guard let planeNode = node.childNodes.first else {
//            return
//        }
//        planeNode.position = SCNVector3Make(planeAnchor.center.x, -Float(planeHeight / 2), planeAnchor.center.z)
//        if let plane = planeNode.geometry as? SCNBox {
//            plane.width = CGFloat(planeAnchor.extent.x)
//            plane.length = CGFloat(planeAnchor.extent.z)
//            plane.height = planeHeight
//        }
//    }
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
                //print("WRONG TEXT")
                return
            }
            guard let positionTl = self.position(for: self.getTextRect(from: tl.characterBoxes!), from: frame),
                  let positionTr = self.position(for: self.getTextRect(from: tr.characterBoxes!), from: frame) else {
                //print("WRONG POSITION")
                return
            }
            if (positionTl - positionTr).length() > 0.1 || (positionTl - positionTr).length() < 0.04 {
                return
            }
            let angle = (positionTr.flatPoint() - positionTl.flatPoint()).angle() + CGFloat.pi * 0.02
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
        mapViewController.modalPresentationStyle = .fullScreen
        present(mapViewController, animated: false, completion: nil)
        mapViewController.parkingLotSelected = {
            self.selectedParkingLot = $0
        }
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
            (SCNVector3(0.24, 0.005, 0.02), CGFloat.pi * 0.5, .unavailable),
            (SCNVector3(0.24, 0.005, -0.105), CGFloat.pi * 0.5, .unavailable),
            (SCNVector3(0.035, 0.005, -0.235), CGFloat.pi, .unavailable),
            (SCNVector3(-0.045, 0.005, -0.235), CGFloat.pi, .available),
            (SCNVector3(-0.25, 0.005, 0.05), -CGFloat.pi * 0.5, .unavailable),
            (SCNVector3(-0.25, 0.005, 0.13), -CGFloat.pi * 0.5, .available),
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
        guard meterNode == nil || meterNode?.isHidden == true else { return }
        let meter = MeterNode()
        meter.position = SCNVector3(0.0, 0.2, 0.4)
        meter.eulerAngles = SCNVector3(0.0, CGFloat.pi, 0.0)
        meter.parkingLot = parkingLot
        let meterSubNode = SCNNode()
        meterSubNode.addChildNode(meter)
        nodes[0].addChildNode(meterSubNode)
        meterSubNode.look(at: sceneView.pointOfView!, offset: SCNVector3(0.0, -0.6, 0.0))
        meter.buttonNode.action = { [weak self] _ in
            meter.isHidden = true
            let startDate = Date()
            let endDate = Date().addingTimeInterval(meter.duration)
            guard let parkingLot = self?.selectedParkingLot else { return }
            ParkBookingManager.shared.bookParkingSpot(parkingLot.parkingSpotId, startDate: startDate, endDate: endDate) { (error) in
                guard error == nil else {
                    print("Error booking parking")
                    return
                }
                let content = UNMutableNotificationContent()
                content.title = "Parking Space Expiring"
                content.body = "Would you like to extend your parking space?"
                content.sound = UNNotificationSound.default()
                content.categoryIdentifier = "com.silverlogic.OmniPark.category"
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 25, repeats: false)
                let notification = UNNotificationRequest(identifier: "com.silverlogic.OmniPark.request",
                                                         content: content,
                                                         trigger: trigger)
                UNUserNotificationCenter.current().add(notification) { (error) in
                    guard error == nil else {
                        print("Error setting notification")
                        return
                    }
                    print("Notification sent")
                }
            }
            self?.showOffers()
        }
    }
    
    func showOffers() {
        let offerTao = OfferNode(#imageLiteral(resourceName: "icon-offertao"))
        let offerInNOut = OfferNode(#imageLiteral(resourceName: "icon-offerinnout"))
        offerTao.position = SCNVector3(-0.25, 0.2, -0.4)
        offerInNOut.position = SCNVector3(0.25, 0.2, -0.4)
        offerTao.look(at: sceneView.pointOfView!, offset: nil)
        offerInNOut.look(at: sceneView.pointOfView!, offset: nil)
        nodes[0].addChildNode(offerTao)
        nodes[0].addChildNode(offerInNOut)
        offerTao.action = { _ in
            offerTao.isHidden = true
            offerInNOut.isHidden = true
        }
        offerInNOut.action = { _ in
            offerTao.isHidden = true
            offerInNOut.isHidden = true
        }
    }
}
