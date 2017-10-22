//
//  ARGesture.swift
//  OmniPark
//
//  Created by Vasilii Muravev on 10/22/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import ARKit

class ARGesture {
    
    /// Touch types enum.
    enum TouchEventType {
        case touchBegan
        case touchMoved
        case touchEnded
        case touchCancelled
    }
    
    
    // MARK: - Public Instance Attributes
    var currentTouches = Set<UITouch>()
    let sceneView: ARSCNView
    let virtualObject: SCNNode
    var refreshTimer: Timer?
    
    
    // MARK: - Initializers
    init(_ touches: Set<UITouch>, _ sceneView: ARSCNView, _ virtualObject: SCNNode) {
        currentTouches = touches
        self.sceneView = sceneView
        self.virtualObject = virtualObject
        self.refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.016_667, repeats: true, block: { _ in
            self.refreshCurrentGesture()
        })
    }
    
    
    // MARK: - Public Class Methods
    static func startGestureFromTouches(_ touches: Set<UITouch>, _ sceneView: ARSCNView, _ virtualObject: SCNNode) -> ARGesture? {
        if touches.count == 1 {
            return SingleFingerGesture(touches, sceneView, virtualObject)
        } else {
            return nil
        }
    }
    
    
    // MARK: - Public Instance Methods
    func refreshCurrentGesture() {
        if let singleFingerGesture = self as? SingleFingerGesture {
            singleFingerGesture.updateGesture()
        }
    }
    
    func updateGestureFromTouches(_ touches: Set<UITouch>, _ type: TouchEventType) -> ARGesture? {
        if touches.isEmpty {
            return self
        }
        if type == .touchBegan || type == .touchMoved {
            currentTouches = touches.union(currentTouches)
        } else if type == .touchEnded || type == .touchCancelled {
            currentTouches.subtract(touches)
        }
        if let singleFingerGesture = self as? SingleFingerGesture {
            if currentTouches.count == 1 {
                singleFingerGesture.updateGesture()
                return singleFingerGesture
            } else {
                singleFingerGesture.finishGesture()
                singleFingerGesture.refreshTimer?.invalidate()
                singleFingerGesture.refreshTimer = nil
                return ARGesture.startGestureFromTouches(currentTouches, sceneView, virtualObject)
            }
        } else {
            return self
        }
    }
}


/// A `ARGesture` for managing single touch gestures.
final class SingleFingerGesture: ARGesture {
    
    // MARK: - Public Instance Attributes
    var initialTouchLocation = CGPoint()
    var latestTouchLocation = CGPoint()
    let translationThreshold: CGFloat = 10
    var translationThresholdPassed = false
    var hasMovedObject = false
    var firstTouchWasOnObject = false
    var dragOffset = CGPoint()
    
    
    // MARK: - Initializers
    override init(_ touches: Set<UITouch>, _ sceneView: ARSCNView, _ virtualObject: SCNNode) {
        super.init(touches, sceneView, virtualObject)
        let touch = currentTouches[currentTouches.index(currentTouches.startIndex, offsetBy: 0)]
        initialTouchLocation = touch.location(in: sceneView)
        latestTouchLocation = initialTouchLocation
        firstTouchWasOnObject = true
    }
    
    
    // MARK: - Public Instance Methods
    func updateGesture() {
    }
    
    func finishGesture() {
        if currentTouches.count > 1 {
            return
        }
        if hasMovedObject {
            return
        }
        virtualObject.performAction()
    }
}

