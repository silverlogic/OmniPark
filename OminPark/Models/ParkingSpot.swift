//
//  ParkingSpot.swift
//  OmniPark
//
//  Created by Emanuel  Guerrero on 10/21/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import Foundation
import GoogleMaps
import SwiftyJSON

struct ParkingSpot: Decodable {
    struct ParkingLocation: Decodable {
        let latitude: Double
        let longitude: Double
        
        // MARK: - CodingKeys
        enum CodingKeys: String, CodingKey {
            case latitude = "lat"
            case longitude = "long"
        }
    }
    
    let parkingSpotId: Int16
    let type: String
    let addressLine1: String
    let addressLine2: String
    let city: String
    let state: String
    let postalCode: String
    let location: ParkingLocation
    
    
    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case parkingSpotId = "id"
        case type = "type"
        case addressLine1 = "address_line1"
        case addressLine2 = "address_line2"
        case city = "address_city"
        case state = "address_state"
        case postalCode = "address_postalcode"
        case location = "location"
    }
}

final class ParkingSpotManager {
    
    // MARK: - Shared Instance
    static let shared = ParkingSpotManager()
    
    
    // MARK: - Private Instance Attributes
    private var parkingSpots: [ParkingSpot] = []
    
    
    // Initializers
    private init() {}
    
    
    // MARK: - Public Instance Methods
    func fetchParkingSpots() {
        let url = "\(BASE_URL)/spots"
        DispatchQueue.global(qos: .userInitiated).async {
            let networkClient = NetworkClient()
            networkClient.performRequest(url: url, httpMethod: .get, parameters: nil, headers: nil) { (data, error) in
                guard error == nil else {
                    print("Error retrieving spots")
                    print(error!)
                    return
                }
                guard let responseData = data else {
                    print("No response data for parking spots")
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let parkingSpots = try decoder.decode([ParkingSpot].self, from: responseData)
                    self.parkingSpots = parkingSpots
                    print("Parking spots retrieved")
                } catch {
                    print("Error parsing response data for parking spots")
                    print(error)
                }
            }
        }
    }
    
    func parkingSpotMarkers(for mapView: GMSMapView) -> [GMSMarker] {
        return parkingSpots.flatMap {
            let latitude = $0.location.latitude
            let longitude = $0.location.longitude
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let marker = GMSMarker(position: coordinate)
            switch $0.type {
            case "public":
                marker.icon = #imageLiteral(resourceName: "public-park-pin")
            case "commercial":
                marker.icon = #imageLiteral(resourceName: "merchant-park-pin")
            case "private":
                marker.icon = #imageLiteral(resourceName: "peer-park-pin")
            default:
                marker.icon = #imageLiteral(resourceName: "peer-park-pin")
            }
            marker.map = mapView
            marker.appearAnimation = .pop
            return marker
        }
    }
    
    func directionsToMarker(_ destinationMarker: GMSMarker, starting from: CLLocationCoordinate2D, completion: @escaping (_ polyLine: GMSPolyline?, _ error: Error?) -> Void) {
        let startingPoint = "\(from.latitude),\(from.longitude)"
        let destinationPoint = "\(destinationMarker.position.latitude),\(destinationMarker.position.longitude)"
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(startingPoint)&destination=\(destinationPoint)&mode=driving&key=\(GOOGLE_DIRECTIONS_API_KEY)"
        DispatchQueue.global(qos: .userInitiated).async {
            let networkClient = NetworkClient()
            networkClient.performRequest(url: url, httpMethod: .get, parameters: nil, headers: nil, completion: { (data, error) in
                DispatchQueue.main.async {
                    guard error == nil else {
                        completion(nil, error!)
                        return
                    }
                    guard let responseData = data else {
                        completion(nil, nil)
                        return
                    }
                    do {
                        let json = try JSON(data: responseData)
                        let routes = json["routes"].arrayObject!
                        let route = routes[0] as! [String: Any]
                        let overviewPolyline = route["overview_polyline"] as! [String: Any]
                        let polystring = overviewPolyline["points"] as! String
                        let path = GMSPath(fromEncodedPath: polystring)
                        let polyLine = GMSPolyline(path: path!)
                        polyLine.strokeWidth = 3
                        polyLine.strokeColor = #colorLiteral(red: 0.9490196078, green: 0.7921568627, blue: 0.09019607843, alpha: 1)
                        completion(polyLine, nil)
                    } catch {
                        completion(nil, nil)
                    }
                }
            })
        }
    }
}
