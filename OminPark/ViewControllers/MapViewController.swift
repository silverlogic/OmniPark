//
//  MapViewController.swift
//  OminPark
//
//  Created by Emanuel  Guerrero on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import UIKit
import GoogleMaps

final class MapViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var mapView: GMSMapView!
    
    
    // MARK: - Lifecycle
    override func loadView() {
        super.loadView()
        setup()
    }
}


// MARK: - Private Instance Attributes
fileprivate extension MapViewController {
    func setup() {
        let coordinate = CLLocationCoordinate2D(latitude: 36.1226597, longitude: -115.1700866)
        let camera = GMSCameraPosition.camera(withTarget: coordinate, zoom: 6.0)
        mapView.camera = camera
        let marker = GMSMarker(position: coordinate)
        marker.appearAnimation = .pop
        marker.title = "Tao"
        marker.map = mapView
    }
}
