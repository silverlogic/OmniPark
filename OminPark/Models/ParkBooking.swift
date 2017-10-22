//
//  ParkBooking.swift
//  OmniPark
//
//  Created by Emanuel  Guerrero on 10/22/17.
//  Copyright © 2017 SilverLogic, LLC. All rights reserved.
//

import Foundation

enum BookingError: Error {
    case notAuthenticated
}

final class ParkBookingManager {
    
    // MARK: - Shared Instance
    static let shared = ParkBookingManager()
    
    
    // MARK: - Initializers
    private init() {}
    
    
    // MARK: - Public Instance Methods
    func bookParkingSpot(_ parkingSpotId: Int16, startDate: Date, endDate: Date, completion: @escaping (_ error: Error?) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let formatedStartDate = dateFormatter.string(from: startDate)
        let formatedEndDate = dateFormatter.string(from: endDate)
        guard let token = UserManager.shared.token else {
            completion(BookingError.notAuthenticated)
            return
        }
        let url = "\(BASE_URL)/bookings"
        let headers: [String: String] = ["Authorization": "Token \(token)"]
        let body: [String: Any] = ["spot": parkingSpotId, "start": formatedStartDate, "end": formatedEndDate]
        DispatchQueue.global(qos: .userInitiated).async {
            let networkClient = NetworkClient()
            networkClient.performRequest(url: url, httpMethod: .post, parameters: body, headers: headers) { (data, error) in
                DispatchQueue.main.async {
                    guard error == nil else {
                        print("Error booking parking spot")
                        print(error!)
                        completion(error!)
                        return
                    }
                    completion(nil)
                }
            }
        }
    }
}
